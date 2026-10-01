import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class PillSelectorRow extends StatelessWidget {
  const PillSelectorRow({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    this.textStyle,
    this.height = 36,
    this.horizontalPadding = AppSpacing.marginMobile,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final TextStyle? textStyle;
  final double height;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final style = textStyle ?? AppTextStyles.labelMd;
    return SizedBox(
      height: height,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final selected = i == selectedIndex;
          return GestureDetector(
            onTap: () => onSelected(i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? colors.primary : colors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)],
              ),
              child: Text(
                labels[i],
                style: style.copyWith(color: selected ? colors.onPrimary : colors.onSurfaceVariant),
              ),
            ),
          );
        },
      ),
    );
  }
}
