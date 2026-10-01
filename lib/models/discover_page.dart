import 'public_circle_summary.dart';

class DiscoverPage {
  const DiscoverPage({required this.items, required this.nextCursor});

  final List<PublicCircleSummary> items;
  final String? nextCursor;

  factory DiscoverPage.fromJson(Map<String, dynamic> json) => DiscoverPage(
        items: (json['items'] as List).map((e) => PublicCircleSummary.fromJson(e as Map<String, dynamic>)).toList(),
        nextCursor: json['nextCursor'] as String?,
      );
}
