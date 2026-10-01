import 'package:cember/models/circle_detail.dart';
import 'package:cember/theme/app_theme.dart';
import 'package:cember/widgets/circle_detail/circle_rules_card.dart';
import 'package:cember/widgets/common/rules_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => MaterialApp(theme: AppTheme.light, home: Scaffold(body: SingleChildScrollView(child: child)));

void main() {
  test('circle detail reads its rules, and older payloads without them', () {
    final base = {
      'id': 'c1',
      'name': 'Bodrum',
      'eventDate': null,
      'participantCount': 1,
      'memoryCount': 0,
      'isOpenJoin': false,
      'autoPublish': true,
      'allowGuestDownloads': true,
      'viewerIsHost': true,
      'hostDisplayName': 'Ali',
      'coverUrl': null,
    };
    expect(CircleDetail.fromJson({...base, 'rules': ['A', 'B']}).rules, ['A', 'B']);
    expect(CircleDetail.fromJson(base).rules, isEmpty);
  });

  testWidgets('everyone sees the rules; only the host can edit them', (tester) async {
    var edits = 0;
    await tester.pumpWidget(_app(CircleRulesCard(rules: const ['En az 3 kare', 'Gülen yüzler'], onEdit: () => edits++)));
    expect(find.text('Kurallar'), findsOneWidget);
    expect(find.text('En az 3 kare'), findsOneWidget);
    await tester.tap(find.text('Düzenle'));
    expect(edits, 1);

    await tester.pumpWidget(_app(const CircleRulesCard(rules: ['En az 3 kare'])));
    expect(find.text('Düzenle'), findsNothing);
  });

  test('an empty rule list is hidden from guests but offered to the host', () {
    expect(CircleRulesCard.shouldShow(const [], canEdit: false), isFalse);
    expect(CircleRulesCard.shouldShow(const [], canEdit: true), isTrue);
    expect(CircleRulesCard.shouldShow(const ['x'], canEdit: false), isTrue);
  });

  testWidgets('the editor adds, fills and removes rules, reporting only non-empty ones', (tester) async {
    var reported = <String>[];
    await tester.pumpWidget(_app(RulesEditor(onChanged: (rules) => reported = rules)));

    await tester.tap(find.text('Kural ekle'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).last, '  Herkes en az 3 kare atar ');
    await tester.tap(find.text('Bir kural daha'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).last, 'Sadece Şipşak');
    expect(reported, ['Herkes en az 3 kare atar', 'Sadece Şipşak']);

    await tester.tap(find.byTooltip('Kuralı sil').first);
    await tester.pump();
    expect(reported, ['Sadece Şipşak']);
  });
}
