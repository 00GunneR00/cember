import 'package:flutter/material.dart';

import '../../models/brand_profile.dart';
import '../../theme/app_theme.dart';
import 'app_logo_mark.dart';

/// Small "sponsored by" chip shown on list cards for branded circles — a discoverability
/// hint only, not a full re-theme of the card.
class BrandSponsorBadge extends StatelessWidget {
  const BrandSponsorBadge({super.key, required this.brand});

  final BrandProfile brand;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: brand.primaryColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppLogoMark(size: 14, imageUrl: brand.logoUrl),
          const SizedBox(width: 4),
          Text(
            brand.name,
            style: AppTextStyles.labelSm.copyWith(color: brand.primaryColor, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
