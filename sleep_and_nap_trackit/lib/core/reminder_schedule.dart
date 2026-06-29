// Pure scheduling helpers, free of any plugin/Flutter dependency so they can
// be unit-tested directly.

/// Returns the next wall-clock occurrence of [hour]:[minute] strictly after
/// [from]. If today's occurrence is still in the future it is used; otherwise
/// the time rolls over to tomorrow.
///
/// Used to compute when a daily reminder or alarm should next fire.
DateTime nextDailyOccurrence(int hour, int minute, DateTime from) {
  var candidate =
      DateTime(from.year, from.month, from.day, hour, minute);
  if (!candidate.isAfter(from)) {
    candidate = candidate.add(const Duration(days: 1));
  }
  return candidate;
}

/// Resolves a per-session wake alarm for [hour]:[minute] relative to [from]:
/// the next occurrence of that clock time, strictly after [from]. Identical to
/// [nextDailyOccurrence] but named for the session-alarm use case.
DateTime sessionAlarmAt(int hour, int minute, DateTime from) =>
    nextDailyOccurrence(hour, minute, from);

/// An hour/minute pair, parsed from the `"HH:mm[:ss]"` strings the profile
/// stores for bedtime and wake-up time.
class ClockTime {
  const ClockTime(this.hour, this.minute);

  final int hour;
  final int minute;

  /// Parses `"22:00"` or `"22:00:00"`. Returns null on malformed input rather
  /// than throwing, so callers can fall back to a default.
  static ClockTime? tryParse(String? value) {
    if (value == null) return null;
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
      return null;
    }
    return ClockTime(h, m);
  }

  /// Serialises back to the profile's `"HH:mm:00"` storage format.
  String toStorageString() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:00';

  @override
  bool operator ==(Object other) =>
      other is ClockTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);
}
