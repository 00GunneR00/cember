import 'package:image_picker/image_picker.dart';

import '../models/brand_profile.dart';
import '../models/circle_comment.dart';
import '../models/circle_detail.dart';
import '../models/circle_photo.dart';
import '../models/deletion_request_status.dart';
import '../models/photo_page.dart';
import '../models/photo_source.dart';
import '../models/reaction_result.dart';
import '../models/report_reason.dart';

abstract class CircleDetailRepository {
  const CircleDetailRepository();

  Future<CircleDetail> fetch(String circleId);
  Future<PhotoPage> fetchPhotos(String circleId, {String? cursor, PhotoSource? source});
  Future<ReactionResult> toggleReaction(String circleId, String photoId);
  Future<CircleComment> addComment(String circleId, String photoId, String body);
  Future<DeletionRequestStatus> fetchDeletionStatus(String circleId);
  Future<DeletionRequestStatus> requestDeletion(String circleId);
  Future<DeletionRequestStatus> voteOnDeletion(String circleId, bool approve);
  Future<void> cancelDeletionRequest(String circleId);

  /// Sets (or replaces) the circle's cover photo. Works identically for open and locked circles.
  Future<CircleDetail> setCoverPhoto(String circleId, XFile file);

  /// Host only: queues (re)generation of the recap video.
  Future<CircleDetail> requestRecap(String circleId);

  /// Host only: reveals a developing (Banyo) circle's photos right now.
  Future<CircleDetail> revealNow(String circleId);

  /// Host only: moves a developing circle's reveal time.
  Future<CircleDetail> updateRevealAt(String circleId, DateTime revealAt);

  /// Host only: replaces the circle's rules (an empty list clears them).
  Future<CircleDetail> updateRules(String circleId, List<String> rules);

  /// Allowed for the uploader and the circle owner.
  Future<void> deletePhoto(String photoId);

  /// The photo disappears for the reporter right away.
  Future<void> reportPhoto(String photoId, ReportReason reason, {String? note});

  /// Hides everything the photo's uploader posts from the viewer.
  Future<void> blockUploader(String photoId);
}

/// Sample brand used by design-mode previews when a [MockCircleDetailRepository]
/// is constructed with `brand: sampleBrandProfile` to exercise the branded-circle UI.
final sampleBrandProfile = BrandProfile.fromJson({
  'id': 'mock-brand',
  'name': 'Nova Enerji',
  'logoUrl': null,
  'primaryColorHex': '#E8462F',
  'secondaryColorHex': '#1B1B1B',
});

class MockCircleDetailRepository extends CircleDetailRepository {
  const MockCircleDetailRepository({this.brand});

  /// Non-null only in previews that want to exercise the branded-circle UI —
  /// the default (unbranded) design-mode screens are unaffected.
  final BrandProfile? brand;

  @override
  Future<CircleDetail> fetch(String circleId) async {
    return CircleDetail(
      id: circleId,
      title: 'Karaköy Rooftop Lansman & Akustik Gece',
      eventDate: DateTime(2025, 5, 18),
      participantCount: 24,
      memoryCount: 6,
      isOpenJoin: true,
      autoPublish: true,
      allowGuestDownloads: true,
      viewerIsHost: true,
      hostDisplayName: 'Selin A. & Kolektif',
      coverUrl: null,
      brand: brand,
    );
  }

  @override
  Future<PhotoPage> fetchPhotos(String circleId, {String? cursor, PhotoSource? source}) async {
    CirclePhoto photo(String id, String uploader, int reactions, DateTime time) => CirclePhoto(
          id: id,
          uploader: uploader,
          reactionCount: reactions,
          viewerHasReacted: false,
          commentCount: 0,
          thumbnailUrl: '',
          createdAt: time,
          source: PhotoSource.gallery,
        );
    return PhotoPage(
      photos: [
        photo('mock-1', 'Ece K.', 34, DateTime(2025, 5, 18, 21, 14)),
        photo('mock-2', 'Selin A.', 42, DateTime(2025, 5, 18, 21, 5)),
        photo('mock-3', 'Mert', 19, DateTime(2025, 5, 18, 20, 48)),
        photo('mock-4', 'Deniz T.', 27, DateTime(2025, 5, 18, 20, 20)),
        photo('mock-5', 'Can Y.', 58, DateTime(2025, 5, 18, 21, 30)),
        photo('mock-6', 'Ayşe O.', 61, DateTime(2025, 5, 18, 19, 55)),
      ],
      nextCursor: null,
    );
  }

  @override
  Future<ReactionResult> toggleReaction(String circleId, String photoId) async {
    return const ReactionResult(reacted: true, reactionCount: 1);
  }

  @override
  Future<CircleComment> addComment(String circleId, String photoId, String body) async {
    return CircleComment(id: 'mock-comment', author: 'Sen', body: body, createdAt: DateTime.now());
  }

  @override
  Future<DeletionRequestStatus> fetchDeletionStatus(String circleId) async {
    return const DeletionRequestStatus(
      isPending: false,
      requestedByDisplayName: null,
      eligibleVoterCount: 0,
      requiredApprovals: 0,
      currentApprovals: 0,
      viewerIsEligible: false,
      viewerVote: null,
      deleted: false,
    );
  }

  @override
  Future<DeletionRequestStatus> requestDeletion(String circleId) async {
    return const DeletionRequestStatus(
      isPending: false,
      requestedByDisplayName: null,
      eligibleVoterCount: 0,
      requiredApprovals: 0,
      currentApprovals: 0,
      viewerIsEligible: false,
      viewerVote: null,
      deleted: true,
    );
  }

  @override
  Future<DeletionRequestStatus> voteOnDeletion(String circleId, bool approve) async {
    return DeletionRequestStatus(
      isPending: false,
      requestedByDisplayName: null,
      eligibleVoterCount: 1,
      requiredApprovals: 1,
      currentApprovals: 1,
      viewerIsEligible: true,
      viewerVote: approve,
      deleted: approve,
    );
  }

  @override
  Future<void> cancelDeletionRequest(String circleId) async {}

  @override
  Future<CircleDetail> setCoverPhoto(String circleId, XFile file) => fetch(circleId);

  @override
  Future<CircleDetail> requestRecap(String circleId) => fetch(circleId);

  @override
  Future<CircleDetail> revealNow(String circleId) => fetch(circleId);

  @override
  Future<CircleDetail> updateRevealAt(String circleId, DateTime revealAt) => fetch(circleId);

  @override
  Future<CircleDetail> updateRules(String circleId, List<String> rules) => fetch(circleId);

  @override
  Future<void> deletePhoto(String photoId) async {}

  @override
  Future<void> reportPhoto(String photoId, ReportReason reason, {String? note}) async {}

  @override
  Future<void> blockUploader(String photoId) async {}
}
