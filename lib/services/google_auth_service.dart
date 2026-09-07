import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:fitlek1/constants/urls.dart';

class GoogleAuthResult {
  final String accessToken;
  final Map<String, dynamic> user;
  final bool isNewUser;
  final bool hasPassword;
  final bool isApproved;

  const GoogleAuthResult({
    required this.accessToken,
    required this.user,
    required this.isNewUser,
    required this.hasPassword,
    required this.isApproved,
  });
}

class GoogleAuthService {
  static Future<GoogleAuthResult> signInWithGoogle({
    String role = 'client',
    String? referralCode,
  }) async {
    try {
      UserCredential userCredential;

      if (kIsWeb) {
        // On Web, Firebase Auth has built-in popup support which is much more reliable
        // than using the google_sign_in package.
        final googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        
        userCredential = await FirebaseAuth.instance.signInWithPopup(googleProvider);
      } else {
        // On Mobile, we use the native google_sign_in package
        final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
        await googleSignIn.signOut(); // force account picker
        
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          throw Exception('cancelled');
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      }

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
      if (referralCode != null && referralCode.isNotEmpty) {
        requestBody['referralCode'] = referralCode;
      }

      final http.Response response = await http
          .post(
            Uri.parse('$baseUrl/auth/google'),
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
              'Google sign-in error (${response.statusCode})',
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('🔥 GoogleAuthService Error: $e');
      rethrow;
    }
  }
}
