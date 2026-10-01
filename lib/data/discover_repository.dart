import '../models/discover_page.dart';
import '../models/join_circle_result.dart';

abstract class DiscoverRepository {
  const DiscoverRepository();

  Future<DiscoverPage> fetch({String? query, String? cursor});
  Future<JoinCircleResult> join(String circleId);

  /// Up to 10 thumbnails of what's already been shared, for the pre-join preview screen.
  Future<List<String>> fetchPreviewPhotos(String circleId);
}

class MockDiscoverRepository extends DiscoverRepository {
  const MockDiscoverRepository();

  @override
  Future<DiscoverPage> fetch({String? query, String? cursor}) async => const DiscoverPage(items: [], nextCursor: null);

  @override
  Future<JoinCircleResult> join(String circleId) => throw UnimplementedError();

  @override
  Future<List<String>> fetchPreviewPhotos(String circleId) async => const [];
}
