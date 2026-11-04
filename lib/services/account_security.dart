import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/urls.dart' as urls;

class AccountSecurity {
  static Future<void> changePassword(
      {required String token,
      required String currentPassword,
      required String newPassword,
      http.Client? client}) async {
    final ownedClient = client == null;
    final transport = client ?? http.Client();
    try {
      final response = await transport
          .put(
            Uri.parse('${urls.baseUrl}/auth/account/password'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json'
            },
            body: jsonEncode({
              'currentPassword': currentPassword,
              'newPassword': newPassword
            }),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        String message = 'Could not update your password. Please try again.';
        try {
          final body = jsonDecode(response.body);
          if (body is Map)
            message = '${body['error'] ?? body['message'] ?? message}';
        } catch (_) {}
        throw PasswordUpdateException(message);
      }
    } finally {
      if (ownedClient) transport.close();
    }
  }
}

class PasswordUpdateException implements Exception {
  final String message;
  const PasswordUpdateException(this.message);
}
