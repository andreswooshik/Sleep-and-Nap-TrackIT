import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/sleep_log.dart';
import '../providers/home_provider.dart';

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
