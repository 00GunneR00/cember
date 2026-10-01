import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/albums_controller.dart';
import '../controllers/discover_controller.dart';
import '../core/api_client.dart';
import '../core/push_notifications.dart';
import '../core/storage_image.dart';
import '../core/token_store.dart';
import '../models/public_circle_summary.dart';
import '../theme/app_theme.dart';
import 'circle_detail_screen.dart';

/// Shown before a viewer joins a circle discovered in Keşfet — lets them see what it's
/// about (cover, host, stats, description) before committing, rather than joining on tap.
class DiscoverCirclePreviewScreen extends StatefulWidget {
  const DiscoverCirclePreviewScreen({
    super.key,
    required this.circle,
    required this.controller,
    this.apiClient,
    this.tokenStore = const TokenStore(),
  });

  final PublicCircleSummary circle;
  final DiscoverController controller;
  final ApiClient? apiClient;
  final TokenStore tokenStore;

  @override
  State<DiscoverCirclePreviewScreen> createState() => _DiscoverCirclePreviewScreenState();
}

class _DiscoverCirclePreviewScreenState extends State<DiscoverCirclePreviewScreen> {
  bool _joining = false;
  bool _loadingPhotos = true;
  List<String> _previewPhotos = const [];

  @override
  void initState() {
    super.initState();
    _loadPreviewPhotos();
  }

  Future<void> _loadPreviewPhotos() async {
    final photos = await widget.controller.fetchPreviewPhotos(widget.circle.id);
    if (!mounted) return;
    setState(() {
      _previewPhotos = photos;
      _loadingPhotos = false;
    });
  }

  String get _dateLabel {
    final date = widget.circle.eventDate;
    if (date == null) return '';
    const months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _join() async {
    if (widget.apiClient == null || _joining) return;
    setState(() => _joining = true);
    final result = await widget.controller.join(widget.circle.id);
    if (!mounted) return;

    if (result == null) {
      setState(() => _joining = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Çembere katılamadın, tekrar dene.')));
      return;
    }

    await widget.tokenStore.saveGuestToken(result.circle.id, result.guestSessionToken);
    await widget.tokenStore.addJoinedCircleId(result.circle.id);
    // Refresh "Çemberlerim" in the background so it's already there when the viewer switches tabs.
    if (Get.isRegistered<AlbumsController>(tag: 'albums')) {
      Get.find<AlbumsController>(tag: 'albums').load(silent: true);
    }
    if (!mounted) return;

    final guestClient = ApiClient(baseUrl: widget.apiClient!.dio.options.baseUrl, bearerToken: result.guestSessionToken);
    unawaited(PushNotifications.instance.registerIdentity(guestClient));
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => CircleDetailScreen(circleId: result.circle.id, apiClient: guestClient)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final circle = widget.circle;
    return Scaffold(
      backgroundColor: colors.surface,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: AspectRatio(
                  aspectRatio: 4 / 3.2,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (circle.coverUrl != null)
                        CachedNetworkImage(imageUrl: circle.coverUrl!, cacheKey: storageCacheKey(circle.coverUrl!), fit: BoxFit.cover)
                      else
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: colors.coverGradientColors,
                            ),
                          ),
                        ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [colors.scrim, colors.scrim.withValues(alpha: 0.45), Colors.transparent],
                          ),
                        ),
                      ),
                      Positioned(
                        left: AppSpacing.marginMobile,
                        right: AppSpacing.marginMobile,
                        bottom: AppSpacing.marginMobile,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(circle.name, style: AppTextStyles.headlineLgMobile.copyWith(color: Colors.white)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const CircleAvatar(radius: 12, backgroundColor: Colors.white24, child: Icon(Icons.person, size: 12, color: Colors.white)),
                                const SizedBox(width: 6),
                                Text.rich(
                                  TextSpan(
                                    style: AppTextStyles.labelSm.copyWith(color: Colors.white70),
                                    children: [
                                      const TextSpan(text: 'Ev Sahibi: '),
                                      TextSpan(text: circle.hostDisplayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.marginMobile),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.photo_library, size: 18, color: colors.secondary),
                          const SizedBox(width: 6),
                          Text('${circle.photoCount} kare', style: AppTextStyles.bodySm.copyWith(color: colors.onSurfaceVariant)),
                          const SizedBox(width: 16),
                          Icon(Icons.group, size: 18, color: colors.secondary),
                          const SizedBox(width: 6),
                          Text('${circle.participantCount} kişi', style: AppTextStyles.bodySm.copyWith(color: colors.onSurfaceVariant)),
                          if (circle.eventDate != null) ...[
                            const SizedBox(width: 16),
                            Icon(Icons.calendar_today, size: 16, color: colors.secondary),
                            const SizedBox(width: 6),
                            Text(_dateLabel, style: AppTextStyles.bodySm.copyWith(color: colors.onSurfaceVariant)),
                          ],
                        ],
                      ),
                      if (_loadingPhotos) ...[
                        const SizedBox(height: AppSpacing.lg),
                        const Center(child: CircularProgressIndicator()),
                      ] else if (_previewPhotos.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Neler paylaşılıyor?',
                          style: AppTextStyles.headlineSm.copyWith(color: colors.primary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Katılmadan önce bir fikir edin — en fazla 10 örnek.',
                          style: AppTextStyles.bodySm.copyWith(color: colors.onSurfaceVariant),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        GridView.count(
                          crossAxisCount: 3,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: AppSpacing.xs,
                          mainAxisSpacing: AppSpacing.xs,
                          children: _previewPhotos
                              .map((url) => ClipRRect(
                                    borderRadius: BorderRadius.circular(AppRadius.card),
                                    child: CachedNetworkImage(imageUrl: url, cacheKey: storageCacheKey(url), fit: BoxFit.cover),
                                  ))
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      Text('Bu çember hakkında', style: AppTextStyles.headlineSm.copyWith(color: colors.primary)),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        circle.description != null && circle.description!.isNotEmpty
                            ? circle.description!
                            : 'Bu çember için henüz bir açıklama eklenmemiş. Katıldığında paylaşılan anıları görebilir, sen de kendi fotoğraflarını ekleyebilirsin.',
                        style: AppTextStyles.bodyMd.copyWith(color: colors.onSurface),
                      ),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xs2),
                child: IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.25), shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.marginMobile),
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _joining ? null : _join,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.secondary,
                      foregroundColor: colors.onSecondary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                      elevation: 6,
                    ),
                    icon: _joining
                        ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: colors.onSecondary))
                        : const Icon(Icons.group_add),
                    label: Text(
                      _joining ? 'Katılınıyor...' : 'Çembere Katıl',
                      style: AppTextStyles.labelLg.copyWith(color: colors.onSecondary, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
