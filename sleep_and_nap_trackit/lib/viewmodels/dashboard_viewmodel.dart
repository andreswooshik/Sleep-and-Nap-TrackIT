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
    required this.averageSleepDuration,
    required this.napCount,
    required this.averageQuality,
    required this.logs,
  });

  final SleepLog? latestSleep;
  final Duration averageSleepDuration;
  final int napCount;
  final int averageQuality;
  final List<SleepLog> logs;

  factory DashboardStats.fromLogs(List<SleepLog> logs) {
    final sleeps = logs.where((l) => l.type == SleepLogType.sleep).toList();

    final avg = sleeps.isEmpty
        ? Duration.zero
        : Duration(
            minutes: sleeps.fold<int>(0, (s, l) => s + l.duration.inMinutes) ~/ sleeps.length,
          );

    final avgQuality = logs.isEmpty
        ? 0
        : (logs.fold<int>(0, (s, l) => s + l.quality) / logs.length).round();

    return DashboardStats(
      latestSleep: sleeps.isEmpty ? null : sleeps.first,
      averageSleepDuration: avg,
      napCount: logs.where((l) => l.type == SleepLogType.nap).length,
      averageQuality: avgQuality,
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
    required this.recommendation,
  });

  final Duration sleepLoggedToday;
  final int napsToday;

  /// Null when no profile (or date of birth) is available yet.
  final SleepRecommendation? recommendation;

  bool get hasLoggedSleep => sleepLoggedToday > Duration.zero;

  factory TodayStatus.fromLogs(
    List<SleepLog> logs, {
    required SleepRecommendation? recommendation,
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    bool isToday(DateTime d) =>
        d.year == today.year && d.month == today.month && d.day == today.day;

    final todays = logs.where((l) => isToday(l.startedAt));
    final sleepMinutes = todays
        .where((l) => l.type == SleepLogType.sleep)
        .fold<int>(0, (sum, l) => sum + l.duration.inMinutes);

    return TodayStatus(
      sleepLoggedToday: Duration(minutes: sleepMinutes),
      napsToday: todays.where((l) => l.type == SleepLogType.nap).length,
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
