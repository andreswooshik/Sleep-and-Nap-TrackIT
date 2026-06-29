import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleep_and_nap_trackit/models/sleep_log.dart';
import 'package:sleep_and_nap_trackit/providers/service_providers.dart';
import 'package:sleep_and_nap_trackit/repositories/sleep_log_repository.dart';
import 'package:sleep_and_nap_trackit/services/sleep_service.dart';

ProviderContainer _container() {
  final container = ProviderContainer(
    overrides: [sleepServiceProvider.overrideWithValue(MockSleepService())],
  );
  addTearDown(container.dispose);
  return container;
}

/// Lets the realtime stream deliver its next emission to the repository.
Future<void> _tick() => Future<void>.delayed(const Duration(milliseconds: 10));

SleepLog _newLog() {
  final now = DateTime.now();
  return SleepLog(
    userId: 'user-1',
    type: SleepLogType.sleep,
    startedAt: now.subtract(const Duration(hours: 8)),
    endedAt: now,
    quality: 90,
  );
}

void main() {
  group('SleepLogRepository', () {
    test('build loads logs from the service', () async {
      final container = _container();
      final logs = await container.read(sleepLogsProvider.future);
      expect(logs, isNotEmpty);
    });

    test('add persists through the service and keeps the list sorted', () async {
      final container = _container();
      container.listen(sleepLogsProvider, (_, _) {});
      final before = await container.read(sleepLogsProvider.future);

      await container.read(sleepLogsProvider.notifier).add(_newLog());
      await _tick();

      final logs = container.read(sleepLogsProvider).requireValue;
      expect(logs.length, before.length + 1);
      // The stored row carries a server-assigned id.
      final added = logs.firstWhere((l) => l.quality == 90);
      expect(added.id, isNotNull);
      // Sorted newest-first by start time.
      for (var i = 0; i < logs.length - 1; i++) {
        expect(logs[i].startedAt.isBefore(logs[i + 1].startedAt), isFalse);
      }
    });

    test('delete removes the item from the local array immediately', () async {
      final container = _container();
      final initial = await container.read(sleepLogsProvider.future);
      final target = initial.first;

      // Synchronous local removal — no await, no re-fetch.
      final future = container.read(sleepLogsProvider.notifier).delete(target.id!);

      final afterLocal = container.read(sleepLogsProvider).requireValue;
      expect(afterLocal.any((l) => l.id == target.id), isFalse);
      expect(afterLocal.length, initial.length - 1);

      await future;
    });

    test('delete is mirrored to the remote table', () async {
      final service = MockSleepService();
      final container = ProviderContainer(
        overrides: [sleepServiceProvider.overrideWithValue(service)],
      );
      addTearDown(container.dispose);

      final initial = await container.read(sleepLogsProvider.future);
      final target = initial.first;
      await container.read(sleepLogsProvider.notifier).delete(target.id!);

      final remote = await service.getSleepLogs();
      expect(remote.any((l) => l.id == target.id), isFalse);
    });

    test('edit updates the matching local entry', () async {
      final container = _container();
      container.listen(sleepLogsProvider, (_, _) {});
      final initial = await container.read(sleepLogsProvider.future);
      final edited = initial.first.copyWith(quality: 12);

      await container.read(sleepLogsProvider.notifier).edit(edited);
      await _tick();

      final logs = container.read(sleepLogsProvider).requireValue;
      expect(logs.firstWhere((l) => l.id == edited.id).quality, 12);
    });

    test('reflects remote changes pushed through the realtime stream', () async {
      final service = MockSleepService();
      final container = ProviderContainer(
        overrides: [sleepServiceProvider.overrideWithValue(service)],
      );
      addTearDown(container.dispose);
      // Keep the notifier alive so its stream subscription stays active.
      container.listen(sleepLogsProvider, (_, _) {});

      final initial = await container.read(sleepLogsProvider.future);
      // Let the realtime subscription attach after the initial REST load
      // (it goes live just after the fetch resolves).
      await _tick();

      // Simulate a change originating from the database (not a repository call).
      await service.deleteSleepLog(initial.first.id!);
      await _tick();

      final updated = container.read(sleepLogsProvider).requireValue;
      expect(updated.length, initial.length - 1);
      expect(updated.any((l) => l.id == initial.first.id), isFalse);
    });
  });
}
