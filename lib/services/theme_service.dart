import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { light, dark, system }

class ThemeService {
  static const _prefKey = 'app_theme_mode';

  static Future<AppThemeMode> load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_prefKey);
    switch (value) {
      case 'light':
        return AppThemeMode.light;
      case 'dark':
        return AppThemeMode.dark;
      default:
        return AppThemeMode.system;
    }
  }

  static Future<void> save(AppThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, mode.name);
  }

  static ThemeMode toFlutterMode(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  static String label(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.system:
        return 'System';
    }
  }
}

class ThemeController extends ChangeNotifier {
  AppThemeMode _mode = AppThemeMode.system;
  bool _loaded = false;

  AppThemeMode get mode => _mode;
  bool get isLoaded => _loaded;
  ThemeMode get flutterMode => ThemeService.toFlutterMode(_mode);

  Future<void> load() async {
    _mode = await ThemeService.load();
    _loaded = true;
    notifyListeners();
  }

  Future<void> setMode(AppThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    await ThemeService.save(mode);
  }
}
