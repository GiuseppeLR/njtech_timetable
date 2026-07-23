import 'section_time.dart';

class SchoolConfig {
  static const String schoolName = '南京工业大学';
  static const int totalWeeks = 20;
  static const int maxSectionsPerDay = 10;

  static const List<String> weekdays = [
    '周一',
    '周二',
    '周三',
    '周四',
    '周五',
    '周六',
    '周日',
  ];

  static const List<SectionTime> sectionTimes = [
    SectionTime(index: 1, start: '08:10', end: '08:55'),
    SectionTime(index: 2, start: '09:05', end: '09:50'),
    SectionTime(index: 3, start: '10:20', end: '11:05'),
    SectionTime(index: 4, start: '11:15', end: '12:00'),
    SectionTime(index: 5, start: '14:00', end: '14:45'),
    SectionTime(index: 6, start: '14:55', end: '15:40'),
    SectionTime(index: 7, start: '16:10', end: '16:55'),
    SectionTime(index: 8, start: '17:05', end: '17:50'),
    SectionTime(index: 9, start: '19:00', end: '19:45'),
    SectionTime(index: 10, start: '19:55', end: '20:40'),
  ];
}
