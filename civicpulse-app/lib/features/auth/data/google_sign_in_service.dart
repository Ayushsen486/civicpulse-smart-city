import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

final googleSignInServiceProvider = Provider<GoogleSignInService>((ref) {
  return GoogleSignInService();
});

class GoogleSignInService {
  final GoogleSignIn _googleSignIn;

  static const String defaultClientId =
      '1024729300393-461mvfgdra4p5mfq1lfesro7inihqs5a.apps.googleusercontent.com';

  GoogleSignInService({GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ??
            GoogleSignIn(
              clientId: kIsWeb
                  ? (const String.fromEnvironment('GOOGLE_CLIENT_ID').isNotEmpty
                      ? const String.fromEnvironment('GOOGLE_CLIENT_ID')
                      : defaultClientId)
                  : null,
              serverClientId: const String.fromEnvironment('GOOGLE_CLIENT_ID').isNotEmpty
                  ? const String.fromEnvironment('GOOGLE_CLIENT_ID')
                  : defaultClientId,
              scopes: const [
                'email',
                'profile',
              ],
            );

  /// Initiates interactive Google Sign-In and extracts the cryptographic ID Token.
  /// Returns `null` if the user aborted or cancelled the prompt.
  Future<String?> getGoogleIdToken() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        return null;
      }
      final authentication = await account.authentication;
      return authentication.idToken;
    } catch (e) {
      final err = e.toString();
      if (err.contains('popup_closed') ||
          err.contains('popup_closed_by_user') ||
          err.contains('access_denied') ||
          err.contains('cancelled') ||
          err.contains('canceled')) {
        return null; // Graceful user cancellation
      }
      if (err.contains('Null check operator') ||
          err.contains('clientId') ||
          err.contains('PlatformException') ||
          err.contains('idpiframe_initialization_failed')) {
        throw FormatException(
          kIsWeb
              ? 'Google Sign-In on Web requires a registered Google OAuth Web Client ID for http://localhost:5000. For instant access, use the test account chips below.'
              : 'Google Sign-In service is not configured or unavailable on this device.',
        );
      }
      rethrow;
    }
  }

  /// Cleans up local provider authentication session without revoking user account.
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Graceful ignoring of offline or decoupled local state
    }
  }
}
