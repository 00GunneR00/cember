import 'circle_summary.dart';

/// A circle the viewer joined as a guest (via Discover), paired with the guest-session
/// token needed to act inside it — kept separate from the host's own identity.
class JoinedCircleSummary {
  const JoinedCircleSummary({required this.circle, required this.guestToken});

  final CircleSummary circle;
  final String guestToken;
}
