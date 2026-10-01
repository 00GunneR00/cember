import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class ToggleRow extends StatelessWidget {
  const ToggleRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.labelMd.copyWith(color: colors.primary)),
              const SizedBox(height: 2),
              Text(subtitle, style: AppTextStyles.bodySm.copyWith(color: colors.onSurfaceVariant)),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged, activeThumbColor: Colors.white, activeTrackColor: colors.secondary),
      ],
    );
  }
}
