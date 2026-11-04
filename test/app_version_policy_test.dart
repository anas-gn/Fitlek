import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitlek1/services/app_version_policy.dart';
import 'package:fitlek1/services/apiService.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const policy = AppVersionPolicy(
      latestVersion: '2.1.0',
      minimumVersion: '2.0.0',
      storeUrl: 'https://play.google.com/store/apps/details?id=com.sirvya.app');
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('versions compare numerically and support release suffixes', () {
    expect(compareAppVersions('1.10.0', '1.9.9'), greaterThan(0));
    expect(compareAppVersions('2.0.0-beta.2', '2.0.0-beta.11'), lessThan(0));
    expect(compareAppVersions('2.0.0-beta', '2.0.0'), lessThan(0));
    expect(compareAppVersions('2.0.0+123', '2.0.0+456'), 0);
    expect(() => compareAppVersions('invalid', '2.0.0'), throwsFormatException);
  });
  test('admin minimum version blocks old builds and caches the requirement',
      () async {
    final client = MockClient((request) async {
      expect(request.url.path, endsWith('/app-version'));
      expect(request.url.queryParameters['platform'], 'android');
      return http.Response(
          jsonEncode({'success': true, 'data': policy.toJson()}), 200);
    });
    final result = await AppVersionRepository.check(
        installedVersion: '1.0.0', platform: 'android', client: client);
    expect(result!.required, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(
        jsonDecode(prefs.getString('app_version_policy_android')!)[
            'min_required_version'],
        '2.0.0');
  });
  test(
      'offline relaunch retains cached minimum and newer installed builds unlock',
      () async {
    SharedPreferences.setMockInitialValues(
        {'app_version_policy_android': jsonEncode(policy.toJson())});
    final client =
        MockClient((_) async => throw http.ClientException('Offline'));
    final old = await AppVersionRepository.check(
        installedVersion: '1.0.0', platform: 'android', client: client);
    expect(old!.required, isTrue);
    final updated = await AppVersionRepository.check(
        installedVersion: '2.1.0', platform: 'android', client: client);
    expect(updated!.required, isFalse);
    expect(updated.available, isFalse);
    expect(
        await AppVersionRepository.check(
            installedVersion: '1.0.0', platform: 'ios', client: client),
        isNull);
  });
  test('invalid server response cannot erase a cached required update',
      () async {
    SharedPreferences.setMockInitialValues(
        {'app_version_policy_android': jsonEncode(policy.toJson())});
    final client = MockClient((_) async => http.Response(
        '{"success":true,"data":{"min_required_version":"invalid"}}', 200));
    final result = await AppVersionRepository.check(
        installedVersion: '1.0.0', platform: 'android', client: client);
    expect(result!.required, isTrue);
  });
  test('compatible builds get an optional update rather than a mandatory block',
      () {
    const result = AppVersionCheck(installedVersion: '2.0.0', policy: policy);
    expect(result.required, isFalse);
    expect(result.available, isTrue);
  });
  test('logout preserves the non-account update requirement', () async {
    SharedPreferences.setMockInitialValues({
      'role': 'client',
      'app_version_policy_android': jsonEncode(policy.toJson())
    });
    await ApiService.clearToken();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('role'), isNull);
    expect(prefs.getString('app_version_policy_android'), isNotNull);
  });
}
