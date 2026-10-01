import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class ActivityBanner extends StatelessWidget {
  const ActivityBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(color: colors.surfaceContainerLow, borderRadius: BorderRadius.circular(AppRadius.card)),
      child: Row(
        children: [
          CircleAvatar(radius: 14, backgroundColor: colors.surfaceContainer, child: Icon(Icons.sync, size: 14, color: colors.onSurfaceVariant)),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text('Bu çemberde yeni anılar paylaşılıyor', style: AppTextStyles.bodySm.copyWith(color: colors.onSurface)),
          ),
          Text('Canlı', style: AppTextStyles.labelSm.copyWith(color: colors.secondary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
