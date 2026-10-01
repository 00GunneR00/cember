class BlockedUser {
  const BlockedUser({required this.id, required this.displayName, required this.blockedAt, this.circleName});

  final String id;
  final String displayName;
  final DateTime blockedAt;

  /// Set when the block was made inside a circle joined as a guest — it only applies in that circle.
  final String? circleName;

  factory BlockedUser.fromJson(Map<String, dynamic> json) => BlockedUser(
    id: json['id'] as String,
    displayName: json['displayName'] as String,
    blockedAt: DateTime.parse(json['createdAt'] as String),
    circleName: json['circleName'] as String?,
  );
}
