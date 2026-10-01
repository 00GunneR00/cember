import 'circle_detail.dart';

class JoinCircleResult {
  const JoinCircleResult({required this.guestSessionToken, required this.circle});

  final String guestSessionToken;
  final CircleDetail circle;

  factory JoinCircleResult.fromJson(Map<String, dynamic> json) => JoinCircleResult(
        guestSessionToken: json['guestSessionToken'] as String,
        circle: CircleDetail.fromJson(json['circle'] as Map<String, dynamic>),
      );
}
