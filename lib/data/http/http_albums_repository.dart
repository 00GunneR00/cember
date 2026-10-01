import '../../core/api_client.dart';
import '../../core/token_store.dart';
import '../../models/albums_overview.dart';
import '../../models/circle_detail.dart';
import '../../models/circle_summary.dart';
import '../../models/joined_circle_summary.dart';
import '../../models/photo_upload_mode.dart';
import '../albums_repository.dart';

class HttpAlbumsRepository extends AlbumsRepository {
  const HttpAlbumsRepository(this._client, {TokenStore? tokenStore}) : _tokenStore = tokenStore ?? const TokenStore();

  final ApiClient _client;
  final TokenStore _tokenStore;

  @override
  Future<AlbumsOverview> fetch() async {
    final responses = await Future.wait([
      _client.dio.get('/circles'),
      _client.dio.get('/me'),
    ]);
    final circlesJson = responses[0].data as Map<String, dynamic>;
    final meJson = responses[1].data as Map<String, dynamic>;
    return AlbumsOverview(
      userName: meJson['displayName'] as String,
      live: (circlesJson['live'] as List).map((e) => CircleSummary.fromJson(e as Map<String, dynamic>)).toList(),
      past: (circlesJson['past'] as List).map((e) => CircleSummary.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  @override
  Future<CircleSummary> createCircle(
    String name, {
    DateTime? eventDate,
    required bool isOpenJoin,
    String? description,
    PhotoUploadMode uploadMode = PhotoUploadMode.both,
    DateTime? revealAt,
    String? challengeTemplateId,
    List<String>? rules,
  }) async {
    final response = await _client.dio.post('/circles', data: {
      'name': name,
      'eventDate': eventDate == null ? null : _dateOnly(eventDate),
      'isOpenJoin': isOpenJoin,
      'description': description,
      'uploadMode': uploadMode.apiValue,
      'revealAt': revealAt?.toUtc().toIso8601String(),
      'challengeTemplateId': challengeTemplateId,
      'rules': ?rules,
    });
    return CircleSummary.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<JoinedCircleSummary>> fetchJoinedCircles() async {
    final ids = await _tokenStore.readJoinedCircleIds();
    if (ids.isEmpty) return const [];

    final results = <JoinedCircleSummary>[];
    for (final id in ids) {
      final token = await _tokenStore.readGuestToken(id);
      if (token == null) continue;
      try {
        final guestClient = ApiClient(baseUrl: _client.dio.options.baseUrl, bearerToken: token);
        final response = await guestClient.dio.get('/circles/$id');
        final detail = CircleDetail.fromJson(response.data as Map<String, dynamic>);
        results.add(JoinedCircleSummary(
          circle: CircleSummary(
            id: detail.id,
            name: detail.title,
            eventDate: detail.eventDate,
            isArchived: false,
            isOpenJoin: detail.isOpenJoin,
            photoCount: detail.memoryCount,
            participantCount: detail.participantCount,
            coverUrl: detail.coverUrl,
            description: detail.description,
            uploadMode: detail.uploadMode,
          ),
          guestToken: token,
        ));
      } catch (_) {
        // Circle deleted, or the guest session expired — quietly drop it from the list.
        continue;
      }
    }
    return results;
  }

  String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
