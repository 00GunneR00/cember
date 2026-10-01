import 'package:flutter/material.dart';

import '../../models/challenge_template.dart';
import '../../models/photo_upload_mode.dart';
import '../../theme/app_theme.dart';

/// A challenge on Keşfet: its own gradient and emoji on top, the idea and social proof below.
class ChallengeCard extends StatelessWidget {
  const ChallengeCard({super.key, required this.challenge, required this.onTap});

  final ChallengeTemplate challenge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppRadius.cardLarge),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 104,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [challenge.gradientStart, challenge.gradientEnd]),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(challenge.emoji, style: const TextStyle(fontSize: 46)),
                  const Spacer(),
                  Wrap(
                    direction: Axis.vertical,
                    spacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.end,
                    children: [
                      if (challenge.isFeatured) const _Pill(icon: Icons.local_fire_department, label: 'Öne çıkan'),
                      if (challenge.usesBanyo) const _Pill(icon: Icons.photo_filter, label: 'Banyo'),
                      if (challenge.uploadMode == PhotoUploadMode.quickCaptureOnly) const _Pill(icon: Icons.bolt, label: 'Sadece Şipşak'),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(challenge.title, style: AppTextStyles.headlineSm.copyWith(color: colors.primary)),
                  const SizedBox(height: 2),
                  Text(challenge.tagline, style: AppTextStyles.bodySm.copyWith(color: colors.onSurfaceVariant)),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      // One flexible group on the left, so the count on the right sits flush with the edge.
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                challenge.creatorLabel,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.labelSm.copyWith(color: colors.secondary, fontWeight: FontWeight.w700),
                              ),
                            ),
                            if (challenge.creatorVerified) ...[const SizedBox(width: 3), Icon(Icons.verified, size: 13, color: colors.secondary)],
                            Text(' · ${challenge.prompts.length} kural', style: AppTextStyles.labelSm.copyWith(color: colors.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      Text(
                        challenge.startedCount > 0 ? '${challenge.startedCount} grup başlattı' : 'Yeni',
                        style: AppTextStyles.labelSm.copyWith(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.labelSm.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
