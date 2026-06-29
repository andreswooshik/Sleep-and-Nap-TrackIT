// Pure presentation helpers for sleep data — no Flutter or I/O dependencies so
// they can be unit-tested in isolation and reused across every view.

/// Formats a raw [minutes] count as a friendly duration string.
///
/// - `0`            -> `"0m"`
/// - `45`           -> `"45m"`
/// - `480`          -> `"8h"`
/// - `495`          -> `"8h 15m"`
///
/// Negative inputs are clamped to zero.
String formatMinutes(int minutes) {
  final total = minutes < 0 ? 0 : minutes;
  final h = total ~/ 60;
  final m = total % 60;
  if (h == 0) return '${m}m';
  if (m == 0) return '${h}h';
  return '${h}h ${m}m';
}

/// Convenience overload for a [Duration].
String formatDuration(Duration duration) => formatMinutes(duration.inMinutes);

/// Sleep-duration value for a summary tile. Falls back to an encouraging
/// placeholder (rather than a bare "—") when there is no data yet.
String formatAverageSleep(Duration? average) {
  if (average == null || average.inMinutes <= 0) return 'Log to see';
  return formatDuration(average);
}

/// Rest-quality value for a summary tile. `0` / null means "no data yet",
/// which we present encouragingly instead of a broken dash.
String formatQuality(int? qualityPercent) {
  if (qualityPercent == null || qualityPercent <= 0) return '—';
  return '$qualityPercent%';
}

/// A short, encouraging caption shown under an empty quality/average tile.
String get emptyMetricHint => 'Start tracking tonight';

/// Contextual coaching line for the dashboard, driven by what's logged today
/// and (optionally) the current hour for a time-of-day nuance.
///
/// [sleepLoggedToday] is today's total sleep; [recommendedRangeLabel] is e.g.
/// "7–9 h". [hour] (0–23) lets the copy adapt to morning/evening.
String coachingText({
  required Duration sleepLoggedToday,
  String recommendedRangeLabel = '7–9 h',
  int? hour,
}) {
  final loggedMinutes = sleepLoggedToday.inMinutes;

  if (loggedMinutes <= 0) {
    final h = hour ?? DateTime.now().hour;
    if (h >= 20 || h < 4) {
      return 'Winding down? Aim for $recommendedRangeLabel of sleep tonight.';
    }
    return 'Aim for $recommendedRangeLabel of sleep today. '
        'Keep naps short and before mid-afternoon.';
  }

  return "Nicely done — you've logged ${formatDuration(sleepLoggedToday)} so far today.";
}
