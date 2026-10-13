import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import '../constants/urls.dart';
import 'user_location_service.dart';

@pragma('vm:entry-point')
void locationTaskDispatcher() {
  Workmanager().executeTask((task, data) async {
    if (task != BackgroundLocationService.task) return true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final token = prefs.getString('token');
      final id = prefs.getInt('userId');
      if (token == null || id != data?['userId'] ||
          !['client', 'coach'].contains(prefs.getString('role')) ||
          await Geolocator.checkPermission() != LocationPermission.always) return true;
      final headers = {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'};
      Future<bool> enabled() async {
        final response = await http.get(Uri.parse('$baseUrl/locations/me'), headers: headers)
            .timeout(const Duration(seconds: 10));
        if (response.statusCode != 200) return false;
        final saved = jsonDecode(response.body);
        return saved['autoRefresh'] == 1 || saved['autoRefresh'] == true;
      }
      if (!await enabled()) return true;
      final location = await UserLocationService.detect(requestPermission: false);
      await prefs.reload();
      if (prefs.getString('token') != token || prefs.getInt('userId') != id || !await enabled()) return true;
      final response = await http.put(Uri.parse('$baseUrl/locations/me'), headers: headers,
          body: jsonEncode(location)).timeout(const Duration(seconds: 10));
      return response.statusCode == 200 || response.statusCode == 401;
    } catch (_) { return true; } // Try again on the next interval; never prompt in the background.
  });
}

class BackgroundLocationService {
  static const task = 'com.sirvya.location.refresh';
  static bool get supported => !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);
  static Future<void> initialize() async {
    if (supported) await Workmanager().initialize(locationTaskDispatcher);
  }
  static Future<void> synchronize(bool enabled) async {
    if (!supported) return;
    if (!enabled || await Geolocator.checkPermission() != LocationPermission.always) {
      await Workmanager().cancelByUniqueName(task);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('userId');
    if (id == null || prefs.getString('token') == null) return;
    await Workmanager().registerPeriodicTask(task, task,
        frequency: const Duration(minutes: 15),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
        constraints: Constraints(networkType: NetworkType.connected),
        inputData: {'userId': id});
  }
}
