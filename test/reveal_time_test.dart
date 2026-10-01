import 'package:cember/core/reveal_time.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 9, 27, 14, 0);

  group('formatRevealTime', () {
    test('says today, tomorrow, or the date', () {
      expect(formatRevealTime(DateTime(2026, 9, 27, 23, 5), now: now), 'Bugün 23:05');
      expect(formatRevealTime(DateTime(2026, 9, 28, 10, 0), now: now), 'Yarın 10:00');
      expect(formatRevealTime(DateTime(2026, 10, 3, 9, 30), now: now), '3 Ekim 09:30');
    });
  });

  group('formatCountdown', () {
    test('scales from days down to seconds', () {
      expect(formatCountdown(const Duration(days: 2, hours: 3, minutes: 4)), '2 gün 3 sa 4 dk');
      expect(formatCountdown(const Duration(hours: 5, minutes: 6, seconds: 7)), '5 sa 6 dk 07 sn');
      expect(formatCountdown(const Duration(minutes: 1, seconds: 9)), '1 dk 09 sn');
      expect(formatCountdown(const Duration(seconds: -3)), '0 sn');
    });
  });

  group('defaultRevealTime', () {
    test('is 10:00 the morning after the event', () {
      final eventDay = DateTime.now().add(const Duration(days: 3));
      final reveal = defaultRevealTime(eventDay);
      expect(reveal, DateTime(eventDay.year, eventDay.month, eventDay.day + 1, 10));
    });

    test('never lands in the past', () {
      final reveal = defaultRevealTime(DateTime(2020, 1, 1));
      expect(reveal.isAfter(DateTime.now()), isTrue);
    });
  });
}
