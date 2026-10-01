import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/albums_controller.dart';
import '../core/api_client.dart';
import '../models/circle_summary.dart';
import '../models/photo_upload_mode.dart';
import '../screens/add_photo_screen.dart';
import '../screens/quick_capture_screen.dart';
import '../theme/app_theme.dart';

class _UploadTarget {
  const _UploadTarget(this.circle, this.client);

  final CircleSummary circle;

  /// The host's own client, or a guest client for circles joined via Discover.
  final ApiClient client;
}

enum _UploadMethod { quickCapture, gallery }

/// The bottom bar's + button: pick one of the viewer's live circles, then open Şipşak or the
/// gallery picker — whichever that circle's upload mode allows.
Future<void> startAddPhotoFlow(BuildContext context, ApiClient apiClient) async {
  if (!Get.isRegistered<AlbumsController>(tag: 'albums')) return;
  final albums = Get.find<AlbumsController>(tag: 'albums');
  final targets = [
    for (final c in albums.overview.value?.live ?? const <CircleSummary>[]) _UploadTarget(c, apiClient),
    for (final j in albums.joinedCircles.where((j) => !j.circle.isArchived))
      _UploadTarget(j.circle, ApiClient(baseUrl: apiClient.dio.options.baseUrl, bearerToken: j.guestToken)),
  ];

  final target = await showModalBottomSheet<_UploadTarget>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.colors.surface,
    builder: (context) => _CirclePickerSheet(targets: targets),
  );
  if (target == null || !context.mounted) return;

  final mode = target.circle.uploadMode;
  final method = switch (mode) {
    PhotoUploadMode.quickCaptureOnly => _UploadMethod.quickCapture,
    PhotoUploadMode.galleryOnly => _UploadMethod.gallery,
    PhotoUploadMode.both => await showModalBottomSheet<_UploadMethod>(
      context: context,
      backgroundColor: context.colors.surface,
      builder: (context) => const _MethodPickerSheet(),
    ),
  };
  if (method == null || !context.mounted) return;

  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => method == _UploadMethod.quickCapture
          ? QuickCaptureScreen(circleId: target.circle.id, apiClient: target.client, brand: target.circle.brand)
          : AddPhotoScreen(circleId: target.circle.id, apiClient: target.client, brand: target.circle.brand),
    ),
  );
  albums.load(silent: true);
}

class _CirclePickerSheet extends StatelessWidget {
  const _CirclePickerSheet({required this.targets});

  final List<_UploadTarget> targets;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.marginMobile, AppSpacing.md, AppSpacing.marginMobile, AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Fotoğraf Ekle', style: AppTextStyles.headlineSm.copyWith(color: colors.primary)),
              const SizedBox(height: 4),
              Text(
                targets.isEmpty ? 'Fotoğraf eklemek için önce bir çember oluştur ya da bir çembere katıl.' : 'Hangi çembere eklemek istiyorsun?',
                style: AppTextStyles.bodySm.copyWith(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (targets.isNotEmpty)
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final t in targets)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: colors.surfaceContainerHigh,
                            child: Icon(Icons.photo_library_outlined, color: colors.secondary),
                          ),
                          title: Text(t.circle.name, style: AppTextStyles.labelLg.copyWith(color: colors.primary)),
                          subtitle: Text(
                            '${t.circle.photoCount} fotoğraf · ${t.circle.participantCount} kişi',
                            style: AppTextStyles.bodySm.copyWith(color: colors.onSurfaceVariant),
                          ),
                          onTap: () => Navigator.of(context).pop(t),
                        ),
                    ],
                  ),
                )
              else
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Tamam')),
            ],
          ),
        ),
      ),
    );
  }
}

class _MethodPickerSheet extends StatelessWidget {
  const _MethodPickerSheet();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_camera_outlined, color: colors.secondary),
              title: const Text('Şipşak'),
              subtitle: const Text('Çek, anında yüklensin'),
              onTap: () => Navigator.of(context).pop(_UploadMethod.quickCapture),
            ),
            ListTile(
              leading: Icon(Icons.photo_library_outlined, color: colors.secondary),
              title: const Text('Galeriden Seç'),
              subtitle: const Text('Telefonundaki fotoğraflardan ekle'),
              onTap: () => Navigator.of(context).pop(_UploadMethod.gallery),
            ),
          ],
        ),
      ),
    );
  }
}
