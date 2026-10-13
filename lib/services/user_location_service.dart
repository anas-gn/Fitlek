import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'apiService.dart';
import 'background_location_service.dart';

class UserLocationService {
  static Timer? _timer;
  static bool _updating = false;
  static int _generation = 0;
  static void Function(String)? _onCityChanged;

  static Future<Map<String, dynamic>> detect(
      {bool requestPermission = true}) async {
    if (!await Geolocator.isLocationServiceEnabled())
      throw Exception(
          'Turn on location services, then press the location button again.');
    var permission = await Geolocator.checkPermission();
    if (!requestPermission &&
        permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      throw Exception('Location refresh is not permitted.');
    }
    if (permission == LocationPermission.denied && requestPermission)
      permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever)
      throw Exception(
          'Allow location access in your device settings, then try again.');
    final position = await Geolocator.getCurrentPosition()
        .timeout(const Duration(seconds: 20));
    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'format': 'json',
      'lat': '${position.latitude}',
      'lon': '${position.longitude}',
      'zoom': '18',
      'addressdetails': '1',
    });
    final response = await http.get(uri, headers: {
      'User-Agent': 'Sirvya/1.0',
      'Accept-Language': 'en'
    }).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200)
      throw Exception(
          'Could not identify your city. Please try the location button again.');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final address = data['address'] as Map<String, dynamic>? ?? {};
    final city = address['city'] ??
        address['town'] ??
        address['village'] ??
        address['municipality'];
    if (city == null || '$city'.isEmpty)
      throw Exception('City unavailable. Please try the location button again.');
    return {
      'city': '$city',
      'latitude': position.latitude,
      'longitude': position.longitude,
      'fullAddress': data['display_name'] ?? '',
      'country': address['country'] ?? '',
      'accuracy': position.accuracy,
      'autoRefresh': true
    };
  }

  static Future<String> save(Map<String, dynamic> location) async {
    final result = await ApiService.put('/locations/me', location);
    if (result['ok'] != true)
      throw Exception(result['message'] ?? 'Could not save your location.');
    final city = '${result['city']}';
    try {
      await BackgroundLocationService.synchronize(location['autoRefresh'] == true || location['autoRefresh'] == 1);
    } catch (_) { /* A scheduling failure must not undo a successful location save. */ }
    _onCityChanged?.call(city);
    return city;
  }

  static void start({void Function(String)? onCityChanged}) {
    _timer?.cancel();
    final generation = ++_generation;
    _onCityChanged = onCityChanged;
    Future<void> update() async {
      if (_updating ||
          WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed)
        return;
      _updating = true;
      try {
        final token = await ApiService.getToken();
        if (token == null) return;
        final saved = await ApiService.get('/locations/me');
        if (saved['ok'] != true) return;
        final enabled = saved['autoRefresh'] == 1 || saved['autoRefresh'] == true;
        try { await BackgroundLocationService.synchronize(enabled); } catch (_) {}
        if (!enabled) return;
        final epoch = num.tryParse('${saved['updatedAtEpoch']}');
        final recorded = epoch == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch((epoch * 1000).round());
        if (recorded != null &&
            DateTime.now().difference(recorded).inMinutes < 15) return;
        final location = await detect(requestPermission: false);
        if (generation != _generation || token != await ApiService.getToken())
          return;
        final latest = await ApiService.get('/locations/me');
        if (latest['autoRefresh'] != 1 && latest['autoRefresh'] != true) return;
        await save(location);
      } catch (_) {
        /* Keep the last successful location when GPS/network is unavailable. */
      } finally {
        _updating = false;
      }
    }

    update();
    _timer = Timer.periodic(const Duration(minutes: 15), (_) => update());
  }

  static void stop() {
    _generation++;
    _timer?.cancel();
    _timer = null;
    _onCityChanged = null;
  }
}
