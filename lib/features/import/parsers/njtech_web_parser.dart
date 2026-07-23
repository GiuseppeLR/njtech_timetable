import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/school_config.dart';
import '../../timetable/models/course.dart';
import 'course_parser.dart';

class NjtechWebParser implements CourseParser {
  int _colorIndex = 0;

  @override
  bool canParse(dynamic input) {
    if (input is String) {
      return input.contains('kbList') || input.contains('body');
    }

    if (input is Map) {
      return input.containsKey('kbList') || input.containsKey('body');
    }

    return false;
  }

  @override
  List<Course> parse(dynamic input) {
    _colorIndex = 0;

    final body = _normalizeBody(input);
    if (body == null) {
      return [];
    }

    final rawCourses = <dynamic>[
      ...?body['kbList'] as List?,
      ...?body['sjkList'] as List?,
      ...?body['jxhjkcList'] as List?,
    ];

    final courses = <Course>[];

    for (final item in rawCourses) {
      if (item is! Map) continue;

      final course = _parseItem(Map<String, dynamic>.from(item));
      if (course != null) {
        courses.add(course);
      }
    }

    return courses;
  }

  Map<String, dynamic>? _normalizeBody(dynamic input) {
    try {
      dynamic decoded = input;

      if (decoded is String) {
        decoded = jsonDecode(decoded.replaceAll(r"\'", "'"));
      }

      if (decoded is Map && decoded.containsKey('body')) {
        final bodyText = decoded['body']?.toString() ?? '';
        return Map<String, dynamic>.from(
          jsonDecode(bodyText.replaceAll(r"\'", "'")) as Map,
        );
      }

      if (decoded is Map && decoded.containsKey('kbList')) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  Course? _parseItem(Map<String, dynamic> item) {
    final name = _stringValue(item['kcmc']);
    if (name.isEmpty) {
      return null;
    }

    final teacher = _stringValue(item['xm'], fallback: '未知教师');
    final classroom = _stringValue(item['cdmc'], fallback: '待定');
    final weekday = _parseWeekday(item['xqj']);
    final sections = _parseSections(_stringValue(item['jcs']));
    final weeks = _parseWeeks(_stringValue(item['zcd']));

    if (weekday < 1 || weekday > 7) {
      return null;
    }

    final startSection =
        sections.$1.clamp(1, SchoolConfig.maxSectionsPerDay).toInt();
    final endSection =
        sections.$2.clamp(startSection, SchoolConfig.maxSectionsPerDay).toInt();

    final color =
        AppColors.courseColors[_colorIndex % AppColors.courseColors.length];
    _colorIndex++;

    return Course(
      id: const Uuid().v4(),
      name: name,
      teacher: teacher,
      classroom: classroom,
      weekday: weekday,
      startSection: startSection,
      endSection: endSection,
      weeks: weeks.isEmpty
          ? List.generate(SchoolConfig.totalWeeks, (index) => index + 1)
          : weeks,
      color: color,
      source: CourseSource.imported,
    );
  }

  int _parseWeekday(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  (int, int) _parseSections(String text) {
    final match = RegExp(r'(\d+)\s*-\s*(\d+)').firstMatch(text);
    if (match != null) {
      return (
        int.tryParse(match.group(1) ?? '') ?? 1,
        int.tryParse(match.group(2) ?? '') ?? 1,
      );
    }

    final single = RegExp(r'\d+').firstMatch(text);
    final section = int.tryParse(single?.group(0) ?? '') ?? 1;
    return (section, section);
  }

  List<int> _parseWeeks(String text) {
    final weeks = <int>{};
    final segments = text.split(',');

    for (final rawSegment in segments) {
      final segment = rawSegment.trim();
      if (segment.isEmpty) continue;

      final isOdd = segment.contains('(单)');
      final isEven = segment.contains('(双)');
      final rangeMatch = RegExp(r'(\d+)\s*-\s*(\d+)周?').firstMatch(segment);

      if (rangeMatch != null) {
        final start = int.tryParse(rangeMatch.group(1) ?? '') ?? 1;
        final end = int.tryParse(rangeMatch.group(2) ?? '') ?? start;

        for (var week = start; week <= end; week++) {
          if (isOdd && week.isEven) continue;
          if (isEven && week.isOdd) continue;
          weeks.add(week);
        }

        continue;
      }

      final singleMatch = RegExp(r'(\d+)周?').firstMatch(segment);
      if (singleMatch != null) {
        final week = int.tryParse(singleMatch.group(1) ?? '');
        if (week != null) {
          weeks.add(week);
        }
      }
    }

    return weeks.toList()..sort();
  }

  String _stringValue(dynamic value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }
}
