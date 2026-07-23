class WeekCalculator {
  static int calculateCurrentWeek({
    required DateTime semesterStartDate,
    required DateTime now,
    required int totalWeeks,
  }) {
    final start = DateTime(
      semesterStartDate.year,
      semesterStartDate.month,
      semesterStartDate.day,
    );

    final today = DateTime(now.year, now.month, now.day);
    final diffDays = today.difference(start).inDays;

    if (diffDays < 0) {
      return 1;
    }

    final week = diffDays ~/ 7 + 1;

    if (week < 1) {
      return 1;
    }

    if (week > totalWeeks) {
      return totalWeeks;
    }

    return week;
  }
}
