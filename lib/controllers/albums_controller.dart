import 'package:get/get.dart';

import '../core/api_errors.dart';
import '../data/albums_repository.dart';
import '../models/albums_overview.dart';
import '../models/joined_circle_summary.dart';
import '../models/photo_upload_mode.dart';

class AlbumsController extends GetxController {
  AlbumsController(this._repository);

  final AlbumsRepository _repository;

  final loading = true.obs;
  final error = Rxn<String>();
  final overview = Rxn<AlbumsOverview>();
  final joinedCircles = <JoinedCircleSummary>[].obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  /// [silent] refreshes in place — no full-screen spinner, and a failure keeps what's already shown.
  /// Used when coming back to Albümler, so a new cover or photo count just appears.
  Future<void> load({bool silent = false}) async {
    if (!silent) {
      loading.value = true;
      error.value = null;
    }
    try {
      overview.value = await _repository.fetch();
      joinedCircles.assignAll(await _repository.fetchJoinedCircles());
      error.value = null;
    } catch (_) {
      if (!silent) error.value = 'Çemberler yüklenemedi.';
    } finally {
      loading.value = false;
    }
  }

  /// Returns the new circle's id, or a user-facing error explaining why it couldn't be created.
  Future<({String? id, String? error})> createCircle(
    String name, {
    DateTime? eventDate,
    required bool isOpenJoin,
    String? description,
    PhotoUploadMode uploadMode = PhotoUploadMode.both,
    DateTime? revealAt,
    String? challengeTemplateId,
    List<String>? rules,
  }) async {
    try {
      final created = await _repository.createCircle(
        name,
        eventDate: eventDate,
        isOpenJoin: isOpenJoin,
        description: description,
        uploadMode: uploadMode,
        revealAt: revealAt,
        challengeTemplateId: challengeTemplateId,
        rules: rules,
      );
      await load(silent: true);
      return (id: created.id, error: null);
    } catch (e) {
      return (id: null, error: apiErrorMessage(e, 'Çember oluşturulamadı, tekrar dene.'));
    }
  }
}
