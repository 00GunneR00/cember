import 'brand_profile.dart';

class InvitePreview {
  const InvitePreview({
    required this.circleName,
    required this.eventDate,
    required this.coverUrl,
    required this.hostDisplayName,
    this.brand,
  });

  final String circleName;
  final DateTime? eventDate;
  final String? coverUrl;
  final String hostDisplayName;
  final BrandProfile? brand;

  factory InvitePreview.fromJson(Map<String, dynamic> json) => InvitePreview(
        circleName: json['circleName'] as String,
        eventDate: json['eventDate'] == null ? null : DateTime.parse(json['eventDate'] as String),
        coverUrl: json['coverUrl'] as String?,
        hostDisplayName: json['hostDisplayName'] as String,
        brand: json['brand'] == null
            ? null
            : BrandProfile.fromJson(json['brand'] as Map<String, dynamic>),
      );
}
