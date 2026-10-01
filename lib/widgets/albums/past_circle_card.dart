import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/storage_image.dart';
import '../../models/circle_summary.dart';
import '../../theme/app_theme.dart';
import '../common/locked_cover_overlay.dart';

class PastCircleCard extends StatelessWidget {
  const PastCircleCard({super.key, required this.circle, required this.onTap});

  final CircleSummary circle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final year = circle.eventDate?.year.toString() ?? '';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.cardLarge),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  LockedCoverOverlay(
                    locked: !circle.isOpenJoin,
                    child: circle.coverUrl != null
                        ? CachedNetworkImage(imageUrl: circle.coverUrl!, cacheKey: storageCacheKey(circle.coverUrl!), fit: BoxFit.cover)
                        : DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: colors.coverGradientColors,
                              ),
                            ),
                          ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [colors.scrim.withValues(alpha: 0.7), Colors.transparent],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: colors.scrim.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(AppRadius.pill)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.lock, size: 10, color: Colors.white),
                          SizedBox(width: 3),
                          Text('Arşiv', style: TextStyle(fontSize: 10, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 8,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.image, size: 13, color: Colors.white),
                            const SizedBox(width: 4),
                            Text('${circle.photoCount}', style: AppTextStyles.labelSm.copyWith(color: Colors.white)),
                          ],
                        ),
                        Text(year, style: AppTextStyles.labelSm.copyWith(color: Colors.white.withValues(alpha: 0.9))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(circle.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.labelLg.copyWith(color: colors.primary)),
                  const SizedBox(height: 2),
                  Text('${circle.participantCount} katılımcı', style: AppTextStyles.labelSm.copyWith(color: colors.onSurfaceVariant)),
                  if (!circle.isOpenJoin) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.lock, size: 11, color: colors.onSurfaceVariant),
                        const SizedBox(width: 3),
                        Text('Sadece Davetle', style: AppTextStyles.labelSm.copyWith(color: colors.onSurfaceVariant, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
