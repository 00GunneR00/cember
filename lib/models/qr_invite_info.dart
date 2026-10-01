import 'brand_profile.dart';

class QrInviteInfo {
  const QrInviteInfo({
    required this.eventName,
    required this.inviteUrl,
    required this.connectedGuestCount,
    required this.sharedMemoryCount,
    required this.autoPublish,
    required this.allowGuestDownloads,
    this.brand,
  });

  final String eventName;
  final String inviteUrl;
  final int connectedGuestCount;
  final int sharedMemoryCount;
  final bool autoPublish;
  final bool allowGuestDownloads;
  final BrandProfile? brand;

  factory QrInviteInfo.fromInviteJson(
    Map<String, dynamic> json, {
    required String eventName,
    BrandProfile? brand,
  }) =>
      QrInviteInfo(
        eventName: eventName,
        inviteUrl: json['inviteUrl'] as String,
        connectedGuestCount: json['connectedGuestCount'] as int,
        sharedMemoryCount: json['sharedMemoryCount'] as int,
        autoPublish: json['autoPublish'] as bool,
        allowGuestDownloads: json['allowGuestDownloads'] as bool,
        brand: brand,
      );
}
