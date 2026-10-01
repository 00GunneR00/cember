import 'circle_photo.dart';

class PhotoPage {
  const PhotoPage({required this.photos, required this.nextCursor});

  final List<CirclePhoto> photos;
  final String? nextCursor;

  factory PhotoPage.fromJson(Map<String, dynamic> json) => PhotoPage(
        photos: (json['photos'] as List).map((e) => CirclePhoto.fromJson(e as Map<String, dynamic>)).toList(),
        nextCursor: json['nextCursor'] as String?,
      );
}
