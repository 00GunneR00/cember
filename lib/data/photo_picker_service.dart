import 'package:image_picker/image_picker.dart';

abstract class PhotoPickerService {
  const PhotoPickerService();

  Future<List<XFile>> pickFromGallery();
  Future<XFile?> captureFromCamera();
  Future<XFile?> pickSingleFromGallery();
}

class MockPhotoPickerService extends PhotoPickerService {
  const MockPhotoPickerService();

  @override
  Future<List<XFile>> pickFromGallery() async => const [];

  @override
  Future<XFile?> captureFromCamera() async => null;

  @override
  Future<XFile?> pickSingleFromGallery() async => null;
}

class ImagePickerPhotoPickerService extends PhotoPickerService {
  const ImagePickerPhotoPickerService();

  @override
  Future<List<XFile>> pickFromGallery() {
    return ImagePicker().pickMultiImage(imageQuality: 90);
  }

  @override
  Future<XFile?> captureFromCamera() {
    return ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 90);
  }

  @override
  Future<XFile?> pickSingleFromGallery() {
    return ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 90);
  }
}
