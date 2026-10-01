import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class AvatarStack extends StatelessWidget {
  const AvatarStack({
    super.key,
    required this.visibleCount,
    required this.avatarRadius,
    required this.overlapOffset,
    this.extraCount,
    this.extraBadgeFontSize,
  });

  final int visibleCount;
  final double avatarRadius;
  final double overlapOffset;
  final int? extraCount;
  final double? extraBadgeFontSize;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final showExtraBadge = extraCount != null;
    final itemCount = visibleCount + (showExtraBadge ? 1 : 0);
    final width = overlapOffset * (itemCount - 1) + avatarRadius * 2;
    final height = avatarRadius * 2;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          for (var i = 0; i < visibleCount; i++)
            Positioned(
              left: i * overlapOffset,
              child: CircleAvatar(
                radius: avatarRadius,
                backgroundColor: colors.surfaceContainer,
                child: Icon(Icons.person, size: avatarRadius, color: colors.onSurfaceVariant),
              ),
            ),
          if (showExtraBadge)
            Positioned(
              left: visibleCount * overlapOffset,
              child: CircleAvatar(
                radius: avatarRadius,
                backgroundColor: colors.secondaryContainer,
                child: Text(
                  '+$extraCount',
                  style: AppTextStyles.labelSm.copyWith(
                    color: colors.onSecondaryContainer,
                    fontWeight: FontWeight.w700,
                    fontSize: extraBadgeFontSize,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
