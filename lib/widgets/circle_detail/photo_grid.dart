import 'package:flutter/material.dart';

import '../../models/circle_photo.dart';
import '../../theme/app_theme.dart';
import 'photo_tile.dart';

class PhotoGrid extends StatelessWidget {
  const PhotoGrid({super.key, required this.column1, required this.column2, required this.onReact, required this.onMore});

  final List<CirclePhoto> column1;
  final List<CirclePhoto> column2;
  final ValueChanged<CirclePhoto> onReact;
  final ValueChanged<CirclePhoto> onMore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Column(children: column1.map((p) => PhotoTile(photo: p, onReact: () => onReact(p), onMore: () => onMore(p))).toList())),
          const SizedBox(width: 8),
          Expanded(child: Column(children: column2.map((p) => PhotoTile(photo: p, onReact: () => onReact(p), onMore: () => onMore(p))).toList())),
        ],
      ),
    );
  }
}
