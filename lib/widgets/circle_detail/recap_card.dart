import 'package:flutter/material.dart';

import '../../models/circle_detail.dart';
import '../../models/recap_status.dart';
import '../../theme/app_theme.dart';

/// The circle's recap video: a "create" prompt for the host, progress while it renders,
/// and a play button once it's ready.
class RecapCard extends StatelessWidget {
  const RecapCard({super.key, required this.detail, required this.onCreate, required this.onPlay});

  final CircleDetail detail;

  /// Starts (or retries) rendering; null for non-hosts, who can only watch.
  final VoidCallback? onCreate;
  final VoidCallback onPlay;

  /// Only worth showing when there's something to watch, something happening, or the host can start one.
  static bool shouldShow(CircleDetail detail) => detail.recapStatus != RecapStatus.none || (detail.viewerIsHost && detail.memoryCount >= recapMinPhotoCount);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final status = detail.recapStatus;

    final (IconData icon, String title, String subtitle) = switch (status) {
      RecapStatus.ready => (Icons.play_arrow_rounded, 'Özet videon hazır', 'En güzel kareler tek videoda — izle ve paylaş'),
      RecapStatus.pending || RecapStatus.processing => (Icons.movie_filter, 'Özet video hazırlanıyor…', 'Birkaç saniye sürer, bu sayfada kalabilirsin'),
      RecapStatus.failed => (Icons.error_outline, 'Özet video hazırlanamadı', detail.recapError ?? 'Tekrar dene'),
      RecapStatus.none => (Icons.movie_creation_outlined, 'Özet video oluştur', 'En çok beğenilen karelerden paylaşılabilir bir video'),
    };

    final VoidCallback? onTap = switch (status) {
      RecapStatus.ready => onPlay,
      RecapStatus.failed || RecapStatus.none => onCreate,
      _ => null,
    };

    return Material(
      color: colors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppRadius.cardLarge),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: colors.brandGradient,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: status.isInProgress
                    ? const Padding(
                        padding: EdgeInsets.all(15),
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.labelLg.copyWith(color: colors.primary)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTextStyles.bodySm.copyWith(color: colors.onSurfaceVariant)),
                  ],
                ),
              ),
              if (status == RecapStatus.ready && detail.viewerIsHost && onCreate != null)
                IconButton(
                  onPressed: onCreate,
                  tooltip: 'Yeni fotoğraflarla yeniden oluştur',
                  icon: Icon(Icons.refresh, color: colors.onSurfaceVariant),
                )
              else if (onTap != null)
                Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
