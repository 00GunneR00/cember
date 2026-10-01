import '../models/notification_page.dart';

abstract class NotificationsRepository {
  const NotificationsRepository();

  Future<NotificationPage> fetch({String? cursor});
  Future<int> fetchUnreadCount();
  Future<void> markRead(String id);
  Future<void> markAllRead();
}

class MockNotificationsRepository extends NotificationsRepository {
  const MockNotificationsRepository();

  @override
  Future<NotificationPage> fetch({String? cursor}) async => const NotificationPage(items: [], nextCursor: null, unreadCount: 0);

  @override
  Future<int> fetchUnreadCount() async => 0;

  @override
  Future<void> markRead(String id) async {}

  @override
  Future<void> markAllRead() async {}
}
