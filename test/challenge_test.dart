import 'package:cember/data/challenge_repository.dart';
import 'package:cember/models/challenge_template.dart';
import 'package:cember/models/photo_upload_mode.dart';
import 'package:cember/screens/discover_screen.dart';
import 'package:cember/theme/app_theme.dart';
import 'package:cember/widgets/discover/challenge_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

Map<String, dynamic> challengeJson(String title, {String category = 'Gece', int? revealAfterDays = 1, bool featured = false}) => {
      'id': title,
      'slug': title.toLowerCase(),
      'title': title,
      'tagline': '$title sloganı',
      'description': 'Nasıl oynanır',
      'emoji': '🎞️',
      'category': category,
      'gradientStartHex': '#D6197E',
      'gradientEndHex': '#F2552C',
      'uploadMode': 'QuickCaptureOnly',
      'revealAfterDays': revealAfterDays,
      'revealHour': 10,
      'prompts': ['Birinci', 'İkinci'],
      'creatorName': null,
      'creatorHandle': null,
      'creatorVerified': false,
      'isFeatured': featured,
      'startedCount': 3,
    };

class _FakeChallenges extends ChallengeRepository {
  const _FakeChallenges(this.items);

  final List<ChallengeTemplate> items;

  @override
  Future<List<ChallengeTemplate>> fetchAll() async => items;
}

void main() {
  test('reads a challenge and suggests the reveal moment', () {
    final challenge = ChallengeTemplate.fromJson(challengeJson('Tek Kullanımlık Gece'));
    expect(challenge.uploadMode, PhotoUploadMode.quickCaptureOnly);
    expect(challenge.category, ChallengeCategory.gece);
    expect(challenge.creatorLabel, 'Çember');
    expect(challenge.suggestedRevealAt(DateTime(2026, 10, 3)), DateTime(2026, 10, 4, 10));

    final noBanyo = ChallengeTemplate.fromJson(challengeJson('Kahvaltı', revealAfterDays: null));
    expect(noBanyo.usesBanyo, isFalse);
    expect(noBanyo.suggestedRevealAt(DateTime(2026, 10, 3)), isNull);
  });

  testWidgets('a challenge card shows its idea, settings and social proof', (tester) async {
    final challenge = ChallengeTemplate.fromJson(challengeJson('Tek Kullanımlık Gece', featured: true));
    var tapped = false;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: ChallengeCard(challenge: challenge, onTap: () => tapped = true)),
    ));

    expect(find.text('Tek Kullanımlık Gece'), findsOneWidget);
    expect(find.text('Banyo'), findsOneWidget);
    expect(find.text('Sadece Şipşak'), findsOneWidget);
    expect(find.text('Öne çıkan'), findsOneWidget);
    expect(find.text('3 grup başlattı'), findsOneWidget);
    await tester.tap(find.text('Tek Kullanımlık Gece'));
    expect(tapped, isTrue);
  });

  testWidgets('Keşfet splits brands and challenges, and challenges filter by category', (tester) async {
    final challenges = [
      ChallengeTemplate.fromJson(challengeJson('Konser Gecesi')),
      ChallengeTemplate.fromJson(challengeJson('Maç Günü', category: 'Spor')),
    ];
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: DiscoverScreen(challengeRepository: _FakeChallenges(challenges)),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Challenge'));
    await tester.pumpAndSettle();
    expect(find.text('Konser Gecesi'), findsOneWidget);
    expect(find.text('Maç Günü'), findsOneWidget);

    await tester.tap(find.text('Spor'));
    await tester.pumpAndSettle();
    expect(find.text('Konser Gecesi'), findsNothing);
    expect(find.text('Maç Günü'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('Bu aramaya uyan bir challenge yok.'), findsOneWidget);

    Get.reset();
  });
}
