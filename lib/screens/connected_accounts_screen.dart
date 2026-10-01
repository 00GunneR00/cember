import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/profile_controller.dart';
import '../core/api_client.dart';
import '../core/google_auth.dart';
import '../data/auth_repository.dart';
import '../data/http/http_auth_repository.dart';
import '../theme/app_theme.dart';

/// Lets the host link their Google account, so they can sign back in and recover their
/// circles from a new device instead of losing access if this device's apiKey is gone.
class ConnectedAccountsScreen extends StatefulWidget {
  const ConnectedAccountsScreen({super.key, this.apiClient});

  final ApiClient? apiClient;

  @override
  State<ConnectedAccountsScreen> createState() => _ConnectedAccountsScreenState();
}

class _ConnectedAccountsScreenState extends State<ConnectedAccountsScreen> {
  late final AuthRepository _authRepository =
      widget.apiClient != null ? HttpAuthRepository(widget.apiClient!) : const MockAuthRepository();
  final GoogleAuth _googleAuth = const GoogleAuth();

  bool _linking = false;
  String? _error;

  Future<void> _linkGoogle() async {
    setState(() {
      _linking = true;
      _error = null;
    });
    try {
      final idToken = await _googleAuth.signIn();
      if (idToken == null) {
        setState(() => _linking = false);
        return;
      }
      await _authRepository.linkGoogle(idToken);
      if (Get.isRegistered<ProfileController>(tag: 'profile')) {
        await Get.find<ProfileController>(tag: 'profile').load();
      }
    } catch (_) {
      setState(() => _error = 'Google hesabı bağlanamadı, tekrar dene.');
    } finally {
      if (mounted) setState(() => _linking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final linkedEmail = Get.isRegistered<ProfileController>(tag: 'profile')
        ? Get.find<ProfileController>(tag: 'profile').profile.value?.linkedGoogleEmail
        : null;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        title: Text('Bağlı Hesaplar', style: AppTextStyles.headlineSm.copyWith(color: colors.primary)),
      ),
      body: Obx(() {
        final profile = Get.isRegistered<ProfileController>(tag: 'profile')
            ? Get.find<ProfileController>(tag: 'profile').profile.value
            : null;
        final email = profile?.linkedGoogleEmail ?? linkedEmail;

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.marginMobile),
          children: [
            Text(
              'Bir Google hesabını bağlarsan, bu telefonu kaybedersen veya uygulamayı silersen '
              'başka bir cihazda Google ile giriş yapıp çemberlerine geri dönebilirsin.',
              style: AppTextStyles.bodySm.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              decoration: BoxDecoration(
                color: colors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppRadius.cardLarge),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                leading: Icon(Icons.g_mobiledata, size: 32, color: colors.onSurfaceVariant),
                title: Text('Google', style: AppTextStyles.labelMd.copyWith(color: colors.primary)),
                subtitle: Text(
                  email != null ? 'Bağlı: $email' : 'Bağlı değil',
                  style: AppTextStyles.bodySm.copyWith(color: colors.onSurfaceVariant),
                ),
                trailing: email != null
                    ? Icon(Icons.check_circle, color: colors.onTertiaryContainer)
                    : _linking
                        ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: colors.secondary))
                        : TextButton(
                            onPressed: _linkGoogle,
                            child: Text('Bağlan', style: AppTextStyles.labelMd.copyWith(color: colors.secondary)),
                          ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(_error!, style: AppTextStyles.bodySm.copyWith(color: colors.error)),
            ],
          ],
        );
      }),
    );
  }
}
