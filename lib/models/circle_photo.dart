import 'photo_source.dart';

class CirclePhoto {
  CirclePhoto({
    required this.id,
    required this.uploader,
    required this.reactionCount,
    required this.viewerHasReacted,
    required this.commentCount,
    required this.thumbnailUrl,
    required this.createdAt,
    required this.source,
    this.viewerCanDelete = false,
  });

  final String id;
  final String uploader;
  int reactionCount;
  bool viewerHasReacted;
  final int commentCount;
  final String thumbnailUrl;
  final DateTime createdAt;
  final PhotoSource source;

  /// The viewer uploaded it or owns the circle — offer "Sil" rather than "Şikayet Et".
  final bool viewerCanDelete;

  factory CirclePhoto.fromJson(Map<String, dynamic> json) => CirclePhoto(
        id: json['id'] as String,
        uploader: json['uploaderDisplayName'] as String,
        reactionCount: json['reactionCount'] as int,
        viewerHasReacted: json['viewerHasReacted'] as bool,
        commentCount: json['commentCount'] as int,
        thumbnailUrl: json['thumbnailUrl'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        source: PhotoSource.fromApi(json['source'] as String),
        viewerCanDelete: json['viewerCanDelete'] as bool? ?? false,
      );
}
