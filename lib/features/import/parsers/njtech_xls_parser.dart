import 'package:uuid/uuid.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/school_config.dart';
import '../../timetable/models/course.dart';
import 'course_parser.dart';

class NjtechXlsParser implements CourseParser {
  static const _weekMap = {
    '一': 1,
    '二': 2,
    '三': 3,
    '四': 4,
    '五': 5,
    '六': 6,
    '日': 7,
  };

  int _colorIndex = 0;

  @override
  bool canParse(dynamic input) {
    if (input is! List<List<dynamic>>) return false;
    if (input.length < 13) return false;

    return true;
  }

  @override
  List<Course> parse(dynamic input) {
    _colorIndex = 0;

    if (input is! List<List<dynamic>>) {
      return [];
    }

    final courses = <Course>[];

    for (final row in input) {
      if (row is! List<dynamic>) continue;

      final sectionText = _cellValue(row, 1);
      final sectionNum = _parseSectionNum(sectionText);
      if (sectionNum == null) continue;

      for (final colIdx in [2, 3, 4, 5, 6, 7, 8]) {
        final cellContent = _cellValue(row, colIdx);
        if (cellContent.isEmpty) continue;

        final weekday = _parseWeekday(colIdx);
        if (weekday == null) continue;

        final cellCourses = _parseCellCourses(
          content: cellContent,
          weekday: weekday,
          section: sectionNum,
        );

        courses.addAll(cellCourses);
      }
    }

    return courses;
  }

  int? _parseSectionNum(String text) {
    final map = {
      '一': 1,
      '二': 2,
      '三': 3,
      '四': 4,
      '五': 5,
      '六': 6,
      '七': 7,
      '八': 8,
      '九': 9,
      '十': 10,
    };

    for (final entry in map.entries) {
      if (text.contains(entry.key)) {
        return entry.value;
      }
    }

    return null;
  }

  int? _parseWeekday(int colIndex) {
    final weekdayColumns = {2: 1, 3: 2, 4: 3, 5: 4, 6: 5, 7: 6, 8: 7};
    return weekdayColumns[colIndex];
  }

  List<Course> _parseCellCourses({
    required String content,
    required int weekday,
    required int section,
  }) {
    final courses = <Course>[];

    final parts = content.split(RegExp(r'\r?\n'));

    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.isEmpty) continue;

      final course = _parseSingleCourse(
        text: trimmed,
        weekday: weekday,
        section: section,
      );

      if (course != null) {
        courses.add(course);
      }
    }

    return courses;
  }

  Course? _parseSingleCourse({
    required String text,
    required int weekday,
    required int section,
  }) {
    final segments = text.split('/');
    if (segments.isEmpty) return null;

    var name = segments[0].trim();
    name = name.replaceAll(RegExp(r'[★○●◇◆]'), '').trim();
    if (name.isEmpty) return null;

    int startSection = section;
    int endSection = section;
    List<int> weeks = [];
    String classroom = '';
    String teacher = '';

    for (final seg in segments.skip(1)) {
      final trimmed = seg.trim();

      final sectionMatch = RegExp(r'\((\d+)-(\d+)节\)').firstMatch(trimmed);
      if (sectionMatch != null) {
        startSection = int.parse(sectionMatch.group(1)!);
        endSection = int.parse(sectionMatch.group(2)!);
        continue;
      }

      final weekMatch = RegExp(r'(\d+)-(\d+)周').firstMatch(trimmed);
      if (weekMatch != null) {
        final startWeek = int.parse(weekMatch.group(1)!);
        final endWeek = int.parse(weekMatch.group(2)!);

        final isOddWeek = trimmed.contains('(单)');
        final isEvenWeek = trimmed.contains('(双)');

        if (isOddWeek) {
          for (var w = startWeek; w <= endWeek; w++) {
            if (w.isOdd) weeks.add(w);
          }
        } else if (isEvenWeek) {
          for (var w = startWeek; w <= endWeek; w++) {
            if (w.isEven) weeks.add(w);
          }
        } else {
          for (var w = startWeek; w <= endWeek; w++) {
            weeks.add(w);
          }
        }
        continue;
      }

      final singleWeekMatch = RegExp(r'(\d+)周\b').firstMatch(trimmed);
      if (singleWeekMatch != null && weeks.isEmpty) {
        weeks.add(int.parse(singleWeekMatch.group(1)!));
        continue;
      }

      if (classroom.isEmpty && !trimmed.contains('周') && !trimmed.contains('节') && !trimmed.contains('场地') && !trimmed.contains('课程性质')) {
        final roomMatch = RegExp(r'^[\s]*(.+)$').firstMatch(trimmed);
        if (roomMatch != null) {
          final candidate = roomMatch.group(1)!.trim();
          if (candidate.isNotEmpty && !candidate.contains('周') && !candidate.contains('节')) {
            if (classroom.isEmpty) {
              classroom = candidate;
            } else if (teacher.isEmpty) {
              teacher = candidate;
            }
          }
        }
        continue;
      }
    }

    if (weeks.isEmpty) {
      weeks = List.generate(SchoolConfig.totalWeeks, (index) => index + 1);
    }

    final color = AppColors.courseColors[_colorIndex % AppColors.courseColors.length];
    _colorIndex++;

    return Course(
      id: const Uuid().v4(),
      name: name,
      teacher: teacher.isEmpty ? '未知教师' : teacher,
      classroom: classroom.isEmpty ? '待定' : classroom,
      weekday: weekday,
      startSection: startSection,
      endSection: endSection,
      weeks: weeks,
      color: color,
      source: CourseSource.imported,
    );
  }

  String _cellValue(List<dynamic> row, int colIndex) {
    if (row.length <= colIndex) return '';

    final value = row[colIndex];
    if (value == null) return '';
    if (value is String) return value;
    return value.toString();
  }
}
