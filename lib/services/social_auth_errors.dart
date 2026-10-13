import 'package:firebase_auth/firebase_auth.dart';

String socialAuthError(Object error, String provider) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'operation-not-allowed':
        return '$provider sign-in is not available yet. Please use email and password.';
      case 'account-exists-with-different-credential':
        return 'This email already has an account. Sign in using your original method.';
      case 'network-request-failed':
        return 'Check your internet connection and try again.';
      case 'invalid-credential':
      case 'invalid-oauth-client-id':
        return '$provider sign-in could not be verified. Please try again.';
      case 'user-disabled':
        return 'This account is unavailable. Please contact support.';
      case 'popup-closed-by-user':
      case 'web-context-cancelled':
        return 'cancelled';
    }
    return '$provider sign-in failed. Please try again.';
  }
  return error.toString().replaceFirst('Exception: ', '');
}
