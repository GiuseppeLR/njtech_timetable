import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'features/notifications/services/course_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await CourseNotificationService.instance.initialize();

  runApp(
    const ProviderScope(
      child: NjtechTimetableApp(),
    ),
  );
}
