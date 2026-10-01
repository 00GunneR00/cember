import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/storage_image.dart';
import '../../theme/app_theme.dart';

class AppLogoMark extends StatelessWidget {
  const AppLogoMark({super.key, this.size = 32, this.showAccent = false, this.imageUrl});

  final double size;
  final bool showAccent;

  /// When set (a branded circle's logo), this image replaces the vector mark.
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (imageUrl != null) {
      return ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: CachedNetworkImage(
            imageUrl: imageUrl!,
            cacheKey: storageCacheKey(imageUrl!),
            fit: BoxFit.cover,
            errorWidget: (context, url, error) => _vectorMark(colors),
          ),
        ),
      );
    }
    return _vectorMark(colors);
  }

  Widget _vectorMark(AppColorTokens colors) {
    final ringSize = size * 0.56;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(shape: BoxShape.circle, color: colors.logoBackground),
          ),
          Icon(Icons.circle_outlined, color: colors.logoRing, size: ringSize),
          if (showAccent)
            Positioned(
              top: size * 0.06,
              right: size * 0.06,
              child: Container(
                width: size * 0.26,
                height: size * 0.26,
                decoration: BoxDecoration(shape: BoxShape.circle, color: colors.logoAccent),
              ),
            ),
        ],
      ),
    );
  }
}
