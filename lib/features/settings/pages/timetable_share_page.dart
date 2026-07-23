import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../timetable/models/course.dart';
import '../../timetable/providers/timetable_provider.dart';
import '../../timetable/services/course_conflict_service.dart';

class TimetableSharePage extends ConsumerWidget {
  const TimetableSharePage({super.key});

  static const int _shareFormatVersion = 1;

  Future<void> _exportTimetable(BuildContext context, WidgetRef ref) async {
    final courses = ref.read(timetableProvider).value ?? [];

    if (courses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('当前没有可导出的课程')),
      );
      return;
    }

    final payload = {
      'type': 'njtech_timetable_share',
      'version': _shareFormatVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'courseCount': courses.length,
      'courses': courses.map((course) => course.toJson()).toList(),
    };

    final fileName =
        '南工课程表_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.json';

    final outputPath = await FilePicker.platform.saveFile(
      dialogTitle: '导出课表',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (outputPath == null) {
      return;
    }

    await File(outputPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已导出 ${courses.length} 门课程')),
    );
  }

  Future<void> _importTimetable(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: '选择课表分享文件',
      type: FileType.custom,
      allowedExtensions: ['json'],
      allowMultiple: false,
    );

    final path = result?.files.single.path;
    if (path == null) {
      return;
    }

    final importResult = await _readCoursesFromFile(path);

    if (!context.mounted) return;

    if (importResult.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(importResult.errorMessage!)),
      );
      return;
    }

    final importedCourses = importResult.courses;
    if (importedCourses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有识别到可导入的课程')),
      );
      return;
    }

    final conflicts = CourseConflictService.findConflicts(importedCourses);
    final confirmed = await _confirmImport(
      context: context,
      courseCount: importedCourses.length,
      conflicts: conflicts,
    );

    if (confirmed != true) {
      return;
    }

    await ref
        .read(timetableProvider.notifier)
        .clearAndImportCourses(importedCourses);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已导入 ${importedCourses.length} 门课程')),
    );
  }

  Future<bool?> _confirmImport({
    required BuildContext context,
    required int courseCount,
    required List<CourseConflict> conflicts,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        final conflictPreview = conflicts.take(3).map((item) {
          return '• ${item.title}';
        }).join('\n');

        return AlertDialog(
          title: const Text('导入课表'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '已识别到 $courseCount 门课程。\n\n'
                  '确认导入后，会先自动备份当前课表，再用分享文件中的课表替换当前课表。',
                ),
                if (conflicts.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    '检测到 ${conflicts.length} 处课程冲突：',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(conflictPreview),
                  if (conflicts.length > 3) Text('还有 ${conflicts.length - 3} 处冲突未显示'),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('确认导入'),
            ),
          ],
        );
      },
    );
  }

  Future<_TimetableImportResult> _readCoursesFromFile(String path) async {
    try {
      final text = await File(path).readAsString();
      final decoded = jsonDecode(text);

      if (decoded is! Map) {
        return const _TimetableImportResult(
          errorMessage: '文件格式不正确：不是南工课程表分享文件',
        );
      }

      if (decoded['type'] != 'njtech_timetable_share') {
        return const _TimetableImportResult(
          errorMessage: '文件类型不匹配，请选择南工课程表导出的 JSON 文件',
        );
      }

      if (decoded['version'] != _shareFormatVersion) {
        return const _TimetableImportResult(
          errorMessage: '分享文件版本不兼容，请重新导出后再导入',
        );
      }

      final rawCourses = decoded['courses'];
      if (rawCourses is! List) {
        return const _TimetableImportResult(
          errorMessage: '文件缺少课程数据',
        );
      }

      final courses = <Course>[];
      for (final item in rawCourses) {
        if (item is! Map) continue;

        final course = Course.fromJson(Map<dynamic, dynamic>.from(item));
        if (_isValidCourse(course)) {
          courses.add(course);
        }
      }

      return _TimetableImportResult(courses: courses);
    } catch (_) {
      return const _TimetableImportResult(
        errorMessage: '读取失败，请确认文件没有损坏',
      );
    }
  }

  bool _isValidCourse(Course course) {
    if (course.name.trim().isEmpty) return false;
    if (course.weekday < 1 || course.weekday > 7) return false;
    if (course.startSection < 1 || course.startSection > 10) return false;
    if (course.endSection < course.startSection || course.endSection > 10) {
      return false;
    }
    if (course.weeks.any((week) => week < 1 || week > 30)) return false;
    return true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(timetableProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('导入/导出'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '课表分享',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '你可以把当前课表导出成 JSON 文件，发给其他同学；其他同学在这里选择该文件后即可导入使用。',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  coursesAsync.when(
                    data: (courses) => Text('当前共有 ${courses.length} 门课程'),
                    loading: () => const Text('正在读取课程数量...'),
                    error: (error, _) => Text('课程读取失败：$error'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.upload_file_outlined),
                  title: const Text('导出当前课表'),
                  subtitle: const Text('生成可分享的 JSON 课表文件'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _exportTimetable(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.download_outlined),
                  title: const Text('导入分享课表'),
                  subtitle: const Text('选择别人分享给你的 JSON 课表文件'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _importTimetable(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '提示：导入分享课表会替换当前课表，但系统会自动保存导入前备份。你可以在“课程管理”右上角菜单中恢复导入前备份。',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimetableImportResult {
  final List<Course> courses;
  final String? errorMessage;

  const _TimetableImportResult({
    this.courses = const [],
    this.errorMessage,
  });
}
