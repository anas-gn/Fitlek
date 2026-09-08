import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:http/http.dart' as http;
import 'package:fitlek1/constants/urls.dart';
import 'google_auth_service.dart' show GoogleAuthResult;

class AppleAuthService {
  /// Generates a cryptographically secure random nonce, to be included in a
  /// credential request.
  static String generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  /// Returns the sha256 hash of [input] in hex notation.
  static String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static Future<GoogleAuthResult> signInWithApple({
    String role = 'client',
    String? referralCode,
  }) async {
    try {
      final rawNonce = generateNonce();
      final nonce = sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(oauthCredential);
      final User? firebaseUser = userCredential.user;
      
      if (firebaseUser == null) {
        throw Exception('Firebase authentication failed.');
      }

      final String? firebaseIdToken = await firebaseUser.getIdToken();
      if (firebaseIdToken == null) {
        throw Exception('Could not retrieve Firebase ID token.');
      }

      if (kDebugMode) debugPrint('🔐 Firebase ID Token obtained, sending to backend...');

      final Map<String, dynamic> requestBody = {
        'idToken': firebaseIdToken,
        'role': role,
      };
      
      // Pass the name up if it's the first time
      if (appleCredential.givenName != null || appleCredential.familyName != null) {
        requestBody['firstName'] = appleCredential.givenName ?? '';
        requestBody['lastName'] = appleCredential.familyName ?? '';
      }

      if (referralCode != null && referralCode.isNotEmpty) {
        requestBody['referralCode'] = referralCode;
      }

      final http.Response response = await http
          .post(
            Uri.parse('$baseUrl/auth/apple'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 20));

      final Map<String, dynamic> body =
          jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final String? accessToken = body['accessToken'] as String?;
        final Map<String, dynamic>? user = body['user'] as Map<String, dynamic>?;

        if (accessToken == null || accessToken.isEmpty || user == null) {
          throw Exception('Invalid response from server.');
        }

        return GoogleAuthResult(
          accessToken: accessToken,
          user: user,
          isNewUser: body['isNewUser'] == true,
          hasPassword: body['hasPassword'] == true,
          isApproved: body['isApproved'] == true || user['isApproved'] == true,
        );
      } else if (response.statusCode == 403) {
        throw Exception(body['error'] as String? ?? 'Account suspended.');
      } else {
        throw Exception(
          body['error'] as String? ??
              body['message'] as String? ??
              'Apple sign-in error (${response.statusCode})',
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('🔥 AppleAuthService Error: $e');
      rethrow;
    }
  }
}
