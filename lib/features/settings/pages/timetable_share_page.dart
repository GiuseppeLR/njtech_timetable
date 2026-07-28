import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../timetable/models/course.dart';
import '../../timetable/providers/timetable_provider.dart';

class TimetableSharePage extends ConsumerWidget {
  const TimetableSharePage({super.key});

  static const int _shareFormatVersion = 1;

  bool get _isDesktop =>
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  Future<void> _exportTimetable(BuildContext context, WidgetRef ref) async {
    final courses = ref.read(timetableProvider).value ?? [];

    if (courses.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('当前没有可导出的课程')),
        );
      }
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

    final jsonContent = const JsonEncoder.withIndent('  ').convert(payload);

    if (_isDesktop) {
      // 桌面端：使用保存文件对话框
      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: '导出课表',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (outputPath == null) return;

      await File(outputPath).writeAsString(jsonContent);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已导出 ${courses.length} 门课程')),
        );
      }
    } else {
      // 移动端：写入临时目录后通过系统分享面板发送
      try {
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/$fileName');
        await tempFile.writeAsString(jsonContent);

        if (!context.mounted) return;

        // 获取按钮位置用于 iPad 弹出分享面板
        final box = context.findRenderObject() as RenderBox?;
        final sharePositionOrigin = box != null
            ? box.localToGlobal(Offset.zero) & box.size
            : null;

        await Share.shareXFiles(
          [XFile(tempFile.path)],
          text: '南工课程表分享（${courses.length} 门课程）',
          sharePositionOrigin: sharePositionOrigin,
        );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('导出失败：$e')),
          );
        }
      }
    }
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

    final importedCourses = await _readCoursesFromFile(path);

    if (!context.mounted) return;

    if (importedCourses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有识别到可导入的课程')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('导入课表'),
          content: Text(
            '已识别到 ${importedCourses.length} 门课程。\n\n'
            '确认导入后，会先自动备份当前课表，再用分享文件中的课表替换当前课表。',
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

  Future<List<Course>> _readCoursesFromFile(String path) async {
    try {
      final text = await File(path).readAsString();
      final decoded = jsonDecode(text);

      final List rawCourses;
      if (decoded is Map && decoded['courses'] is List) {
        rawCourses = decoded['courses'] as List;
      } else if (decoded is List) {
        rawCourses = decoded;
      } else {
        rawCourses = const [];
      }

      return rawCourses
          .whereType<Map>()
          .map((item) => Course.fromJson(Map<dynamic, dynamic>.from(item)))
          .toList();
    } catch (_) {
      return [];
    }
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
                    data: (courses) =>
                        Text('当前共有 ${courses.length} 门课程'),
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
                '提示：导入分享课表会替换当前课表，但系统会自动保存导入前备份。你可以在"课程管理"右上角菜单中恢复导入前备份。',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color:
                          Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
