import 'package:flutter_test/flutter_test.dart';
import 'package:sleep_and_nap_trackit/core/sleep_recommendation.dart';
import 'package:sleep_and_nap_trackit/models/sleep_log.dart';
import 'package:sleep_and_nap_trackit/viewmodels/dashboard_viewmodel.dart';

void main() {
  final now = DateTime(2026, 6, 29, 9);

  SleepLog log({
    required SleepLogType type,
    required DateTime start,
    required int hours,
    int quality = 80,
  }) =>
      SleepLog(
        type: type,
        startedAt: start,
        endedAt: start.add(Duration(hours: hours)),
        quality: quality,
      );

  group('DashboardStats.fromLogs', () {
    test('averages only sleep sessions and counts naps', () {
      final stats = DashboardStats.fromLogs([
        log(type: SleepLogType.sleep, start: DateTime(2026, 6, 28, 23), hours: 8),
        log(type: SleepLogType.sleep, start: DateTime(2026, 6, 27, 23), hours: 6),
        log(type: SleepLogType.nap, start: DateTime(2026, 6, 28, 14), hours: 1),
      ]);
      expect(stats.averageSleepDuration, const Duration(hours: 7));
      expect(stats.napCount, 1);
      expect(stats.latestSleep, isNotNull);
    });

    test('empty logs yield zeroed stats with no latest sleep', () {
      final stats = DashboardStats.fromLogs([]);
      expect(stats.averageSleepDuration, Duration.zero);
      expect(stats.averageQuality, 0);
      expect(stats.latestSleep, isNull);
    });
  });

  group('TodayStatus.fromLogs', () {
    test('sums only today\'s sleep and counts today\'s naps', () {
      final stats = TodayStatus.fromLogs(
        [
          log(type: SleepLogType.sleep, start: DateTime(2026, 6, 29, 1), hours: 7),
          log(type: SleepLogType.nap, start: DateTime(2026, 6, 29, 14), hours: 1),
          // Yesterday — must be excluded.
          log(type: SleepLogType.sleep, start: DateTime(2026, 6, 28, 23), hours: 8),
        ],
        recommendation: recommendationForAge(30),
        now: now,
      );
      expect(stats.sleepLoggedToday, const Duration(hours: 7));
      expect(stats.napsToday, 1);
      expect(stats.hasLoggedSleep, isTrue);
    });

    test('reports no sleep when nothing is logged today', () {
      final stats = TodayStatus.fromLogs(
        [log(type: SleepLogType.sleep, start: DateTime(2026, 6, 28, 23), hours: 8)],
        recommendation: recommendationForAge(30),
        now: now,
      );
      expect(stats.hasLoggedSleep, isFalse);
      expect(stats.napsToday, 0);
    });

    test('carries a null recommendation when none is supplied', () {
      final stats = TodayStatus.fromLogs([], recommendation: null, now: now);
      expect(stats.recommendation, isNull);
    });
  });
}
