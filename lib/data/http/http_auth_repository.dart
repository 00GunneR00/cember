import '../../core/api_client.dart';
import '../auth_repository.dart';

class HttpAuthRepository extends AuthRepository {
  const HttpAuthRepository(this._client);

  final ApiClient _client;

  @override
  Future<String> registerHost(String displayName) async {
    final response = await _client.dio.post('/auth/host/register', data: {'displayName': displayName});
    return (response.data as Map<String, dynamic>)['apiKey'] as String;
  }

  @override
  Future<String> signInWithGoogle(String idToken) async {
    final response = await _client.dio.post('/auth/google', data: {'idToken': idToken});
    return (response.data as Map<String, dynamic>)['apiKey'] as String;
  }

  @override
  Future<void> linkGoogle(String idToken) async {
    await _client.dio.post('/me/link-google', data: {'idToken': idToken});
  }
}
