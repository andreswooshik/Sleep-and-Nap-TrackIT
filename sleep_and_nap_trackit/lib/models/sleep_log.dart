enum SleepLogType { sleep, nap }

class SleepLog {
  const SleepLog({
    this.id,
    this.userId,
    required this.type,
    required this.startedAt,
    required this.endedAt,
    required this.quality,
    this.factors = const [],
  });

  final String? id;
  final String? userId;
  final SleepLogType type;
  final DateTime startedAt;
  final DateTime endedAt;
  final int quality;

  /// Keys of the factors the user flagged as affecting a poor session.
  /// Maps to the `factors` text[] column in Supabase.
  final List<String> factors;

  Duration get duration => endedAt.difference(startedAt);

  String get label => type == SleepLogType.sleep ? 'Sleep' : 'Nap';

  SleepLog copyWith({
    String? id,
    String? userId,
    SleepLogType? type,
    DateTime? startedAt,
    DateTime? endedAt,
    int? quality,
    List<String>? factors,
  }) {
    return SleepLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      quality: quality ?? this.quality,
      factors: factors ?? this.factors,
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'type': type == SleepLogType.sleep ? 'sleep' : 'nap',
        'started_at': startedAt.toIso8601String(),
        'ended_at': endedAt.toIso8601String(),
        'quality': quality,
        'factors': factors,
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
        factors: (json['factors'] as List<dynamic>?)?.cast<String>() ?? const [],
      );
}
