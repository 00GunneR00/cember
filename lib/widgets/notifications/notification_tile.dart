import 'package:flutter/material.dart';

import '../../models/notification_item.dart';
import '../../models/notification_type.dart';
import '../../theme/app_theme.dart';

class NotificationTile extends StatelessWidget {
  const NotificationTile({super.key, required this.notification, required this.onTap});

  final NotificationItem notification;
  final VoidCallback onTap;

  static const _icons = {
    NotificationType.photoAdded: Icons.add_a_photo,
    NotificationType.commentAdded: Icons.mode_comment,
    NotificationType.reactionAdded: Icons.favorite,
    NotificationType.guestJoined: Icons.person_add_alt_1,
    NotificationType.deletionVoteNeeded: Icons.how_to_vote,
    NotificationType.photosRevealed: Icons.photo_filter,
    NotificationType.recapReady: Icons.movie_filter,
  };

  String _message() {
    final actor = notification.actorDisplayName;
    final circle = notification.circleName;
    switch (notification.type) {
      case NotificationType.photoAdded:
        final extra = notification.preview;
        return extra == null
            ? '$actor, "$circle" çemberine yeni bir fotoğraf ekledi.'
            : '$actor, "$circle" çemberine $extra ekledi.';
      case NotificationType.commentAdded:
        return '$actor bir fotoğrafına yorum yaptı: "${notification.preview ?? ''}"';
      case NotificationType.reactionAdded:
        return '$actor bir fotoğrafına tepki verdi.';
      case NotificationType.guestJoined:
        return '$actor, "$circle" çemberine katıldı.';
      case NotificationType.deletionVoteNeeded:
        return '"$circle" çemberi için silme oylaması açıldı, oyun gerekiyor.';
      case NotificationType.photosRevealed:
        return '"$circle" banyodan çıktı! ${notification.preview ?? 'Anılar açıldı'} 🎞️';
      case NotificationType.recapReady:
        return '"$circle" özet videon hazır, izle ve paylaş 🎬';
    }
  }

  String _relativeTime() {
    final diff = DateTime.now().difference(notification.createdAt);
    if (diff.inMinutes < 1) return 'şimdi';
    if (diff.inMinutes < 60) return '${diff.inMinutes}dk';
    if (diff.inHours < 24) return '${diff.inHours}sa';
    if (diff.inDays < 7) return '${diff.inDays}g';
    return '${notification.createdAt.day.toString().padLeft(2, '0')}.${notification.createdAt.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isUnread = !notification.isRead;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isUnread ? colors.secondaryContainer.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: colors.surfaceContainer, shape: BoxShape.circle),
              child: Icon(_icons[notification.type], size: 18, color: colors.secondary),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_message(), style: AppTextStyles.bodySm.copyWith(color: colors.onSurface)),
                  const SizedBox(height: 4),
                  Text(_relativeTime(), style: AppTextStyles.labelSm.copyWith(color: colors.onSurfaceVariant)),
                ],
              ),
            ),
            if (isUnread)
              Container(
                margin: const EdgeInsets.only(left: AppSpacing.xs, top: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: colors.secondary, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }
}
