import 'package:flutter/material.dart';

import '../../models/brand_profile.dart';
import '../../theme/app_theme.dart';

/// Shown only on branded circles — recorded per-upload, never blocks the upload itself.
class CommercialConsentCheckbox extends StatelessWidget {
  const CommercialConsentCheckbox({
    super.key,
    required this.brand,
    required this.value,
    required this.onChanged,
  });

  final BrandProfile brand;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs2),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(value: value, onChanged: (v) => onChanged(v ?? false), activeColor: brand.primaryColor),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                '${brand.name} bu fotoğrafları pazarlama/sosyal medya içeriği olarak kullanabilsin.',
                style: AppTextStyles.bodySm.copyWith(color: colors.onSurfaceVariant),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
