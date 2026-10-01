import 'package:cember/data/blocked_users_source.dart';
import 'package:cember/data/profile_repository.dart';
import 'package:cember/models/blocked_user.dart';
import 'package:cember/models/circle_detail.dart';
import 'package:cember/models/circle_photo.dart';
import 'package:cember/models/circle_summary.dart';
import 'package:cember/models/photo_source.dart';
import 'package:cember/models/recap_status.dart';
import 'package:cember/models/report_reason.dart';
import 'package:cember/screens/blocked_users_screen.dart';
import 'package:cember/screens/circle_list_screen.dart';
import 'package:cember/theme/app_theme.dart';
import 'package:cember/widgets/circle_detail/darkroom_panel.dart';
import 'package:cember/widgets/circle_detail/photo_actions_sheet.dart';
import 'package:cember/widgets/circle_detail/recap_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => MaterialApp(theme: AppTheme.light, home: Scaffold(body: child));

CircleDetail _detail({
  bool viewerIsHost = true,
  int memoryCount = 5,
  RecapStatus recapStatus = RecapStatus.none,
  bool isDeveloping = false,
  DateTime? revealAt,
  int viewerUploadCount = 0,
}) =>
    CircleDetail(
      id: 'c1',
      title: 'Bodrum',
      eventDate: null,
      participantCount: 3,
      memoryCount: memoryCount,
      isOpenJoin: false,
      autoPublish: true,
      allowGuestDownloads: true,
      viewerIsHost: viewerIsHost,
      hostDisplayName: 'Ali',
      coverUrl: null,
      recapStatus: recapStatus,
      isDeveloping: isDeveloping,
      revealAt: revealAt,
      viewerUploadCount: viewerUploadCount,
    );

CirclePhoto _photo({required bool canDelete}) => CirclePhoto(
      id: 'p1',
      uploader: 'Ayşe',
      reactionCount: 0,
      viewerHasReacted: false,
      commentCount: 0,
      thumbnailUrl: '',
      createdAt: DateTime(2026, 9, 27),
      source: PhotoSource.gallery,
      viewerCanDelete: canDelete,
    );

void main() {
  group('RecapCard', () {
    test('shows for hosts with enough photos, or once a recap exists', () {
      expect(RecapCard.shouldShow(_detail(memoryCount: 3)), isTrue);
      expect(RecapCard.shouldShow(_detail(memoryCount: 2)), isFalse);
      expect(RecapCard.shouldShow(_detail(viewerIsHost: false, memoryCount: 10)), isFalse);
      expect(RecapCard.shouldShow(_detail(viewerIsHost: false, recapStatus: RecapStatus.ready)), isTrue);
    });

    testWidgets('plays when ready and creates when there is none', (tester) async {
      var played = 0, created = 0;
      await tester.pumpWidget(_app(RecapCard(detail: _detail(recapStatus: RecapStatus.ready), onCreate: () => created++, onPlay: () => played++)));
      expect(find.text('Özet videon hazır'), findsOneWidget);
      await tester.tap(find.text('Özet videon hazır'));
      expect(played, 1);

      await tester.pumpWidget(_app(RecapCard(detail: _detail(), onCreate: () => created++, onPlay: () => played++)));
      await tester.tap(find.text('Özet video oluştur'));
      expect(created, 1);
    });
  });

  group('DarkroomPanel', () {
    testWidgets('counts the hidden shots and only gives the host the reveal controls', (tester) async {
      final detail = _detail(isDeveloping: true, memoryCount: 23, viewerUploadCount: 4, revealAt: DateTime.now().add(const Duration(hours: 5)));

      await tester.pumpWidget(_app(DarkroomPanel(detail: detail, onRevealTimeReached: () {}, onRevealNow: () {}, onChangeRevealTime: () {})));
      expect(find.text('23 kare banyoda'), findsOneWidget);
      expect(find.textContaining('4 tanesi senin'), findsOneWidget);
      expect(find.text('Şimdi Aç'), findsOneWidget);

      await tester.pumpWidget(_app(DarkroomPanel(detail: detail, onRevealTimeReached: () {})));
      expect(find.text('Şimdi Aç'), findsNothing);

      await tester.pumpWidget(const SizedBox()); // stop the countdown timer
    });

    testWidgets('asks for a reload once the countdown reaches zero', (tester) async {
      var reloads = 0;
      // The panel reads the real clock while the test drives fake time, so use a reveal that's already due.
      final detail = _detail(isDeveloping: true, revealAt: DateTime.now().subtract(const Duration(seconds: 1)));
      await tester.pumpWidget(_app(DarkroomPanel(detail: detail, onRevealTimeReached: () => reloads++)));

      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 3));
      expect(reloads, 1);

      await tester.pump(const Duration(seconds: 3));
      expect(reloads, 1, reason: 'fires once, not on every tick');
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('Photo actions', () {
    Future<void> open(WidgetTester tester, CirclePhoto photo, {List<String>? log}) async {
      await tester.pumpWidget(_app(Builder(
        builder: (context) => TextButton(
          onPressed: () => showPhotoActions(
            context,
            photo: photo,
            onDelete: () async {
              log?.add('delete');
              return null;
            },
            onReport: (reason, note) async {
              log?.add('report:${reason.apiValue}');
              return null;
            },
            onBlock: () async {
              log?.add('block');
              return null;
            },
          ),
          child: const Text('⋯'),
        ),
      )));
      await tester.tap(find.text('⋯'));
      await tester.pumpAndSettle();
    }

    testWidgets('your own photo offers delete, not report', (tester) async {
      await open(tester, _photo(canDelete: true));
      expect(find.text('Fotoğrafı Sil'), findsOneWidget);
      expect(find.text('Şikayet Et'), findsNothing);
    });

    testWidgets("someone else's photo can be reported with a reason", (tester) async {
      final log = <String>[];
      await open(tester, _photo(canDelete: false), log: log);
      expect(find.text('Ayşe kişisini engelle'), findsOneWidget);

      await tester.tap(find.text('Şikayet Et'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(ReportReason.privacy.label));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Şikayeti Gönder'));
      await tester.pumpAndSettle();

      expect(log, ['report:Privacy']);
      expect(find.textContaining('şikayetin alındı'), findsOneWidget);
    });
  });

  testWidgets('circle search filters by name and description', (tester) async {
    CircleListEntry entry(String name, {String? description}) => CircleListEntry(
          circle: CircleSummary(
            id: name,
            name: name,
            eventDate: null,
            isArchived: false,
            isOpenJoin: true,
            photoCount: 0,
            participantCount: 1,
            coverUrl: null,
            description: description,
          ),
          onOpen: () {},
        );

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: CircleListScreen(
        title: 'Ara',
        emptyMessage: 'Boş',
        searchable: true,
        entries: [entry('Bodrum Yaz'), entry('Düğün', description: 'Ege ve Selin'), entry('Yılbaşı')],
      ),
    ));

    await tester.enterText(find.byType(TextField), 'selin');
    await tester.pump();
    expect(find.text('Düğün'), findsOneWidget);
    expect(find.text('Bodrum Yaz'), findsNothing);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump();
    expect(find.textContaining('eşleşen çember yok'), findsOneWidget);
  });

  testWidgets('blocked people show where the block applies and can be unblocked', (tester) async {
    final repository = _FakeProfileRepository([
      BlockedUser(id: 'b1', displayName: 'Kaba', blockedAt: DateTime(2026, 9, 27), circleName: 'Bodrum'),
      BlockedUser(id: 'b2', displayName: 'Spamcı', blockedAt: DateTime(2026, 9, 26)),
    ]);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: BlockedUsersScreen(source: BlockedUsersSource(hostRepository: repository)),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Sadece "Bodrum" çemberinde'), findsOneWidget);
    expect(find.text('Tüm çemberlerde'), findsOneWidget);

    await tester.tap(find.text('Engeli Kaldır').first);
    await tester.pumpAndSettle();
    expect(repository.unblocked, ['b1']);
    expect(find.text('Kaba'), findsNothing);
  });
}

class _FakeProfileRepository extends MockProfileRepository {
  _FakeProfileRepository(this.blocks);

  final List<BlockedUser> blocks;
  final unblocked = <String>[];

  @override
  Future<List<BlockedUser>> fetchBlockedUsers() async => blocks.where((b) => !unblocked.contains(b.id)).toList();

  @override
  Future<void> unblock(String blockId) async => unblocked.add(blockId);
}
