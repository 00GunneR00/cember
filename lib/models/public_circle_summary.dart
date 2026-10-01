import 'brand_profile.dart';

class PublicCircleSummary {
  const PublicCircleSummary({
    required this.id,
    required this.name,
    required this.eventDate,
    required this.hostDisplayName,
    required this.photoCount,
    required this.participantCount,
    required this.coverUrl,
    this.description,
    this.brand,
  });

  final String id;
  final String name;
  final DateTime? eventDate;
  final String hostDisplayName;
  final int photoCount;
  final int participantCount;
  final String? coverUrl;
  final String? description;
  final BrandProfile? brand;

  factory PublicCircleSummary.fromJson(Map<String, dynamic> json) => PublicCircleSummary(
        id: json['id'] as String,
        name: json['name'] as String,
        eventDate: json['eventDate'] == null ? null : DateTime.parse(json['eventDate'] as String),
        hostDisplayName: json['hostDisplayName'] as String,
        photoCount: json['photoCount'] as int,
        participantCount: json['participantCount'] as int,
        coverUrl: json['coverUrl'] as String?,
        description: json['description'] as String?,
        brand: json['brand'] == null
            ? null
            : BrandProfile.fromJson(json['brand'] as Map<String, dynamic>),
      );
}
