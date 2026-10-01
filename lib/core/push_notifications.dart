import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'api_client.dart';
import 'token_store.dart';

/// Firebase settings come from build-time defines (see scripts/run_on_device.ps1 and config/firebase.json),
/// so the app builds and runs without Firebase — push is then simply off.
const _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
const _appId = String.fromEnvironment('FIREBASE_APP_ID');
const _senderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');

/// Push notifications (FCM): registers this phone under every identity the user has — the host account
/// and each circle joined as a guest — and turns a tapped notification into "open this circle".
class PushNotifications {
  PushNotifications._();

  static final instance = PushNotifications._();

  /// Shows pushes that arrive while the app is open (Android only draws them when it's in the background).
  final messengerKey = GlobalKey<ScaffoldMessengerState>();

  /// The circle a tapped notification points at; the main shell opens it.
  final circleToOpen = ValueNotifier<String?>(null);

  /// Fires for every push received while the app is open — e.g. to refresh the unread badge.
  final received = ValueNotifier<int>(0);

  bool _enabled = false;
  bool get enabled => _enabled;

  static bool get isConfigured => _apiKey.isNotEmpty && _appId.isNotEmpty && _senderId.isNotEmpty && _projectId.isNotEmpty;

  Future<void> init() async {
    if (!isConfigured || kIsWeb) return;
    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(apiKey: _apiKey, appId: _appId, messagingSenderId: _senderId, projectId: _projectId),
      );
      _enabled = true;
    } catch (e) {
      debugPrint('Firebase başlatılamadı, push kapalı: $e');
      return;
    }

    FirebaseMessaging.onMessage.listen((message) {
      received.value++;
      final notification = message.notification;
      if (notification == null) return;
      messengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text([notification.title, notification.body].whereType<String>().join('\n')),
          action: message.data['circleId'] == null
              ? null
              : SnackBarAction(label: 'Aç', onPressed: () => circleToOpen.value = message.data['circleId'] as String?),
        ),
      );
    });
    FirebaseMessaging.onMessageOpenedApp.listen(_openFromMessage);
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _openFromMessage(initial);
  }

  void _openFromMessage(RemoteMessage message) {
    final circleId = message.data['circleId'];
    if (circleId is String) circleToOpen.value = circleId;
  }

  StreamSubscription<String>? _refreshSubscription;

  /// Asks for permission (Android 13+) and registers this phone for the host and every guest identity.
  Future<void> registerAll(ApiClient hostClient, {TokenStore tokenStore = const TokenStore()}) async {
    if (!_enabled) return;
    try {
      final settings = await FirebaseMessaging.instance.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await _registerEverywhere(token, hostClient, tokenStore);

      _refreshSubscription ??= FirebaseMessaging.instance.onTokenRefresh.listen((fresh) => _registerEverywhere(fresh, hostClient, tokenStore));
    } catch (e) {
      debugPrint('Push kaydı yapılamadı: $e');
    }
  }

  /// Registers this phone for one more identity — called right after joining a circle as a guest.
  Future<void> registerIdentity(ApiClient client) async {
    if (!_enabled) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _register(client, token);
    } catch (e) {
      debugPrint('Push kaydı yapılamadı: $e');
    }
  }

  /// Stops pushes for the host account on this phone — called on sign-out.
  Future<void> unregisterHost(ApiClient hostClient) async {
    if (!_enabled) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await hostClient.dio.delete('/me/device-token', data: {'token': token});
    } catch (_) {
      // Signing out must not depend on the network.
    }
  }

  Future<void> _registerEverywhere(String token, ApiClient hostClient, TokenStore tokenStore) async {
    await _register(hostClient, token);
    for (final circleId in await tokenStore.readJoinedCircleIds()) {
      final guestToken = await tokenStore.readGuestToken(circleId);
      if (guestToken == null) continue;
      try {
        await _register(ApiClient(baseUrl: hostClient.dio.options.baseUrl, bearerToken: guestToken), token);
      } catch (_) {
        // That circle may be gone.
      }
    }
  }

  Future<void> _register(ApiClient client, String token) => client.dio.post('/me/device-token', data: {'token': token, 'platform': Platform.operatingSystem});
}
