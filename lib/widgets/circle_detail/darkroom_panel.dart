import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/reveal_time.dart';
import '../../models/circle_detail.dart';
import '../../theme/app_theme.dart';

/// Shown instead of the photo feed while a Banyo circle is developing: how many shots are waiting,
/// a live countdown to the reveal, and (for the host) controls to reveal early or move the time.
class DarkroomPanel extends StatefulWidget {
  const DarkroomPanel({super.key, required this.detail, required this.onRevealTimeReached, this.onRevealNow, this.onChangeRevealTime});

  final CircleDetail detail;

  /// Fired once when the countdown hits zero, so the screen can reload the now-visible photos.
  final VoidCallback onRevealTimeReached;

  /// Host-only actions; null hides them.
  final VoidCallback? onRevealNow;
  final VoidCallback? onChangeRevealTime;

  @override
  State<DarkroomPanel> createState() => _DarkroomPanelState();
}

class _DarkroomPanelState extends State<DarkroomPanel> with SingleTickerProviderStateMixin {
  Timer? _ticker;
  bool _revealFired = false;
  late final AnimationController _glow = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void didUpdateWidget(DarkroomPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.detail.revealAt != widget.detail.revealAt) _revealFired = false;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _glow.dispose();
    super.dispose();
  }

  Duration get _remaining => (widget.detail.revealAt ?? DateTime.now()).difference(DateTime.now());

  void _tick() {
    if (!mounted) return;
    if (_remaining <= Duration.zero && !_revealFired) {
      _revealFired = true;
      // Give the server clock a moment past the reveal so the reload actually returns photos.
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) widget.onRevealTimeReached();
      });
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final detail = widget.detail;
    final revealAt = detail.revealAt;
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.marginMobile, AppSpacing.md, AppSpacing.marginMobile, 120),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(color: const Color(0xFF140A09), borderRadius: BorderRadius.circular(AppRadius.cardLarge)),
          child: Column(
            children: [
              // The red safelight of a darkroom, gently pulsing.
              AnimatedBuilder(
                animation: _glow,
                builder: (context, child) => Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF2A0F0C),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF3B2F).withValues(alpha: 0.25 + 0.35 * _glow.value),
                        blurRadius: 24 + 24 * _glow.value,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: child,
                ),
                child: const Icon(Icons.photo_filter, size: 40, color: Color(0xFFFF4FA8)),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                '${detail.memoryCount} kare banyoda',
                style: AppTextStyles.headlineLgMobile.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Fotoğraflar açılış anında herkese birlikte açılacak. O zamana kadar kimse göremez — sen de!',
                style: AppTextStyles.bodyMd.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              if (revealAt != null) ...[
                Text('AÇILIŞA', style: AppTextStyles.labelSm.copyWith(color: const Color(0xFFFF4FA8), letterSpacing: 2)),
                const SizedBox(height: 6),
                Text(
                  formatCountdown(_remaining),
                  style: AppTextStyles.headlineMd.copyWith(color: Colors.white, fontFeatures: const [FontFeature.tabularFigures()]),
                ),
                const SizedBox(height: 4),
                Text(formatRevealTime(revealAt), style: AppTextStyles.bodySm.copyWith(color: Colors.white60)),
              ],
              if (detail.viewerUploadCount > 0) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(AppRadius.pill)),
                  child: Text('Bunların ${detail.viewerUploadCount} tanesi senin 📸', style: AppTextStyles.labelMd.copyWith(color: Colors.white)),
                ),
              ],
            ],
          ),
        ),
        if (widget.onRevealNow != null || widget.onChangeRevealTime != null) ...[
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              if (widget.onChangeRevealTime != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.onChangeRevealTime,
                    icon: const Icon(Icons.schedule, size: 18),
                    label: const Text('Saati Değiştir'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.primary,
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                    ),
                  ),
                ),
              if (widget.onRevealNow != null && widget.onChangeRevealTime != null) const SizedBox(width: AppSpacing.xs),
              if (widget.onRevealNow != null)
                Expanded(
                  child: FilledButton.icon(
                    onPressed: widget.onRevealNow,
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('Şimdi Aç'),
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.secondary,
                      foregroundColor: colors.onSecondary,
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
