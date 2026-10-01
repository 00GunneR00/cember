import 'notification_item.dart';

class NotificationPage {
  const NotificationPage({required this.items, required this.nextCursor, required this.unreadCount});

  final List<NotificationItem> items;
  final String? nextCursor;
  final int unreadCount;

  factory NotificationPage.fromJson(Map<String, dynamic> json) => NotificationPage(
        items: (json['items'] as List).map((e) => NotificationItem.fromJson(e as Map<String, dynamic>)).toList(),
        nextCursor: json['nextCursor'] as String?,
        unreadCount: json['unreadCount'] as int,
      );
}
