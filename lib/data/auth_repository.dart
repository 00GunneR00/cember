abstract class AuthRepository {
  const AuthRepository();

  Future<String> registerHost(String displayName);

  /// Signs in with a Google ID token, returning an apiKey for a new or already-linked host.
  Future<String> signInWithGoogle(String idToken);

  /// Links a Google account to the currently signed-in host, for recovery on other devices.
  Future<void> linkGoogle(String idToken);
}

class MockAuthRepository extends AuthRepository {
  const MockAuthRepository();

  @override
  Future<String> registerHost(String displayName) async => 'mock-api-key';

  @override
  Future<String> signInWithGoogle(String idToken) async => 'mock-api-key';

  @override
  Future<void> linkGoogle(String idToken) async {}
}
