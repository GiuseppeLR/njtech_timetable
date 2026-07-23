import 'package:hive_flutter/hive_flutter.dart';

import '../../features/settings/models/app_settings.dart';

class SettingsRepository {
  static const String _boxName = 'settings';
  static const String _settingsKey = 'app_settings';

  Future<Box> _openBox() {
    return Hive.openBox(_boxName);
  }

  Future<AppSettings?> getSettings() async {
    final box = await _openBox();
    final value = box.get(_settingsKey);

    if (value == null) {
      return null;
    }

    return AppSettings.fromJson(Map<dynamic, dynamic>.from(value));
  }

  Future<void> saveSettings(AppSettings settings) async {
    final box = await _openBox();
    await box.put(_settingsKey, settings.toJson());
  }
}
