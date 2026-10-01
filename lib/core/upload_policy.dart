import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Thrown when "Yalnızca Wi-Fi ile Yükle" is on and the device is not on Wi-Fi.
class WifiRequiredException implements Exception {
  const WifiRequiredException();

  static const message = 'Yalnızca Wi-Fi ile yükleme açık. Wi-Fi\'a bağlan ya da Profil\'den bu ayarı kapat.';

  @override
  String toString() => message;
}

/// Device-local copy of the host's "only upload on Wi-Fi" setting, so every upload —
/// including ones made with a guest token, which can't read the host profile — can honour it.
class UploadPolicy {
  const UploadPolicy({FlutterSecureStorage? storage, Connectivity? connectivity})
    : _storage = storage ?? const FlutterSecureStorage(),
      _connectivity = connectivity;

  final FlutterSecureStorage _storage;
  final Connectivity? _connectivity;

  static const _onlyWifiKey = 'cember_only_upload_on_wifi';

  Future<bool> readOnlyUploadOnWifi() async => await _storage.read(key: _onlyWifiKey) == 'true';

  Future<void> saveOnlyUploadOnWifi(bool value) => _storage.write(key: _onlyWifiKey, value: value.toString());

  /// Throws [WifiRequiredException] when uploads are restricted to Wi-Fi and the device isn't on one.
  Future<void> ensureUploadAllowed() async {
    if (!await readOnlyUploadOnWifi()) return;
    final results = await (_connectivity ?? Connectivity()).checkConnectivity();
    final onUnmeteredNetwork = results.contains(ConnectivityResult.wifi) || results.contains(ConnectivityResult.ethernet);
    if (!onUnmeteredNetwork) throw const WifiRequiredException();
  }
}
