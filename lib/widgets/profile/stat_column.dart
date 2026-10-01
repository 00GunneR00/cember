import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class StatColumn extends StatelessWidget {
  const StatColumn({super.key, required this.value, required this.label, this.valueColor});

  final String value;
  final String label;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Expanded(
      child: Column(
        children: [
          Text(value, style: AppTextStyles.headlineMd.copyWith(color: valueColor ?? colors.primary)),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.labelSm.copyWith(color: colors.onSurfaceVariant)),
        ],
      ),
    );
  }
}
