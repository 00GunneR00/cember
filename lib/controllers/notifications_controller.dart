import 'package:get/get.dart';

import '../data/notifications_repository.dart';
import '../models/notification_item.dart';

class NotificationsController extends GetxController {
  NotificationsController(this._repository);

  final NotificationsRepository _repository;

  final loading = true.obs;
  final loadingMore = false.obs;
  final error = Rxn<String>();
  final items = <NotificationItem>[].obs;
  final unreadCount = 0.obs;
  String? _nextCursor;

  bool get hasMore => _nextCursor != null;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      final page = await _repository.fetch();
      items.assignAll(page.items);
      _nextCursor = page.nextCursor;
      unreadCount.value = page.unreadCount;
    } catch (_) {
      error.value = 'Bildirimler yüklenemedi.';
    } finally {
      loading.value = false;
    }
  }

  /// Fetches just the unread badge count, for polling from the bottom nav without loading the full list.
  Future<void> refreshUnreadCount() async {
    try {
      unreadCount.value = await _repository.fetchUnreadCount();
    } catch (_) {
      // Badge staying stale for one tick is harmless; next poll will correct it.
    }
  }

  Future<void> loadMore() async {
    if (!hasMore || loadingMore.value) return;
    loadingMore.value = true;
    try {
      final page = await _repository.fetch(cursor: _nextCursor);
      items.addAll(page.items);
      _nextCursor = page.nextCursor;
    } catch (_) {
      // Keep the already-loaded page visible; the user can pull to refresh.
    } finally {
      loadingMore.value = false;
    }
  }

  Future<void> markRead(String id) async {
    final index = items.indexWhere((n) => n.id == id);
    if (index == -1 || items[index].isRead) return;
    items[index] = items[index].copyWith(isRead: true);
    if (unreadCount.value > 0) unreadCount.value--;
    try {
      await _repository.markRead(id);
    } catch (_) {
      // Best-effort: local state already reflects "read"; a retry happens on next full load().
    }
  }

  Future<void> markAllRead() async {
    if (unreadCount.value == 0) return;
    items.assignAll(items.map((n) => n.copyWith(isRead: true)));
    unreadCount.value = 0;
    try {
      await _repository.markAllRead();
    } catch (_) {
      // Best-effort, same as markRead.
    }
  }
}
