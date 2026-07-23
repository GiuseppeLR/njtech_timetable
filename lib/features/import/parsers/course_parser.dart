import '../../timetable/models/course.dart';

abstract class CourseParser {
  bool canParse(dynamic input);
  List<Course> parse(dynamic input);
}
