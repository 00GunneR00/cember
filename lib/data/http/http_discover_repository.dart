import '../../core/api_client.dart';
import '../../models/discover_page.dart';
import '../../models/join_circle_result.dart';
import '../discover_repository.dart';

class HttpDiscoverRepository extends DiscoverRepository {
  const HttpDiscoverRepository(this._client);

  final ApiClient _client;

  @override
  Future<DiscoverPage> fetch({String? query, String? cursor}) async {
    final response = await _client.dio.get(
      '/circles/discover',
      queryParameters: {'pageSize': 20, 'query': ?query, 'cursor': ?cursor},
    );
    return DiscoverPage.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<JoinCircleResult> join(String circleId) async {
    final response = await _client.dio.post('/circles/$circleId/join');
    return JoinCircleResult.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<String>> fetchPreviewPhotos(String circleId) async {
    final response = await _client.dio.get('/circles/$circleId/preview-photos', queryParameters: {'limit': 10});
    final json = response.data as Map<String, dynamic>;
    return (json['thumbnailUrls'] as List).cast<String>();
  }
}
