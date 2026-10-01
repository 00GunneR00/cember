/// Which upload path a specific photo came through.
enum PhotoSource {
  quickCapture,
  gallery;

  String get apiValue => switch (this) {
        PhotoSource.quickCapture => 'QuickCapture',
        PhotoSource.gallery => 'Gallery',
      };

  static PhotoSource fromApi(String value) => switch (value) {
        'QuickCapture' => PhotoSource.quickCapture,
        _ => PhotoSource.gallery,
      };
}
