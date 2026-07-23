import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../import/pages/import_page.dart';
import '../../settings/pages/settings_page.dart';
import '../../settings/providers/settings_provider.dart';
import '../providers/timetable_provider.dart';
import '../widgets/timetable_grid.dart';
import 'course_edit_page.dart';

class TimetablePage extends ConsumerStatefulWidget {
  const TimetablePage({super.key});

  @override
  ConsumerState<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends ConsumerState<TimetablePage> {
  bool _guideScheduled = false;

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(timetableProvider);
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('南工课程表'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: '导入课表',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ImportPage(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: '设置',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SettingsPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: settingsAsync.when(
        data: (settings) {
          _scheduleFirstLaunchGuide(settings.firstLaunchGuideShown);

          final currentWeek = ref
              .read(settingsProvider.notifier)
              .getCurrentWeek(settings);

          return coursesAsync.when(
            data: (courses) {
              return Column(
                children: [
                  _WeekHeader(
                    currentWeek: currentWeek,
                    totalWeeks: settings.totalWeeks,
                    semesterStartDate: settings.semesterStartDate,
                    isManualWeek: settings.manualCurrentWeek != null,
                    onPreviousWeek: () {
                      ref
                          .read(settingsProvider.notifier)
                          .updateManualCurrentWeek(currentWeek - 1);
                    },
                    onNextWeek: () {
                      ref
                          .read(settingsProvider.notifier)
                          .updateManualCurrentWeek(currentWeek + 1);
                    },
                    onBackToAutoWeek: () {
                      ref
                          .read(settingsProvider.notifier)
                          .clearManualCurrentWeek();
                    },
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: TimetableGrid(
                      courses: courses,
                      currentWeek: currentWeek,
                    ),
                  ),
                ],
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
                  child: Text('课程数据加载失败：$error'),
                ),
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
              child: Text('设置加载失败：$error'),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const CourseEditPage(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _scheduleFirstLaunchGuide(bool alreadyShown) {
    if (alreadyShown || _guideScheduled) return;
    _guideScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('欢迎使用南工课程表'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('建议按下面顺序完成首次设置：'),
                SizedBox(height: 12),
                Text('1. 在设置中确认学期开始日期'),
                Text('2. 从教务系统或 XLS 文件导入课表'),
                Text('3. 按需要开启课程提醒'),
                Text('4. 可通过导入/导出分享课表给同学'),
              ],
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('知道了'),
              ),
            ],
          );
        },
      );

      await ref.read(settingsProvider.notifier).markFirstLaunchGuideShown();
    });
  }
}

class _WeekHeader extends StatelessWidget {
  final int currentWeek;
  final int totalWeeks;
  final DateTime semesterStartDate;
  final bool isManualWeek;
  final VoidCallback onPreviousWeek;
  final VoidCallback onNextWeek;
  final VoidCallback onBackToAutoWeek;

  const _WeekHeader({
    required this.currentWeek,
    required this.totalWeeks,
    required this.semesterStartDate,
    required this.isManualWeek,
    required this.onPreviousWeek,
    required this.onNextWeek,
    required this.onBackToAutoWeek,
  });

  @override
  Widget build(BuildContext context) {
    final canGoPrevious = currentWeek > 1;
    final canGoNext = currentWeek < totalWeeks;
    final weekStartDate = semesterStartDate.add(
      Duration(days: (currentWeek - 1) * 7),
    );
    final weekEndDate = weekStartDate.add(const Duration(days: 6));
    final dateRangeText =
        '${_formatDate(weekStartDate)} - ${_formatDate(weekEndDate)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: '上一周',
                onPressed: canGoPrevious ? onPreviousWeek : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      dateRangeText,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isManualWeek ? '第 $currentWeek 周（手动）' : '第 $currentWeek 周',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isManualWeek ? '正在查看手动选择的周次' : '已根据今天自动定位',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: '下一周',
                onPressed: canGoNext ? onNextWeek : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          TextButton.icon(
            onPressed: isManualWeek ? onBackToAutoWeek : null,
            icon: const Icon(Icons.today_outlined, size: 18),
            label: const Text('自动定位本周'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }
}
