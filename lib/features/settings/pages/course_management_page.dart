import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../timetable/models/course.dart';
import '../../timetable/providers/timetable_provider.dart';
import '../../timetable/pages/course_edit_page.dart';

class CourseManagementPage extends ConsumerStatefulWidget {
  const CourseManagementPage({super.key});

  @override
  ConsumerState<CourseManagementPage> createState() =>
      _CourseManagementPageState();
}

class _CourseManagementPageState extends ConsumerState<CourseManagementPage> {
  String _keyword = '';

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(timetableProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('课程管理'),
        centerTitle: true,
        actions: [
          PopupMenuButton<_CourseAction>(
            onSelected: (action) {
              switch (action) {
                case _CourseAction.clearImported:
                  _confirmClearImported(context, ref);
                  break;
                case _CourseAction.clearAll:
                  _confirmClearAll(context, ref);
                  break;
                case _CourseAction.restoreBackup:
                  _confirmRestoreBackup(context, ref);
                  break;
              }
            },
            itemBuilder: (context) {
              return const [
                PopupMenuItem(
                  value: _CourseAction.clearImported,
                  child: Text('清空导入课程'),
                ),
                PopupMenuItem(
                  value: _CourseAction.clearAll,
                  child: Text('清空全部课程'),
                ),
                PopupMenuItem(
                  value: _CourseAction.restoreBackup,
                  child: Text('恢复导入前备份'),
                ),
              ];
            },
          ),
        ],
      ),
      body: coursesAsync.when(
        data: (courses) {
          if (courses.isEmpty) {
            return const Center(
              child: Text('暂无课程'),
            );
          }

          final filteredCourses = _filterCourses(courses);

          if (filteredCourses.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SearchBox(
                  keyword: _keyword,
                  onChanged: (value) {
                    setState(() {
                      _keyword = value;
                    });
                  },
                ),
                const SizedBox(height: 24),
                const Center(
                  child: Text('没有找到匹配的课程'),
                ),
              ],
            );
          }

          final sortedCourses = [...filteredCourses]
            ..sort((a, b) {
              final weekdayCompare = a.weekday.compareTo(b.weekday);
              if (weekdayCompare != 0) return weekdayCompare;

              return a.startSection.compareTo(b.startSection);
            });

          final groupedCourses = _groupByWeekday(sortedCourses);

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: groupedCourses.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _SearchBox(
                  keyword: _keyword,
                  onChanged: (value) {
                    setState(() {
                      _keyword = value;
                    });
                  },
                );
              }

              final entry = groupedCourses.entries.elementAt(index - 1);

              return _WeekdaySection(
                weekday: entry.key,
                courses: entry.value,
                onEdit: (course) {
                  _openEditPage(context, course);
                },
                onDelete: (course) {
                  _confirmDeleteCourse(context, ref, course);
                },
              );
            },
          );
        },
        loading: () {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
        error: (error, stackTrace) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('课程加载失败：$error'),
            ),
          );
        },
      ),
    );
  }

  List<Course> _filterCourses(List<Course> courses) {
    final keyword = _keyword.trim().toLowerCase();
    if (keyword.isEmpty) {
      return courses;
    }

    return courses.where((course) {
      return course.name.toLowerCase().contains(keyword) ||
          course.teacher.toLowerCase().contains(keyword) ||
          course.classroom.toLowerCase().contains(keyword);
    }).toList();
  }

  Map<int, List<Course>> _groupByWeekday(List<Course> courses) {
    final map = <int, List<Course>>{};

    for (final course in courses) {
      map.putIfAbsent(course.weekday, () => []).add(course);
    }

    return map;
  }

  void _openEditPage(BuildContext context, Course course) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CourseEditPage(course: course),
      ),
    );
  }

  Future<void> _confirmDeleteCourse(
    BuildContext context,
    WidgetRef ref,
    Course course,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除课程'),
          content: Text('确定要删除「${course.name}」吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await ref.read(timetableProvider.notifier).deleteCourse(course.id);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('课程已删除')),
    );
  }

  Future<void> _confirmClearImported(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('清空导入课程'),
          content: const Text('确定要删除所有从教务系统或文件导入的课程吗？手动添加的课程会保留。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('清空'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await ref.read(timetableProvider.notifier).clearImportedCourses();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('导入课程已清空')),
    );
  }

  Future<void> _confirmClearAll(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('清空全部课程'),
          content: const Text('确定要删除全部课程吗？此操作不可恢复。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('清空全部'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await ref.read(timetableProvider.notifier).clearAllCourses();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('全部课程已清空')),
    );
  }

  Future<void> _confirmRestoreBackup(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('恢复导入前备份'),
          content: const Text('将使用最近一次教务导入前自动保存的旧课表覆盖当前课表。确定要恢复吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('恢复'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final restored =
        await ref.read(timetableProvider.notifier).restoreBackupCourses();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(restored ? '已恢复导入前备份' : '暂无可恢复的备份')),
    );
  }
}

class _CourseTile extends StatelessWidget {
  final Course course;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CourseTile({
    required this.course,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 10,
          height: 44,
          decoration: BoxDecoration(
            color: course.color,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        title: Text(
          course.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${_weekdayText(course.weekday)} 第${course.startSection}-${course.endSection}节 · '
          '${course.classroom} · ${course.teacher}\n'
          '${course.source == CourseSource.imported ? '导入课程' : '手动课程'}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<_CourseTileAction>(
          onSelected: (action) {
            switch (action) {
              case _CourseTileAction.edit:
                onEdit();
                break;
              case _CourseTileAction.delete:
                onDelete();
                break;
            }
          },
          itemBuilder: (context) {
            return const [
              PopupMenuItem(
                value: _CourseTileAction.edit,
                child: Text('编辑'),
              ),
              PopupMenuItem(
                value: _CourseTileAction.delete,
                child: Text('删除'),
              ),
            ];
          },
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
}

class _SearchBox extends StatefulWidget {
  final String keyword;
  final ValueChanged<String> onChanged;

  const _SearchBox({
    required this.keyword,
    required this.onChanged,
  });

  @override
  State<_SearchBox> createState() => _SearchBoxState();
}

class _SearchBoxState extends State<_SearchBox> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.keyword);
  }

  @override
  void didUpdateWidget(covariant _SearchBox oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.keyword != _controller.text) {
      _controller.text = widget.keyword;
      _controller.selection = TextSelection.collapsed(
        offset: widget.keyword.length,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.search),
        hintText: '搜索课程、教师或教室',
        border: OutlineInputBorder(),
      ),
      onChanged: widget.onChanged,
    );
  }
}

class _WeekdaySection extends StatelessWidget {
  final int weekday;
  final List<Course> courses;
  final ValueChanged<Course> onEdit;
  final ValueChanged<Course> onDelete;

  const _WeekdaySection({
    required this.weekday,
    required this.courses,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
          child: Row(
            children: [
              Text(
                _weekdayText(weekday),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${courses.length} 门',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
        ...courses.map(
          (course) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _CourseTile(
              course: course,
              onEdit: () => onEdit(course),
              onDelete: () => onDelete(course),
            ),
          ),
        ),
      ],
    );
  }

  String _weekdayText(int weekday) {
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

    if (weekday < 1 || weekday > weekdays.length) {
      return '未知';
    }

    return weekdays[weekday - 1];
  }
}

enum _CourseAction {
  clearImported,
  clearAll,
  restoreBackup,
}

enum _CourseTileAction {
  edit,
  delete,
}
