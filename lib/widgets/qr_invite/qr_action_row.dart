import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class QrActionRow extends StatelessWidget {
  const QrActionRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailingIcon,
    required this.onTap,
    this.backgroundColor,
    this.iconBoxColor,
    this.iconColor,
    this.titleColor,
    this.subtitleColor,
    this.trailingColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final IconData trailingIcon;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? iconBoxColor;
  final Color? iconColor;
  final Color? titleColor;
  final Color? subtitleColor;
  final Color? trailingColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: backgroundColor ?? colors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: iconBoxColor ?? colors.surfaceContainer, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: iconColor ?? colors.onSurfaceVariant, size: 22),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.labelLg.copyWith(color: titleColor ?? colors.primary)),
                    Text(subtitle, style: AppTextStyles.labelSm.copyWith(color: subtitleColor ?? colors.onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(trailingIcon, color: trailingColor ?? colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
