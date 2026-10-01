import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../core/upload_policy.dart';
import '../data/photo_picker_service.dart';
import '../data/upload_repository.dart';
import '../models/photo_source.dart';

class AddPhotoController extends GetxController {
  AddPhotoController(this._pickerService, this._uploadRepository, this.circleId);

  final PhotoPickerService _pickerService;
  final UploadRepository _uploadRepository;
  final String circleId;

  final picked = <XFile>[].obs;
  final uploading = false.obs;
  final uploadFraction = 0.0.obs;
  final uploadDone = false.obs;
  final error = Rxn<String>();

  Future<void> pickFromGallery() async {
    final files = await _pickerService.pickFromGallery();
    picked.addAll(files);
  }

  Future<void> captureFromCamera() async {
    final file = await _pickerService.captureFromCamera();
    if (file != null) picked.add(file);
  }

  void remove(XFile file) => picked.remove(file);

  Future<bool> upload({bool commercialConsent = false}) async {
    if (picked.isEmpty) return false;
    uploading.value = true;
    uploadFraction.value = 0;
    uploadDone.value = false;
    error.value = null;
    try {
      await for (final progress in _uploadRepository.uploadPhotos(
        circleId,
        picked,
        source: PhotoSource.gallery,
        commercialConsent: commercialConsent,
      )) {
        uploadFraction.value = progress.fraction;
        if (progress.done) uploadDone.value = true;
      }
      return true;
    } on WifiRequiredException {
      error.value = WifiRequiredException.message;
      return false;
    } catch (_) {
      error.value = 'Yükleme başarısız oldu.';
      return false;
    } finally {
      uploading.value = false;
    }
  }
}
