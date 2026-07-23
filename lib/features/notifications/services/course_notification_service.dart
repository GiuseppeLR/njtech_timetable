import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../../core/constants/school_config.dart';
import '../../../core/utils/week_calculator.dart';
import '../../settings/models/app_settings.dart';
import '../../timetable/models/course.dart';

class CourseNotificationService {
  CourseNotificationService._();

  static final CourseNotificationService instance =
      CourseNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(settings);
    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    await initialize();

    final iosGranted = await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    final macOSGranted = await _plugin
        .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    final androidGranted = await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    return iosGranted ?? macOSGranted ?? androidGranted ?? true;
  }

  Future<void> rescheduleCourseReminders({
    required List<Course> courses,
    required AppSettings settings,
  }) async {
    await initialize();
    await _plugin.cancelAll();

    if (!settings.courseReminderEnabled) {
      return;
    }

    final granted = await requestPermissions();
    if (!granted) {
      return;
    }

    final now = DateTime.now();
    final currentWeek = settings.manualCurrentWeek ??
        WeekCalculator.calculateCurrentWeek(
          semesterStartDate: settings.semesterStartDate,
          now: now,
          totalWeeks: settings.totalWeeks,
        );

    final candidates = <_ReminderCandidate>[];

    for (final course in courses) {
      for (final week in course.weeks) {
        if (!_shouldScheduleWeek(
          week: week,
          currentWeek: currentWeek,
          scope: settings.courseReminderScope,
        )) {
          continue;
        }

        final courseStartTime = _courseStartDateTime(
          settings: settings,
          course: course,
          week: week,
        );
        if (courseStartTime == null) continue;

        final notifyTime = courseStartTime.subtract(
          Duration(minutes: settings.courseReminderMinutes),
        );

        if (!notifyTime.isAfter(now)) continue;

        if (settings.courseReminderScope == ReminderScope.today &&
            !_isSameDate(courseStartTime, now)) {
          continue;
        }

        candidates.add(
          _ReminderCandidate(
            course: course,
            week: week,
            courseStartTime: courseStartTime,
            notifyTime: notifyTime,
          ),
        );
      }
    }

    candidates.sort((a, b) => a.notifyTime.compareTo(b.notifyTime));

    for (final candidate in candidates.take(64)) {
      await _scheduleCandidate(
        candidate: candidate,
        minutes: settings.courseReminderMinutes,
      );
    }
  }

  Future<void> cancelAll() async {
    await initialize();
    await _plugin.cancelAll();
  }

  bool _shouldScheduleWeek({
    required int week,
    required int currentWeek,
    required ReminderScope scope,
  }) {
    switch (scope) {
      case ReminderScope.today:
        return week == currentWeek;
      case ReminderScope.currentWeek:
        return week == currentWeek;
      case ReminderScope.allFuture:
        return week >= currentWeek;
    }
  }

  DateTime? _courseStartDateTime({
    required AppSettings settings,
    required Course course,
    required int week,
  }) {
    if (course.weekday < 1 || course.weekday > 7) return null;
    if (course.startSection < 1 ||
        course.startSection > SchoolConfig.sectionTimes.length) {
      return null;
    }

    final sectionTime = SchoolConfig.sectionTimes[course.startSection - 1];
    final parts = sectionTime.start.split(':');
    if (parts.length != 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;

    final date = settings.semesterStartDate.add(
      Duration(days: (week - 1) * 7 + (course.weekday - 1)),
    );

    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  Future<void> _scheduleCandidate({
    required _ReminderCandidate candidate,
    required int minutes,
  }) async {
    final notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'course_reminders',
        '课程提醒',
        channelDescription: '课程开始前提醒',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
      macOS: const DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      _notificationId(candidate),
      '$minutes 分钟后上课',
      '${candidate.course.name}\n'
          '${candidate.course.classroom} · ${candidate.course.teacher}',
      tz.TZDateTime.from(candidate.notifyTime, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  int _notificationId(_ReminderCandidate candidate) {
    return Object.hash(
          candidate.course.id,
          candidate.week,
          candidate.courseStartTime.millisecondsSinceEpoch,
        ) &
        0x7fffffff;
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _ReminderCandidate {
  final Course course;
  final int week;
  final DateTime courseStartTime;
  final DateTime notifyTime;

  const _ReminderCandidate({
    required this.course,
    required this.week,
    required this.courseStartTime,
    required this.notifyTime,
  });
}
