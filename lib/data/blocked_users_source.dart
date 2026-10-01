import '../core/api_client.dart';
import '../core/token_store.dart';
import '../models/blocked_user.dart';
import 'http/http_profile_repository.dart';
import 'profile_repository.dart';

/// A block plus the identity that made it — unblocking has to go through that same identity.
class BlockedEntry {
  const BlockedEntry(this.user, this._owner);

  final BlockedUser user;
  final ProfileRepository _owner;

  Future<void> unblock() => _owner.unblock(user.id);
}

/// Everyone the user blocked, from every identity on this device: the host account, plus each
/// guest identity used in a circle joined via QR or Discover (blocks made there are scoped to that circle).
class BlockedUsersSource {
  const BlockedUsersSource({required this.hostRepository, this.apiClient, this.tokenStore = const TokenStore()});

  final ProfileRepository hostRepository;

  /// Null in design previews — then only the host repository is consulted.
  final ApiClient? apiClient;
  final TokenStore tokenStore;

  Future<List<BlockedEntry>> load() async {
    final entries = [for (final user in await hostRepository.fetchBlockedUsers()) BlockedEntry(user, hostRepository)];

    final client = apiClient;
    if (client != null) {
      for (final circleId in await tokenStore.readJoinedCircleIds()) {
        final token = await tokenStore.readGuestToken(circleId);
        if (token == null) continue;
        final guestRepository = HttpProfileRepository(ApiClient(baseUrl: client.dio.options.baseUrl, bearerToken: token));
        try {
          entries.addAll([for (final user in await guestRepository.fetchBlockedUsers()) BlockedEntry(user, guestRepository)]);
        } catch (_) {
          // That circle may be gone — its blocks went with it.
        }
      }
    }

    entries.sort((a, b) => b.user.blockedAt.compareTo(a.user.blockedAt));
    return entries;
  }
}
