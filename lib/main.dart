import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'controllers/theme_controller.dart';
import 'core/api_client.dart';
import 'core/invite_links.dart';
import 'core/push_notifications.dart';
import 'core/theme_store.dart';
import 'core/token_store.dart';
import 'data/http/http_auth_repository.dart';
import 'screens/main_shell.dart';
import 'screens/onboarding_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PushNotifications.instance.init();
  Get.put(ThemeController(const ThemeStore()), permanent: true);
  // Listen for invite links (WhatsApp etc.) from the very start, so one that launches the app isn't missed.
  InviteLinks.instance.start();
  runApp(const CemberApp());
}

class CemberApp extends StatelessWidget {
  const CemberApp({super.key, this.tokenStore = const TokenStore()});

  final TokenStore tokenStore;

  @override
  Widget build(BuildContext context) {
    final apiClient = ApiClient(tokenStore: tokenStore);
    if (!Get.isRegistered<ThemeController>()) {
      Get.put(ThemeController(const ThemeStore()), permanent: true);
    }
    final themeController = Get.find<ThemeController>();
    return GetMaterialApp(
      title: 'Çember',
      scaffoldMessengerKey: PushNotifications.instance.messengerKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeController.mode.value,
      home: FutureBuilder<String?>(
        future: tokenStore.readApiKey(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Scaffold(backgroundColor: context.colors.surface, body: const Center(child: CircularProgressIndicator()));
          }
          return snapshot.data != null
              ? const MainShell()
              : OnboardingScreen(authRepository: HttpAuthRepository(apiClient), tokenStore: tokenStore);
        },
      ),
    );
  }
}
