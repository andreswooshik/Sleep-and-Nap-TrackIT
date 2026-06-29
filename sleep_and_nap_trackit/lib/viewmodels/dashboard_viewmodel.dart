import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/sleep_recommendation.dart';
import '../models/sleep_log.dart';
import '../providers/home_provider.dart';
import '../providers/profile_provider.dart';

/// Presentation-ready dashboard figures derived from a user's sleep logs.
/// Pure value object — keeps computation out of the view (MVVM).
class DashboardStats {
  const DashboardStats({
    required this.latestSleep,
    required this.sleepToday,
    required this.averageSleepDuration,
    required this.napCount,
    required this.averageQuality,
    required this.sleepStreak,
    required this.logs,
  });

  final SleepLog? latestSleep;

  /// Total sleep logged today — shown in the header so it agrees with the
  /// "Today" card rather than reporting the most recent session ever.
  final Duration sleepToday;

  final Duration averageSleepDuration;
  final int napCount;
  final int averageQuality;

  /// Consecutive days (counting back from today, with a one-day grace if today
  /// isn't logged yet) that have at least one sleep session.
  final int sleepStreak;

  final List<SleepLog> logs;

  factory DashboardStats.fromLogs(List<SleepLog> logs, {DateTime? now}) {
    final sleeps = logs.where((l) => l.type == SleepLogType.sleep).toList();

    final avg = sleeps.isEmpty
        ? Duration.zero
        : Duration(
            minutes: sleeps.fold<int>(0, (s, l) => s + l.duration.inMinutes) ~/ sleeps.length,
          );

    final avgQuality = logs.isEmpty
        ? 0
        : (logs.fold<int>(0, (s, l) => s + l.quality) / logs.length).round();

    final today = now ?? DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final sleepTodayMinutes = sleeps
        .where((l) =>
            l.startedAt.year == today.year &&
            l.startedAt.month == today.month &&
            l.startedAt.day == today.day)
        .fold<int>(0, (s, l) => s + l.duration.inMinutes);

    // Set of distinct calendar days that have at least one sleep session.
    final sleepDays = sleeps
        .map((l) => DateTime(l.startedAt.year, l.startedAt.month, l.startedAt.day))
        .toSet();

    // Count back from today; allow a one-day grace if today isn't logged yet.
    var cursor = todayDate;
    if (!sleepDays.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    var streak = 0;
    while (sleepDays.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return DashboardStats(
      latestSleep: sleeps.isEmpty ? null : sleeps.first,
      sleepToday: Duration(minutes: sleepTodayMinutes),
      averageSleepDuration: avg,
      napCount: logs.where((l) => l.type == SleepLogType.nap).length,
      averageQuality: avgQuality,
      sleepStreak: streak,
      logs: logs,
    );
  }
}

final dashboardStatsProvider = Provider<AsyncValue<DashboardStats>>((ref) {
  final logsAsync = ref.watch(sleepLogsProvider);
  return logsAsync.whenData(DashboardStats.fromLogs);
});

/// Today's tracking status: how much sleep/nap has been logged today and how it
/// stacks up against the user's age-based [SleepRecommendation].
class TodayStatus {
  const TodayStatus({
    required this.sleepLoggedToday,
    required this.napsToday,
    required this.sleepLoggedYesterday,
    required this.napsYesterday,
    required this.recommendation,
  });

  final Duration sleepLoggedToday;
  final int napsToday;
  final Duration sleepLoggedYesterday;
  final int napsYesterday;

  /// Null when no profile (or date of birth) is available yet.
  final SleepRecommendation? recommendation;

  bool get hasLoggedSleep => sleepLoggedToday > Duration.zero;
  bool get hasLoggedYesterday => sleepLoggedYesterday > Duration.zero;

  factory TodayStatus.fromLogs(
    List<SleepLog> logs, {
    required SleepRecommendation? recommendation,
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final yesterdayDate = todayDate.subtract(const Duration(days: 1));

    bool onDay(DateTime d, DateTime day) =>
        d.year == day.year && d.month == day.month && d.day == day.day;

    Duration sleepOn(DateTime day) => Duration(
          minutes: logs
              .where((l) => l.type == SleepLogType.sleep && onDay(l.startedAt, day))
              .fold<int>(0, (sum, l) => sum + l.duration.inMinutes),
        );
    int napsOn(DateTime day) =>
        logs.where((l) => l.type == SleepLogType.nap && onDay(l.startedAt, day)).length;

    return TodayStatus(
      sleepLoggedToday: sleepOn(todayDate),
      napsToday: napsOn(todayDate),
      sleepLoggedYesterday: sleepOn(yesterdayDate),
      napsYesterday: napsOn(yesterdayDate),
      recommendation: recommendation,
    );
  }
}

/// Combines today's logs with the profile-derived recommendation so the
/// dashboard can show a live "today" summary.
final todayStatusProvider = Provider<AsyncValue<TodayStatus>>((ref) {
  final logsAsync = ref.watch(sleepLogsProvider);
  final profile = ref.watch(profileProvider).valueOrNull;
  final recommendation = profile == null
      ? null
      : recommendationForBirthDate(profile.dateOfBirth);
  return logsAsync.whenData(
    (logs) => TodayStatus.fromLogs(logs, recommendation: recommendation),
  );
});
