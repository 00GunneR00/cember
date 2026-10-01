import '../../core/api_client.dart';
import '../../models/brand_profile.dart';
import '../../models/qr_invite_info.dart';
import '../qr_invite_repository.dart';

class HttpQrInviteRepository extends QrInviteRepository {
  const HttpQrInviteRepository(this._client);

  final ApiClient _client;

  BrandProfile? _brandFrom(Map<String, dynamic> circleJson) => circleJson['brand'] == null
      ? null
      : BrandProfile.fromJson(circleJson['brand'] as Map<String, dynamic>);

  @override
  Future<QrInviteInfo> fetch(String circleId) async {
    final responses = await Future.wait([
      _client.dio.get('/circles/$circleId/invite'),
      _client.dio.get('/circles/$circleId'),
    ]);
    final inviteJson = responses[0].data as Map<String, dynamic>;
    final circleJson = responses[1].data as Map<String, dynamic>;
    return QrInviteInfo.fromInviteJson(
      inviteJson,
      eventName: circleJson['name'] as String,
      brand: _brandFrom(circleJson),
    );
  }

  @override
  Future<QrInviteInfo> rotate(String circleId) async {
    final responses = await Future.wait([
      _client.dio.post('/circles/$circleId/invite'),
      _client.dio.get('/circles/$circleId'),
    ]);
    final inviteJson = responses[0].data as Map<String, dynamic>;
    final circleJson = responses[1].data as Map<String, dynamic>;
    return QrInviteInfo.fromInviteJson(
      inviteJson,
      eventName: circleJson['name'] as String,
      brand: _brandFrom(circleJson),
    );
  }

  @override
  Future<void> updateModeration(String circleId, {bool? autoPublish, bool? allowGuestDownloads}) async {
    await _client.dio.patch('/circles/$circleId', data: {
      'autoPublish': ?autoPublish,
      'allowGuestDownloads': ?allowGuestDownloads,
    });
  }
}
