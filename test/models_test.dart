import 'package:cember/core/api_errors.dart';
import 'package:cember/models/blocked_user.dart';
import 'package:cember/models/circle_detail.dart';
import 'package:cember/models/circle_photo.dart';
import 'package:cember/models/notification_type.dart';
import 'package:cember/models/recap_status.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> circleDetailJson([Map<String, dynamic> extra = const {}]) => {
      'id': 'c1',
      'name': 'Bodrum',
      'eventDate': null,
      'participantCount': 3,
      'memoryCount': 12,
      'isOpenJoin': false,
      'autoPublish': true,
      'allowGuestDownloads': true,
      'viewerIsHost': true,
      'hostDisplayName': 'Ali',
      'coverUrl': null,
      ...extra,
    };

void main() {
  test('CircleDetail reads Banyo and recap fields', () {
    final detail = CircleDetail.fromJson(circleDetailJson({
      'revealAt': '2026-09-28T07:00:00+00:00',
      'isDeveloping': true,
      'viewerUploadCount': 4,
      'recapStatus': 'Ready',
      'recapUrl': 'https://x/recap.mp4',
    }));
    expect(detail.isDeveloping, isTrue);
    expect(detail.viewerUploadCount, 4);
    expect(detail.revealAt!.isUtc, isFalse, reason: 'shown in local time');
    expect(detail.recapStatus, RecapStatus.ready);
    expect(detail.recapUrl, 'https://x/recap.mp4');
  });

  test('CircleDetail defaults stay sensible for older servers', () {
    final detail = CircleDetail.fromJson(circleDetailJson());
    expect(detail.isDeveloping, isFalse);
    expect(detail.recapStatus, RecapStatus.none);
  });

  test('RecapStatus knows which states are still rendering', () {
    expect(RecapStatus.fromApi('Pending').isInProgress, isTrue);
    expect(RecapStatus.fromApi('Processing').isInProgress, isTrue);
    expect(RecapStatus.fromApi('Failed').isInProgress, isFalse);
    expect(RecapStatus.fromApi(null), RecapStatus.none);
  });

  test('NotificationType understands the Banyo and recap notifications', () {
    expect(NotificationType.fromApi('PhotosRevealed'), NotificationType.photosRevealed);
    expect(NotificationType.fromApi('RecapReady'), NotificationType.recapReady);
  });

  test('CirclePhoto only allows deleting when the server says so', () {
    final json = {
      'id': 'p1',
      'uploaderDisplayName': 'Ayşe',
      'reactionCount': 0,
      'viewerHasReacted': false,
      'commentCount': 0,
      'thumbnailUrl': '',
      'createdAt': '2026-09-27T10:00:00Z',
      'source': 'Gallery',
    };
    expect(CirclePhoto.fromJson(json).viewerCanDelete, isFalse);
    expect(CirclePhoto.fromJson({...json, 'viewerCanDelete': true}).viewerCanDelete, isTrue);
  });

  test('BlockedUser keeps the circle a guest block applies to', () {
    final user = BlockedUser.fromJson({'id': 'b1', 'displayName': 'Kaba', 'createdAt': '2026-09-27T10:00:00Z', 'circleName': 'Bodrum'});
    expect(user.circleName, 'Bodrum');
  });

  test('apiErrorMessage prefers the server message', () {
    final withMessage = DioException(
      requestOptions: RequestOptions(),
      response: Response(requestOptions: RequestOptions(), statusCode: 400, data: {'message': 'Açılış zamanı ileride olmalı.'}),
    );
    expect(apiErrorMessage(withMessage, 'x'), 'Açılış zamanı ileride olmalı.');
    expect(apiErrorMessage(Exception('boom'), 'Yedek mesaj'), 'Yedek mesaj');
  });
}
