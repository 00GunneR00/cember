import 'package:flutter/material.dart';

import '../core/google_auth.dart';
import '../core/token_store.dart';
import '../data/auth_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/common/app_logo_mark.dart';
import '../widgets/common/gradient_button.dart';
import 'main_shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    this.authRepository = const MockAuthRepository(),
    this.tokenStore = const TokenStore(),
  });

  final AuthRepository authRepository;
  final TokenStore tokenStore;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = TextEditingController();
  final GoogleAuth _googleAuth = const GoogleAuth();
  bool _submitting = false;
  String? _error;

  Future<void> _submit() async {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Lütfen adını yaz.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final apiKey = await widget.authRepository.registerHost(name);
      await _enterApp(apiKey);
    } catch (_) {
      setState(() {
        _submitting = false;
        _error = 'Bir şeyler ters gitti, tekrar dene.';
      });
    }
  }

  /// Recovers an existing host's circles on this device via their linked Google account,
  /// or creates a new host if this Google account has never signed in before.
  Future<void> _continueWithGoogle() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final idToken = await _googleAuth.signIn();
      if (idToken == null) {
        setState(() => _submitting = false);
        return;
      }
      final apiKey = await widget.authRepository.signInWithGoogle(idToken);
      await _enterApp(apiKey);
    } catch (_) {
      setState(() {
        _submitting = false;
        _error = 'Google ile giriş yapılamadı, tekrar dene.';
      });
    }
  }

  Future<void> _enterApp(String apiKey) async {
    await widget.tokenStore.saveApiKey(apiKey);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainShell()));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppLogoMark(size: 64, showAccent: true),
                const SizedBox(height: AppSpacing.lg),
                Text('Çember\'e Hoş Geldin', style: AppTextStyles.headlineLgMobile.copyWith(color: colors.primary), textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.xs),
                Text('Adın ne?', style: AppTextStyles.bodyMd.copyWith(color: colors.onSurface), textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.xl),
                TextField(
                  controller: _controller,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headlineSm.copyWith(color: colors.primary),
                  decoration: InputDecoration(
                    hintText: 'Zeynep',
                    filled: true,
                    fillColor: colors.surfaceContainerLowest,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.pill), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(_error!, style: AppTextStyles.bodySm.copyWith(color: colors.error), textAlign: TextAlign.center),
                ],
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  height: 52,
                  child: GradientButton(
                    onPressed: _submitting ? null : _submit,
                    borderRadius: AppRadius.pill,
                    child: _submitting
                        ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: colors.onSecondary))
                        : const Text('Devam Et'),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: _submitting ? null : _continueWithGoogle,
                  child: Text(
                    'Zaten hesabım var, Google ile devam et',
                    style: AppTextStyles.labelMd.copyWith(color: colors.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
