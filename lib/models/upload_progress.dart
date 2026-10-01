class UploadProgress {
  const UploadProgress({required this.sentBytes, required this.totalBytes, this.done = false});

  final int sentBytes;
  final int totalBytes;
  final bool done;

  double get fraction => totalBytes == 0 ? 0 : sentBytes / totalBytes;
}
