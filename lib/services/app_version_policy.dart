import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/urls.dart';

int compareAppVersions(String left, String right) {
  List<String> parse(String version) {
    final match = RegExp(
            r'^(\d+)\.(\d+)\.(\d+)(?:-([0-9A-Za-z.-]+))?(?:\+[0-9A-Za-z.-]+)?$')
        .firstMatch(version.trim());
    if (match == null) throw FormatException('Invalid app version', version);
    return [match[1]!, match[2]!, match[3]!, match[4] ?? ''];
  }

  final a = parse(left), b = parse(right);
  for (var i = 0; i < 3; i++) {
    final comparison = int.parse(a[i]).compareTo(int.parse(b[i]));
    if (comparison != 0) return comparison;
  }
  if (a[3] == b[3]) return 0;
  if (a[3].isEmpty) return 1;
  if (b[3].isEmpty) return -1;
  final ap = a[3].split('.'), bp = b[3].split('.');
  for (var i = 0; i < ap.length && i < bp.length; i++) {
    if (ap[i] == bp[i]) continue;
    final an = int.tryParse(ap[i]), bn = int.tryParse(bp[i]);
    if (an != null && bn != null) return an.compareTo(bn);
    if (an != null) return -1;
    if (bn != null) return 1;
    return ap[i].compareTo(bp[i]);
  }
  return ap.length.compareTo(bp.length);
}

class AppVersionPolicy {
  final String latestVersion, minimumVersion, storeUrl;
  const AppVersionPolicy(
      {required this.latestVersion,
      required this.minimumVersion,
      required this.storeUrl});
  factory AppVersionPolicy.fromJson(Map<String, dynamic> json) {
    final minimum = '${json['min_required_version'] ?? ''}';
    final latest = '${json['latest_version'] ?? minimum}';
    compareAppVersions(minimum, minimum);
    compareAppVersions(latest, latest);
    return AppVersionPolicy(
        latestVersion: latest,
        minimumVersion: minimum,
        storeUrl: '${json['store_url'] ?? ''}');
  }
  Map<String, dynamic> toJson() => {
        'latest_version': latestVersion,
        'min_required_version': minimumVersion,
        'store_url': storeUrl
      };
}

class AppVersionCheck {
  final String installedVersion;
  final AppVersionPolicy policy;
  const AppVersionCheck({required this.installedVersion, required this.policy});
  bool get required =>
      compareAppVersions(installedVersion, policy.minimumVersion) < 0;
  bool get available =>
      compareAppVersions(installedVersion, policy.latestVersion) < 0;
}

class AppVersionRepository {
  static Future<AppVersionCheck?> check(
      {String? installedVersion, String? platform, http.Client? client}) async {
    final installed =
        installedVersion ?? (await PackageInfo.fromPlatform()).version;
    final device = platform ??
        (defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android');
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'app_version_policy_$device';
    AppVersionPolicy? cached;
    try {
      final raw = prefs.getString(cacheKey);
      if (raw != null) {
        cached =
            AppVersionPolicy.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      }
    } catch (_) {/* Ignore invalid cache entries. */}
    final transport = client ?? http.Client();
    try {
      final response = await transport
          .get(Uri.parse('$baseUrl/app-version?platform=$device'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw StateError('Version check unavailable');
      }
      final json = jsonDecode(response.body);
      if (json is! Map || json['success'] != true || json['data'] is! Map) {
        throw const FormatException('Invalid version policy');
      }
      final policy =
          AppVersionPolicy.fromJson(Map<String, dynamic>.from(json['data']));
      // A cache write failure must not discard a valid update requirement.
      try {
        await prefs.setString(cacheKey, jsonEncode(policy.toJson()));
      } catch (_) {}
      return AppVersionCheck(installedVersion: installed, policy: policy);
    } catch (error) {
      debugPrint('App version check unavailable: $error');
      return cached == null
          ? null
          : AppVersionCheck(installedVersion: installed, policy: cached);
    } finally {
      if (client == null) transport.close();
    }
  }
}
