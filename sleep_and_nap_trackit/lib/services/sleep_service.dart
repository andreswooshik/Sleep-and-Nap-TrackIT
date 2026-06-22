import '../models/sleep_log.dart';

abstract class SleepService {
  Future<List<SleepLog>> getSleepLogs();
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
}
