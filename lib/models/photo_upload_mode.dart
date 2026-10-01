/// Which upload paths a circle accepts photos from — set by the owner at creation time.
enum PhotoUploadMode {
  quickCaptureOnly,
  galleryOnly,
  both;

  String get apiValue => switch (this) {
        PhotoUploadMode.quickCaptureOnly => 'QuickCaptureOnly',
        PhotoUploadMode.galleryOnly => 'GalleryOnly',
        PhotoUploadMode.both => 'Both',
      };

  bool get allowsQuickCapture => this != PhotoUploadMode.galleryOnly;
  bool get allowsGallery => this != PhotoUploadMode.quickCaptureOnly;

  static PhotoUploadMode fromApi(String value) => switch (value) {
        'QuickCaptureOnly' => PhotoUploadMode.quickCaptureOnly,
        'GalleryOnly' => PhotoUploadMode.galleryOnly,
        _ => PhotoUploadMode.both,
      };
}
