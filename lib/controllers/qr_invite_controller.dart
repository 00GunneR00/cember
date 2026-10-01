import 'package:get/get.dart';

import '../data/qr_invite_repository.dart';
import '../models/qr_invite_info.dart';

class QrInviteController extends GetxController {
  QrInviteController(this._repository, this.circleId);

  final QrInviteRepository _repository;
  final String circleId;

  final loading = true.obs;
  final error = Rxn<String>();
  final info = Rxn<QrInviteInfo>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      info.value = await _repository.fetch(circleId);
    } catch (_) {
      error.value = 'Davet bilgisi yüklenemedi.';
    } finally {
      loading.value = false;
    }
  }

  Future<void> setAutoPublish(bool value) async {
    final current = info.value;
    if (current == null) return;
    info.value = QrInviteInfo(
      eventName: current.eventName,
      inviteUrl: current.inviteUrl,
      connectedGuestCount: current.connectedGuestCount,
      sharedMemoryCount: current.sharedMemoryCount,
      autoPublish: value,
      allowGuestDownloads: current.allowGuestDownloads,
    );
    try {
      await _repository.updateModeration(circleId, autoPublish: value);
    } catch (_) {
      info.value = current;
    }
  }

  Future<void> setAllowGuestDownloads(bool value) async {
    final current = info.value;
    if (current == null) return;
    info.value = QrInviteInfo(
      eventName: current.eventName,
      inviteUrl: current.inviteUrl,
      connectedGuestCount: current.connectedGuestCount,
      sharedMemoryCount: current.sharedMemoryCount,
      autoPublish: current.autoPublish,
      allowGuestDownloads: value,
    );
    try {
      await _repository.updateModeration(circleId, allowGuestDownloads: value);
    } catch (_) {
      info.value = current;
    }
  }
}
