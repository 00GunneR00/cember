import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api_client.dart';
import '../../models/circle_comment.dart';
import '../../models/circle_detail.dart';
import '../../models/deletion_request_status.dart';
import '../../models/photo_page.dart';
import '../../models/photo_source.dart';
import '../../models/reaction_result.dart';
import '../../models/report_reason.dart';
import '../circle_detail_repository.dart';

class HttpCircleDetailRepository extends CircleDetailRepository {
  const HttpCircleDetailRepository(this._client);

  final ApiClient _client;

  @override
  Future<CircleDetail> fetch(String circleId) async {
    final response = await _client.dio.get('/circles/$circleId');
    return CircleDetail.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<PhotoPage> fetchPhotos(String circleId, {String? cursor, PhotoSource? source}) async {
    final response = await _client.dio.get(
      '/circles/$circleId/photos',
      queryParameters: {'pageSize': 40, 'cursor': ?cursor, 'source': ?source?.apiValue},
    );
    return PhotoPage.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<ReactionResult> toggleReaction(String circleId, String photoId) async {
    final response = await _client.dio.post('/photos/$photoId/reactions');
    return ReactionResult.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<CircleComment> addComment(String circleId, String photoId, String body) async {
    final response = await _client.dio.post('/photos/$photoId/comments', data: {'body': body});
    return CircleComment.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<DeletionRequestStatus> fetchDeletionStatus(String circleId) async {
    final response = await _client.dio.get('/circles/$circleId/deletion-request');
    return DeletionRequestStatus.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<DeletionRequestStatus> requestDeletion(String circleId) async {
    final response = await _client.dio.post('/circles/$circleId/deletion-request');
    return DeletionRequestStatus.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<DeletionRequestStatus> voteOnDeletion(String circleId, bool approve) async {
    final response = await _client.dio.post('/circles/$circleId/deletion-request/vote', data: {'approve': approve});
    return DeletionRequestStatus.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> cancelDeletionRequest(String circleId) async {
    await _client.dio.delete('/circles/$circleId/deletion-request');
  }

  @override
  Future<CircleDetail> setCoverPhoto(String circleId, XFile file) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: file.name),
    });
    final response = await _client.dio.post('/circles/$circleId/cover', data: formData);
    return CircleDetail.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<CircleDetail> requestRecap(String circleId) async {
    final response = await _client.dio.post('/circles/$circleId/recap');
    return CircleDetail.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<CircleDetail> revealNow(String circleId) async {
    await _client.dio.patch('/circles/$circleId', data: {'revealNow': true});
    // Re-fetch rather than use the PATCH response: it doesn't carry viewer-specific counts.
    return fetch(circleId);
  }

  @override
  Future<CircleDetail> updateRevealAt(String circleId, DateTime revealAt) async {
    await _client.dio.patch('/circles/$circleId', data: {'revealAt': revealAt.toUtc().toIso8601String()});
    return fetch(circleId);
  }

  @override
  Future<CircleDetail> updateRules(String circleId, List<String> rules) async {
    await _client.dio.patch('/circles/$circleId', data: {'rules': rules});
    // Re-fetch: the PATCH response doesn't carry viewer-specific fields.
    return fetch(circleId);
  }

  @override
  Future<void> deletePhoto(String photoId) async {
    await _client.dio.delete('/photos/$photoId');
  }

  @override
  Future<void> reportPhoto(String photoId, ReportReason reason, {String? note}) async {
    await _client.dio.post('/photos/$photoId/report', data: {'reason': reason.apiValue, 'note': note});
  }

  @override
  Future<void> blockUploader(String photoId) async {
    await _client.dio.post('/photos/$photoId/block-uploader');
  }
}
