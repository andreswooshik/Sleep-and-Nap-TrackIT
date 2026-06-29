import 'package:flutter_test/flutter_test.dart';
import 'package:sleep_and_nap_trackit/core/reminder_schedule.dart';

void main() {
  group('nextDailyOccurrence', () {
    test('uses today when the time is still in the future', () {
      final from = DateTime(2026, 6, 29, 8, 0);
      final next = nextDailyOccurrence(22, 0, from);
      expect(next, DateTime(2026, 6, 29, 22, 0));
    });

    test('rolls over to tomorrow when the time has passed', () {
      final from = DateTime(2026, 6, 29, 23, 0);
      final next = nextDailyOccurrence(22, 0, from);
      expect(next, DateTime(2026, 6, 30, 22, 0));
    });

    test('rolls over when the time equals now (strictly after)', () {
      final from = DateTime(2026, 6, 29, 7, 0);
      final next = nextDailyOccurrence(7, 0, from);
      expect(next, DateTime(2026, 6, 30, 7, 0));
    });
  });

  group('ClockTime.tryParse', () {
    test('parses HH:mm:ss', () {
      expect(ClockTime.tryParse('22:30:00'), const ClockTime(22, 30));
    });

    test('parses HH:mm', () {
      expect(ClockTime.tryParse('07:05'), const ClockTime(7, 5));
    });

    test('returns null for malformed or out-of-range input', () {
      expect(ClockTime.tryParse(null), isNull);
      expect(ClockTime.tryParse('nope'), isNull);
      expect(ClockTime.tryParse('25:00'), isNull);
      expect(ClockTime.tryParse('10:75'), isNull);
    });

    test('round-trips through storage format', () {
      expect(const ClockTime(7, 5).toStorageString(), '07:05:00');
      expect(ClockTime.tryParse(const ClockTime(7, 5).toStorageString()),
          const ClockTime(7, 5));
    });
  });
}
