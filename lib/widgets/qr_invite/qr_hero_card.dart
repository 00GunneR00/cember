import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/qr_invite_info.dart';
import '../../theme/app_theme.dart';
import '../common/app_logo_mark.dart';
import '../common/avatar_stack.dart';

class QrHeroCard extends StatelessWidget {
  const QrHeroCard({super.key, required this.info, required this.copied, required this.onCopy});

  final QrInviteInfo info;
  final bool copied;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(color: colors.surfaceContainer, borderRadius: BorderRadius.circular(AppRadius.pill)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.celebration, size: 15, color: colors.onSurfaceVariant),
                const SizedBox(width: 6),
                Text('Özel Etkinlik · Canlı Havuz', style: AppTextStyles.labelSm.copyWith(color: colors.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(info.eventName, style: AppTextStyles.headlineLgMobile.copyWith(color: colors.primary), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text('Anılarını anında çember havuzuna bırak', style: AppTextStyles.bodySm.copyWith(color: colors.onSurfaceVariant), textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xl),
          Container(
            width: 200,
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colors.surfaceContainer, borderRadius: BorderRadius.circular(20)),
            child: Stack(
              alignment: Alignment.center,
              children: [
                QrImageView(
                  data: info.inviteUrl,
                  size: 168,
                  backgroundColor: Colors.white,
                  eyeStyle: QrEyeStyle(color: colors.primary),
                  dataModuleStyle: QrDataModuleStyle(color: colors.primary),
                ),
                AppLogoMark(size: 40, imageUrl: info.brand?.logoUrl),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            decoration: BoxDecoration(color: colors.surfaceContainerLow, borderRadius: BorderRadius.circular(AppRadius.card)),
            child: Row(
              children: [
                Icon(Icons.link, size: 20, color: colors.secondary),
                const SizedBox(width: AppSpacing.xs),
                Expanded(child: Text(info.inviteUrl, style: AppTextStyles.labelLg.copyWith(color: colors.primary), overflow: TextOverflow.ellipsis)),
                TextButton.icon(
                  onPressed: onCopy,
                  icon: Icon(copied ? Icons.check : Icons.content_copy, size: 16),
                  label: Text(copied ? 'Kopyalandı' : 'Kopyala', style: AppTextStyles.labelMd.copyWith(color: colors.primary)),
                  style: TextButton.styleFrom(foregroundColor: colors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AvatarStack(visibleCount: 3, avatarRadius: 12, overlapOffset: 16),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text.rich(
                  TextSpan(
                    style: AppTextStyles.labelSm.copyWith(color: colors.onSurfaceVariant, fontWeight: FontWeight.w500),
                    children: [
                      const TextSpan(text: 'Şu an bağlı '),
                      TextSpan(text: '${info.connectedGuestCount} misafir', style: TextStyle(color: colors.primary, fontWeight: FontWeight.w700)),
                      const TextSpan(text: ' · '),
                      TextSpan(text: '${info.sharedMemoryCount} paylaşılan anı', style: TextStyle(color: colors.secondary, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
