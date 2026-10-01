import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/notifications_controller.dart';
import '../core/api_client.dart';
import '../data/http/http_notifications_repository.dart';
import '../data/notifications_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/notifications/notification_tile.dart';
import 'circle_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, this.repository = const MockNotificationsRepository(), this.apiClient});

  final NotificationsRepository repository;
  final ApiClient? apiClient;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final NotificationsRepository _effectiveRepository =
      widget.apiClient != null ? HttpNotificationsRepository(widget.apiClient!) : widget.repository;
  late final NotificationsController controller = Get.put(NotificationsController(_effectiveRepository), tag: 'notifications');

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    Get.delete<NotificationsController>(tag: 'notifications');
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      controller.loadMore();
    }
  }

  Future<void> _openNotification(String id, String circleId) async {
    await controller.markRead(id);
    if (!mounted || widget.apiClient == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CircleDetailScreen(circleId: circleId, apiClient: widget.apiClient)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.marginMobile, AppSpacing.xs, AppSpacing.marginMobile, AppSpacing.xs),
              child: Row(
                children: [
                  Expanded(child: Text('Bildirimler', style: AppTextStyles.headlineLgMobile.copyWith(color: colors.primary))),
                  Obx(() => controller.unreadCount.value > 0
                      ? TextButton(
                          onPressed: controller.markAllRead,
                          child: Text('Tümünü okundu işaretle', style: AppTextStyles.labelMd.copyWith(color: colors.secondary)),
                        )
                      : const SizedBox.shrink()),
                ],
              ),
            ),
            Expanded(
              child: Obx(() {
                if (controller.loading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (controller.error.value != null) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(controller.error.value!, style: AppTextStyles.bodyMd.copyWith(color: colors.onSurface)),
                        const SizedBox(height: AppSpacing.sm),
                        TextButton(onPressed: controller.load, child: const Text('Tekrar Dene')),
                      ],
                    ),
                  );
                }
                if (controller.items.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.notifications_none, size: 40, color: colors.onSurfaceVariant),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Henüz bir bildirimin yok.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMd.copyWith(color: colors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: controller.load,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(AppSpacing.marginMobile, AppSpacing.xs, AppSpacing.marginMobile, 100),
                    itemCount: controller.items.length + (controller.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= controller.items.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final item = controller.items[index];
                      return NotificationTile(notification: item, onTap: () => _openNotification(item.id, item.circleId));
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
