import 'package:flutter/material.dart';
import 'course_detail_sheet.dart';

import '../../../core/constants/school_config.dart';
import '../models/course.dart';
import 'course_card.dart';

class TimetableGrid extends StatelessWidget {
  final List<Course> courses;
  final int currentWeek;

  const TimetableGrid({
    super.key,
    required this.courses,
    required this.currentWeek,
  });

  @override
  Widget build(BuildContext context) {
    const sectionWidth = 42.0;
    const dayWidth = 96.0;
    const sectionHeight = 64.0;
    final todayWeekday = DateTime.now().weekday;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: sectionWidth + dayWidth * 7,
        child: Column(
          children: [
            _buildWeekdayHeader(
              context: context,
              sectionWidth: sectionWidth,
              dayWidth: dayWidth,
              todayWeekday: todayWeekday,
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionColumn(context, sectionWidth, sectionHeight),
                    ...List.generate(7, (index) {
                      final weekday = index + 1;
                      return _buildDayColumn(
                        weekday: weekday,
                        context: context,
                        width: dayWidth,
                        sectionHeight: sectionHeight,
                        isToday: weekday == todayWeekday,
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekdayHeader({
    required BuildContext context,
    required double sectionWidth,
    required double dayWidth,
    required int todayWeekday,
  }) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          SizedBox(width: sectionWidth),
          ...List.generate(SchoolConfig.weekdays.length, (index) {
            final weekday = index + 1;
            final isToday = weekday == todayWeekday;

            return Container(
              width: dayWidth,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isToday
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                isToday ? '${SchoolConfig.weekdays[index]} 今天' : SchoolConfig.weekdays[index],
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: isToday
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : null,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSectionColumn(
    BuildContext context,
    double sectionWidth,
    double sectionHeight,
  ) {
    final borderColor = Theme.of(context).dividerColor.withOpacity(0.45);

    return Column(
      children: List.generate(SchoolConfig.maxSectionsPerDay, (index) {
        final section = index + 1;

        return Container(
          width: sectionWidth,
          height: sectionHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: borderColor),
              right: BorderSide(color: borderColor),
            ),
          ),
          child: Text(
            '$section',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        );
      }),
    );
  }

  Widget _buildDayColumn({
    required BuildContext context,
    required int weekday,
    required double width,
    required double sectionHeight,
    required bool isToday,
  }) {
    final dayCourses = courses
        .where((course) =>
            course.weekday == weekday &&
            course.weeks.contains(currentWeek) &&
            course.startSection >= 1 &&
            course.endSection >= course.startSection &&
            course.endSection <= SchoolConfig.maxSectionsPerDay)
        .toList();

    return SizedBox(
      width: width,
      height: sectionHeight * SchoolConfig.maxSectionsPerDay,
      child: Stack(
        children: [
          if (isToday)
            Positioned.fill(
              child: ColoredBox(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withOpacity(0.18),
              ),
            ),
          _buildGridBackground(context, width, sectionHeight),
          ...dayCourses.map((course) {
            return Positioned(
              top: (course.startSection - 1) * sectionHeight,
              left: 0,
              right: 0,
              height: course.sectionCount * sectionHeight,
              child: CourseCard(
                course: course,
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    showDragHandle: false,
                    builder: (_) {
                      return CourseDetailSheet(course: course);
                    },
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildGridBackground(
    BuildContext context,
    double width,
    double sectionHeight,
  ) {
    final borderColor = Theme.of(context).dividerColor.withOpacity(0.45);

    return Column(
      children: List.generate(SchoolConfig.maxSectionsPerDay, (index) {
        return Container(
          width: width,
          height: sectionHeight,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: borderColor),
              right: BorderSide(color: borderColor),
            ),
          ),
        );
      }),
    );
  }
}
