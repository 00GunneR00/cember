import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../common/live_dot.dart';

class StatusBanner extends StatelessWidget {
  const StatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(color: colors.surfaceContainerLow, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Row(
        children: [
          const LiveDot(size: 12),
          const SizedBox(width: AppSpacing.xs),
          Expanded(child: Text('Canlı Fotoğraf Havuzu Açık', style: AppTextStyles.labelMd.copyWith(color: colors.onSurface))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: colors.surfaceContainerLowest, borderRadius: BorderRadius.circular(AppRadius.pill)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.wifi_tethering, size: 16, color: colors.secondary),
                const SizedBox(width: 4),
                Text('Canlı Senk', style: AppTextStyles.labelSm.copyWith(color: colors.secondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
