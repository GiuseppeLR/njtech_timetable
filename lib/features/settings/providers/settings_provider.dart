import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/school_config.dart';
import '../../../core/utils/week_calculator.dart';
import '../../../data/local/course_repository.dart';
import '../../../data/local/settings_repository.dart';
import '../../notifications/services/course_notification_service.dart';
import '../models/app_settings.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    final repository = ref.read(settingsRepositoryProvider);
    final savedSettings = await repository.getSettings();

    if (savedSettings != null) {
      if (savedSettings.manualCurrentWeek != null) {
        final autoSettings = savedSettings.copyWith(
          clearManualCurrentWeek: true,
        );
        await repository.saveSettings(autoSettings);
        return autoSettings;
      }

      return savedSettings;
    }

    final defaultSettings = AppSettings(
      semesterStartDate: _defaultSemesterStartDate(),
      totalWeeks: SchoolConfig.totalWeeks,
    );

    await repository.saveSettings(defaultSettings);
    return defaultSettings;
  }

  int getCurrentWeek(AppSettings settings) {
    if (settings.manualCurrentWeek != null) {
      return settings.manualCurrentWeek!;
    }

    return WeekCalculator.calculateCurrentWeek(
      semesterStartDate: settings.semesterStartDate,
      now: DateTime.now(),
      totalWeeks: settings.totalWeeks,
    );
  }

  Future<void> updateSemesterStartDate(DateTime date) async {
    final old = state.value;
    if (old == null) return;

    final normalizedDate = DateTime(date.year, date.month, date.day);
    final updated = old.copyWith(
      semesterStartDate: normalizedDate,
      clearManualCurrentWeek: true,
    );

    state = AsyncData(updated);
    await ref.read(settingsRepositoryProvider).saveSettings(updated);
    await _rescheduleReminders(updated);
  }

  Future<void> updateManualCurrentWeek(int week) async {
    final old = state.value;
    if (old == null) return;

    final safeWeek = week.clamp(1, old.totalWeeks).toInt();
    final updated = old.copyWith(manualCurrentWeek: safeWeek);

    state = AsyncData(updated);
    await ref.read(settingsRepositoryProvider).saveSettings(updated);
    await _rescheduleReminders(updated);
  }

  Future<void> clearManualCurrentWeek() async {
    final old = state.value;
    if (old == null) return;

    final updated = old.copyWith(clearManualCurrentWeek: true);

    state = AsyncData(updated);
    await ref.read(settingsRepositoryProvider).saveSettings(updated);
    await _rescheduleReminders(updated);
  }

  Future<void> updateCourseReminderEnabled(bool enabled) async {
    final old = state.value;
    if (old == null) return;

    final updated = old.copyWith(courseReminderEnabled: enabled);

    state = AsyncData(updated);
    await ref.read(settingsRepositoryProvider).saveSettings(updated);
    await _rescheduleReminders(updated);
  }

  Future<void> updateCourseReminderMinutes(int minutes) async {
    final old = state.value;
    if (old == null) return;

    final updated = old.copyWith(courseReminderMinutes: minutes);

    state = AsyncData(updated);
    await ref.read(settingsRepositoryProvider).saveSettings(updated);
    await _rescheduleReminders(updated);
  }

  Future<void> updateCourseReminderScope(ReminderScope scope) async {
    final old = state.value;
    if (old == null) return;

    final updated = old.copyWith(courseReminderScope: scope);

    state = AsyncData(updated);
    await ref.read(settingsRepositoryProvider).saveSettings(updated);
    await _rescheduleReminders(updated);
  }

  Future<void> updateThemeMode(ThemeModeOption mode) async {
    final old = state.value;
    if (old == null) return;

    final updated = old.copyWith(themeModeOption: mode);

    state = AsyncData(updated);
    await ref.read(settingsRepositoryProvider).saveSettings(updated);
  }

  Future<void> markFirstLaunchGuideShown() async {
    final old = state.value;
    if (old == null || old.firstLaunchGuideShown) return;

    final updated = old.copyWith(firstLaunchGuideShown: true);
    state = AsyncData(updated);
    await ref.read(settingsRepositoryProvider).saveSettings(updated);
  }

  Future<void> refreshCourseReminders() async {
    final settings = state.value;
    if (settings == null) return;

    await _rescheduleReminders(settings);
  }

  Future<void> _rescheduleReminders(AppSettings settings) async {
    final courses = await CourseRepository().getCourses();

    await CourseNotificationService.instance.rescheduleCourseReminders(
      courses: courses,
      settings: settings,
    );
  }

  static DateTime _defaultSemesterStartDate() {
    final now = DateTime.now();
    final springStart = DateTime(now.year, 2, 24);
    final autumnStart = DateTime(now.year, 9, 1);

    if (now.isBefore(springStart)) {
      return DateTime(now.year - 1, 9, 1);
    }

    if (now.isBefore(autumnStart)) {
      return springStart;
    }

    return autumnStart;
  }
}
