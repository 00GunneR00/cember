import 'package:flutter/material.dart';

import '../models/circle_summary.dart';
import '../theme/app_theme.dart';
import '../widgets/albums/live_circle_card.dart';
import '../widgets/albums/past_circle_card.dart';

/// A circle plus how to open it — own circles and circles joined as a guest open differently.
class CircleListEntry {
  const CircleListEntry({required this.circle, required this.onOpen});

  final CircleSummary circle;
  final VoidCallback onOpen;
}

/// Full-page list of circles, pushed from Albümler for "Tümü", "Daha Eski Anılar" and search.
class CircleListScreen extends StatefulWidget {
  const CircleListScreen({super.key, required this.title, required this.entries, required this.emptyMessage, this.grid = false, this.searchable = false});

  final String title;
  final List<CircleListEntry> entries;
  final String emptyMessage;

  /// Archive-style two-column grid instead of full-width live cards.
  final bool grid;

  /// Shows a search field that filters by circle name and description.
  final bool searchable;

  @override
  State<CircleListScreen> createState() => _CircleListScreenState();
}

class _CircleListScreenState extends State<CircleListScreen> {
  String _query = '';

  List<CircleListEntry> get _visibleEntries {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return widget.entries;
    return widget.entries.where((e) {
      final name = e.circle.name.toLowerCase();
      final description = e.circle.description?.toLowerCase() ?? '';
      return name.contains(query) || description.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final entries = _visibleEntries;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        title: widget.searchable
            ? TextField(
                autofocus: true,
                onChanged: (value) => setState(() => _query = value),
                style: AppTextStyles.bodyMd.copyWith(color: colors.onSurface),
                decoration: const InputDecoration(hintText: 'Çemberlerinde ara', border: InputBorder.none),
              )
            : Text(widget.title, style: AppTextStyles.headlineSm.copyWith(color: colors.primary)),
      ),
      body: entries.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  _query.trim().isEmpty ? widget.emptyMessage : '"${_query.trim()}" ile eşleşen çember yok.',
                  style: AppTextStyles.bodyMd.copyWith(color: colors.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : widget.grid
          ? GridView.count(
              padding: const EdgeInsets.all(AppSpacing.marginMobile),
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.gutterMobile,
              mainAxisSpacing: AppSpacing.gutterMobile,
              childAspectRatio: 0.78,
              children: [for (final e in entries) PastCircleCard(circle: e.circle, onTap: e.onOpen)],
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.marginMobile),
              children: [
                for (final e in entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: LiveCircleCard(circle: e.circle, onTap: e.onOpen),
                  ),
              ],
            ),
    );
  }
}
