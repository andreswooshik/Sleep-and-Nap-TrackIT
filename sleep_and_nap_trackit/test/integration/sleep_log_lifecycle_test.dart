import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleep_and_nap_trackit/models/sleep_log.dart';
import 'package:sleep_and_nap_trackit/providers/service_providers.dart';
import 'package:sleep_and_nap_trackit/repositories/sleep_log_repository.dart';
import 'package:sleep_and_nap_trackit/services/sleep_service.dart';
import 'package:sleep_and_nap_trackit/viewmodels/dashboard_viewmodel.dart';
import 'package:sleep_and_nap_trackit/viewmodels/trends_viewmodel.dart';

/// End-to-end lifecycle of a sleep log through the real provider graph, backed
/// by an in-memory service: create -> appears in dashboard/trends -> edit ->
/// delete -> disappears everywhere. Verifies the repository and every derived
/// view-model stay in lock-step.
void main() {
  // Start from an empty backend so assertions are deterministic.
  ProviderContainer container() {
    final service = MockSleepService();
    // Drain the seeded mock data so we begin from zero.
    for (final seeded in [..._seedIds]) {
      service.deleteSleepLog(seeded);
    }
    final c = ProviderContainer(
      overrides: [sleepServiceProvider.overrideWithValue(service)],
    );
    addTearDown(c.dispose);
    return c;
  }

  Future<void> tick() => Future<void>.delayed(const Duration(milliseconds: 10));

  SleepLog newSleep({required int hours, int quality = 85}) {
    final now = DateTime.now();
    return SleepLog(
      userId: 'user-1',
      type: SleepLogType.sleep,
      startedAt: now.subtract(Duration(hours: hours)),
      endedAt: now,
      quality: quality,
    );
  }

  test('full create/edit/delete lifecycle keeps every view in sync', () async {
    final c = container();
    // Keep the realtime subscription alive for the test's lifetime.
    c.listen(sleepLogsProvider, (_, _) {});
    await c.read(sleepLogsProvider.future);
    await tick();

    // 1. CREATE
    await c.read(sleepLogsProvider.notifier).add(newSleep(hours: 8, quality: 90));
    await tick();

    var logs = c.read(sleepLogsProvider).requireValue;
    expect(logs.length, 1);
    final created = logs.first;
    expect(created.id, isNotNull);

    // Derived dashboard + trends reflect the new log.
    var dashboard = c.read(dashboardStatsProvider).requireValue;
    expect(dashboard.averageSleepDuration, const Duration(hours: 8));
    var trends = c.read(trendsStatsProvider).requireValue;
    expect(trends.totalSessions, 1);
    expect(trends.averageQuality, 90);

    // 2. EDIT — change the quality; trends average must follow.
    await c.read(sleepLogsProvider.notifier).edit(created.copyWith(quality: 50));
    await tick();

    trends = c.read(trendsStatsProvider).requireValue;
    expect(trends.averageQuality, 50);

    // 3. DELETE — disappears from the list and all derived views.
    await c.read(sleepLogsProvider.notifier).delete(created.id!);
    await tick();

    logs = c.read(sleepLogsProvider).requireValue;
    expect(logs, isEmpty);
    dashboard = c.read(dashboardStatsProvider).requireValue;
    expect(dashboard.latestSleep, isNull);
    trends = c.read(trendsStatsProvider).requireValue;
    expect(trends.isEmpty, isTrue);
  });
}

/// The ids MockSleepService seeds itself with on construction.
const _seedIds = ['mock-1', 'mock-2', 'mock-3'];
