import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/settings/models/app_settings.dart';
import 'features/settings/providers/settings_provider.dart';
import 'features/timetable/pages/timetable_page.dart';

class NjtechTimetableApp extends ConsumerWidget {
  const NjtechTimetableApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    final themeMode = settingsAsync.when(
      data: (settings) {
        switch (settings.themeModeOption) {
          case ThemeModeOption.light:
            return ThemeMode.light;
          case ThemeModeOption.dark:
            return ThemeMode.dark;
          case ThemeModeOption.system:
            return ThemeMode.system;
        }
      },
      loading: () => ThemeMode.system,
      error: (_, __) => ThemeMode.system,
    );

    return MaterialApp(
      title: '南工课程表',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF6750A4),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFF6750A4),
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      themeMode: themeMode,
      home: const TimetablePage(),
    );
  }
}
