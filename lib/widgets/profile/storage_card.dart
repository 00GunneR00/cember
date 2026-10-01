import 'package:flutter/material.dart';

import '../../models/user_profile.dart';
import '../../theme/app_theme.dart';
import '../common/live_dot.dart';
import 'stat_column.dart';

class StorageCard extends StatelessWidget {
  const StorageCard({super.key, required this.profile, required this.onUpgradeTap});

  final UserProfile profile;
  final VoidCallback onUpgradeTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
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
              StatColumn(value: '${profile.circleCount}', label: 'Çemberim'),
              StatColumn(value: '${profile.photoCount}', label: 'Fotoğraf', valueColor: colors.secondary),
              StatColumn(value: '${profile.eventCount}', label: 'Etkinlik'),
            ],
          ),
          Divider(height: 24, color: colors.surfaceContainer),
          Row(
            children: [
              Icon(Icons.cloud_outlined, color: colors.secondary),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bulut Depolama', style: AppTextStyles.labelMd.copyWith(color: colors.primary)),
                    Row(
                      children: [
                        const LiveDot(size: 6),
                        const SizedBox(width: 4),
                        Text('Orijinal Kalitede Yedekleme', style: AppTextStyles.labelSm.copyWith(color: colors.onSurfaceVariant)),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onUpgradeTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: colors.secondaryContainer, borderRadius: BorderRadius.circular(AppRadius.pill)),
                  child: Text('Yükselt', style: AppTextStyles.labelSm.copyWith(color: colors.onSecondaryContainer, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: profile.storageFraction,
              minHeight: 8,
              backgroundColor: colors.surfaceContainerHigh,
              valueColor: AlwaysStoppedAnimation(colors.secondary),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${profile.storageUsedGb.toStringAsFixed(1)} GB / ${profile.storageTotalGb.toStringAsFixed(0)} GB', style: AppTextStyles.labelSm.copyWith(color: colors.onSurfaceVariant)),
              Text('%${(profile.storageFraction * 100).round()} Kullanıldı', style: AppTextStyles.labelSm.copyWith(color: colors.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }
}
