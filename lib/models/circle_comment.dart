class CircleComment {
  const CircleComment({required this.id, required this.author, required this.body, required this.createdAt});

  final String id;
  final String author;
  final String body;
  final DateTime createdAt;

  factory CircleComment.fromJson(Map<String, dynamic> json) => CircleComment(
        id: json['id'] as String,
        author: json['authorDisplayName'] as String,
        body: json['body'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
