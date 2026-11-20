import 'package:fitlek1/services/svc_l10n.dart';
import 'package:firebase_auth/firebase_auth.dart';

String socialAuthError(Object error, String provider) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'operation-not-allowed':
        return svcL10n.socialAuthNotAvailable(provider);
      case 'account-exists-with-different-credential':
        return svcL10n.socialAuthAccountExists;
      case 'network-request-failed':
        return svcL10n.socialAuthNetwork;
      case 'invalid-credential':
      case 'invalid-oauth-client-id':
        return svcL10n.socialAuthNotVerified(provider);
      case 'user-disabled':
        return svcL10n.socialAuthUserDisabled;
      case 'popup-closed-by-user':
      case 'web-context-cancelled':
        return 'cancelled';
    }
    return svcL10n.socialAuthFailed(provider);
  }
  return error.toString().replaceFirst('Exception: ', '');
}
