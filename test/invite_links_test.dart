import 'package:cember/core/invite_links.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('extractInviteToken', () {
    test('reads the WhatsApp-style https link', () {
      expect(extractInviteToken('https://cember.app/join/abc123'), 'abc123');
    });

    test('reads the app scheme link', () {
      expect(extractInviteToken('cember://join/abc123'), 'abc123');
    });

    test('accepts a bare token from older QR codes', () {
      expect(extractInviteToken('  abc123 '), 'abc123');
    });

    test('falls back to the last path segment for a differently configured base URL', () {
      expect(extractInviteToken('https://example.com/i/xyz'), 'xyz');
    });

    test('ignores unrelated app-scheme links and empty input', () {
      expect(extractInviteToken('cember://settings/profile'), isNull);
      expect(extractInviteToken(''), isNull);
      expect(extractInviteToken('https://cember.app/'), isNull);
    });
  });
}
