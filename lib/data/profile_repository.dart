import 'package:flutter/material.dart';

import '../models/blocked_user.dart';
import '../models/profile_collection.dart';
import '../models/settings_item.dart';
import '../models/user_profile.dart';

abstract class ProfileRepository {
  const ProfileRepository();

  Future<UserProfile> fetchProfile();
  Future<ProfileCollection> fetchFavorites();
  Future<void> updateOnlyUploadOnWifi(bool value);
  Future<void> updateNotifyOnPhotoAdded(bool value);
  Future<void> updateNotifyOnComment(bool value);
  Future<void> updateNotifyOnReaction(bool value);
  Future<void> updateNotifyOnGuestJoined(bool value);
  Future<void> updateDisplayName(String name);
  Future<List<BlockedUser>> fetchBlockedUsers();
  Future<void> unblock(String blockId);

  /// Permanently deletes the host account and everything in it.
  Future<void> deleteAccount();

  List<SettingsItem> accountSettings() => const [
        SettingsItem(icon: Icons.notifications_outlined, title: 'Bildirim Tercihleri', subtitle: 'Yeni fotoğraf ve yorum uyarıları'),
        SettingsItem(icon: Icons.lock_outline, title: 'Gizlilik & İzinler', subtitle: 'Fotoğraflarını kimler görebilir'),
        SettingsItem(icon: Icons.wifi, title: 'Yalnızca Wi-Fi ile Yükle', subtitle: 'Hücresel veri tasarrufu sağlar', hasToggle: true),
        SettingsItem(icon: Icons.link, title: 'Bağlı Hesaplar', subtitle: 'Google hesabı bağlantısı'),
        SettingsItem(icon: Icons.block, title: 'Engellenen Kişiler', subtitle: 'Fotoğraflarını gizlediğin kişiler'),
      ];

  List<SettingsItem> appSettings() => const [
        SettingsItem(icon: Icons.dark_mode_outlined, title: 'Görünüm', subtitle: 'Sistem varsayılanı (Aydınlık)'),
        SettingsItem(icon: Icons.help_outline, title: 'Yardım & Geri Bildirim', subtitle: 'Sıkça sorulan sorular, destek'),
        SettingsItem(icon: Icons.shield_outlined, title: 'Topluluk & Güvenlik', subtitle: 'Kurallar ve etik ilkeler'),
        SettingsItem(icon: Icons.logout, title: 'Çıkış Yap', subtitle: 'Oturumunuzu sonlandırın', destructive: true),
        SettingsItem(icon: Icons.delete_forever_outlined, title: 'Hesabı Sil', subtitle: 'Hesabını ve tüm verilerini kalıcı olarak sil', destructive: true),
      ];
}

class MockProfileRepository extends ProfileRepository {
  const MockProfileRepository();

  @override
  Future<UserProfile> fetchProfile() async => const UserProfile(
        name: 'Zeynep Yılmaz',
        circleCount: 8,
        photoCount: 428,
        eventCount: 14,
        storageUsedBytes: 12400000000,
        storageTotalBytes: 25000000000,
        onlyUploadOnWifi: true,
        notifyOnPhotoAdded: true,
        notifyOnComment: true,
        notifyOnReaction: true,
        notifyOnGuestJoined: true,
      );

  @override
  Future<ProfileCollection> fetchFavorites() async => const ProfileCollection(
        icon: Icons.favorite,
        title: 'Favorilerim',
        subtitle: 'Beğenilen fotoğraflar',
        count: 74,
        previewUrls: [],
      );

  @override
  Future<void> updateOnlyUploadOnWifi(bool value) async {}

  @override
  Future<void> updateNotifyOnPhotoAdded(bool value) async {}

  @override
  Future<void> updateNotifyOnComment(bool value) async {}

  @override
  Future<void> updateNotifyOnReaction(bool value) async {}

  @override
  Future<void> updateNotifyOnGuestJoined(bool value) async {}

  @override
  Future<void> updateDisplayName(String name) async {}

  @override
  Future<List<BlockedUser>> fetchBlockedUsers() async => const [];

  @override
  Future<void> unblock(String blockId) async {}

  @override
  Future<void> deleteAccount() async {}
}
