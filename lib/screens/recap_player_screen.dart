import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../core/circle_sharing.dart';
import '../theme/app_theme.dart';

/// Full-screen, looping playback of a circle's vertical recap video, with a share button.
class RecapPlayerScreen extends StatefulWidget {
  const RecapPlayerScreen({super.key, required this.videoUrl, required this.circleName});

  final String videoUrl;
  final String circleName;

  @override
  State<RecapPlayerScreen> createState() => _RecapPlayerScreenState();
}

class _RecapPlayerScreenState extends State<RecapPlayerScreen> {
  late final VideoPlayerController _video = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
  bool _failed = false;
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    _video
        .initialize()
        .then((_) {
          if (!mounted) return;
          _video
            ..setLooping(true)
            ..play();
          setState(() {});
        })
        .catchError((Object _) {
          if (mounted) setState(() => _failed = true);
        });
  }

  @override
  void dispose() {
    _video.dispose();
    super.dispose();
  }

  void _togglePlayback() {
    setState(() => _video.value.isPlaying ? _video.pause() : _video.play());
  }

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      await shareRecapVideo(videoUrl: widget.videoUrl, circleName: widget.circleName);
    } on ExportFailure catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final ready = _video.value.isInitialized;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.circleName, style: AppTextStyles.headlineSm.copyWith(color: Colors.white)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: _failed
                    ? Text('Video oynatılamadı.', style: AppTextStyles.bodyMd.copyWith(color: Colors.white70))
                    : !ready
                    ? const CircularProgressIndicator(color: Colors.white)
                    : GestureDetector(
                        onTap: _togglePlayback,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            AspectRatio(aspectRatio: _video.value.aspectRatio, child: VideoPlayer(_video)),
                            if (!_video.value.isPlaying) const Icon(Icons.play_circle_fill, size: 72, color: Colors.white70),
                          ],
                        ),
                      ),
              ),
            ),
            if (ready)
              VideoProgressIndicator(
                _video,
                allowScrubbing: true,
                colors: VideoProgressColors(playedColor: colors.secondary, backgroundColor: Colors.white24),
              ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.marginMobile),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _sharing || _failed ? null : _share,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.secondary,
                    foregroundColor: colors.onSecondary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                  ),
                  icon: _sharing
                      ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: colors.onSecondary))
                      : const Icon(Icons.ios_share),
                  label: Text(_sharing ? 'Hazırlanıyor…' : 'Paylaş', style: AppTextStyles.labelLg.copyWith(color: colors.onSecondary)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
