import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the user-selected app locale (null = follow system language).
class LocaleService {
  static const _prefKey = 'app_locale';
  static const supported = [Locale('en'), Locale('fr')];

  /// Listen to this in MaterialApp.
  static final ValueNotifier<Locale?> locale = ValueNotifier<Locale?>(null);

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefKey);
    locale.value = code == null ? null : Locale(code);
  }

  static Future<void> set(Locale? value) async {
    locale.value = value;
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(_prefKey);
    } else {
      await prefs.setString(_prefKey, value.languageCode);
    }
  }
}

