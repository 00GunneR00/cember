import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/reveal_time.dart';
import '../../core/storage_image.dart';
import '../../models/circle_summary.dart';
import '../../theme/app_theme.dart';
import '../common/avatar_stack.dart';
import '../common/brand_sponsor_badge.dart';
import '../common/live_dot.dart';
import '../common/locked_cover_overlay.dart';

class LiveCircleCard extends StatelessWidget {
  const LiveCircleCard({super.key, required this.circle, required this.onTap});

  final CircleSummary circle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.cardLarge),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 192,
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
                        colors: [colors.scrim.withValues(alpha: 0.75), Colors.transparent],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerLowest.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (circle.isDeveloping && circle.revealAt != null) ...[
                            Icon(Icons.photo_filter, size: 12, color: colors.secondary),
                            const SizedBox(width: 6),
                            Text(
                              'BANYODA · ${formatRevealTime(circle.revealAt!)}',
                              style: AppTextStyles.labelSm.copyWith(color: colors.primary, fontWeight: FontWeight.w700),
                            ),
                          ] else ...[
                            const LiveDot(size: 8),
                            const SizedBox(width: 6),
                            Text('CANLI YÜKLEME', style: AppTextStyles.labelSm.copyWith(color: colors.primary, fontWeight: FontWeight.w700)),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (!circle.isOpenJoin)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: colors.scrim.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.lock, size: 12, color: Colors.white),
                            const SizedBox(width: 5),
                            Text('Sadece Davetle', style: AppTextStyles.labelSm.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerLowest.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(AppRadius.card),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_a_photo, size: 18, color: colors.secondary),
                          const SizedBox(width: 6),
                          Text('Fotoğraf At', style: AppTextStyles.labelMd.copyWith(color: colors.onSurface)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(circle.name, style: AppTextStyles.headlineSm.copyWith(color: colors.primary)),
                  if (circle.brand != null) ...[
                    const SizedBox(height: 6),
                    BrandSponsorBadge(brand: circle.brand!),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      AvatarStack(
                        visibleCount: 3,
                        avatarRadius: 14,
                        overlapOffset: 18,
                        extraCount: circle.participantCount > 3 ? circle.participantCount - 3 : 0,
                      ),
                      const Spacer(),
                      Icon(Icons.photo_library, size: 16, color: colors.secondary),
                      const SizedBox(width: 4),
                      Text('${circle.photoCount} kare', style: AppTextStyles.labelSm.copyWith(color: colors.onSurfaceVariant)),
                      const SizedBox(width: 12),
                      Icon(Icons.group, size: 16, color: colors.secondary),
                      const SizedBox(width: 4),
                      Text('${circle.participantCount} kişi', style: AppTextStyles.labelSm.copyWith(color: colors.onSurfaceVariant)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
