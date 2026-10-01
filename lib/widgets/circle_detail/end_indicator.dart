import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class EndIndicator extends StatelessWidget {
  const EndIndicator({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          Container(width: 32, height: 4, decoration: BoxDecoration(color: colors.surfaceContainerHigh, borderRadius: BorderRadius.circular(AppRadius.pill))),
          const SizedBox(height: 8),
          Text(label, style: AppTextStyles.labelSm.copyWith(color: colors.onSurfaceVariant)),
        ],
      ),
    );
  }
}
