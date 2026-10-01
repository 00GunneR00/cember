import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/storage_image.dart';
import '../../models/public_circle_summary.dart';
import '../../theme/app_theme.dart';
import '../common/brand_sponsor_badge.dart';

class PublicCircleCard extends StatelessWidget {
  const PublicCircleCard({super.key, required this.circle, required this.onTap});

  final PublicCircleSummary circle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.cardLarge),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: SizedBox(
                width: 72,
                height: 72,
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
                        child: Icon(Icons.groups_outlined, color: colors.onPrimaryContainer),
                      ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(circle.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.labelLg.copyWith(color: colors.primary)),
                  if (circle.brand != null) ...[
                    const SizedBox(height: 2),
                    BrandSponsorBadge(brand: circle.brand!),
                  ],
                  if (circle.description != null && circle.description!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      circle.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySm.copyWith(color: colors.secondary, fontStyle: FontStyle.italic, fontWeight: FontWeight.w600),
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text('${circle.hostDisplayName} tarafından', style: AppTextStyles.labelSm.copyWith(color: colors.onSurfaceVariant)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.photo_library, size: 14, color: colors.secondary),
                      const SizedBox(width: 4),
                      Text('${circle.photoCount} kare', style: AppTextStyles.labelSm.copyWith(color: colors.onSurfaceVariant)),
                      const SizedBox(width: 10),
                      Icon(Icons.group, size: 14, color: colors.secondary),
                      const SizedBox(width: 4),
                      Text('${circle.participantCount} kişi', style: AppTextStyles.labelSm.copyWith(color: colors.onSurfaceVariant)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
