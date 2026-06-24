enum SleepLogType { sleep, nap }

class SleepLog {
  const SleepLog({
    this.id,
    this.userId,
    required this.type,
    required this.startedAt,
    required this.endedAt,
    required this.quality,
  });

  final String? id;
  final String? userId;
  final SleepLogType type;
  final DateTime startedAt;
  final DateTime endedAt;
  final int quality;

  Duration get duration => endedAt.difference(startedAt);

  String get label => type == SleepLogType.sleep ? 'Sleep' : 'Nap';

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'type': type == SleepLogType.sleep ? 'sleep' : 'nap',
        'started_at': startedAt.toIso8601String(),
        'ended_at': endedAt.toIso8601String(),
        'quality': quality,
      };

  factory SleepLog.fromJson(Map<String, dynamic> json) => SleepLog(
        id: json['id'] as String?,
        userId: json['user_id'] as String?,
        type: (json['type'] as String) == 'sleep'
            ? SleepLogType.sleep
            : SleepLogType.nap,
        startedAt: DateTime.parse(json['started_at'] as String),
        endedAt: DateTime.parse(json['ended_at'] as String),
        quality: json['quality'] as int,
      );
}
