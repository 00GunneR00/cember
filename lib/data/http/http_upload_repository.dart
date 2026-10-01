import 'dart:async';

import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api_client.dart';
import '../../core/upload_policy.dart';
import '../../models/photo_source.dart';
import '../../models/upload_progress.dart';
import '../upload_repository.dart';

class HttpUploadRepository extends UploadRepository {
  const HttpUploadRepository(this._client, {UploadPolicy uploadPolicy = const UploadPolicy()}) : _uploadPolicy = uploadPolicy;

  final ApiClient _client;
  final UploadPolicy _uploadPolicy;

  @override
  Stream<UploadProgress> uploadPhotos(
    String circleId,
    List<XFile> files, {
    required PhotoSource source,
    bool commercialConsent = false,
  }) {
    final controller = StreamController<UploadProgress>();
    unawaited(_run(circleId, files, source, commercialConsent, controller));
    return controller.stream;
  }

  Future<void> _run(
    String circleId,
    List<XFile> files,
    PhotoSource source,
    bool commercialConsent,
    StreamController<UploadProgress> controller,
  ) async {
    try {
      await _uploadPolicy.ensureUploadAllowed();
      final formData = FormData();
      formData.fields.add(MapEntry('source', source.apiValue));
      formData.fields.add(MapEntry('commercialConsent', commercialConsent.toString()));
      for (final file in files) {
        formData.files.add(MapEntry('files', await MultipartFile.fromFile(file.path, filename: file.name)));
      }
      await _client.dio.post(
        '/circles/$circleId/photos',
        data: formData,
        onSendProgress: (sent, total) {
          if (total > 0) controller.add(UploadProgress(sentBytes: sent, totalBytes: total));
        },
      );
      controller.add(const UploadProgress(sentBytes: 1, totalBytes: 1, done: true));
    } catch (e) {
      controller.addError(e);
    } finally {
      await controller.close();
    }
  }
}
