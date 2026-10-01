import 'circle_summary.dart';

class AlbumsOverview {
  const AlbumsOverview({required this.userName, required this.live, required this.past});

  final String userName;
  final List<CircleSummary> live;
  final List<CircleSummary> past;
}
