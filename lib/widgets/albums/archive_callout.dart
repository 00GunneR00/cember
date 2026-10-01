import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class ArchiveCallout extends StatelessWidget {
  const ArchiveCallout({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppRadius.cardLarge),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(shape: BoxShape.circle, color: colors.primaryContainer),
                child: Icon(Icons.folder_open, color: colors.logoAccent),
              ),
              const SizedBox(height: 8),
              Text(
                'Daha Eski Anılar',
                style: AppTextStyles.labelLg.copyWith(color: colors.primary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Tüm arşive göz at ve anılarını indir',
                style: AppTextStyles.bodySm.copyWith(color: colors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
