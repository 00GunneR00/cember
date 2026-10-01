import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/albums_controller.dart';
import '../core/api_client.dart';
import '../core/invite_links.dart';
import '../core/push_notifications.dart';
import '../core/token_store.dart';
import '../data/http/http_notifications_repository.dart';
import '../data/notifications_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/add_photo_flow.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/invite_join.dart';
import 'albums_screen.dart';
import 'circle_detail_screen.dart';
import 'discover_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  final ApiClient _apiClient = ApiClient();
  late final NotificationsRepository _notificationsRepository = HttpNotificationsRepository(_apiClient);
  final _unreadCount = 0.obs;

  late final _screens = [
    AlbumsScreen(apiClient: _apiClient),
    DiscoverScreen(apiClient: _apiClient),
    NotificationsScreen(apiClient: _apiClient),
    ProfileScreen(apiClient: _apiClient),
  ];

  @override
  void initState() {
    super.initState();
    _refreshUnreadCount();
    InviteLinks.instance.pendingToken.addListener(_openPendingInvite);
    PushNotifications.instance.circleToOpen.addListener(_openPushedCircle);
    PushNotifications.instance.received.addListener(_refreshUnreadCount);
    unawaited(PushNotifications.instance.registerAll(_apiClient));
    // A link or a tapped notification may have launched the app before sign-in — pick it up now.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openPendingInvite();
      _openPushedCircle();
    });
  }

  @override
  void dispose() {
    InviteLinks.instance.pendingToken.removeListener(_openPendingInvite);
    PushNotifications.instance.circleToOpen.removeListener(_openPushedCircle);
    PushNotifications.instance.received.removeListener(_refreshUnreadCount);
    _unreadCount.close();
    super.dispose();
  }

  /// Opens the circle a tapped push points at — as a guest when this phone joined it that way.
  Future<void> _openPushedCircle() async {
    if (!mounted) return;
    final circleId = PushNotifications.instance.circleToOpen.value;
    if (circleId == null) return;
    PushNotifications.instance.circleToOpen.value = null;

    final guestToken = await const TokenStore().readGuestToken(circleId);
    if (!mounted) return;
    final client = guestToken == null ? _apiClient : ApiClient(baseUrl: _apiClient.dio.options.baseUrl, bearerToken: guestToken);
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CircleDetailScreen(circleId: circleId, apiClient: client)),
    );
    _refreshUnreadCount();
  }

  bool _handlingInvite = false;

  Future<void> _openPendingInvite() async {
    if (!mounted || _handlingInvite) return;
    final token = InviteLinks.instance.take();
    if (token == null) return;

    _handlingInvite = true;
    final joiner = InviteJoiner(apiClient: _apiClient);
    try {
      final preview = await joiner.preview(token);
      if (!mounted) return;
      final defaultName = Get.isRegistered<AlbumsController>(tag: 'albums')
          ? Get.find<AlbumsController>(tag: 'albums').overview.value?.userName ?? ''
          : '';
      final displayName = await joiner.askDisplayName(context, preview, defaultDisplayName: defaultName);
      if (displayName == null || !mounted) return;
      final joined = await joiner.join(token, displayName);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => CircleDetailScreen(circleId: joined.circleId, apiClient: joined.guestClient)),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bu davet bağlantısı geçersiz ya da süresi dolmuş.')),
        );
      }
    } finally {
      _handlingInvite = false;
    }
  }

  Future<void> _refreshUnreadCount() async {
    try {
      _unreadCount.value = await _notificationsRepository.fetchUnreadCount();
    } catch (_) {
      // Badge staying stale is harmless; it refreshes on the next tab switch.
    }
  }

  void _onTabSelected(int index) {
    setState(() => _index = index);
    _refreshUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.surface,
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: Obx(() => BottomNavBar(
            currentIndex: _index,
            onTabSelected: _onTabSelected,
            onAddPressed: () => startAddPhotoFlow(context, _apiClient),
            notificationCount: _unreadCount.value,
          )),
    );
  }
}
