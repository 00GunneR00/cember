import 'package:flutter/material.dart';

import '../../models/challenge_template.dart';
import '../../theme/app_theme.dart';

/// The circle's rules, right under its actions so "kurallar neler?" is always one glance away.
/// Hosts can edit them; for a circle started from a challenge, the challenge is credited.
class CircleRulesCard extends StatelessWidget {
  const CircleRulesCard({super.key, required this.rules, this.challenge, this.onEdit});

  final List<String> rules;
  final CircleChallenge? challenge;

  /// Host only; null hides editing.
  final VoidCallback? onEdit;

  /// Guests see nothing when there are no rules; the host gets a prompt to add some.
  static bool shouldShow(List<String> rules, {required bool canEdit}) => rules.isNotEmpty || canEdit;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (rules.isEmpty) {
      return Material(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: onEdit,
          leading: Icon(Icons.rule, color: colors.secondary),
          title: Text('Kural ekle', style: AppTextStyles.labelLg.copyWith(color: colors.primary)),
          subtitle: Text('Arkadaşların neyi, nasıl çekeceğini bilsin.', style: AppTextStyles.bodySm.copyWith(color: colors.onSurfaceVariant)),
          trailing: Icon(Icons.add, color: colors.secondary),
        ),
      );
    }

    final source = challenge;
    return Material(
      color: colors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppRadius.cardLarge),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        // ExpansionTile draws divider lines by default; the card already has its own edge.
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          childrenPadding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
          leading: source != null ? Text(source.emoji, style: const TextStyle(fontSize: 26)) : Icon(Icons.rule, color: colors.secondary),
          title: Text('Kurallar', style: AppTextStyles.labelLg.copyWith(color: colors.primary)),
          subtitle: Text(
            source != null ? '${source.title} challenge\'ı · ${rules.length} kural' : '${rules.length} kural',
            style: AppTextStyles.bodySm.copyWith(color: colors.onSurfaceVariant),
          ),
          children: [
            for (final (i, rule) in rules.indexed)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: colors.secondaryContainer, shape: BoxShape.circle),
                      child: Text(
                        '${i + 1}',
                        style: AppTextStyles.labelSm.copyWith(color: colors.onSecondaryContainer, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(rule, style: AppTextStyles.bodyMd.copyWith(color: colors.onSurface)),
                    ),
                  ],
                ),
              ),
            if (onEdit != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onEdit,
                  icon: Icon(Icons.edit_outlined, size: 16, color: colors.secondary),
                  label: Text('Düzenle', style: AppTextStyles.labelMd.copyWith(color: colors.secondary)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
