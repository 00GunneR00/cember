import '../core/api_client.dart';
import '../core/google_auth.dart';
import '../core/token_store.dart';
import '../core/upload_policy.dart';
import 'profile_repository.dart';

/// Deletes the user's whole footprint: every guest identity this device used to join circles
/// (and what was posted through it), then the host account itself, then every credential on the device.
class AccountDeletion {
  const AccountDeletion({
    required this.apiClient,
    required this.profileRepository,
    this.tokenStore = const TokenStore(),
    this.uploadPolicy = const UploadPolicy(),
    this.googleAuth = const GoogleAuth(),
  });

  final ApiClient apiClient;
  final ProfileRepository profileRepository;
  final TokenStore tokenStore;
  final UploadPolicy uploadPolicy;
  final GoogleAuth googleAuth;

  /// Throws if the account itself couldn't be deleted — nothing local is cleared in that case,
  /// so the user is still signed in and can retry.
  Future<void> run() async {
    // Guest identities first: they're only reachable with their own tokens, which get wiped below.
    for (final circleId in await tokenStore.readJoinedCircleIds()) {
      final token = await tokenStore.readGuestToken(circleId);
      if (token == null) continue;
      try {
        await ApiClient(baseUrl: apiClient.dio.options.baseUrl, bearerToken: token).dio.delete('/me/guest-session');
      } catch (_) {
        // Already gone — e.g. that circle was deleted by its owner.
      }
    }

    await profileRepository.deleteAccount();

    await tokenStore.clearAll();
    await uploadPolicy.saveOnlyUploadOnWifi(false);
    await googleAuth.signOut();
  }
}
