enum SleepLogType { sleep, nap }

class SleepLog {
  const SleepLog({
    required this.type,
    required this.startedAt,
    required this.endedAt,
    required this.quality,
  });

  final SleepLogType type;
  final DateTime startedAt;
  final DateTime endedAt;
  final int quality;

  Duration get duration => endedAt.difference(startedAt);

  String get label => type == SleepLogType.sleep ? 'Sleep' : 'Nap';
}
