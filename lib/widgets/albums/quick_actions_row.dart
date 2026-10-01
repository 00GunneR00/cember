import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../common/gradient_button.dart';

class QuickActionsRow extends StatelessWidget {
  const QuickActionsRow({super.key, required this.onJoinWithQr, required this.onCreateCircle});

  final VoidCallback onJoinWithQr;
  final VoidCallback onCreateCircle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Expanded(
          flex: 7,
          child: SizedBox(
            height: 48,
            child: GradientButton(
              onPressed: onJoinWithQr,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [Icon(Icons.photo_camera), SizedBox(width: 8), Text('QR ile Katıl')],
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.gutterMobile),
        Expanded(
          flex: 5,
          child: SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: onCreateCircle,
              style: OutlinedButton.styleFrom(
                backgroundColor: colors.surfaceContainerLowest,
                foregroundColor: colors.primary,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
              ),
              icon: Icon(Icons.add_circle, size: 20, color: colors.secondary),
              label: Text('Yeni Çember', style: AppTextStyles.labelLg.copyWith(color: colors.primary)),
            ),
          ),
        ),
      ],
    );
  }
}
