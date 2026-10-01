import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.countPillLabel,
    this.trailingText,
    this.trailingActionLabel,
    this.onTrailingAction,
  });

  final String title;
  final IconData? icon;
  final String? countPillLabel;
  final String? trailingText;
  final String? trailingActionLabel;
  final VoidCallback? onTrailingAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Text(title, style: AppTextStyles.headlineSm.copyWith(color: colors.primary)),
        if (icon != null) ...[
          const SizedBox(width: 6),
          Icon(icon, size: 18, color: colors.onSurfaceVariant),
        ],
        if (countPillLabel != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: colors.surfaceContainer, borderRadius: BorderRadius.circular(AppRadius.pill)),
            child: Text(countPillLabel!, style: AppTextStyles.labelSm.copyWith(color: colors.onSurfaceVariant)),
          ),
        ],
        const Spacer(),
        if (trailingText != null) Text(trailingText!, style: AppTextStyles.bodySm.copyWith(color: colors.onSurfaceVariant)),
        if (trailingActionLabel != null)
          GestureDetector(
            onTap: onTrailingAction,
            child: Row(
              children: [
                Text(trailingActionLabel!, style: AppTextStyles.labelMd.copyWith(color: colors.secondary)),
                Icon(Icons.chevron_right, size: 16, color: colors.secondary),
              ],
            ),
          ),
      ],
    );
  }
}
