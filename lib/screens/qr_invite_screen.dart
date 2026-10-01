import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../controllers/qr_invite_controller.dart';
import '../core/api_client.dart';
import '../core/circle_sharing.dart';
import '../data/http/http_qr_invite_repository.dart';
import '../data/qr_invite_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/qr_invite/instruction_card.dart';
import '../widgets/qr_invite/moderation_card.dart';
import '../widgets/qr_invite/qr_action_row.dart';
import '../widgets/qr_invite/qr_hero_card.dart';
import '../widgets/qr_invite/status_banner.dart';

class QrInviteScreen extends StatefulWidget {
  const QrInviteScreen({super.key, required this.circleId, this.repository = const MockQrInviteRepository(), this.apiClient});

  final String circleId;
  final QrInviteRepository repository;
  final ApiClient? apiClient;

  @override
  State<QrInviteScreen> createState() => _QrInviteScreenState();
}

class _QrInviteScreenState extends State<QrInviteScreen> {
  bool _copied = false;
  late final QrInviteRepository _effectiveRepository =
      widget.apiClient != null ? HttpQrInviteRepository(widget.apiClient!) : widget.repository;
  late final QrInviteController controller = Get.put(
    QrInviteController(_effectiveRepository, widget.circleId),
    tag: 'qr-${widget.circleId}',
  );

  @override
  void dispose() {
    Get.delete<QrInviteController>(tag: 'qr-${widget.circleId}');
    super.dispose();
  }

  void _share() {
    final info = controller.info.value;
    if (info == null) return;
    shareInviteLink(eventName: info.eventName, inviteUrl: info.inviteUrl);
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bu özellik çok yakında geliyor.')));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: Icon(Icons.arrow_back, color: colors.onSurface),
        ),
        title: Text('QR Davet', style: AppTextStyles.headlineSm.copyWith(color: colors.primary)),
        actions: [
          IconButton(
            onPressed: _share,
            tooltip: 'Davet bağlantısını paylaş',
            icon: Icon(Icons.share, color: colors.onSurfaceVariant),
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.marginMobile),
            child: CircleAvatar(radius: 16, backgroundColor: colors.surfaceContainerHigh, child: Icon(Icons.person, size: 16, color: colors.onSurfaceVariant)),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final info = controller.info.value;
        if (controller.error.value != null || info == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(controller.error.value ?? 'Davet bilgisi bulunamadı.', style: AppTextStyles.bodyMd.copyWith(color: colors.onSurface)),
                const SizedBox(height: AppSpacing.sm),
                TextButton(onPressed: controller.load, child: const Text('Tekrar Dene')),
              ],
            ),
          );
        }
        final brand = info.brand;
        final content = SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.marginMobile, 0, AppSpacing.marginMobile, AppSpacing.xl),
          child: Builder(builder: (context) {
            final colors = context.colors;
            return Column(
              children: [
                const StatusBanner(),
                const SizedBox(height: AppSpacing.lg),
                QrHeroCard(
                  info: info,
                  copied: _copied,
                  onCopy: () {
                    Clipboard.setData(ClipboardData(text: info.inviteUrl));
                    setState(() => _copied = true);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                const InstructionCard(),
                const SizedBox(height: AppSpacing.md),
                QrActionRow(
                  icon: Icons.tv,
                  title: 'Projeksiyon / Canlı Duvar Modu',
                  subtitle: 'Parti ekranları için canlı slayt gösterisi',
                  trailingIcon: Icons.play_arrow,
                  onTap: _showComingSoon,
                  backgroundColor: colors.secondary,
                  iconBoxColor: Colors.white.withValues(alpha: 0.15),
                  iconColor: colors.onSecondary,
                  titleColor: colors.onSecondary,
                  subtitleColor: Colors.white70,
                  trailingColor: colors.onSecondary,
                ),
                const SizedBox(height: AppSpacing.sm),
                QrActionRow(
                  icon: Icons.picture_as_pdf,
                  title: 'Karekod Masa Kartı (PDF) İndir',
                  subtitle: 'Masa ve giriş standları için hazır baskı şablonu',
                  trailingIcon: Icons.download,
                  onTap: _showComingSoon,
                ),
                const SizedBox(height: AppSpacing.md),
                ModerationCard(
                  autoPublish: info.autoPublish,
                  onAutoPublishChanged: controller.setAutoPublish,
                  guestDownloads: info.allowGuestDownloads,
                  onGuestDownloadsChanged: controller.setAllowGuestDownloads,
                ),
              ],
            );
          }),
        );
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
}
