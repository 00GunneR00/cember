import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/storage_image.dart';
import '../../models/public_circle_summary.dart';
import '../../theme/app_theme.dart';
import '../common/app_logo_mark.dart';

/// A brand's circle on Keşfet > Markalar. The brand's colors and logo lead; its motto is the headline.
class BrandCircleCard extends StatelessWidget {
  const BrandCircleCard({super.key, required this.circle, required this.onTap});

  final PublicCircleSummary circle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final brand = circle.brand;
    final brandColor = brand?.primaryColor ?? colors.secondary;
    final motto = circle.description;
    return Material(
      color: colors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppRadius.cardLarge),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 150,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  circle.coverUrl != null
                      ? CachedNetworkImage(imageUrl: circle.coverUrl!, cacheKey: storageCacheKey(circle.coverUrl!), fit: BoxFit.cover)
                      : DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [brandColor, brand?.secondaryColor ?? colors.primaryContainer],
                            ),
                          ),
                        ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.center,
                        colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    bottom: 12,
                    right: 12,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: AppLogoMark(size: 30, imageUrl: brand?.logoUrl),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            brand?.name ?? circle.hostDisplayName,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.labelLg.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(AppRadius.pill)),
                          child: Text(
                            'Marka çemberi',
                            style: AppTextStyles.labelSm.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (motto != null && motto.isNotEmpty) ...[
                    // The brand's own color marks the motto; the text itself stays in the readable ink color.
                    Container(
                      padding: const EdgeInsets.only(left: 10),
                      decoration: BoxDecoration(
                        border: Border(left: BorderSide(color: brandColor, width: 3)),
                      ),
                      child: Text(
                        '“$motto”',
                        style: AppTextStyles.headlineSm.copyWith(color: colors.primary, fontStyle: FontStyle.italic),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                  ],
                  Text(circle.name, style: AppTextStyles.labelLg.copyWith(color: colors.onSurfaceVariant)),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Icon(Icons.photo_library, size: 14, color: colors.secondary),
                      const SizedBox(width: 4),
                      Text('${circle.photoCount} kare', style: AppTextStyles.labelSm.copyWith(color: colors.onSurfaceVariant)),
                      const SizedBox(width: 10),
                      Icon(Icons.group, size: 14, color: colors.secondary),
                      const SizedBox(width: 4),
                      Text('${circle.participantCount} kişi', style: AppTextStyles.labelSm.copyWith(color: colors.onSurfaceVariant)),
                      const Spacer(),
                      Text('Katıl ›', style: AppTextStyles.labelMd.copyWith(color: colors.secondary)),
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
