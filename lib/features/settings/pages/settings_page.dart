import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/app_settings.dart';
import '../providers/settings_provider.dart';
import 'about_page.dart';
import 'backup_management_page.dart';
import 'course_management_page.dart';
import 'feedback_page.dart';
import 'timetable_share_page.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        centerTitle: true,
      ),
      body: settingsAsync.when(
        data: (settings) {
          final currentWeek = ref
              .read(settingsProvider.notifier)
              .getCurrentWeek(settings);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SettingsSection(
                title: '课程',
                children: [
                  ListTile(
                    leading: const Icon(Icons.list_alt_outlined),
                    title: const Text('课程管理'),
                    subtitle: const Text('查看、编辑、删除课程或清空导入课程'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _push(context, const CourseManagementPage()),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.ios_share_outlined),
                    title: const Text('导入/导出'),
                    subtitle: const Text('导出课表文件，或导入别人分享的课表'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _push(context, const TimetableSharePage()),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.history_outlined),
                    title: const Text('备份管理'),
                    subtitle: const Text('查看、恢复或清除导入前备份'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _push(context, const BackupManagementPage()),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _AppearanceCard(
                settings: settings,
                onChanged: (mode) {
                  ref.read(settingsProvider.notifier).updateThemeMode(mode);
                },
              ),
              const SizedBox(height: 12),
              _SemesterCard(
                settings: settings,
                currentWeek: currentWeek,
                onPickDate: () => _pickSemesterStartDate(
                  context: context,
                  ref: ref,
                  initialDate: settings.semesterStartDate,
                ),
                onChangeWeek: (week) {
                  ref
                      .read(settingsProvider.notifier)
                      .updateManualCurrentWeek(week);
                },
                onClearManualWeek: () {
                  ref
                      .read(settingsProvider.notifier)
                      .clearManualCurrentWeek();
                },
              ),
              const SizedBox(height: 12),
              _ReminderCard(
                settings: settings,
                onEnabledChanged: (enabled) {
                  ref
                      .read(settingsProvider.notifier)
                      .updateCourseReminderEnabled(enabled);
                },
                onMinutesChanged: (minutes) {
                  ref
                      .read(settingsProvider.notifier)
                      .updateCourseReminderMinutes(minutes);
                },
                onScopeChanged: (scope) {
                  ref
                      .read(settingsProvider.notifier)
                      .updateCourseReminderScope(scope);
                },
                onRefreshReminders: () async {
                  await ref
                      .read(settingsProvider.notifier)
                      .refreshCourseReminders();

                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('课程提醒已重新生成')),
                  );
                },
              ),
              const SizedBox(height: 12),
              _SettingsSection(
                title: '其他',
                children: [
                  ListTile(
                    leading: const Icon(Icons.feedback_outlined),
                    title: const Text('反馈'),
                    subtitle: const Text('通过邮箱联系开发者'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _push(context, const FeedbackPage()),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('关于'),
                    subtitle: const Text('产品介绍、联系方式与开源许可'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _push(context, const AboutPage()),
                  ),
                ],
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
              child: Text('设置加载失败：$error'),
            ),
          );
        },
      ),
    );
  }

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  Future<void> _pickSemesterStartDate({
    required BuildContext context,
    required WidgetRef ref,
    required DateTime initialDate,
  }) async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 2, 1, 1),
      lastDate: DateTime(now.year + 2, 12, 31),
    );

    if (pickedDate == null) {
      return;
    }

    await ref
        .read(settingsProvider.notifier)
        .updateSemesterStartDate(pickedDate);
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _AppearanceCard extends StatelessWidget {
  final AppSettings settings;
  final ValueChanged<ThemeModeOption> onChanged;

  const _AppearanceCard({
    required this.settings,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '外观',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SegmentedButton<ThemeModeOption>(
              segments: const [
                ButtonSegment(
                  value: ThemeModeOption.system,
                  label: Text('跟随'),
                  icon: Icon(Icons.brightness_auto_outlined),
                ),
                ButtonSegment(
                  value: ThemeModeOption.light,
                  label: Text('浅色'),
                  icon: Icon(Icons.light_mode_outlined),
                ),
                ButtonSegment(
                  value: ThemeModeOption.dark,
                  label: Text('深色'),
                  icon: Icon(Icons.dark_mode_outlined),
                ),
              ],
              selected: {settings.themeModeOption},
              onSelectionChanged: (selection) {
                onChanged(selection.first);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SemesterCard extends StatelessWidget {
  final AppSettings settings;
  final int currentWeek;
  final VoidCallback onPickDate;
  final ValueChanged<int> onChangeWeek;
  final VoidCallback onClearManualWeek;

  const _SemesterCard({
    required this.settings,
    required this.currentWeek,
    required this.onPickDate,
    required this.onChangeWeek,
    required this.onClearManualWeek,
  });

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat('yyyy-MM-dd').format(settings.semesterStartDate);
    final isManual = settings.manualCurrentWeek != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '学期',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('学期开始日期'),
              subtitle: Text(dateText),
              trailing: const Icon(Icons.calendar_month_outlined),
              onTap: onPickDate,
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('当前周'),
              subtitle: Text(isManual ? '手动设置' : '根据学期开始日期自动计算'),
              trailing: Text(
                '第 $currentWeek 周',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: currentWeek,
              decoration: const InputDecoration(
                labelText: '手动设置当前周',
                border: OutlineInputBorder(),
              ),
              items: List.generate(settings.totalWeeks, (index) {
                final week = index + 1;

                return DropdownMenuItem(
                  value: week,
                  child: Text('第 $week 周'),
                );
              }),
              onChanged: (week) {
                if (week == null) return;
                onChangeWeek(week);
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: isManual ? onClearManualWeek : null,
              icon: const Icon(Icons.refresh),
              label: const Text('恢复自动计算当前周'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final AppSettings settings;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<int> onMinutesChanged;
  final ValueChanged<ReminderScope> onScopeChanged;
  final VoidCallback onRefreshReminders;

  const _ReminderCard({
    required this.settings,
    required this.onEnabledChanged,
    required this.onMinutesChanged,
    required this.onScopeChanged,
    required this.onRefreshReminders,
  });

  @override
  Widget build(BuildContext context) {
    const minuteOptions = [5, 10, 15, 30, 60];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '课程提醒',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('开启课程提醒'),
              subtitle: const Text('课程开始前发送系统通知；如果收不到提醒，请检查系统通知权限'),
              value: settings.courseReminderEnabled,
              onChanged: onEnabledChanged,
            ),
            const Divider(),
            DropdownButtonFormField<int>(
              value: settings.courseReminderMinutes,
              decoration: const InputDecoration(
                labelText: '提醒时间',
                border: OutlineInputBorder(),
              ),
              items: minuteOptions.map((minutes) {
                return DropdownMenuItem(
                  value: minutes,
                  child: Text('提前 $minutes 分钟'),
                );
              }).toList(),
              onChanged: settings.courseReminderEnabled
                  ? (minutes) {
                      if (minutes == null) return;
                      onMinutesChanged(minutes);
                    }
                  : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ReminderScope>(
              value: settings.courseReminderScope,
              decoration: const InputDecoration(
                labelText: '提醒范围',
                border: OutlineInputBorder(),
              ),
              items: ReminderScope.values.map((scope) {
                return DropdownMenuItem(
                  value: scope,
                  child: Text(_scopeText(scope)),
                );
              }).toList(),
              onChanged: settings.courseReminderEnabled
                  ? (scope) {
                      if (scope == null) return;
                      onScopeChanged(scope);
                    }
                  : null,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed:
                  settings.courseReminderEnabled ? onRefreshReminders : null,
              icon: const Icon(Icons.notifications_active_outlined),
              label: const Text('检查权限并重新生成提醒'),
            ),
          ],
        ),
      ),
    );
  }

  String _scopeText(ReminderScope scope) {
    switch (scope) {
      case ReminderScope.today:
        return '仅当天课程';
      case ReminderScope.currentWeek:
        return '仅当前周课程';
      case ReminderScope.allFuture:
        return '所有未来课程';
    }
  }
}
