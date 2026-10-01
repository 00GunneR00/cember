import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class LiveDot extends StatelessWidget {
  const LiveDot({super.key, this.size = 10, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color ?? context.colors.onTertiaryContainer),
    );
  }
}
