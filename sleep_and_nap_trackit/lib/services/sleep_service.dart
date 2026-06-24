import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/sleep_log.dart';

abstract class SleepService {
  Future<List<SleepLog>> getSleepLogs();
  Future<void> addSleepLog(SleepLog log);
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
  Future<void> addSleepLog(SleepLog log) async {
    await _client.from('sleep_logs').insert(log.toJson());
  }

  @override
  Future<void> deleteSleepLog(String id) async {
    await _client.from('sleep_logs').delete().eq('id', id);
  }
}

class MockSleepService implements SleepService {
  @override
  Future<List<SleepLog>> getSleepLogs() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));

    final now = DateTime.now();
    return [
      SleepLog(
        type: SleepLogType.sleep,
        startedAt: DateTime(now.year, now.month, now.day - 1, 22, 45),
        endedAt: DateTime(now.year, now.month, now.day, 6, 20),
        quality: 86,
      ),
      SleepLog(
        type: SleepLogType.nap,
        startedAt: DateTime(now.year, now.month, now.day - 1, 14, 10),
        endedAt: DateTime(now.year, now.month, now.day - 1, 14, 45),
        quality: 78,
      ),
      SleepLog(
        type: SleepLogType.sleep,
        startedAt: DateTime(now.year, now.month, now.day - 2, 23, 15),
        endedAt: DateTime(now.year, now.month, now.day - 1, 6, 5),
        quality: 74,
      ),
    ];
  }

  @override
  Future<void> addSleepLog(SleepLog log) async {}

  @override
  Future<void> deleteSleepLog(String id) async {}
}
