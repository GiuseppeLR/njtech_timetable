import 'package:hive_flutter/hive_flutter.dart';

import '../../features/timetable/models/course.dart';

class CourseBackupInfo {
  final int index;
  final DateTime createdAt;
  final int courseCount;

  const CourseBackupInfo({
    required this.index,
    required this.createdAt,
    required this.courseCount,
  });
}

class CourseRepository {
  static const String _boxName = 'courses';
  static const String _backupBoxName = 'course_backup';
  static const String _backupListKey = 'backupList';
  static const String _legacyBackupCoursesKey = 'courses';
  static const String _legacyBackupTimeKey = 'backupTime';
  static const int _maxBackups = 3;

  Future<Box> _openBox() {
    return Hive.openBox(_boxName);
  }

  Future<List<Course>> getCourses() async {
    final box = await _openBox();

    return box.values
        .map((value) => Course.fromJson(Map<dynamic, dynamic>.from(value)))
        .toList();
  }

  Future<void> saveCourses(List<Course> courses) async {
    final box = await _openBox();

    await box.clear();

    for (final course in courses) {
      await box.put(course.id, course.toJson());
    }
  }

  Future<void> backupCourses(List<Course> courses) async {
    if (courses.isEmpty) return;

    final box = await Hive.openBox(_backupBoxName);
    final backups = await _readBackupEntries(box);

    backups.insert(0, {
      'createdAt': DateTime.now().toIso8601String(),
      'courses': courses.map((course) => course.toJson()).toList(),
    });

    await box.put(_backupListKey, backups.take(_maxBackups).toList());
  }

  Future<List<CourseBackupInfo>> getBackupInfos() async {
    final box = await Hive.openBox(_backupBoxName);
    final backups = await _readBackupEntries(box);

    return [
      for (var index = 0; index < backups.length; index++)
        CourseBackupInfo(
          index: index,
          createdAt: DateTime.tryParse(
                backups[index]['createdAt']?.toString() ?? '',
              ) ??
              DateTime.fromMillisecondsSinceEpoch(0),
          courseCount: (backups[index]['courses'] as List?)?.length ?? 0,
        ),
    ];
  }

  Future<List<Course>> getBackupCourses({int index = 0}) async {
    final box = await Hive.openBox(_backupBoxName);
    final backups = await _readBackupEntries(box);

    if (index < 0 || index >= backups.length) {
      return [];
    }

    final values = backups[index]['courses'];
    if (values is! List) {
      return [];
    }

    return values
        .map((value) => Course.fromJson(Map<dynamic, dynamic>.from(value)))
        .toList();
  }

  Future<DateTime?> getBackupTime() async {
    final infos = await getBackupInfos();
    if (infos.isEmpty) return null;
    return infos.first.createdAt;
  }

  Future<void> clearBackups() async {
    final box = await Hive.openBox(_backupBoxName);
    await box.clear();
  }

  Future<List<Map<dynamic, dynamic>>> _readBackupEntries(Box box) async {
    final current = box.get(_backupListKey);
    if (current is List) {
      return current
          .whereType<Map>()
          .map((item) => Map<dynamic, dynamic>.from(item))
          .toList();
    }

    final legacyCourses = box.get(_legacyBackupCoursesKey);
    if (legacyCourses is List) {
      final legacyTime = DateTime.tryParse(
            box.get(_legacyBackupTimeKey)?.toString() ?? '',
          ) ??
          DateTime.now();

      final migrated = [
        {
          'createdAt': legacyTime.toIso8601String(),
          'courses': legacyCourses,
        }
      ];
      await box.put(_backupListKey, migrated);
      return migrated;
    }

    return [];
  }

  Future<void> addCourse(Course course) async {
    final box = await _openBox();
    await box.put(course.id, course.toJson());
  }

  Future<void> updateCourse(Course course) async {
    final box = await _openBox();
    await box.put(course.id, course.toJson());
  }

  Future<void> deleteCourse(String courseId) async {
    final box = await _openBox();
    await box.delete(courseId);
  }
}
