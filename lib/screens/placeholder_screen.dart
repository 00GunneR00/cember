import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(shape: BoxShape.circle, color: colors.surfaceContainer),
                child: Icon(icon, size: 32, color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(title, style: AppTextStyles.headlineSm.copyWith(color: colors.primary)),
              const SizedBox(height: AppSpacing.xs),
              Text('Yakında', style: AppTextStyles.bodySm.copyWith(color: colors.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}
