import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/school_config.dart';
import '../models/course.dart';
import '../providers/timetable_provider.dart';

class CourseEditPage extends ConsumerStatefulWidget {
  final Course? course;

  const CourseEditPage({
    super.key,
    this.course,
  });

  @override
  ConsumerState<CourseEditPage> createState() => _CourseEditPageState();
}

class _CourseEditPageState extends ConsumerState<CourseEditPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _teacherController = TextEditingController();
  final _classroomController = TextEditingController();

  int _weekday = 1;
  int _startSection = 1;
  int _endSection = 2;
  Color _selectedColor = AppColors.primary;

  @override
  void initState() {
    super.initState();

    final course = widget.course;
    if (course != null) {
      _nameController.text = course.name;
      _teacherController.text = course.teacher;
      _classroomController.text = course.classroom;
      _weekday = course.weekday.clamp(1, 7).toInt();
      _startSection =
          course.startSection.clamp(1, SchoolConfig.maxSectionsPerDay).toInt();
      _endSection =
          course.endSection.clamp(1, SchoolConfig.maxSectionsPerDay).toInt();
      _selectedColor = course.color;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _teacherController.dispose();
    _classroomController.dispose();
    super.dispose();
  }

  Future<void> _saveCourse() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_endSection < _startSection) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('结束节次不能小于开始节次')),
      );
      return;
    }

    final oldCourse = widget.course;

    final course = Course(
      id: oldCourse?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      teacher: _teacherController.text.trim(),
      classroom: _classroomController.text.trim(),
      weekday: _weekday,
      startSection: _startSection,
      endSection: _endSection,
      weeks: oldCourse?.weeks ??
          List.generate(SchoolConfig.totalWeeks, (index) => index + 1),
      color: _selectedColor,
      source: oldCourse?.source ?? CourseSource.manual,
    );

    final conflictCourse = _findConflictCourse(course);
    if (conflictCourse != null) {
      final shouldContinue = await _confirmConflict(conflictCourse);
      if (shouldContinue != true) {
        return;
      }
    }

    if (oldCourse == null) {
      await ref.read(timetableProvider.notifier).addCourse(course);
    } else {
      await ref.read(timetableProvider.notifier).updateCourse(course);
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Course? _findConflictCourse(Course course) {
    final courses = ref.read(timetableProvider).value ?? [];

    for (final item in courses) {
      if (item.id == course.id) continue;
      if (item.weekday != course.weekday) continue;
      if (!_hasWeekOverlap(item.weeks, course.weeks)) continue;
      if (!_hasSectionOverlap(item, course)) continue;

      return item;
    }

    return null;
  }

  bool _hasWeekOverlap(List<int> a, List<int> b) {
    final weeks = a.toSet();
    return b.any(weeks.contains);
  }

  bool _hasSectionOverlap(Course a, Course b) {
    return a.startSection <= b.endSection && b.startSection <= a.endSection;
  }

  Future<bool?> _confirmConflict(Course conflictCourse) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('检测到课程冲突'),
          content: Text(
            '当前课程与「${conflictCourse.name}」在部分周次和节次上有重叠。\n\n'
            '如果这是单双周或临时安排，你仍然可以继续保存。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('返回修改'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('继续保存'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.course != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? '编辑课程' : '添加课程'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saveCourse,
            child: const Text('保存'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildTextField(
                  controller: _nameController,
                  label: '课程名称',
                  hintText: '例如：高等数学',
                  requiredMessage: '请输入课程名称',
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _teacherController,
                  label: '任课老师',
                  hintText: '例如：张老师',
                  requiredMessage: '请输入任课老师',
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _classroomController,
                  label: '上课地点',
                  hintText: '例如：仁智楼 301',
                  requiredMessage: '请输入上课地点',
                ),
                const SizedBox(height: 20),
                _buildWeekdaySelector(),
                const SizedBox(height: 20),
                _buildSectionSelector(),
                const SizedBox(height: 20),
                _buildColorSelector(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required String requiredMessage,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return requiredMessage;
        }

        return null;
      },
    );
  }

  Widget _buildWeekdaySelector() {
    return _FormSection(
      title: '星期',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(7, (index) {
          final weekday = index + 1;
          final selected = _weekday == weekday;

          return ChoiceChip(
            label: Text(_weekdayText(weekday)),
            selected: selected,
            onSelected: (_) {
              setState(() {
                _weekday = weekday;
              });
            },
          );
        }),
      ),
    );
  }

  Widget _buildSectionSelector() {
    return _FormSection(
      title: '节次',
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<int>(
              value: _startSection,
              decoration: const InputDecoration(
                labelText: '开始节次',
                border: OutlineInputBorder(),
              ),
              items: List.generate(SchoolConfig.maxSectionsPerDay, (index) {
                final section = index + 1;
                final sectionTime = SchoolConfig.sectionTimes[index];

                return DropdownMenuItem(
                  value: section,
                  child: Text(
                    '第 $section 节 ${sectionTime.start}-${sectionTime.end}',
                  ),
                );
              }),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _startSection = value;

                  if (_endSection < _startSection) {
                    _endSection = _startSection;
                  }
                });
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<int>(
              value: _endSection,
              decoration: const InputDecoration(
                labelText: '结束节次',
                border: OutlineInputBorder(),
              ),
              items: List.generate(SchoolConfig.maxSectionsPerDay, (index) {
                final section = index + 1;
                final sectionTime = SchoolConfig.sectionTimes[index];

                return DropdownMenuItem(
                  value: section,
                  child: Text(
                    '第 $section 节 ${sectionTime.start}-${sectionTime.end}',
                  ),
                );
              }),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _endSection = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorSelector() {
    return _FormSection(
      title: '课程颜色',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: AppColors.courseColors.map((color) {
          final selected = _selectedColor == color;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedColor = color;
              });
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? Colors.black : Colors.transparent,
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 20,
                    )
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }

  String _weekdayText(int weekday) {
    switch (weekday) {
      case 1:
        return '周一';
      case 2:
        return '周二';
      case 3:
        return '周三';
      case 4:
        return '周四';
      case 5:
        return '周五';
      case 6:
        return '周六';
      case 7:
        return '周日';
      default:
        return '';
    }
  }
}

class _FormSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _FormSection({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
