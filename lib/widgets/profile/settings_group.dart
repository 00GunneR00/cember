import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.rows});

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
      ),
      child: Material(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              rows[i],
              if (i != rows.length - 1) Divider(height: 1, indent: 56, color: colors.surfaceContainer),
            ],
          ],
        ),
      ),
    );
  }
}
