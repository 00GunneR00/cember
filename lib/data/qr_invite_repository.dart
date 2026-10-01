import '../models/brand_profile.dart';
import '../models/qr_invite_info.dart';

abstract class QrInviteRepository {
  const QrInviteRepository();

  Future<QrInviteInfo> fetch(String circleId);
  Future<QrInviteInfo> rotate(String circleId);
  Future<void> updateModeration(String circleId, {bool? autoPublish, bool? allowGuestDownloads});
}

class MockQrInviteRepository extends QrInviteRepository {
  const MockQrInviteRepository({this.brand});

  /// Non-null only in previews that want to exercise the branded-circle UI.
  final BrandProfile? brand;

  @override
  Future<QrInviteInfo> fetch(String circleId) async {
    return QrInviteInfo(
      eventName: 'Karaköy Rooftop Lansman',
      inviteUrl: 'https://cember.app/join/karakoy25',
      connectedGuestCount: 28,
      sharedMemoryCount: 142,
      autoPublish: true,
      allowGuestDownloads: true,
      brand: brand,
    );
  }

  @override
  Future<QrInviteInfo> rotate(String circleId) => fetch(circleId);

  @override
  Future<void> updateModeration(String circleId, {bool? autoPublish, bool? allowGuestDownloads}) async {}
}
