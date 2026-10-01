import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../controllers/albums_controller.dart';
import '../controllers/profile_controller.dart';
import '../controllers/theme_controller.dart';
import '../core/api_client.dart';
import '../core/push_notifications.dart';
import '../core/token_store.dart';
import '../data/account_deletion.dart';
import '../data/blocked_users_source.dart';
import '../data/http/http_auth_repository.dart';
import '../data/http/http_profile_repository.dart';
import '../data/profile_repository.dart';
import '../models/settings_item.dart';
import '../theme/app_theme.dart';
import '../widgets/common/section_header.dart';
import '../widgets/profile/collection_card.dart';
import '../widgets/profile/profile_header.dart';
import '../widgets/profile/settings_group.dart';
import '../widgets/profile/settings_list_tile.dart';
import '../widgets/profile/storage_card.dart';
import 'blocked_users_screen.dart';
import 'connected_accounts_screen.dart';
import 'info_screen.dart';
import 'notification_preferences_screen.dart';
import 'onboarding_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    this.repository = const MockProfileRepository(),
    this.tokenStore = const TokenStore(),
    this.apiClient,
  });

  final ProfileRepository repository;
  final TokenStore tokenStore;
  final ApiClient? apiClient;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileRepository _effectiveRepository =
      widget.apiClient != null ? HttpProfileRepository(widget.apiClient!) : widget.repository;
  late final ProfileController controller = Get.put(ProfileController(_effectiveRepository), tag: 'profile');
  final ThemeController _themeController = Get.find<ThemeController>();
  final Future<PackageInfo> _packageInfo = PackageInfo.fromPlatform();

  Future<void> _logout() async {
    final apiClient = widget.apiClient;
    // Before the key is gone — unregistering needs it.
    if (apiClient != null) await PushNotifications.instance.unregisterHost(apiClient);
    await widget.tokenStore.clear();
    _goToOnboarding();
  }

  void _goToOnboarding() {
    if (!mounted) return;
    // OnboardingScreen defaults to a mock auth repository (for design previews) — it must get the real one,
    // or signing back in stores a fake key and the app stops working.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => OnboardingScreen(authRepository: HttpAuthRepository(ApiClient()), tokenStore: widget.tokenStore),
      ),
      (route) => false,
    );
  }

  Future<void> _deleteAccount() async {
    final colors = context.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hesabın silinsin mi?'),
        content: const Text(
          'Bu işlem geri alınamaz. Silinecekler:\n\n'
          '• Oluşturduğun tüm çemberler ve içlerindeki bütün fotoğraflar (başkalarının yüklediği fotoğraflar dahil)\n'
          '• Başka çemberlere yüklediğin fotoğraflar, yorumların ve beğenilerin\n'
          '• Bağlı Google hesabın ve bu cihazdaki oturumun',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Vazgeç')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Kalıcı Olarak Sil', style: TextStyle(color: colors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final apiClient = widget.apiClient;
    if (apiClient == null) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(canPop: false, child: Center(child: CircularProgressIndicator())),
    );
    try {
      await AccountDeletion(apiClient: apiClient, profileRepository: _effectiveRepository, tokenStore: widget.tokenStore).run();
      _goToOnboarding();
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context).pop(); // the progress dialog
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hesap silinemedi. İnternet bağlantını kontrol edip tekrar dene.')));
    }
  }

  String _themeSubtitle(BuildContext context, ThemeMode mode) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return switch (mode) {
      ThemeMode.light => 'Aydınlık',
      ThemeMode.dark => 'Karanlık',
      ThemeMode.system => isDark ? 'Sistem varsayılanı (Karanlık)' : 'Sistem varsayılanı (Aydınlık)',
    };
  }

  Future<void> _openThemePicker() async {
    final colors = context.colors;
    final chosen = await showDialog<ThemeMode>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Görünüm'),
        content: RadioGroup<ThemeMode>(
          groupValue: _themeController.mode.value,
          onChanged: (value) => Navigator.of(context).pop(value),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final option in const [
                (ThemeMode.system, 'Sistem Varsayılanı'),
                (ThemeMode.light, 'Aydınlık'),
                (ThemeMode.dark, 'Karanlık'),
              ])
                RadioListTile<ThemeMode>(
                  value: option.$1,
                  title: Text(option.$2, style: AppTextStyles.bodyMd.copyWith(color: colors.onSurface)),
                  activeColor: colors.secondary,
                ),
            ],
          ),
        ),
      ),
    );
    if (chosen != null) {
      await _themeController.setMode(chosen);
    }
  }

  Future<void> _editName(String currentName) async {
    final nameController = TextEditingController(text: currentName);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adını Düzenle'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          maxLength: 40,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Adın'),
          onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('İptal')),
          TextButton(onPressed: () => Navigator.of(context).pop(nameController.text.trim()), child: const Text('Kaydet')),
        ],
      ),
    );
    nameController.dispose();
    if (newName == null || newName.isEmpty || newName == currentName) return;
    final saved = await controller.setDisplayName(newName);
    if (!mounted) return;
    if (saved) {
      // Albümler greets the user by name; refresh it so the new name shows there too.
      if (Get.isRegistered<AlbumsController>(tag: 'albums')) Get.find<AlbumsController>(tag: 'albums').load(silent: true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ad güncellenemedi, tekrar dene.')));
    }
  }

  void _showUpgradeSheet() {
    final colors = context.colors;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.surface,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.workspace_premium, size: 48, color: colors.secondary),
              const SizedBox(height: AppSpacing.sm),
              Text('Çember Plus çok yakında', style: AppTextStyles.headlineSm.copyWith(color: colors.primary)),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Daha fazla depolama alanı ve ek özellikler üzerinde çalışıyoruz. '
                'Şimdilik tüm hesaplarda 25 GB ücretsiz alan var.',
                style: AppTextStyles.bodyMd.copyWith(color: colors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Tamam')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openInfo(String title, List<InfoSection> sections) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => InfoScreen(title: title, sections: sections)));
  }

  VoidCallback? _accountSettingTap(SettingsItem item) => switch (item.title) {
        'Bildirim Tercihleri' => () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationPreferencesScreen()),
            ),
        'Bağlı Hesaplar' => () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ConnectedAccountsScreen(apiClient: widget.apiClient)),
            ),
        'Gizlilik & İzinler' => () => _openInfo(item.title, privacyInfoSections),
        'Engellenen Kişiler' => () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BlockedUsersScreen(
                  source: BlockedUsersSource(hostRepository: _effectiveRepository, apiClient: widget.apiClient, tokenStore: widget.tokenStore),
                ),
              ),
            ),
        _ => null,
      };

  VoidCallback? _appSettingTap(SettingsItem item) {
    return switch (item.title) {
      'Çıkış Yap' => _logout,
      'Hesabı Sil' => _deleteAccount,
      'Görünüm' => _openThemePicker,
      'Yardım & Geri Bildirim' => () => _openInfo(item.title, helpInfoSections),
      'Topluluk & Güvenlik' => () => _openInfo(item.title, communityInfoSections),
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Obx(() {
          if (controller.loading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          final profile = controller.profile.value;
          if (controller.error.value != null || profile == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(controller.error.value ?? 'Profil bulunamadı.', style: AppTextStyles.bodyMd.copyWith(color: colors.onSurface)),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(onPressed: controller.load, child: const Text('Tekrar Dene')),
                ],
              ),
            );
          }
          final favorites = controller.favorites.value;
          final accountSettings = _effectiveRepository.accountSettings();
          final currentThemeMode = _themeController.mode.value;
          final appSettings = _effectiveRepository.appSettings().map((item) {
            if (item.title != 'Görünüm') return item;
            return item.copyWith(subtitle: _themeSubtitle(context, currentThemeMode));
          }).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.marginMobile, AppSpacing.md, AppSpacing.marginMobile, 100),
            children: [
              ProfileHeader(profile: profile, onEditTap: () => _editName(profile.name)),
              const SizedBox(height: AppSpacing.md),
              StorageCard(profile: profile, onUpgradeTap: _showUpgradeSheet),
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: 'Koleksiyonlarım'),
              const SizedBox(height: AppSpacing.sm),
              if (favorites != null) CollectionCard(collection: favorites),
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: 'Hesap & Çemberler'),
              const SizedBox(height: AppSpacing.sm),
              SettingsGroup(
                rows: [
                  for (final item in accountSettings)
                    SettingsListTile(
                      item: item,
                      trailing: item.hasToggle
                          ? Switch(
                              value: profile.onlyUploadOnWifi,
                              onChanged: controller.setOnlyUploadOnWifi,
                              activeThumbColor: Colors.white,
                              activeTrackColor: colors.secondary,
                            )
                          : null,
                      onTap: _accountSettingTap(item),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: 'Uygulama & Güvenlik'),
              const SizedBox(height: AppSpacing.sm),
              SettingsGroup(
                rows: [
                  for (final item in appSettings)
                    SettingsListTile(
                      item: item,
                      onTap: _appSettingTap(item),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: FutureBuilder<PackageInfo>(
                  future: _packageInfo,
                  builder: (context, snapshot) {
                    final info = snapshot.data;
                    return Text(
                      info == null ? 'Çember' : 'Çember v${info.version} (Build ${info.buildNumber})',
                      style: AppTextStyles.labelSm.copyWith(color: colors.onSurfaceVariant),
                    );
                  },
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
