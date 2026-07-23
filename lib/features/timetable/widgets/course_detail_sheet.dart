import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/school_config.dart';
import '../models/course.dart';
import '../pages/course_edit_page.dart';
import '../providers/timetable_provider.dart';

class CourseDetailSheet extends ConsumerWidget {
  final Course course;

  const CourseDetailSheet({
    super.key,
    required this.course,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final safeStartSection =
        course.startSection.clamp(1, SchoolConfig.maxSectionsPerDay).toInt();
    final safeEndSection =
        course.endSection.clamp(1, SchoolConfig.maxSectionsPerDay).toInt();
    final startTime = SchoolConfig.sectionTimes[safeStartSection - 1];
    final endTime = SchoolConfig.sectionTimes[safeEndSection - 1];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 36,
                  decoration: BoxDecoration(
                    color: course.color,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    course.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _InfoRow(label: '老师', value: course.teacher),
            _InfoRow(label: '教室', value: course.classroom),
            _InfoRow(label: '星期', value: _weekdayText(course.weekday)),
            _InfoRow(
              label: '节次',
              value: '第 ${course.startSection}-${course.endSection} 节',
            ),
            _InfoRow(
              label: '时间',
              value: '${startTime.start}-${endTime.end}',
            ),
            _InfoRow(
              label: '周次',
              value: _formatWeeks(course.weeks),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();

                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CourseEditPage(course: course),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('编辑'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () async {
                      await ref
                          .read(timetableProvider.notifier)
                          .deleteCourse(course.id);

                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('删除'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _weekdayText(int weekday) {
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    if (weekday < 1 || weekday > weekdays.length) {
      return '未知';
    }

    return weekdays[weekday - 1];
  }

  String _formatWeeks(List<int> weeks) {
    if (weeks.length >= SchoolConfig.totalWeeks) {
      return '全部周';
    }

    return weeks.join('、');
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
