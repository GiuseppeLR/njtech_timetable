import '../models/course.dart';

class CourseConflict {
  final Course first;
  final Course second;

  const CourseConflict({
    required this.first,
    required this.second,
  });

  String get title => '${first.name} 与 ${second.name}';
}

class CourseConflictService {
  const CourseConflictService._();

  static List<CourseConflict> findConflicts(List<Course> courses) {
    final conflicts = <CourseConflict>[];

    for (var i = 0; i < courses.length; i++) {
      for (var j = i + 1; j < courses.length; j++) {
        final a = courses[i];
        final b = courses[j];

        if (_isConflict(a, b)) {
          conflicts.add(CourseConflict(first: a, second: b));
        }
      }
    }

    return conflicts;
  }

  static Course? findFirstConflict({
    required Course target,
    required List<Course> courses,
  }) {
    for (final course in courses) {
      if (course.id == target.id) continue;
      if (_isConflict(target, course)) {
        return course;
      }
    }

    return null;
  }

  static bool _isConflict(Course a, Course b) {
    if (a.weekday != b.weekday) return false;
    if (!_hasWeekOverlap(a.weeks, b.weeks)) return false;
    return _hasSectionOverlap(a, b);
  }

  static bool _hasWeekOverlap(List<int> a, List<int> b) {
    final weeks = a.toSet();
    return b.any(weeks.contains);
  }

  static bool _hasSectionOverlap(Course a, Course b) {
    return a.startSection <= b.endSection && b.startSection <= a.endSection;
  }
}
