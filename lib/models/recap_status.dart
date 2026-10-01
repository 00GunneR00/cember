/// Mirrors the backend's RecapLimits.MinPhotoCount.
const recapMinPhotoCount = 3;

/// Lifecycle of a circle's auto-generated recap video.
enum RecapStatus {
  none,
  pending,
  processing,
  ready,
  failed;

  bool get isInProgress => this == RecapStatus.pending || this == RecapStatus.processing;

  static RecapStatus fromApi(String? value) => switch (value) {
    'Pending' => RecapStatus.pending,
    'Processing' => RecapStatus.processing,
    'Ready' => RecapStatus.ready,
    'Failed' => RecapStatus.failed,
    _ => RecapStatus.none,
  };
}
