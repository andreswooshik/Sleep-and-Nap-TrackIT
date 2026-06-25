import 'package:flutter_test/flutter_test.dart';
import 'package:sleep_and_nap_trackit/models/sleep_log.dart';
import 'package:sleep_and_nap_trackit/viewmodels/trends_viewmodel.dart';

void main() {
  final now = DateTime(2026, 6, 25, 9);

  SleepLog sleep({required int dayOffset, required int hours, int quality = 80, List<String> factors = const []}) {
    final start = DateTime(2026, 6, 25 - dayOffset, 23);
    return SleepLog(
      type: SleepLogType.sleep,
      startedAt: start,
      endedAt: start.add(Duration(hours: hours)),
      quality: quality,
      factors: factors,
    );
  }

  group('TrendsStats.fromLogs', () {
    test('empty logs produce an empty stats object', () {
      final stats = TrendsStats.fromLogs([], now: now);
      expect(stats.isEmpty, isTrue);
      expect(stats.last7Days.length, 7);
      expect(stats.averageSleep, Duration.zero);
      expect(stats.consistency, 0);
      expect(stats.topFactors, isEmpty);
    });

    test('always returns 7 day buckets', () {
      final stats = TrendsStats.fromLogs([sleep(dayOffset: 0, hours: 8)], now: now);
      expect(stats.last7Days.length, 7);
    });

    test('averages sleep duration across sleep sessions', () {
      final stats = TrendsStats.fromLogs([
        sleep(dayOffset: 0, hours: 8),
        sleep(dayOffset: 1, hours: 6),
      ], now: now);
      expect(stats.averageSleep, const Duration(hours: 7));
    });

    test('consistency reflects days with sleep out of 7', () {
      final stats = TrendsStats.fromLogs([
        sleep(dayOffset: 0, hours: 8),
        sleep(dayOffset: 1, hours: 7),
        sleep(dayOffset: 2, hours: 7),
      ], now: now);
      // 3 of 7 days = 43%
      expect(stats.consistency, 43);
    });

    test('averages quality across all logs', () {
      final stats = TrendsStats.fromLogs([
        sleep(dayOffset: 0, hours: 8, quality: 90),
        sleep(dayOffset: 1, hours: 8, quality: 70),
      ], now: now);
      expect(stats.averageQuality, 80);
    });

    test('tallies and sorts factors by frequency', () {
      final stats = TrendsStats.fromLogs([
        sleep(dayOffset: 0, hours: 8, factors: ['caffeine', 'noise']),
        sleep(dayOffset: 1, hours: 8, factors: ['caffeine']),
      ], now: now);
      expect(stats.topFactors.first.key, 'caffeine');
      expect(stats.topFactors.first.count, 2);
      expect(stats.topFactors[1].key, 'noise');
    });

    test('counts naps separately', () {
      final nap = SleepLog(
        type: SleepLogType.nap,
        startedAt: DateTime(2026, 6, 25, 14),
        endedAt: DateTime(2026, 6, 25, 14, 30),
        quality: 75,
      );
      final stats = TrendsStats.fromLogs([sleep(dayOffset: 0, hours: 8), nap], now: now);
      expect(stats.napCount, 1);
      expect(stats.totalSessions, 2);
    });
  });
}
