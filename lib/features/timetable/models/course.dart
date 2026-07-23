import 'package:flutter/material.dart';

enum CourseSource {
  imported,
  manual,
}

class Course {
  final String id;
  final String name;
  final String teacher;
  final String classroom;
  final int weekday; // 1-7，表示周一到周日
  final int startSection;
  final int endSection;
  final List<int> weeks;
  final Color color;
  final CourseSource source;

  const Course({
    required this.id,
    required this.name,
    required this.teacher,
    required this.classroom,
    required this.weekday,
    required this.startSection,
    required this.endSection,
    required this.weeks,
    required this.color,
    required this.source,
  });

  int get sectionCount => endSection - startSection + 1;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'teacher': teacher,
      'classroom': classroom,
      'weekday': weekday,
      'startSection': startSection,
      'endSection': endSection,
      'weeks': weeks,
      'color': color.value,
      'source': source.name,
    };
  }

  factory Course.fromJson(Map<dynamic, dynamic> json) {
    return Course(
      id: json['id'] as String,
      name: json['name'] as String,
      teacher: json['teacher'] as String,
      classroom: json['classroom'] as String,
      weekday: json['weekday'] as int,
      startSection: json['startSection'] as int,
      endSection: json['endSection'] as int,
      weeks: List<int>.from(json['weeks'] as List),
      color: Color(json['color'] as int),
      source: CourseSource.values.firstWhere(
        (item) => item.name == json['source'],
        orElse: () => CourseSource.manual,
      ),
    );
  }
}
