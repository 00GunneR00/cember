import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// The app's main call to action, filled with the brand gradient. ElevatedButton can't paint a
/// gradient, so the ink sits on a decorated transparent Material and keeps its ripple.
class GradientButton extends StatelessWidget {
  const GradientButton({super.key, required this.onPressed, required this.child, this.borderRadius = AppRadius.card});

  /// Null disables the button (dimmed, no ripple).
  final VoidCallback? onPressed;
  final Widget child;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = BorderRadius.circular(borderRadius);
    return Opacity(
      opacity: onPressed == null ? 0.5 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: colors.brandGradient,
          borderRadius: radius,
          boxShadow: [BoxShadow(color: colors.secondary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onPressed,
            borderRadius: radius,
            child: Center(
              child: DefaultTextStyle.merge(
                style: AppTextStyles.labelLg.copyWith(color: colors.onSecondary),
                child: IconTheme.merge(
                  data: IconThemeData(color: colors.onSecondary, size: 20),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
