import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitlek1/services/apiService.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({
    'token': 'short-fixture-token', 'role': 'client', 'userId': 42,
    'firstName': 'Fixture',
  }));

  test('Client session validation calls the existing authenticated profile', () async {
    await http.runWithClient(() async {
      expect(await ApiService.checkSession(), 'client');
    }, () => MockClient((request) async {
      expect(request.url.path, '/api/clients/me');
      expect(request.url.queryParameters['userID'], '42');
      expect(request.headers['Authorization'], 'Bearer short-fixture-token');
      return http.Response('{"id":42}', 200);
    }));
  });

  test('An expired session clears authentication', () async {
    await http.runWithClient(() async {
      expect(await ApiService.checkSession(), isNull);
      expect(await ApiService.getToken(), isNull);
      expect(await ApiService.getRole(), isNull);
    }, () => MockClient((_) async => http.Response('{"error":"Expired"}', 401)));
  });

  test('A temporary network failure preserves the signed-in account', () async {
    await http.runWithClient(() async {
      expect(await ApiService.checkSession(), 'client');
      expect(await ApiService.getToken(), 'short-fixture-token');
    }, () => MockClient((_) async => throw http.ClientException('Fixture offline')));
  });

  test('Coach session validation preserves the existing coach profile route', () async {
    await ApiService.saveRole('coach');
    await http.runWithClient(() async {
      expect(await ApiService.checkSession(), 'coach');
    }, () => MockClient((request) async {
      expect(request.url.path, '/api/coach/profile');
      return http.Response('{"id":42}', 200);
    }));
  });
}
