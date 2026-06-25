import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/sleep_log.dart';
import '../providers/service_providers.dart';
import '../services/sleep_service.dart';

/// CRUD repository for the user's [SleepLog]s.
///
/// Holds the canonical local copy of the logs as Riverpod state so the UI can
/// render instantly, while mirroring every create/update/delete to the remote
/// Supabase table through [SleepService]. Writes are local-first: the on-screen
/// list and the cloud table stay in lock-step without a full re-fetch after
/// each change.
class SleepLogRepository extends AsyncNotifier<List<SleepLog>> {
  SleepService get _service => ref.read(sleepServiceProvider);

  @override
  Future<List<SleepLog>> build() => _service.getSleepLogs();

  /// Reloads the full list from the remote table.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_service.getSleepLogs);
  }

  /// Persists [log] to the cloud, then inserts the stored row (with its
  /// server-assigned id) into the local list in chronological order.
  Future<void> add(SleepLog log) async {
    final created = await _service.addSleepLog(log);
    final current = state.valueOrNull ?? const [];
    state = AsyncValue.data(_sorted([created, ...current]));
  }

  /// Saves edits to [log] remotely and swaps the matching local entry in place.
  Future<void> edit(SleepLog log) async {
    final saved = await _service.updateSleepLog(log);
    final current = state.valueOrNull ?? const [];
    state = AsyncValue.data(_sorted([
      for (final entry in current)
        if (entry.id == saved.id) saved else entry,
    ]));
  }

  /// Removes the log with [id] from the local list immediately, then deletes it
  /// from the cloud. If the remote delete fails the entry is restored so local
  /// state never drifts from the table.
  Future<void> delete(String id) async {
    final current = state.valueOrNull ?? const [];
    final remaining = [
      for (final entry in current)
        if (entry.id != id) entry,
    ];
    // Optimistic: drop it from the local array right away.
    state = AsyncValue.data(remaining);
    try {
      await _service.deleteSleepLog(id);
    } catch (_) {
      // Roll back so the UI matches the still-present remote row.
      state = AsyncValue.data(current);
      rethrow;
    }
  }

  List<SleepLog> _sorted(List<SleepLog> logs) {
    return [...logs]..sort((a, b) => b.startedAt.compareTo(a.startedAt));
  }
}

/// Exposes the user's sleep logs as live [AsyncValue] state. Read the
/// `.notifier` to perform CRUD operations.
final sleepLogsProvider =
    AsyncNotifierProvider<SleepLogRepository, List<SleepLog>>(
  SleepLogRepository.new,
);
