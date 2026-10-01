import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/profile_controller.dart';
import '../models/settings_item.dart';
import '../theme/app_theme.dart';
import '../widgets/profile/settings_group.dart';
import '../widgets/profile/settings_list_tile.dart';

/// Lets the host choose which circle activity raises a notification —
/// pushed from "Bildirim Tercihleri" on Profil.
class NotificationPreferencesScreen extends StatelessWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final controller = Get.find<ProfileController>(tag: 'profile');
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        title: Text('Bildirim Tercihleri', style: AppTextStyles.headlineSm.copyWith(color: colors.primary)),
      ),
      body: Obx(() {
        final profile = controller.profile.value;
        if (profile == null) return const SizedBox.shrink();
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.marginMobile),
          children: [
            SettingsGroup(
              rows: [
                SettingsListTile(
                  item: const SettingsItem(
                    icon: Icons.add_photo_alternate_outlined,
                    title: 'Yeni Fotoğraf',
                    subtitle: 'Bir çembere fotoğraf eklendiğinde',
                    hasToggle: true,
                  ),
                  trailing: Switch(
                    value: profile.notifyOnPhotoAdded,
                    onChanged: controller.setNotifyOnPhotoAdded,
                    activeThumbColor: Colors.white,
                    activeTrackColor: colors.secondary,
                  ),
                ),
                SettingsListTile(
                  item: const SettingsItem(
                    icon: Icons.mode_comment_outlined,
                    title: 'Yorumlar',
                    subtitle: 'Bir fotoğrafına yorum yapıldığında',
                    hasToggle: true,
                  ),
                  trailing: Switch(
                    value: profile.notifyOnComment,
                    onChanged: controller.setNotifyOnComment,
                    activeThumbColor: Colors.white,
                    activeTrackColor: colors.secondary,
                  ),
                ),
                SettingsListTile(
                  item: const SettingsItem(
                    icon: Icons.favorite_border,
                    title: 'Beğeniler',
                    subtitle: 'Bir fotoğrafına tepki verildiğinde',
                    hasToggle: true,
                  ),
                  trailing: Switch(
                    value: profile.notifyOnReaction,
                    onChanged: controller.setNotifyOnReaction,
                    activeThumbColor: Colors.white,
                    activeTrackColor: colors.secondary,
                  ),
                ),
                SettingsListTile(
                  item: const SettingsItem(
                    icon: Icons.person_add_alt_outlined,
                    title: 'Misafir Katılımları',
                    subtitle: 'Biri çemberine QR ile katıldığında',
                    hasToggle: true,
                  ),
                  trailing: Switch(
                    value: profile.notifyOnGuestJoined,
                    onChanged: controller.setNotifyOnGuestJoined,
                    activeThumbColor: Colors.white,
                    activeTrackColor: colors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Text(
                'Silme oylaması gerektiren bildirimler her zaman gönderilir, çünkü senden bir işlem bekler.',
                style: AppTextStyles.bodySm.copyWith(color: colors.onSurfaceVariant),
              ),
            ),
          ],
        );
      }),
    );
  }
}
