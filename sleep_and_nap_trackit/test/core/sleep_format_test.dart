import 'package:flutter_test/flutter_test.dart';
import 'package:sleep_and_nap_trackit/core/sleep_format.dart';

void main() {
  group('formatMinutes', () {
    test('zero renders as 0m', () {
      expect(formatMinutes(0), '0m');
    });

    test('sub-hour renders as minutes only', () {
      expect(formatMinutes(45), '45m');
    });

    test('whole hours drop the minutes', () {
      expect(formatMinutes(480), '8h');
    });

    test('hours and minutes render together', () {
      expect(formatMinutes(495), '8h 15m');
    });

    test('negative input is clamped to 0m', () {
      expect(formatMinutes(-30), '0m');
    });
  });

  group('formatDuration', () {
    test('delegates to formatMinutes', () {
      expect(formatDuration(const Duration(hours: 8, minutes: 15)), '8h 15m');
    });
  });

  group('formatAverageSleep', () {
    test('null falls back to an encouraging string, not a dash', () {
      expect(formatAverageSleep(null), 'Log to see');
    });

    test('zero falls back to an encouraging string', () {
      expect(formatAverageSleep(Duration.zero), 'Log to see');
    });

    test('real data is formatted', () {
      expect(formatAverageSleep(const Duration(hours: 7, minutes: 30)), '7h 30m');
    });
  });

  group('formatQuality', () {
    test('null and zero show a neutral dash placeholder', () {
      expect(formatQuality(null), '—');
      expect(formatQuality(0), '—');
    });

    test('real percentage is suffixed with %', () {
      expect(formatQuality(82), '82%');
    });
  });

  group('coachingText', () {
    test('no sleep logged gives the daytime recommendation', () {
      final text = coachingText(
        sleepLoggedToday: Duration.zero,
        hour: 10,
      );
      expect(text, contains('Aim for 7–9 h'));
      expect(text, contains('naps short'));
    });

    test('no sleep logged late at night gives a wind-down nudge', () {
      final text = coachingText(sleepLoggedToday: Duration.zero, hour: 22);
      expect(text.toLowerCase(), contains('tonight'));
    });

    test('respects a custom recommended range label', () {
      final text = coachingText(
        sleepLoggedToday: Duration.zero,
        recommendedRangeLabel: '8–10 h',
        hour: 9,
      );
      expect(text, contains('8–10 h'));
    });

    test('once sleep is logged it acknowledges progress', () {
      final text = coachingText(
        sleepLoggedToday: const Duration(hours: 7, minutes: 30),
        hour: 9,
      );
      expect(text, contains('7h 30m'));
    });
  });
}
