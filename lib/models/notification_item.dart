import 'notification_type.dart';

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.type,
    required this.circleId,
    required this.circleName,
    required this.actorDisplayName,
    required this.photoId,
    required this.preview,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final NotificationType type;
  final String circleId;
  final String circleName;
  final String actorDisplayName;
  final String? photoId;
  final String? preview;
  final bool isRead;
  final DateTime createdAt;

  NotificationItem copyWith({bool? isRead}) => NotificationItem(
        id: id,
        type: type,
        circleId: circleId,
        circleName: circleName,
        actorDisplayName: actorDisplayName,
        photoId: photoId,
        preview: preview,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );

  factory NotificationItem.fromJson(Map<String, dynamic> json) => NotificationItem(
        id: json['id'] as String,
        type: NotificationType.fromApi(json['type'] as String),
        circleId: json['circleId'] as String,
        circleName: json['circleName'] as String,
        actorDisplayName: json['actorDisplayName'] as String,
        photoId: json['photoId'] as String?,
        preview: json['preview'] as String?,
        isRead: json['isRead'] as bool,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
