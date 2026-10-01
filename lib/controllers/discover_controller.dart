import 'package:get/get.dart';

import '../data/discover_repository.dart';
import '../models/join_circle_result.dart';
import '../models/public_circle_summary.dart';

class DiscoverController extends GetxController {
  DiscoverController(this._repository);

  final DiscoverRepository _repository;

  final loading = true.obs;
  final loadingMore = false.obs;
  final error = Rxn<String>();
  final circles = <PublicCircleSummary>[].obs;
  String? _nextCursor;
  String _query = '';

  bool get hasMore => _nextCursor != null;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load({String? query}) async {
    if (query != null) _query = query;
    loading.value = true;
    error.value = null;
    try {
      final page = await _repository.fetch(query: _query.isEmpty ? null : _query);
      circles.assignAll(page.items);
      _nextCursor = page.nextCursor;
    } catch (_) {
      error.value = 'Çemberler yüklenemedi.';
    } finally {
      loading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (!hasMore || loadingMore.value) return;
    loadingMore.value = true;
    try {
      final page = await _repository.fetch(query: _query.isEmpty ? null : _query, cursor: _nextCursor);
      circles.addAll(page.items);
      _nextCursor = page.nextCursor;
    } catch (_) {
      // Keep the already-loaded page visible; the user can pull to refresh.
    } finally {
      loadingMore.value = false;
    }
  }

  Future<JoinCircleResult?> join(String circleId) async {
    try {
      return await _repository.join(circleId);
    } catch (_) {
      return null;
    }
  }

  Future<List<String>> fetchPreviewPhotos(String circleId) async {
    try {
      return await _repository.fetchPreviewPhotos(circleId);
    } catch (_) {
      return const [];
    }
  }
}
