import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStore {
  const TokenStore({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _apiKeyKey = 'cember_host_api_key';

  Future<String?> readApiKey() => _storage.read(key: _apiKeyKey);

  Future<void> saveApiKey(String apiKey) => _storage.write(key: _apiKeyKey, value: apiKey);

  Future<void> clear() => _storage.delete(key: _apiKeyKey);

  /// Guest-session tokens obtained by joining another host's open circle from Discover.
  /// Kept separate from the host's own apiKey so the two identities never mix on one request.
  String _guestKey(String circleId) => 'cember_guest_token_$circleId';

  Future<String?> readGuestToken(String circleId) => _storage.read(key: _guestKey(circleId));

  Future<void> saveGuestToken(String circleId, String token) => _storage.write(key: _guestKey(circleId), value: token);

  /// Circles joined as a guest via Discover — shown in the host's own "Çemberlerim" list
  /// alongside the circles they own.
  static const _joinedCircleIdsKey = 'cember_joined_circle_ids';

  Future<List<String>> readJoinedCircleIds() async {
    final raw = await _storage.read(key: _joinedCircleIdsKey);
    if (raw == null || raw.isEmpty) return const [];
    return (jsonDecode(raw) as List).cast<String>();
  }

  Future<void> addJoinedCircleId(String circleId) async {
    final ids = await readJoinedCircleIds();
    if (ids.contains(circleId)) return;
    await _storage.write(key: _joinedCircleIdsKey, value: jsonEncode([...ids, circleId]));
  }

  /// Removes every credential on this device — the host key and all guest tokens. Used after account deletion.
  Future<void> clearAll() async {
    for (final circleId in await readJoinedCircleIds()) {
      await _storage.delete(key: _guestKey(circleId));
    }
    await _storage.delete(key: _joinedCircleIdsKey);
    await clear();
  }
}
