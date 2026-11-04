import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:fitlek1/services/account_security.dart';

void main() {
  test(
      'password update uses authenticated account endpoint and preserves spaces',
      () async {
    final client = MockClient((request) async {
      expect(request.method, 'PUT');
      expect(request.url.path, endsWith('/auth/account/password'));
      expect(request.headers['Authorization'], 'Bearer test-token');
      expect(jsonDecode(request.body), {
        'currentPassword': ' old password ',
        'newPassword': ' new password '
      });
      return http.Response('{"message":"Password updated successfully."}', 200);
    });
    await AccountSecurity.changePassword(
        token: 'test-token',
        currentPassword: ' old password ',
        newPassword: ' new password ',
        client: client);
  });
  test('incorrect current password displays backend error', () async {
    final client = MockClient((_) async =>
        http.Response('{"error":"Incorrect current password"}', 401));
    await expectLater(
        AccountSecurity.changePassword(
            token: 'test-token',
            currentPassword: 'incorrect',
            newPassword: 'newPassword123',
            client: client),
        throwsA(isA<PasswordUpdateException>().having(
            (e) => e.message, 'message', 'Incorrect current password')));
  });
}
