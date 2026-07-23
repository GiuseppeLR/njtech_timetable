import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/local/course_repository.dart';
import '../../timetable/providers/timetable_provider.dart';

class BackupManagementPage extends ConsumerStatefulWidget {
  const BackupManagementPage({super.key});

  @override
  ConsumerState<BackupManagementPage> createState() =>
      _BackupManagementPageState();
}

class _BackupManagementPageState extends ConsumerState<BackupManagementPage> {
  late Future<List<CourseBackupInfo>> _future;

  @override
  void initState() {
    super.initState();
    _future = CourseRepository().getBackupInfos();
  }

  void _reload() {
    setState(() {
      _future = CourseRepository().getBackupInfos();
    });
  }

  Future<void> _restoreBackup(CourseBackupInfo info) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('恢复备份'),
          content: Text(
            '确定要恢复 ${DateFormat('yyyy-MM-dd HH:mm').format(info.createdAt)} 的备份吗？\n\n'
            '当前课表会先自动备份。',
          ),
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

    final restored = await ref
        .read(timetableProvider.notifier)
        .restoreBackupCourses(index: info.index);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(restored ? '备份已恢复' : '恢复失败，备份为空')),
    );
    _reload();
  }

  Future<void> _clearBackups() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('清除备份'),
          content: const Text('确定要清除所有导入前备份吗？此操作不可恢复。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('清除'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await CourseRepository().clearBackups();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('备份已清除')),
    );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('备份管理'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: '清除备份',
            onPressed: _clearBackups,
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
      body: FutureBuilder<List<CourseBackupInfo>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final backups = snapshot.data!;
          if (backups.isEmpty) {
            return const Center(child: Text('暂无备份'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: backups.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final backup = backups[index];

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.history_outlined),
                  title: Text('备份 ${index + 1}'),
                  subtitle: Text(
                    '${DateFormat('yyyy-MM-dd HH:mm').format(backup.createdAt)} · '
                    '${backup.courseCount} 门课程',
                  ),
                  trailing: const Icon(Icons.restore_outlined),
                  onTap: () => _restoreBackup(backup),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
