import 'package:flutter/material.dart';

/// Wraps a circle's cover content (photo or placeholder) and, when [locked] is true,
/// desaturates it and lays a dark veil over it — a visual cue, independent of any
/// text badge, that the circle is invite-only.
class LockedCoverOverlay extends StatelessWidget {
  const LockedCoverOverlay({super.key, required this.locked, required this.child});

  final bool locked;
  final Widget child;

  static const _grayscale = <double>[
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 1, 0,
  ];

  @override
  Widget build(BuildContext context) {
    if (!locked) return child;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColorFiltered(colorFilter: const ColorFilter.matrix(_grayscale), child: child),
        const ColoredBox(color: Color.fromRGBO(0, 0, 0, 0.32)),
      ],
    );
  }
}
