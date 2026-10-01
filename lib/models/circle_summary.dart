import 'brand_profile.dart';
import 'photo_upload_mode.dart';

class CircleSummary {
  const CircleSummary({
    required this.id,
    required this.name,
    required this.eventDate,
    required this.isArchived,
    required this.isOpenJoin,
    required this.photoCount,
    required this.participantCount,
    required this.coverUrl,
    this.description,
    this.uploadMode = PhotoUploadMode.both,
    this.brand,
    this.revealAt,
    this.isDeveloping = false,
  });

  final String id;
  final String name;
  final DateTime? eventDate;
  final bool isArchived;
  final bool isOpenJoin;
  final int photoCount;
  final int participantCount;
  final String? coverUrl;
  final String? description;
  final PhotoUploadMode uploadMode;
  final BrandProfile? brand;

  /// Banyo modu: photos stay hidden from everyone until this moment.
  final DateTime? revealAt;
  final bool isDeveloping;

  factory CircleSummary.fromJson(Map<String, dynamic> json) => CircleSummary(
        id: json['id'] as String,
        name: json['name'] as String,
        eventDate: json['eventDate'] == null ? null : DateTime.parse(json['eventDate'] as String),
        isArchived: json['isArchived'] as bool,
        isOpenJoin: json['isOpenJoin'] as bool,
        photoCount: json['photoCount'] as int,
        participantCount: json['participantCount'] as int,
        coverUrl: json['coverUrl'] as String?,
        description: json['description'] as String?,
        uploadMode: PhotoUploadMode.fromApi(json['uploadMode'] as String? ?? 'Both'),
        brand: json['brand'] == null
            ? null
            : BrandProfile.fromJson(json['brand'] as Map<String, dynamic>),
        revealAt: json['revealAt'] == null ? null : DateTime.parse(json['revealAt'] as String).toLocal(),
        isDeveloping: json['isDeveloping'] as bool? ?? false,
      );
}
