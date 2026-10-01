import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../models/blocked_user.dart';
import '../../models/circle_photo.dart';
import '../../models/profile_collection.dart';
import '../../models/user_profile.dart';
import '../profile_repository.dart';

class HttpProfileRepository extends ProfileRepository {
  const HttpProfileRepository(this._client);

  final ApiClient _client;

  @override
  Future<UserProfile> fetchProfile() async {
    final response = await _client.dio.get('/me');
    return UserProfile.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<ProfileCollection> fetchFavorites() async {
    final response = await _client.dio.get('/me/favorites', queryParameters: {'pageSize': 100});
    final json = response.data as Map<String, dynamic>;
    final photos = (json['photos'] as List).map((e) => CirclePhoto.fromJson(e as Map<String, dynamic>)).toList();
    return ProfileCollection(
      icon: Icons.favorite,
      title: 'Favorilerim',
      subtitle: 'Beğenilen fotoğraflar',
      count: photos.length,
      previewUrls: photos.take(3).map((p) => p.thumbnailUrl).toList(),
    );
  }

  @override
  Future<void> updateOnlyUploadOnWifi(bool value) async {
    await _client.dio.patch('/me/settings', data: {'onlyUploadOnWifi': value});
  }

  @override
  Future<void> updateNotifyOnPhotoAdded(bool value) async {
    await _client.dio.patch('/me/settings', data: {'notifyOnPhotoAdded': value});
  }

  @override
  Future<void> updateNotifyOnComment(bool value) async {
    await _client.dio.patch('/me/settings', data: {'notifyOnComment': value});
  }

  @override
  Future<void> updateNotifyOnReaction(bool value) async {
    await _client.dio.patch('/me/settings', data: {'notifyOnReaction': value});
  }

  @override
  Future<void> updateNotifyOnGuestJoined(bool value) async {
    await _client.dio.patch('/me/settings', data: {'notifyOnGuestJoined': value});
  }

  @override
  Future<void> updateDisplayName(String name) async {
    await _client.dio.patch('/me/settings', data: {'displayName': name});
  }

  @override
  Future<List<BlockedUser>> fetchBlockedUsers() async {
    final response = await _client.dio.get('/blocks');
    return (response.data as List).map((e) => BlockedUser.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> unblock(String blockId) async {
    await _client.dio.delete('/blocks/$blockId');
  }

  @override
  Future<void> deleteAccount() async {
    await _client.dio.delete('/me');
  }
}
