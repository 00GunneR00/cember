import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class InstructionCard extends StatelessWidget {
  const InstructionCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: colors.surfaceContainerLow, borderRadius: BorderRadius.circular(AppRadius.cardLarge)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: colors.secondaryContainer, borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.photo_camera, size: 20, color: colors.secondary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Uygulama İndirmeden Katılım', style: AppTextStyles.labelMd.copyWith(color: colors.primary)),
                const SizedBox(height: 2),
                Text(
                  'Etkinlikteki misafirler bu kodu telefon kamerasıyla taratarak uygulamayı indirmeden veya tek dokunuşla çembere dahil olup fotoğraflarını havuza ekleyebilir.',
                  style: AppTextStyles.bodySm.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
