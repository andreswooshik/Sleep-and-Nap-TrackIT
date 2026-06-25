import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/sleep_log.dart';

/// Low-level data access for the `sleep_logs` cloud table.
///
/// Implementations translate between [SleepLog] objects and rows in the remote
/// store. Higher layers (the repository) own caching and local-list state.
abstract class SleepService {
  Future<List<SleepLog>> getSleepLogs();

  /// Persists [log] and returns it as stored, including the server-assigned
  /// `id` so callers can track the row locally.
  Future<SleepLog> addSleepLog(SleepLog log);

  /// Saves edits to an existing log (matched by [SleepLog.id]) and returns the
  /// stored row.
  Future<SleepLog> updateSleepLog(SleepLog log);

  Future<void> deleteSleepLog(String id);
}

class SupabaseSleepService implements SleepService {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<List<SleepLog>> getSleepLogs() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final data = await _client
        .from('sleep_logs')
        .select()
        .eq('user_id', userId)
        .order('started_at', ascending: false);

    return data.map((json) => SleepLog.fromJson(json)).toList();
  }

  @override
  Future<SleepLog> addSleepLog(SleepLog log) async {
    final data = await _client
        .from('sleep_logs')
        .insert(log.toJson())
        .select()
        .single();
    return SleepLog.fromJson(data);
  }

  @override
  Future<SleepLog> updateSleepLog(SleepLog log) async {
    final id = log.id;
    if (id == null) {
      throw ArgumentError('Cannot update a sleep log without an id.');
    }
    final data = await _client
        .from('sleep_logs')
        .update(log.toJson())
        .eq('id', id)
        .select()
        .single();
    return SleepLog.fromJson(data);
  }

  @override
  Future<void> deleteSleepLog(String id) async {
    await _client.from('sleep_logs').delete().eq('id', id);
  }
}

/// In-memory stand-in used by tests and offline development. Keeps a mutable
/// list so add/update/delete behave like a real backing table.
class MockSleepService implements SleepService {
  MockSleepService() {
    final now = DateTime.now();
    _logs.addAll([
      SleepLog(
        id: 'mock-1',
        type: SleepLogType.sleep,
        startedAt: DateTime(now.year, now.month, now.day - 1, 22, 45),
        endedAt: DateTime(now.year, now.month, now.day, 6, 20),
        quality: 86,
      ),
      SleepLog(
        id: 'mock-2',
        type: SleepLogType.nap,
        startedAt: DateTime(now.year, now.month, now.day - 1, 14, 10),
        endedAt: DateTime(now.year, now.month, now.day - 1, 14, 45),
        quality: 78,
      ),
      SleepLog(
        id: 'mock-3',
        type: SleepLogType.sleep,
        startedAt: DateTime(now.year, now.month, now.day - 2, 23, 15),
        endedAt: DateTime(now.year, now.month, now.day - 1, 6, 5),
        quality: 74,
      ),
    ]);
  }

  final List<SleepLog> _logs = [];
  int _nextId = 100;

  @override
  Future<List<SleepLog>> getSleepLogs() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final copy = [..._logs]
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return copy;
  }

  @override
  Future<SleepLog> addSleepLog(SleepLog log) async {
    final stored = log.copyWith(id: 'mock-${_nextId++}');
    _logs.add(stored);
    return stored;
  }

  @override
  Future<SleepLog> updateSleepLog(SleepLog log) async {
    final index = _logs.indexWhere((l) => l.id == log.id);
    if (index != -1) _logs[index] = log;
    return log;
  }

  @override
  Future<void> deleteSleepLog(String id) async {
    _logs.removeWhere((l) => l.id == id);
  }
}
