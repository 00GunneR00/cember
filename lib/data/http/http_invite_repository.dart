import '../../core/api_client.dart';
import '../../models/invite_preview.dart';
import '../../models/join_circle_result.dart';
import '../invite_repository.dart';

class HttpInviteRepository extends InviteRepository {
  const HttpInviteRepository(this._client);

  final ApiClient _client;

  @override
  Future<InvitePreview> preview(String token) async {
    final response = await _client.dio.get('/invite/$token');
    return InvitePreview.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<JoinCircleResult> join(String token, String displayName) async {
    final response = await _client.dio.post('/invite/$token/join', data: {'displayName': displayName});
    return JoinCircleResult.fromJson(response.data as Map<String, dynamic>);
  }
}
