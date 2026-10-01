import 'package:flutter_test/flutter_test.dart';

import 'package:cember/core/token_store.dart';
import 'package:cember/main.dart';

class _NoTokenStore extends TokenStore {
  const _NoTokenStore();

  @override
  Future<String?> readApiKey() async => null;
}

void main() {
  testWidgets('App shows onboarding when no host key is saved yet', (WidgetTester tester) async {
    await tester.pumpWidget(const CemberApp(tokenStore: _NoTokenStore()));
    await tester.pumpAndSettle();

    expect(find.text('Çember\'e Hoş Geldin'), findsOneWidget);
  });
}
