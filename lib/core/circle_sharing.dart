import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'api_client.dart';

/// Opens the system share sheet with a circle's invite link. [message] replaces the default invitation text.
Future<void> shareInviteLink({required String eventName, required String inviteUrl, String? message}) async {
  final text = message ?? '"$eventName" çemberine katıl ve anıları birlikte biriktirelim:';
  await SharePlus.instance.share(ShareParams(text: '$text $inviteUrl', subject: eventName));
}

/// Downloads every photo of a circle as one ZIP, then hands it to the share sheet so the
/// user can save it to Files / Drive or send it on. Throws [ExportFailure] on failure.
Future<void> exportCircleZip(ApiClient client, {required String circleId, required String circleName}) async {
  final dir = await getTemporaryDirectory();
  final safeName = circleName.replaceAll(RegExp(r'[^\wçğıöşüÇĞİÖŞÜ -]'), '').trim();
  final file = File('${dir.path}/${safeName.isEmpty ? 'cember' : safeName}.zip');
  try {
    await client.dio.download('/circles/$circleId/export.zip', file.path, options: Options(receiveTimeout: const Duration(minutes: 10)));
  } on DioException catch (e) {
    if (e.response?.statusCode == 403) throw const ExportFailure('Bu çemberde misafir indirmeleri kapalı.');
    throw const ExportFailure('Albüm indirilemedi, tekrar dene.');
  }
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path, mimeType: 'application/zip')],
      subject: circleName,
    ),
  );
}

/// Downloads a recap video and hands it to the share sheet (Instagram, WhatsApp, Drive…).
/// The URL is presigned, so no auth header is needed. Throws [ExportFailure] on failure.
Future<void> shareRecapVideo({required String videoUrl, required String circleName}) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/cember_ozet_${DateTime.now().millisecondsSinceEpoch}.mp4');
  try {
    await Dio().download(videoUrl, file.path);
  } on DioException {
    throw const ExportFailure('Video indirilemedi, tekrar dene.');
  }
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path, mimeType: 'video/mp4')],
      text: '"$circleName" 🎬 Çember ile yapıldı',
    ),
  );
}

class ExportFailure implements Exception {
  const ExportFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
