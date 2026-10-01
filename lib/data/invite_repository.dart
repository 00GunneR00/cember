import '../models/invite_preview.dart';
import '../models/join_circle_result.dart';

abstract class InviteRepository {
  const InviteRepository();

  /// Circle info shown before the scanner commits to joining.
  Future<InvitePreview> preview(String token);

  Future<JoinCircleResult> join(String token, String displayName);
}

class MockInviteRepository extends InviteRepository {
  const MockInviteRepository();

  @override
  Future<InvitePreview> preview(String token) => throw UnimplementedError();

  @override
  Future<JoinCircleResult> join(String token, String displayName) => throw UnimplementedError();
}
