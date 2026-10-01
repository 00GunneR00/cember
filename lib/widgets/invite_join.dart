import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/albums_controller.dart';
import '../core/api_client.dart';
import '../core/push_notifications.dart';
import '../core/token_store.dart';
import '../data/http/http_invite_repository.dart';
import '../data/invite_repository.dart';
import '../models/invite_preview.dart';
import '../theme/app_theme.dart';

/// A circle just joined as a guest, with the client that acts as that guest.
class JoinedViaInvite {
  const JoinedViaInvite(this.circleId, this.guestClient);

  final String circleId;
  final ApiClient guestClient;
}

/// Joining a circle from an invite token — shared by the QR scanner and invite links.
class InviteJoiner {
  InviteJoiner({required this.apiClient, InviteRepository? repository, this.tokenStore = const TokenStore()})
    : repository = repository ?? HttpInviteRepository(apiClient);

  final ApiClient apiClient;
  final InviteRepository repository;
  final TokenStore tokenStore;

  Future<InvitePreview> preview(String token) => repository.preview(token);

  /// Asks for the name to show in the circle; null if the user backs out.
  Future<String?> askDisplayName(BuildContext context, InvitePreview preview, {String defaultDisplayName = ''}) {
    final colors = context.colors;
    final nameController = TextEditingController(text: defaultDisplayName);
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card))),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.marginMobile,
          right: AppSpacing.marginMobile,
          top: AppSpacing.lg,
          bottom: AppSpacing.lg + MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(preview.circleName, style: AppTextStyles.headlineSm.copyWith(color: colors.primary)),
            const SizedBox(height: 4),
            Text('${preview.hostDisplayName} seni bu çembere davet ediyor.', style: AppTextStyles.bodySm.copyWith(color: colors.onSurfaceVariant)),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(hintText: 'Görünecek adın'),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  if (name.isEmpty) return;
                  Navigator.of(sheetContext).pop(name);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.secondary,
                  foregroundColor: colors.onSecondary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
                ),
                child: const Text('Çembere Katıl'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Joins, remembers the guest token on this device and refreshes Albümler.
  Future<JoinedViaInvite> join(String token, String displayName) async {
    final result = await repository.join(token, displayName);
    await tokenStore.saveGuestToken(result.circle.id, result.guestSessionToken);
    await tokenStore.addJoinedCircleId(result.circle.id);
    if (Get.isRegistered<AlbumsController>(tag: 'albums')) {
      Get.find<AlbumsController>(tag: 'albums').load(silent: true);
    }
    final guestClient = ApiClient(baseUrl: apiClient.dio.options.baseUrl, bearerToken: result.guestSessionToken);
    // So this guest identity gets the circle's pushes (Banyo reveal, recap video).
    unawaited(PushNotifications.instance.registerIdentity(guestClient));
    return JoinedViaInvite(result.circle.id, guestClient);
  }
}
