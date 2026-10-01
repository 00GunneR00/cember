import 'package:flutter/material.dart';

import '../../models/settings_item.dart';
import '../../theme/app_theme.dart';

class SettingsListTile extends StatelessWidget {
  const SettingsListTile({super.key, required this.item, this.trailing, this.onTap});

  final SettingsItem item;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = item.destructive ? colors.error : colors.primary;
    return ListTile(
      leading: Icon(item.icon, color: item.destructive ? colors.error : colors.onSurfaceVariant),
      title: Text(item.title, style: AppTextStyles.labelMd.copyWith(color: color)),
      subtitle: Text(item.subtitle, style: AppTextStyles.bodySm.copyWith(color: colors.onSurfaceVariant)),
      trailing: trailing ?? (item.destructive ? null : Icon(Icons.chevron_right, color: colors.onSurfaceVariant)),
      onTap: onTap ?? () {},
    );
  }
}
