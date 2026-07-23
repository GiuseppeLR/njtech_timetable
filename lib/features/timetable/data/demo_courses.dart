import '../../../core/constants/app_colors.dart';
import '../models/course.dart';

const demoCourses = [
  Course(
    id: '1',
    name: '高等数学',
    teacher: '张老师',
    classroom: '仁智楼 301',
    weekday: 1,
    startSection: 1,
    endSection: 2,
    weeks: [1, 2, 3, 4, 5, 6, 7, 8],
    color: AppColors.primary,
    source: CourseSource.manual,
  ),
  Course(
    id: '2',
    name: '大学英语',
    teacher: '李老师',
    classroom: '厚学楼 205',
    weekday: 3,
    startSection: 3,
    endSection: 4,
    weeks: [1, 2, 3, 4, 5, 6, 7, 8],
    color: AppColors.blue,
    source: CourseSource.manual,
  ),
  Course(
    id: '3',
    name: '程序设计基础',
    teacher: '王老师',
    classroom: '计算机楼 406',
    weekday: 5,
    startSection: 5,
    endSection: 6,
    weeks: [1, 2, 3, 4, 5, 6, 7, 8, 9],
    color: AppColors.green,
    source: CourseSource.manual,
  ),
];