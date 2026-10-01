import 'package:flutter/material.dart';

import '../../models/user_profile.dart';
import '../../theme/app_theme.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.profile, required this.onEditTap});

  final UserProfile profile;
  final VoidCallback onEditTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        CircleAvatar(radius: 32, backgroundColor: colors.surfaceContainerHigh, child: Icon(Icons.person, size: 32, color: colors.onSurfaceVariant)),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(profile.name, style: AppTextStyles.headlineSm.copyWith(color: colors.primary)),
        ),
        IconButton(onPressed: onEditTap, icon: Icon(Icons.edit_outlined, color: colors.onSurfaceVariant)),
      ],
    );
  }
}
