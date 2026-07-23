enum ReminderScope {
  today,
  currentWeek,
  allFuture,
}

enum ThemeModeOption {
  system,
  light,
  dark,
}

class AppSettings {
  final DateTime semesterStartDate;
  final int totalWeeks;
  final int? manualCurrentWeek;
  final bool courseReminderEnabled;
  final int courseReminderMinutes;
  final ReminderScope courseReminderScope;
  final ThemeModeOption themeModeOption;
  final bool firstLaunchGuideShown;

  const AppSettings({
    required this.semesterStartDate,
    required this.totalWeeks,
    this.manualCurrentWeek,
    this.courseReminderEnabled = false,
    this.courseReminderMinutes = 10,
    this.courseReminderScope = ReminderScope.currentWeek,
    this.themeModeOption = ThemeModeOption.system,
    this.firstLaunchGuideShown = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'semesterStartDate': semesterStartDate.toIso8601String(),
      'totalWeeks': totalWeeks,
      'manualCurrentWeek': manualCurrentWeek,
      'courseReminderEnabled': courseReminderEnabled,
      'courseReminderMinutes': courseReminderMinutes,
      'courseReminderScope': courseReminderScope.name,
      'themeModeOption': themeModeOption.name,
      'firstLaunchGuideShown': firstLaunchGuideShown,
    };
  }

  factory AppSettings.fromJson(Map<dynamic, dynamic> json) {
    return AppSettings(
      semesterStartDate: DateTime.parse(json['semesterStartDate'] as String),
      totalWeeks: json['totalWeeks'] as int,
      manualCurrentWeek: json['manualCurrentWeek'] as int?,
      courseReminderEnabled: json['courseReminderEnabled'] as bool? ?? false,
      courseReminderMinutes: json['courseReminderMinutes'] as int? ?? 10,
      courseReminderScope: ReminderScope.values.firstWhere(
        (item) => item.name == json['courseReminderScope'],
        orElse: () => ReminderScope.currentWeek,
      ),
      themeModeOption: ThemeModeOption.values.firstWhere(
        (item) => item.name == json['themeModeOption'],
        orElse: () => ThemeModeOption.system,
      ),
      firstLaunchGuideShown: json['firstLaunchGuideShown'] as bool? ?? false,
    );
  }

  AppSettings copyWith({
    DateTime? semesterStartDate,
    int? totalWeeks,
    int? manualCurrentWeek,
    bool? courseReminderEnabled,
    int? courseReminderMinutes,
    ReminderScope? courseReminderScope,
    ThemeModeOption? themeModeOption,
    bool? firstLaunchGuideShown,
    bool clearManualCurrentWeek = false,
  }) {
    return AppSettings(
      semesterStartDate: semesterStartDate ?? this.semesterStartDate,
      totalWeeks: totalWeeks ?? this.totalWeeks,
      manualCurrentWeek: clearManualCurrentWeek
          ? null
          : manualCurrentWeek ?? this.manualCurrentWeek,
      courseReminderEnabled:
          courseReminderEnabled ?? this.courseReminderEnabled,
      courseReminderMinutes:
          courseReminderMinutes ?? this.courseReminderMinutes,
      courseReminderScope: courseReminderScope ?? this.courseReminderScope,
      themeModeOption: themeModeOption ?? this.themeModeOption,
      firstLaunchGuideShown:
          firstLaunchGuideShown ?? this.firstLaunchGuideShown,
    );
  }
}
