import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class UploadProgressCard extends StatelessWidget {
  const UploadProgressCard({super.key, required this.selectedCount, required this.progress});

  final int selectedCount;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.marginMobile),
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sync, size: 18, color: colors.secondary),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    '$selectedCount/$selectedCount fotoğraf sıkıştırılıyor...',
                    style: AppTextStyles.labelSm.copyWith(color: colors.onSurface, fontWeight: FontWeight.w600),
                  ),
                ),
                Text('${(progress * 100).round()}%', style: AppTextStyles.labelSm.copyWith(color: colors.secondary, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: colors.surfaceContainerHigh,
                valueColor: AlwaysStoppedAnimation(colors.secondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
