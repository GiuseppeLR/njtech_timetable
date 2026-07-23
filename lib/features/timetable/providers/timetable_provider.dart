import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/course_repository.dart';
import '../../../data/local/settings_repository.dart';
import '../../notifications/services/course_notification_service.dart';
import '../data/demo_courses.dart';
import '../models/course.dart';

final courseRepositoryProvider = Provider<CourseRepository>((ref) {
  return CourseRepository();
});

final timetableProvider =
    AsyncNotifierProvider<TimetableNotifier, List<Course>>(
  TimetableNotifier.new,
);

class TimetableNotifier extends AsyncNotifier<List<Course>> {
  @override
  Future<List<Course>> build() async {
    final repository = ref.read(courseRepositoryProvider);
    final courses = await repository.getCourses();

    if (courses.isEmpty) {
      final initialCourses = List.of(demoCourses);
      await repository.saveCourses(initialCourses);
      return initialCourses;
    }

    return courses;
  }

  Future<void> addCourse(Course course) async {
    final currentCourses = state.value ?? [];
    final newCourses = [...currentCourses, course];

    state = AsyncData(newCourses);
    await ref.read(courseRepositoryProvider).addCourse(course);
    await _rescheduleReminders(newCourses);
  }

  Future<void> updateCourse(Course updatedCourse) async {
    final currentCourses = state.value ?? [];

    final newCourses = [
      for (final course in currentCourses)
        if (course.id == updatedCourse.id) updatedCourse else course,
    ];

    state = AsyncData(newCourses);
    await ref.read(courseRepositoryProvider).updateCourse(updatedCourse);
    await _rescheduleReminders(newCourses);
  }

  Future<void> deleteCourse(String courseId) async {
    final currentCourses = state.value ?? [];

    final newCourses =
        currentCourses.where((course) => course.id != courseId).toList();

    state = AsyncData(newCourses);
    await ref.read(courseRepositoryProvider).deleteCourse(courseId);
    await _rescheduleReminders(newCourses);
  }

  Future<void> importCourses(List<Course> newCourses) async {
    final currentCourses = state.value ?? [];

    final manualCourses =
        currentCourses.where((c) => c.source != CourseSource.imported).toList();
    final allCourses = [...manualCourses, ...newCourses];

    state = AsyncData(allCourses);
    await ref.read(courseRepositoryProvider).saveCourses(allCourses);
    await _rescheduleReminders(allCourses);
  }

  Future<void> clearAndImportCourses(List<Course> newCourses) async {
    final currentCourses = state.value ?? [];
    if (currentCourses.isNotEmpty) {
      await ref.read(courseRepositoryProvider).backupCourses(currentCourses);
    }

    state = AsyncData(newCourses);
    await ref.read(courseRepositoryProvider).saveCourses(newCourses);
    await _rescheduleReminders(newCourses);
  }

  Future<bool> restoreBackupCourses({int index = 0}) async {
    final repository = ref.read(courseRepositoryProvider);
    final backupCourses = await repository.getBackupCourses(index: index);

    if (backupCourses.isEmpty) {
      return false;
    }

    final currentCourses = state.value ?? [];
    if (currentCourses.isNotEmpty) {
      await repository.backupCourses(currentCourses);
    }

    state = AsyncData(backupCourses);
    await repository.saveCourses(backupCourses);
    await _rescheduleReminders(backupCourses);
    return true;
  }

  Future<void> clearImportedCourses() async {
    final currentCourses = state.value ?? [];
    final manualCourses =
        currentCourses.where((c) => c.source != CourseSource.imported).toList();

    state = AsyncData(manualCourses);
    await ref.read(courseRepositoryProvider).saveCourses(manualCourses);
    await _rescheduleReminders(manualCourses);
  }

  Future<void> clearAllCourses() async {
    state = const AsyncData<List<Course>>([]);
    await ref.read(courseRepositoryProvider).saveCourses([]);
    await _rescheduleReminders([]);
  }

  Future<void> _rescheduleReminders(List<Course> courses) async {
    final settings = await SettingsRepository().getSettings();
    if (settings == null) return;

    await CourseNotificationService.instance.rescheduleCourseReminders(
      courses: courses,
      settings: settings,
    );
  }
}
