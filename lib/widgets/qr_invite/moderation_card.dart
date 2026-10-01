import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'toggle_row.dart';

class ModerationCard extends StatelessWidget {
  const ModerationCard({
    super.key,
    required this.autoPublish,
    required this.onAutoPublishChanged,
    required this.guestDownloads,
    required this.onGuestDownloadsChanged,
  });

  final bool autoPublish;
  final ValueChanged<bool> onAutoPublishChanged;
  final bool guestDownloads;
  final ValueChanged<bool> onGuestDownloadsChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
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
              Icon(Icons.shield, size: 20, color: colors.primary),
              const SizedBox(width: AppSpacing.xs),
              Expanded(child: Text('Misafir İzinleri & Moderasyon', style: AppTextStyles.labelLg.copyWith(color: colors.primary))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: colors.surfaceContainerLow, borderRadius: BorderRadius.circular(AppRadius.pill)),
                child: Text('Güvenli Mod', style: AppTextStyles.labelSm.copyWith(color: colors.onTertiaryContainer, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ToggleRow(
            title: 'Otomatik Anında Yayınlama',
            subtitle: 'Yüklenen fotoğraflar moderasyon beklemeden havuza düşer',
            value: autoPublish,
            onChanged: onAutoPublishChanged,
          ),
          Divider(height: 20, color: colors.surfaceContainer),
          ToggleRow(
            title: 'Misafir İndirmelerine İzin Ver',
            subtitle: 'Katılımcılar orijinal kalitede toplu indirme yapabilir',
            value: guestDownloads,
            onChanged: onGuestDownloadsChanged,
          ),
        ],
      ),
    );
  }
}
