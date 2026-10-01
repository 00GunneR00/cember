import 'dart:async';

import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../core/api_errors.dart';
import '../data/circle_detail_repository.dart';
import '../models/circle_detail.dart';
import '../models/circle_photo.dart';
import '../models/deletion_request_status.dart';
import '../models/photo_source.dart';
import '../models/photo_upload_mode.dart';
import '../models/report_reason.dart';
import 'albums_controller.dart';
import 'photo_feed.dart';

class CircleDetailController extends GetxController {
  CircleDetailController(this._repository, this.circleId);

  final CircleDetailRepository _repository;
  final String circleId;

  final loading = true.obs;
  final error = Rxn<String>();
  final detail = Rxn<CircleDetail>();
  final deletionStatus = Rxn<DeletionRequestStatus>();
  final deletionActionError = Rxn<String>();
  final coverUploading = false.obs;
  final coverError = Rxn<String>();

  /// Used when the circle only accepts one upload source (nothing to split).
  late final PhotoFeed allFeed = PhotoFeed(({cursor}) => _repository.fetchPhotos(circleId, cursor: cursor));

  /// Used side by side, only when [CircleDetail.uploadMode] is [PhotoUploadMode.both].
  late final PhotoFeed quickCaptureFeed =
      PhotoFeed(({cursor}) => _repository.fetchPhotos(circleId, cursor: cursor, source: PhotoSource.quickCapture));
  late final PhotoFeed galleryFeed =
      PhotoFeed(({cursor}) => _repository.fetchPhotos(circleId, cursor: cursor, source: PhotoSource.gallery));

  /// Re-fetches the detail while the recap video is being rendered, so it appears without a manual refresh.
  Timer? _recapPoll;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    _recapPoll?.cancel();
    super.onClose();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      final fetchedDetail = await _repository.fetch(circleId);
      detail.value = fetchedDetail;
      // While developing the server returns no photos anyway — skip the feed requests.
      if (!fetchedDetail.isDeveloping) {
        if (fetchedDetail.uploadMode == PhotoUploadMode.both) {
          await Future.wait([quickCaptureFeed.load(), galleryFeed.load()]);
        } else {
          await allFeed.load();
        }
      }
      deletionStatus.value = await _repository.fetchDeletionStatus(circleId);
    } catch (_) {
      error.value = 'Çember yüklenemedi.';
    } finally {
      loading.value = false;
      _syncRecapPolling();
    }
  }

  void _syncRecapPolling() {
    if (detail.value?.recapStatus.isInProgress ?? false) {
      _recapPoll ??= Timer.periodic(const Duration(seconds: 5), (_) => _refreshDetailQuietly());
    } else {
      _recapPoll?.cancel();
      _recapPoll = null;
    }
  }

  Future<void> _refreshDetailQuietly() async {
    try {
      detail.value = await _repository.fetch(circleId);
    } catch (_) {
      // Transient — the next tick retries.
    }
    _syncRecapPolling();
  }

  /// Returns a user-facing error, or null on success.
  Future<String?> requestRecap() => _detailAction(() => _repository.requestRecap(circleId), 'Özet video başlatılamadı.');

  /// Returns a user-facing error, or null on success. Reloads everything, since photos just became visible.
  Future<String?> revealNow() async {
    final failure = await _detailAction(() => _repository.revealNow(circleId), 'Fotoğraflar açılamadı.');
    if (failure == null) await load();
    return failure;
  }

  /// Returns a user-facing error, or null on success.
  Future<String?> updateRules(List<String> rules) =>
      _detailAction(() => _repository.updateRules(circleId, rules), 'Kurallar kaydedilemedi.');

  /// Returns a user-facing error, or null on success.
  Future<String?> updateRevealAt(DateTime revealAt) =>
      _detailAction(() => _repository.updateRevealAt(circleId, revealAt), 'Açılış zamanı değiştirilemedi.');

  Future<String?> _detailAction(Future<CircleDetail> Function() action, String fallback) async {
    try {
      detail.value = await action();
      _syncRecapPolling();
      return null;
    } catch (e) {
      return apiErrorMessage(e, fallback);
    }
  }

  Future<void> toggleReaction(CirclePhoto photo) async {
    final previousReacted = photo.viewerHasReacted;
    final previousCount = photo.reactionCount;
    photo.viewerHasReacted = !previousReacted;
    photo.reactionCount += photo.viewerHasReacted ? 1 : -1;
    _refreshFeedsFor(photo.id);
    try {
      final result = await _repository.toggleReaction(circleId, photo.id);
      photo.viewerHasReacted = result.reacted;
      photo.reactionCount = result.reactionCount;
    } catch (_) {
      photo.viewerHasReacted = previousReacted;
      photo.reactionCount = previousCount;
    } finally {
      _refreshFeedsFor(photo.id);
    }
  }

  /// Returns a user-facing error, or null on success.
  Future<String?> deletePhoto(CirclePhoto photo) async {
    try {
      await _repository.deletePhoto(photo.id);
      _removeFromFeeds((p) => p.id == photo.id);
      // Photo count changes, and the recap video may now be re-rendering without this photo.
      unawaited(_refreshDetailQuietly());
      return null;
    } catch (e) {
      return apiErrorMessage(e, 'Fotoğraf silinemedi.');
    }
  }

  /// Returns a user-facing error, or null on success. The photo disappears for the reporter right away.
  Future<String?> reportPhoto(CirclePhoto photo, ReportReason reason, {String? note}) async {
    try {
      await _repository.reportPhoto(photo.id, reason, note: note);
      _removeFromFeeds((p) => p.id == photo.id);
      unawaited(_refreshDetailQuietly());
      return null;
    } catch (e) {
      return apiErrorMessage(e, 'Şikayet gönderilemedi.');
    }
  }

  /// Returns a user-facing error, or null on success. Everything by that uploader disappears for the viewer.
  Future<String?> blockUploader(CirclePhoto photo) async {
    try {
      await _repository.blockUploader(photo.id);
      // Display names aren't unique, so reload rather than guess which photos share the uploader.
      await load();
      return null;
    } catch (e) {
      return apiErrorMessage(e, 'Kişi engellenemedi.');
    }
  }

  void _removeFromFeeds(bool Function(CirclePhoto photo) test) {
    allFeed.removeWhere(test);
    quickCaptureFeed.removeWhere(test);
    galleryFeed.removeWhere(test);
  }

  void _refreshFeedsFor(String photoId) {
    allFeed.refreshIfPresent(photoId);
    quickCaptureFeed.refreshIfPresent(photoId);
    galleryFeed.refreshIfPresent(photoId);
  }

  Future<bool> addComment(String photoId, String body) async {
    try {
      await _repository.addComment(circleId, photoId, body);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestDeletion() async {
    deletionActionError.value = null;
    try {
      final status = await _repository.requestDeletion(circleId);
      deletionStatus.value = status;
      return status.deleted;
    } catch (_) {
      deletionActionError.value = 'Silme talebi gönderilemedi.';
      return false;
    }
  }

  Future<bool> vote(bool approve) async {
    deletionActionError.value = null;
    try {
      final status = await _repository.voteOnDeletion(circleId, approve);
      deletionStatus.value = status;
      return status.deleted;
    } catch (_) {
      deletionActionError.value = 'Oy gönderilemedi.';
      return false;
    }
  }

  Future<void> cancelDeletionRequest() async {
    deletionActionError.value = null;
    try {
      await _repository.cancelDeletionRequest(circleId);
      deletionStatus.value = await _repository.fetchDeletionStatus(circleId);
    } catch (_) {
      deletionActionError.value = 'Silme talebi iptal edilemedi.';
    }
  }

  Future<bool> setCoverPhoto(XFile file) async {
    coverUploading.value = true;
    coverError.value = null;
    try {
      detail.value = await _repository.setCoverPhoto(circleId, file);
      // Albümler shows the cover too — refresh it now so it's already there on the way back.
      if (Get.isRegistered<AlbumsController>(tag: 'albums')) {
        unawaited(Get.find<AlbumsController>(tag: 'albums').load(silent: true));
      }
      return true;
    } catch (_) {
      coverError.value = 'Kapak fotoğrafı güncellenemedi.';
      return false;
    } finally {
      coverUploading.value = false;
    }
  }
}
