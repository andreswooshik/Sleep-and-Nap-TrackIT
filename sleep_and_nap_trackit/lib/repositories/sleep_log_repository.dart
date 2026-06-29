import 'dart:async';

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

  /// Subscribes to the live table feed. The first emission resolves the
  /// initial load; every later emission (from a remote insert/update/delete)
  /// updates [state] so the UI reflects database changes instantly.
  @override
  Future<List<SleepLog>> build() {
    final completer = Completer<List<SleepLog>>();
    final sub = _service.watchSleepLogs().listen(
      (logs) {
        final sorted = _sorted(logs);
        if (completer.isCompleted) {
          state = AsyncValue.data(sorted);
        } else {
          completer.complete(sorted);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (completer.isCompleted) {
          state = AsyncValue.error(error, stackTrace);
        } else {
          completer.completeError(error, stackTrace);
        }
      },
    );
    ref.onDispose(sub.cancel);
    return completer.future;
  }

  /// Reloads the full list from the remote table.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_service.getSleepLogs);
  }

  /// Persists [log] to the cloud and merges the stored row (with its
  /// server-assigned id) into local state immediately, so the UI updates even
  /// if realtime replication isn't delivering self-inserts. If the realtime
  /// stream also re-emits, the id-dedup below prevents a duplicate.
  Future<void> add(SleepLog log) async {
    final stored = await _service.addSleepLog(log);
    final current = state.valueOrNull ?? const [];
    if (current.any((l) => l.id != null && l.id == stored.id)) return;
    state = AsyncValue.data(_sorted([...current, stored]));
  }

  /// Saves edits to [log] remotely and reflects them locally right away
  /// (realtime, if enabled, will reconcile to the same state).
  Future<void> edit(SleepLog log) async {
    final stored = await _service.updateSleepLog(log);
    final current = state.valueOrNull ?? const [];
    state = AsyncValue.data(_sorted([
      for (final entry in current)
        if (entry.id == stored.id) stored else entry,
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
