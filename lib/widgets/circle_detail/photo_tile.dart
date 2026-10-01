import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/storage_image.dart';
import '../../models/circle_photo.dart';
import '../../theme/app_theme.dart';

class PhotoTile extends StatelessWidget {
  const PhotoTile({super.key, required this.photo, required this.onReact, required this.onMore});

  final CirclePhoto photo;
  final VoidCallback onReact;

  /// Opens the photo's actions (delete, or report / block).
  final VoidCallback onMore;

  String get _timeLabel {
    final h = photo.createdAt.hour.toString().padLeft(2, '0');
    final m = photo.createdAt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.cardLarge),
              child: photo.thumbnailUrl.isEmpty
                  ? Container(color: colors.surfaceContainer)
                  : CachedNetworkImage(imageUrl: photo.thumbnailUrl, cacheKey: storageCacheKey(photo.thumbnailUrl), fit: BoxFit.cover),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: colors.surfaceContainerLowest.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(AppRadius.pill)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(radius: 8, backgroundColor: colors.secondaryContainer, child: const Icon(Icons.person, size: 10, color: Colors.white)),
                    const SizedBox(width: 4),
                    Text(photo.uploader, style: AppTextStyles.labelSm.copyWith(color: colors.onSurfaceVariant, fontSize: 11)),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              child: GestureDetector(
                onTap: onReact,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: colors.surfaceContainerLowest.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(AppRadius.pill)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        photo.viewerHasReacted ? Icons.favorite : Icons.favorite_border,
                        size: 13,
                        color: photo.viewerHasReacted ? colors.error : colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text('${photo.reactionCount}', style: AppTextStyles.labelSm.copyWith(color: colors.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 2,
              right: 2,
              child: IconButton(
                onPressed: onMore,
                tooltip: 'Fotoğraf seçenekleri',
                visualDensity: VisualDensity.compact,
                icon: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.35), shape: BoxShape.circle),
                  child: const Icon(Icons.more_horiz, size: 18, color: Colors.white),
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: Text(_timeLabel, style: AppTextStyles.labelSm.copyWith(color: Colors.white70, fontSize: 10)),
            ),
          ],
        ),
      ),
    );
  }
}
