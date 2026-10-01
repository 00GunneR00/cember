import 'package:google_sign_in/google_sign_in.dart';

/// Wraps the native Google Sign-In flow and returns an ID token whose audience is
/// the backend's configured Web client — the same one AuthService validates against.
class GoogleAuth {
  const GoogleAuth();

  static const _webClientId = '586656227578-6lr39fe4fn6p2kod4lpqa29a0ta5a5qe.apps.googleusercontent.com';

  /// Returns the signed-in account's ID token, or null if the user cancelled.
  Future<String?> signIn() async {
    final googleSignIn = GoogleSignIn(scopes: const ['email'], serverClientId: _webClientId);
    final account = await googleSignIn.signIn();
    if (account == null) return null;
    final auth = await account.authentication;
    return auth.idToken;
  }

  /// Forgets the Google account on this device, so the next sign-in asks again.
  Future<void> signOut() async {
    try {
      await GoogleSignIn(serverClientId: _webClientId).disconnect();
    } catch (_) {
      // Not signed in with Google on this device — nothing to forget.
    }
  }
}
