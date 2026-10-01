import 'package:image_picker/image_picker.dart';

import '../models/photo_source.dart';
import '../models/upload_progress.dart';

abstract class UploadRepository {
  const UploadRepository();

  Stream<UploadProgress> uploadPhotos(
    String circleId,
    List<XFile> files, {
    required PhotoSource source,
    bool commercialConsent = false,
  });
}

class MockUploadRepository extends UploadRepository {
  const MockUploadRepository();

  @override
  Stream<UploadProgress> uploadPhotos(
    String circleId,
    List<XFile> files, {
    required PhotoSource source,
    bool commercialConsent = false,
  }) async* {
    yield const UploadProgress(sentBytes: 1, totalBytes: 1, done: true);
  }
}
