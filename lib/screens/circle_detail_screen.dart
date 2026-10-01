import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/circle_detail_controller.dart';
import '../controllers/photo_feed.dart';
import '../core/api_client.dart';
import '../core/circle_sharing.dart';
import '../core/reveal_time.dart';
import '../data/circle_detail_repository.dart';
import '../data/http/http_circle_detail_repository.dart';
import '../data/http/http_qr_invite_repository.dart';
import '../data/photo_picker_service.dart';
import '../models/circle_detail.dart';
import '../models/circle_photo.dart';
import '../models/photo_upload_mode.dart';
import '../theme/app_theme.dart';
import '../widgets/circle_detail/action_button.dart';
import '../widgets/circle_detail/activity_banner.dart';
import '../widgets/circle_detail/circle_hero.dart';
import '../widgets/circle_detail/circle_rules_card.dart';
import '../widgets/circle_detail/darkroom_panel.dart';
import '../widgets/circle_detail/deletion_request_banner.dart';
import '../widgets/circle_detail/end_indicator.dart';
import '../widgets/circle_detail/photo_actions_sheet.dart';
import '../widgets/circle_detail/photo_grid.dart';
import '../widgets/circle_detail/recap_card.dart';
import '../widgets/common/gradient_button.dart';
import '../widgets/common/pill_selector_row.dart';
import '../widgets/common/rules_editor.dart';
import 'add_photo_screen.dart';
import 'qr_invite_screen.dart';
import 'quick_capture_screen.dart';
import 'recap_player_screen.dart';

class CircleDetailScreen extends StatefulWidget {
  const CircleDetailScreen({
    super.key,
    required this.circleId,
    this.repository = const MockCircleDetailRepository(),
    this.apiClient,
    this.pickerService = const MockPhotoPickerService(),
  });

  final String circleId;
  final CircleDetailRepository repository;
  final ApiClient? apiClient;
  final PhotoPickerService pickerService;

  @override
  State<CircleDetailScreen> createState() => _CircleDetailScreenState();
}

class _CircleDetailScreenState extends State<CircleDetailScreen> {
  int _selectedTab = 0;
  int _sourcePage = 0;
  bool _exporting = false;
  final _sourcePageController = PageController();
  late final CircleDetailRepository _effectiveRepository =
      widget.apiClient != null ? HttpCircleDetailRepository(widget.apiClient!) : widget.repository;
  late final PhotoPickerService _effectivePickerService =
      widget.apiClient != null ? const ImagePickerPhotoPickerService() : widget.pickerService;
  late final CircleDetailController controller = Get.put(
    CircleDetailController(_effectiveRepository, widget.circleId),
    tag: widget.circleId,
  );

  static const _tabLabels = ['Tümü', 'Canlı Akış (Yeni)', 'En Çok Beğenilenler 🔥'];

  @override
  void dispose() {
    _sourcePageController.dispose();
    Get.delete<CircleDetailController>(tag: widget.circleId);
    super.dispose();
  }

  void _goToSourcePage(int index) {
    _sourcePageController.animateToPage(index, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  void _openQrInvite() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => QrInviteScreen(circleId: widget.circleId, apiClient: widget.apiClient)),
    );
  }

  Future<void> _openAddPhoto() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddPhotoScreen(
          circleId: widget.circleId,
          apiClient: widget.apiClient,
          brand: controller.detail.value?.brand,
        ),
      ),
    );
    controller.load();
  }

  Future<void> _openQuickCapture() async {
    final uploaded = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => QuickCaptureScreen(
          circleId: widget.circleId,
          apiClient: widget.apiClient,
          brand: controller.detail.value?.brand,
        ),
      ),
    );
    if (uploaded == true) controller.load();
  }

  Future<void> _shareInvite() async {
    final client = widget.apiClient;
    if (client == null) return;
    try {
      final info = await HttpQrInviteRepository(client).fetch(widget.circleId);
      await shareInviteLink(eventName: info.eventName, inviteUrl: info.inviteUrl);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Davet bağlantısı alınamadı, tekrar dene.')));
    }
  }

  Future<void> _downloadAlbum() async {
    final client = widget.apiClient;
    final detail = controller.detail.value;
    if (client == null || detail == null || _exporting) return;
    setState(() => _exporting = true);
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(content: Text('Albüm hazırlanıyor…'), duration: Duration(minutes: 10)));
    try {
      await exportCircleZip(client, circleId: widget.circleId, circleName: detail.title);
      messenger.hideCurrentSnackBar();
    } on ExportFailure catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _showPhotoActions(CirclePhoto photo) {
    showPhotoActions(
      context,
      photo: photo,
      onDelete: () => controller.deletePhoto(photo),
      onReport: (reason, note) => controller.reportPhoto(photo, reason, note: note),
      onBlock: () => controller.blockUploader(photo),
    );
  }

  Future<void> _editRules(CircleDetail detail) async {
    final colors = context.colors;
    var edited = detail.rules;
    final save = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.marginMobile, AppSpacing.md, AppSpacing.marginMobile, AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Kurallar', style: AppTextStyles.headlineSm.copyWith(color: colors.primary)),
                const SizedBox(height: 4),
                Text('Çemberdeki herkes bu kuralları görür.', style: AppTextStyles.bodySm.copyWith(color: colors.onSurfaceVariant)),
                const SizedBox(height: AppSpacing.sm),
                RulesEditor(initialRules: detail.rules, onChanged: (rules) => edited = rules),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  height: 48,
                  child: GradientButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    borderRadius: AppRadius.pill,
                    child: const Text('Kaydet'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (save != true) return;
    final failure = await controller.updateRules(edited);
    _showMessage(failure ?? 'Kurallar güncellendi.');
  }

  void _showMessage(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _createRecap() async {
    final failure = await controller.requestRecap();
    if (failure != null) _showMessage(failure);
  }

  void _playRecap(CircleDetail detail) {
    final url = detail.recapUrl;
    if (url == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RecapPlayerScreen(videoUrl: url, circleName: detail.title)),
    );
  }

  Future<void> _revealNow() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fotoğrafları şimdi aç?'),
        content: const Text('Tüm kareler herkese hemen açılacak. Bu geri alınamaz.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Vazgeç')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Şimdi Aç')),
        ],
      ),
    );
    if (confirmed != true) return;
    final failure = await controller.revealNow();
    if (failure != null) _showMessage(failure);
  }

  Future<void> _changeRevealTime(CircleDetail detail) async {
    final picked = await pickRevealTime(context, detail.revealAt ?? defaultRevealTime(detail.eventDate));
    if (picked == null) return;
    final failure = await controller.updateRevealAt(picked);
    _showMessage(failure ?? 'Açılış zamanı: ${formatRevealTime(picked)}');
  }

  Future<void> _requestDeletion() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çemberi Sil'),
        content: const Text('Bu çemberi silmek istediğine emin misin?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Vazgeç')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Sil')),
        ],
      ),
    );
    if (confirmed != true) return;
    final deleted = await controller.requestDeletion();
    if (deleted && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _vote(bool approve) async {
    final deleted = await controller.vote(approve);
    if (deleted && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _changeCoverPhoto() async {
    final file = await _effectivePickerService.pickSingleFromGallery();
    if (file == null) return;
    final success = await controller.setCoverPhoto(file);
    if (!mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kapak fotoğrafı güncellenemedi, tekrar dene.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.surface,
      body: Obx(() {
        if (controller.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final detail = controller.detail.value;
        if (controller.error.value != null || detail == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  controller.error.value ?? 'Çember bulunamadı.',
                  style: AppTextStyles.bodyMd.copyWith(color: colors.onSurface),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(onPressed: controller.load, child: const Text('Tekrar Dene')),
              ],
            ),
          );
        }
        final deletionStatus = controller.deletionStatus.value;
        final isBoth = detail.uploadMode == PhotoUploadMode.both;
        final brand = detail.brand;

        final content = Builder(builder: (context) {
          final colors = context.colors;
          return Stack(
          children: [
            RefreshIndicator(
              onRefresh: controller.load,
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverToBoxAdapter(
                    child: Obx(
                      () => CircleHero(
                        detail: detail,
                        onEditCover: detail.viewerIsHost ? _changeCoverPhoto : null,
                        coverUploading: controller.coverUploading.value,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _buildActionRow(colors, detail.viewerIsHost, deletionStatus?.isPending ?? false),
                  ),
                  if (CircleRulesCard.shouldShow(detail.rules, canEdit: detail.viewerIsHost))
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.marginMobile, 0, AppSpacing.marginMobile, AppSpacing.sm),
                        child: CircleRulesCard(
                          rules: detail.rules,
                          challenge: detail.challenge,
                          onEdit: detail.viewerIsHost ? () => _editRules(detail) : null,
                        ),
                      ),
                    ),
                  if (deletionStatus != null && deletionStatus.isPending)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
                        child: DeletionRequestBanner(
                          status: deletionStatus,
                          viewerIsHost: detail.viewerIsHost,
                          onCancel: controller.cancelDeletionRequest,
                          onApprove: () => _vote(true),
                          onDecline: () => _vote(false),
                        ),
                      ),
                    ),
                  if (!detail.isDeveloping) ...[
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
                        child: ActivityBanner(),
                      ),
                    ),
                    if (RecapCard.shouldShow(detail))
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(AppSpacing.marginMobile, AppSpacing.sm, AppSpacing.marginMobile, 0),
                          child: RecapCard(
                            detail: detail,
                            onCreate: detail.viewerIsHost ? _createRecap : null,
                            onPlay: () => _playRecap(detail),
                          ),
                        ),
                      ),
                    if (isBoth) SliverToBoxAdapter(child: _buildSourceSwitcher(colors)),
                  ],
                ],
                body: detail.isDeveloping
                    ? DarkroomPanel(
                        detail: detail,
                        onRevealTimeReached: controller.load,
                        onRevealNow: detail.viewerIsHost ? _revealNow : null,
                        onChangeRevealTime: detail.viewerIsHost ? () => _changeRevealTime(detail) : null,
                      )
                    : isBoth
                    ? PageView(
                        controller: _sourcePageController,
                        onPageChanged: (i) => setState(() => _sourcePage = i),
                        children: [
                          _PhotoFeedView(
                            feed: controller.quickCaptureFeed,
                            onReact: controller.toggleReaction,
                            onMore: _showPhotoActions,
                            tabLabels: _tabLabels,
                            selectedTab: _selectedTab,
                            onTabSelected: (i) => setState(() => _selectedTab = i),
                          ),
                          _PhotoFeedView(
                            feed: controller.galleryFeed,
                            onReact: controller.toggleReaction,
                            onMore: _showPhotoActions,
                            tabLabels: _tabLabels,
                            selectedTab: _selectedTab,
                            onTabSelected: (i) => setState(() => _selectedTab = i),
                          ),
                        ],
                      )
                    : _PhotoFeedView(
                        feed: controller.allFeed,
                        onReact: controller.toggleReaction,
                        onMore: _showPhotoActions,
                        tabLabels: _tabLabels,
                        selectedTab: _selectedTab,
                        onTabSelected: (i) => setState(() => _selectedTab = i),
                      ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xs2),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.25), shape: BoxShape.circle),
                          child: const Icon(Icons.arrow_back, color: Colors.white),
                        ),
                      ),
                    ],
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
                  child: SizedBox(height: 56, child: _buildUploadButton(colors, detail.uploadMode)),
                ),
              ),
            ),
          ],
          );
        });

        if (brand == null) return content;
        return Theme(
          data: Theme.of(context).copyWith(
            extensions: [AppColorTokens.brandOverlay(colors, brand)],
          ),
          child: content,
        );
      }),
    );
  }

  Widget _buildSourceSwitcher(AppColorTokens colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.marginMobile, AppSpacing.sm, AppSpacing.marginMobile, 0),
      child: Row(
        children: [
          Expanded(child: _sourceTab(colors, label: '⚡ Şipşak', index: 0)),
          const SizedBox(width: 8),
          Expanded(child: _sourceTab(colors, label: '🖼 Galeriden', index: 1)),
        ],
      ),
    );
  }

  Widget _sourceTab(AppColorTokens colors, {required String label, required int index}) {
    final selected = _sourcePage == index;
    return GestureDetector(
      onTap: () => _goToSourcePage(index),
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? colors.primary : colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMd.copyWith(
            color: selected ? colors.onPrimary : colors.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildUploadButton(AppColorTokens colors, PhotoUploadMode mode) {
    final showQuickCapture = mode == PhotoUploadMode.quickCaptureOnly || (mode == PhotoUploadMode.both && _sourcePage == 0);

    if (showQuickCapture) {
      return ElevatedButton.icon(
        onPressed: _openQuickCapture,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
          elevation: 6,
        ),
        icon: const Icon(Icons.bolt),
        label: Text(
          'Şipşak Çek',
          style: AppTextStyles.labelLg.copyWith(color: colors.onPrimary, fontWeight: FontWeight.w700),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: _openAddPhoto,
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.secondary,
        foregroundColor: colors.onSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
        elevation: 6,
      ),
      icon: const Icon(Icons.add_photo_alternate),
      label: Text(
        'Galeriden Ekle',
        style: AppTextStyles.labelLg.copyWith(color: colors.onSecondary, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildActionRow(AppColorTokens colors, bool viewerIsHost, bool deletionPending) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile, vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: ActionButton(
              icon: Icons.qr_code_scanner,
              iconBg: colors.secondaryContainer,
              iconColor: colors.onSecondaryContainer,
              label: 'QR Göster',
              onTap: _openQrInvite,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: ActionButton(
              icon: Icons.folder_zip,
              iconBg: colors.primaryContainer,
              iconColor: Colors.white,
              label: _exporting ? 'Hazırlanıyor…' : 'Albümü İndir',
              onTap: _downloadAlbum,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: ActionButton(
              icon: Icons.person_add,
              iconBg: colors.tertiaryFixedDim,
              iconColor: colors.tertiary,
              label: 'Davet Et',
              // Hosts share the link straight to WhatsApp & co.; only hosts can fetch the invite link.
              onTap: viewerIsHost ? _shareInvite : _openQrInvite,
            ),
          ),
          if (viewerIsHost && !deletionPending) ...[
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: ActionButton(
                icon: Icons.delete_outline,
                iconBg: colors.errorContainer,
                iconColor: colors.onErrorContainer,
                label: 'Sil',
                onTap: _requestDeletion,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One scrollable page of photos (its own sort tabs + masonry grid) — used standalone for
/// single-source circles, or twice inside a swipeable [PageView] for "Both" circles.
class _PhotoFeedView extends StatelessWidget {
  const _PhotoFeedView({
    required this.feed,
    required this.onReact,
    required this.onMore,
    required this.tabLabels,
    required this.selectedTab,
    required this.onTabSelected,
  });

  final PhotoFeed feed;
  final ValueChanged<CirclePhoto> onReact;
  final ValueChanged<CirclePhoto> onMore;
  final List<String> tabLabels;
  final int selectedTab;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) => CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Obx(
                () => PillSelectorRow(
                  labels: ['Tümü (${feed.photos.length})', ...tabLabels.skip(1)],
                  selectedIndex: selectedTab,
                  onSelected: onTabSelected,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Obx(() => PhotoGrid(column1: feed.columnLeft, column2: feed.columnRight, onReact: onReact, onMore: onMore)),
          ),
          SliverToBoxAdapter(
            child: Obx(() => EndIndicator(label: 'Tüm anılar güncellendi • ${feed.photos.length} Medya')),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 110)),
        ],
      ),
    );
  }
}
