import 'brand_profile.dart';
import 'challenge_template.dart';
import 'photo_upload_mode.dart';
import 'recap_status.dart';

class CircleDetail {
  const CircleDetail({
    required this.id,
    required this.title,
    required this.eventDate,
    required this.participantCount,
    required this.memoryCount,
    required this.isOpenJoin,
    required this.autoPublish,
    required this.allowGuestDownloads,
    required this.viewerIsHost,
    required this.hostDisplayName,
    required this.coverUrl,
    this.description,
    this.uploadMode = PhotoUploadMode.both,
    this.brand,
    this.revealAt,
    this.isDeveloping = false,
    this.viewerUploadCount = 0,
    this.recapStatus = RecapStatus.none,
    this.recapUrl,
    this.recapError,
    this.challenge,
    this.rules = const [],
  });

  final String id;
  final String title;
  final DateTime? eventDate;
  final int participantCount;
  final int memoryCount;
  final bool isOpenJoin;
  final bool autoPublish;
  final bool allowGuestDownloads;
  final bool viewerIsHost;
  final String hostDisplayName;
  final String? coverUrl;
  final String? description;
  final PhotoUploadMode uploadMode;
  final BrandProfile? brand;

  /// Banyo modu: photos stay hidden from everyone until this moment.
  final DateTime? revealAt;
  final bool isDeveloping;

  /// How many of the hidden photos the viewer took — only known while [isDeveloping].
  final int viewerUploadCount;

  final RecapStatus recapStatus;
  final String? recapUrl;
  final String? recapError;

  /// Set when the circle was started from a Keşfet challenge.
  final CircleChallenge? challenge;

  /// The circle's rules / photo tasks, shown to everyone inside it.
  final List<String> rules;

  factory CircleDetail.fromJson(Map<String, dynamic> json) => CircleDetail(
        id: json['id'] as String,
        title: json['name'] as String,
        eventDate: json['eventDate'] == null ? null : DateTime.parse(json['eventDate'] as String),
        participantCount: json['participantCount'] as int,
        memoryCount: json['memoryCount'] as int,
        isOpenJoin: json['isOpenJoin'] as bool,
        autoPublish: json['autoPublish'] as bool,
        allowGuestDownloads: json['allowGuestDownloads'] as bool,
        viewerIsHost: json['viewerIsHost'] as bool,
        hostDisplayName: json['hostDisplayName'] as String,
        coverUrl: json['coverUrl'] as String?,
        description: json['description'] as String?,
        uploadMode: PhotoUploadMode.fromApi(json['uploadMode'] as String? ?? 'Both'),
        brand: json['brand'] == null
            ? null
            : BrandProfile.fromJson(json['brand'] as Map<String, dynamic>),
        revealAt: json['revealAt'] == null ? null : DateTime.parse(json['revealAt'] as String).toLocal(),
        isDeveloping: json['isDeveloping'] as bool? ?? false,
        viewerUploadCount: json['viewerUploadCount'] as int? ?? 0,
        recapStatus: RecapStatus.fromApi(json['recapStatus'] as String?),
        recapUrl: json['recapUrl'] as String?,
        recapError: json['recapError'] as String?,
        challenge: json['challenge'] == null ? null : CircleChallenge.fromJson(json['challenge'] as Map<String, dynamic>),
        rules: (json['rules'] as List?)?.cast<String>() ?? const [],
      );
}
