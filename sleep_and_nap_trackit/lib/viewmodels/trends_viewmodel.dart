import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/sleep_log.dart';
import '../providers/home_provider.dart';

/// One day's total sleep duration, used by the 7-day bar chart.
class DailySleep {
  const DailySleep({required this.date, required this.duration});

  final DateTime date;
  final Duration duration;

  double get hours => duration.inMinutes / 60.0;

  /// Single-letter weekday label (M, T, W, ...).
  String get weekdayLabel {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return labels[date.weekday - 1];
  }
}

/// A factor and how many sessions it appeared in.
class FactorCount {
  const FactorCount({required this.key, required this.count});

  final String key;
  final int count;
}

/// One day's average sleep-quality score, used by the quality trend line.
class DailyQuality {
  const DailyQuality({required this.date, required this.quality});

  final DateTime date;

  /// Average quality (0–100) of that day's sessions, or null when none.
  final int? quality;

  String get weekdayLabel {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return labels[date.weekday - 1];
  }
}

/// Aggregated, presentation-ready trends derived from a user's sleep logs.
/// Pure value object — no Flutter or I/O dependencies, fully unit-testable.
class TrendsStats {
  const TrendsStats({
    required this.last7Days,
    required this.averageSleep,
    required this.weeklyAverageSleep,
    required this.monthlyAverageSleep,
    required this.averageQuality,
    required this.qualityTrend,
    required this.consistency,
    required this.napCount,
    required this.totalSessions,
    required this.topFactors,
  });

  final List<DailySleep> last7Days;
  final Duration averageSleep;

  /// Average nightly sleep over the last 7 / 30 days (per day that has sleep).
  final Duration weeklyAverageSleep;
  final Duration monthlyAverageSleep;

  final int averageQuality;

  /// Per-day average quality for the last 7 days (oldest → newest).
  final List<DailyQuality> qualityTrend;

  /// Percentage of the last 7 days that have at least one sleep session.
  final int consistency;
  final int napCount;
  final int totalSessions;
  final List<FactorCount> topFactors;

  bool get isEmpty => totalSessions == 0;

  factory TrendsStats.fromLogs(List<SleepLog> logs, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final sleeps = logs.where((l) => l.type == SleepLogType.sleep).toList();

    // 7-day duration buckets (oldest -> newest).
    final days = <DailySleep>[];
    var daysWithSleep = 0;
    for (var i = 6; i >= 0; i--) {
      final date = todayDate.subtract(Duration(days: i));
      final dayLogs = sleeps.where((l) {
        final s = l.startedAt;
        return s.year == date.year && s.month == date.month && s.day == date.day;
      });
      final total = dayLogs.fold<int>(0, (sum, l) => sum + l.duration.inMinutes);
      if (total > 0) daysWithSleep++;
      days.add(DailySleep(date: date, duration: Duration(minutes: total)));
    }

    final avgSleep = sleeps.isEmpty
        ? Duration.zero
        : Duration(
            minutes: sleeps.fold<int>(0, (s, l) => s + l.duration.inMinutes) ~/ sleeps.length,
          );

    // Average nightly sleep over a trailing window: total sleep in the window
    // divided by the number of distinct days that have any sleep.
    Duration windowAverage(int windowDays) {
      final cutoff = todayDate.subtract(Duration(days: windowDays - 1));
      final inWindow = sleeps.where((l) {
        final d = DateTime(l.startedAt.year, l.startedAt.month, l.startedAt.day);
        return !d.isBefore(cutoff) && !d.isAfter(todayDate);
      });
      if (inWindow.isEmpty) return Duration.zero;
      final daysWith = inWindow
          .map((l) => DateTime(l.startedAt.year, l.startedAt.month, l.startedAt.day))
          .toSet()
          .length;
      final totalMinutes =
          inWindow.fold<int>(0, (s, l) => s + l.duration.inMinutes);
      return Duration(minutes: totalMinutes ~/ daysWith);
    }

    final avgQuality = logs.isEmpty
        ? 0
        : (logs.fold<int>(0, (s, l) => s + l.quality) / logs.length).round();

    // Per-day average quality across the last 7 days (oldest -> newest).
    final qualityTrend = <DailyQuality>[];
    for (var i = 6; i >= 0; i--) {
      final date = todayDate.subtract(Duration(days: i));
      final dayLogs = logs.where((l) {
        final s = l.startedAt;
        return s.year == date.year && s.month == date.month && s.day == date.day;
      }).toList();
      final q = dayLogs.isEmpty
          ? null
          : (dayLogs.fold<int>(0, (s, l) => s + l.quality) / dayLogs.length).round();
      qualityTrend.add(DailyQuality(date: date, quality: q));
    }

    // Factor frequency across all logs.
    final factorTally = <String, int>{};
    for (final log in logs) {
      for (final f in log.factors) {
        factorTally[f] = (factorTally[f] ?? 0) + 1;
      }
    }
    final topFactors = factorTally.entries
        .map((e) => FactorCount(key: e.key, count: e.value))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    return TrendsStats(
      last7Days: days,
      averageSleep: avgSleep,
      weeklyAverageSleep: windowAverage(7),
      monthlyAverageSleep: windowAverage(30),
      averageQuality: avgQuality,
      qualityTrend: qualityTrend,
      consistency: ((daysWithSleep / 7) * 100).round(),
      napCount: logs.where((l) => l.type == SleepLogType.nap).length,
      totalSessions: logs.length,
      topFactors: topFactors,
    );
  }
}

/// Derives [TrendsStats] from the shared sleep logs provider.
final trendsStatsProvider = Provider<AsyncValue<TrendsStats>>((ref) {
  final logsAsync = ref.watch(sleepLogsProvider);
  return logsAsync.whenData(TrendsStats.fromLogs);
});
