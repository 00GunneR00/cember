import 'package:get/get.dart';

import '../core/upload_policy.dart';
import '../data/profile_repository.dart';
import '../models/profile_collection.dart';
import '../models/user_profile.dart';

class ProfileController extends GetxController {
  ProfileController(this._repository, {UploadPolicy uploadPolicy = const UploadPolicy()}) : _uploadPolicy = uploadPolicy;

  final ProfileRepository _repository;
  final UploadPolicy _uploadPolicy;

  final loading = true.obs;
  final error = Rxn<String>();
  final profile = Rxn<UserProfile>();
  final favorites = Rxn<ProfileCollection>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      profile.value = await _repository.fetchProfile();
      await _uploadPolicy.saveOnlyUploadOnWifi(profile.value!.onlyUploadOnWifi);
      favorites.value = await _repository.fetchFavorites();
    } catch (_) {
      error.value = 'Profil yüklenemedi.';
    } finally {
      loading.value = false;
    }
  }

  Future<void> setOnlyUploadOnWifi(bool value) => _applyOptimistic(
        (current) => current.copyWith(onlyUploadOnWifi: value),
        () async {
          await _repository.updateOnlyUploadOnWifi(value);
          await _uploadPolicy.saveOnlyUploadOnWifi(value);
        },
      );

  /// Returns false when the new name couldn't be saved (the old name is restored).
  Future<bool> setDisplayName(String name) async {
    final current = profile.value;
    if (current == null) return false;
    profile.value = current.copyWith(name: name);
    try {
      await _repository.updateDisplayName(name);
      return true;
    } catch (_) {
      profile.value = current;
      return false;
    }
  }

  Future<void> setNotifyOnPhotoAdded(bool value) =>
      _applyOptimistic((current) => current.copyWith(notifyOnPhotoAdded: value), () => _repository.updateNotifyOnPhotoAdded(value));

  Future<void> setNotifyOnComment(bool value) =>
      _applyOptimistic((current) => current.copyWith(notifyOnComment: value), () => _repository.updateNotifyOnComment(value));

  Future<void> setNotifyOnReaction(bool value) =>
      _applyOptimistic((current) => current.copyWith(notifyOnReaction: value), () => _repository.updateNotifyOnReaction(value));

  Future<void> setNotifyOnGuestJoined(bool value) =>
      _applyOptimistic((current) => current.copyWith(notifyOnGuestJoined: value), () => _repository.updateNotifyOnGuestJoined(value));

  /// Applies [apply] to the profile immediately, then persists via [persist] — reverting on failure.
  Future<void> _applyOptimistic(UserProfile Function(UserProfile current) apply, Future<void> Function() persist) async {
    final current = profile.value;
    if (current == null) return;
    profile.value = apply(current);
    try {
      await persist();
    } catch (_) {
      profile.value = current;
    }
  }
}
