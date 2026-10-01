import 'package:get/get.dart';

import '../models/circle_photo.dart';
import '../models/photo_page.dart';

/// One paginated, masonry-splittable list of photos. A circle in "Both" upload mode
/// holds two of these (Şipşak / Galeriden) side by side; any other circle holds just one.
class PhotoFeed {
  PhotoFeed(this._fetchPage);

  final Future<PhotoPage> Function({String? cursor}) _fetchPage;

  final photos = <CirclePhoto>[].obs;
  final loadingMore = false.obs;
  String? _cursor;

  bool get hasMore => _cursor != null;
  List<CirclePhoto> get columnLeft => [for (var i = 0; i < photos.length; i += 2) photos[i]];
  List<CirclePhoto> get columnRight => [for (var i = 1; i < photos.length; i += 2) photos[i]];

  Future<void> load() async {
    final page = await _fetchPage();
    photos.assignAll(page.photos);
    _cursor = page.nextCursor;
  }

  Future<void> loadMore() async {
    if (!hasMore || loadingMore.value) return;
    loadingMore.value = true;
    try {
      final page = await _fetchPage(cursor: _cursor);
      photos.addAll(page.photos);
      _cursor = page.nextCursor;
    } catch (_) {
      // Keep the already-loaded page visible; the user can pull to refresh.
    } finally {
      loadingMore.value = false;
    }
  }

  /// Finds [photoId] in this feed and re-renders it if present — a no-op otherwise.
  void refreshIfPresent(String photoId) {
    if (photos.any((p) => p.id == photoId)) photos.refresh();
  }

  void removeWhere(bool Function(CirclePhoto photo) test) => photos.removeWhere(test);
}
