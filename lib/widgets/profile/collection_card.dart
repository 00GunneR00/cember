import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/storage_image.dart';
import '../../models/profile_collection.dart';
import '../../theme/app_theme.dart';

class CollectionCard extends StatelessWidget {
  const CollectionCard({super.key, required this.collection});

  final ProfileCollection collection;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(collection.icon, size: 18, color: colors.secondary),
              const Spacer(),
              Text('${collection.count} Öğe', style: AppTextStyles.labelSm.copyWith(color: colors.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(collection.title, style: AppTextStyles.labelLg.copyWith(color: colors.primary)),
          Text(collection.subtitle, style: AppTextStyles.labelSm.copyWith(color: colors.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              for (final url in collection.previewUrls)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(imageUrl: url, cacheKey: storageCacheKey(url), width: 32, height: 32, fit: BoxFit.cover),
                  ),
                ),
              if (collection.previewUrls.isEmpty)
                Container(width: 32, height: 32, decoration: BoxDecoration(color: colors.surfaceContainer, borderRadius: BorderRadius.circular(8))),
            ],
          ),
        ],
      ),
    );
  }
}
