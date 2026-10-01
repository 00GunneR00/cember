import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/storage_image.dart';
import '../../models/circle_detail.dart';
import '../../theme/app_theme.dart';
import '../common/app_logo_mark.dart';
import '../common/live_dot.dart';
import '../common/locked_cover_overlay.dart';

class CircleHero extends StatelessWidget {
  const CircleHero({super.key, required this.detail, this.onEditCover, this.coverUploading = false});

  final CircleDetail detail;

  /// Non-null only when the viewer may change the cover (i.e. they own the circle).
  final VoidCallback? onEditCover;
  final bool coverUploading;

  String get _dateLabel {
    final date = detail.eventDate;
    if (date == null) return '';
    const months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AspectRatio(
      aspectRatio: 4 / 3.4,
      child: Stack(
        fit: StackFit.expand,
        children: [
          LockedCoverOverlay(
            locked: !detail.isOpenJoin,
            child: detail.coverUrl != null
                ? CachedNetworkImage(imageUrl: detail.coverUrl!, cacheKey: storageCacheKey(detail.coverUrl!), fit: BoxFit.cover)
                : DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: detail.brand != null
                            ? [detail.brand!.primaryColor, detail.brand!.secondaryColor ?? detail.brand!.primaryColor]
                            : colors.coverGradientColors,
                      ),
                    ),
                  ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [colors.scrim, colors.scrim.withValues(alpha: 0.5), Colors.transparent],
              ),
            ),
          ),
          Positioned(
            top: 56,
            left: AppSpacing.marginMobile,
            right: AppSpacing.marginMobile,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: colors.surfaceContainerLowest.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(AppRadius.pill)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LiveDot(size: 10, color: colors.error),
                      const SizedBox(width: 6),
                      Text('Canlı Çember • ${detail.participantCount} Katılımcı', style: AppTextStyles.labelSm.copyWith(color: colors.onSurface, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: colors.scrim.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(AppRadius.pill)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(detail.isOpenJoin ? Icons.lock_open : Icons.lock, size: 16, color: colors.tertiaryFixedDim),
                          const SizedBox(width: 4),
                          Text(detail.isOpenJoin ? 'Açık Katılım' : 'Kapalı Katılım', style: AppTextStyles.labelSm.copyWith(color: Colors.white)),
                        ],
                      ),
                    ),
                    if (onEditCover != null) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: coverUploading ? null : onEditCover,
                        child: Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: colors.scrim.withValues(alpha: 0.7), shape: BoxShape.circle),
                          child: coverUploading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            left: AppSpacing.marginMobile,
            right: AppSpacing.marginMobile,
            bottom: AppSpacing.marginMobile,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Colors.white70),
                    const SizedBox(width: 6),
                    Text(_dateLabel, style: AppTextStyles.labelMd.copyWith(color: Colors.white70)),
                  ],
                ),
                const SizedBox(height: 4),
                if (detail.brand != null) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppLogoMark(size: 22, imageUrl: detail.brand!.logoUrl),
                      const SizedBox(width: 6),
                      Text(detail.brand!.name, style: AppTextStyles.labelSm.copyWith(color: Colors.white70, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
                Text(detail.title, style: AppTextStyles.headlineLgMobile.copyWith(color: Colors.white)),
                if (detail.description != null && detail.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    detail.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySm.copyWith(color: Colors.white, fontStyle: FontStyle.italic, fontWeight: FontWeight.w600),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    const CircleAvatar(radius: 12, backgroundColor: Colors.white24, child: Icon(Icons.person, size: 12, color: Colors.white)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          style: AppTextStyles.labelSm.copyWith(color: Colors.white70),
                          children: [
                            const TextSpan(text: 'Ev Sahibi: '),
                            TextSpan(text: detail.hostDisplayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: colors.tertiary.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(AppRadius.pill)),
                      child: Text('${detail.memoryCount} Anı', style: AppTextStyles.labelSm.copyWith(color: colors.tertiaryFixedDim, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
