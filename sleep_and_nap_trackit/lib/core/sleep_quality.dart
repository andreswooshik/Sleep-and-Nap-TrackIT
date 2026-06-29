import '../models/sleep_log.dart';
import 'sleep_insights.dart';
import 'sleep_recommendation.dart';

// A single, transparent contribution to the computed quality score.
class QualityCriterion {
  const QualityCriterion({
    required this.label,
    required this.detail,
    required this.impact,
  });

  final String label;
  final String detail;

  /// Points this criterion added/removed relative to a perfect 100
  /// (`0` = no penalty, negative = deduction).
  final int impact;
}

/// The app's computed rating for a session, with a breakdown of why.
class QualityRating {
  const QualityRating({
    required this.score,
    required this.label,
    required this.criteria,
  });

  final int score; // 0–100
  final String label; // Excellent / Good / Fair / Poor
  final List<QualityCriterion> criteria;
}

/// Ideal nap window, in minutes — short enough to avoid deep-sleep grogginess.
const int kNapIdealMinMinutes = 10;
const int kNapIdealMaxMinutes = 30;

/// Default adult sleep range used when no age-based recommendation is supplied.
const double _defaultMinSleepHours = 7;
const double _defaultMaxSleepHours = 9;

/// Computes a 0–100 sleep/nap quality rating from objective criteria:
/// how well the [duration] fits the recommended range (age-based for sleep,
/// the ideal window for naps) minus a penalty for each negative [factor].
///
/// Pure function — used to pre-fill the rating the user can then adjust.
QualityRating rateSleepQuality({
  required SleepLogType type,
  required Duration duration,
  List<SleepFactor> factors = const [],
  SleepRecommendation? recommendation,
}) {
  final criteria = <QualityCriterion>[];

  final durationCriterion = type == SleepLogType.nap
      ? _napDuration(duration)
      : _sleepDuration(duration, recommendation);
  criteria.add(durationCriterion);

  if (factors.isNotEmpty) {
    final penalty = (factors.length * 6).clamp(0, 40).toInt();
    criteria.add(QualityCriterion(
      label: 'Factors',
      detail: '${factors.length} factor${factors.length == 1 ? '' : 's'} may have disrupted rest',
      impact: -penalty,
    ));
  }

  final raw = 100 + criteria.fold<int>(0, (sum, c) => sum + c.impact);
  final score = raw.clamp(0, 100).toInt();

  return QualityRating(score: score, label: labelForScore(score), criteria: criteria);
}

/// Maps a 0–100 score to a human label.
String labelForScore(int score) {
  if (score >= 85) return 'Excellent';
  if (score >= 70) return 'Good';
  if (score >= 50) return 'Fair';
  return 'Poor';
}

QualityCriterion _sleepDuration(Duration duration, SleepRecommendation? rec) {
  final min = rec?.minSleepHours ?? _defaultMinSleepHours;
  final max = rec?.maxSleepHours ?? _defaultMaxSleepHours;
  final hours = duration.inMinutes / 60.0;
  final range = rec?.sleepRangeLabel ?? '7–9 h';

  if (hours < min) {
    final deficit = min - hours;
    // ~14 pts per hour short, so a couple of hours under is clearly Fair and
    // severe deprivation (≈0h) bottoms out Poor — not a lenient mid-score.
    final impact = -(deficit * 14).round().clamp(0, 80).toInt();
    return QualityCriterion(
      label: 'Duration',
      detail: '${_fmtH(deficit)} under your $range range',
      impact: impact,
    );
  }
  if (hours > max) {
    final excess = hours - max;
    // Oversleeping hurts quality less than deprivation, so penalise it gentler.
    final impact = -(excess * 6).round().clamp(0, 30).toInt();
    return QualityCriterion(
      label: 'Duration',
      detail: '${_fmtH(excess)} over your $range range',
      impact: impact,
    );
  }
  return QualityCriterion(
    label: 'Duration',
    detail: 'Within your $range range',
    impact: 0,
  );
}

QualityCriterion _napDuration(Duration duration) {
  final mins = duration.inMinutes;
  if (mins < kNapIdealMinMinutes) {
    // Scale the penalty by how far below the ideal window it falls, so a
    // near-zero nap scores genuinely low (not a misleadingly high number).
    final shortfall = (kNapIdealMinMinutes - mins) / kNapIdealMinMinutes; // 0..1
    final impact = -(shortfall * 70).round().clamp(0, 70).toInt();
    return QualityCriterion(
      label: 'Nap length',
      detail: mins <= 0
          ? 'Too short to count as real rest'
          : 'Very short — under $kNapIdealMinMinutes min',
      impact: impact,
    );
  }
  if (mins > kNapIdealMaxMinutes) {
    final excess = mins - kNapIdealMaxMinutes;
    final impact = -(excess * 0.8).round().clamp(0, 35).toInt();
    return QualityCriterion(
      label: 'Nap length',
      detail: 'Long nap — over $kNapIdealMaxMinutes min can cause grogginess',
      impact: impact,
    );
  }
  return QualityCriterion(
    label: 'Nap length',
    detail: 'Ideal $kNapIdealMinMinutes–$kNapIdealMaxMinutes min window',
    impact: 0,
  );
}

String _fmtH(double hours) {
  final totalMin = (hours * 60).round();
  final h = totalMin ~/ 60;
  final m = totalMin % 60;
  if (h == 0) return '${m}m';
  if (m == 0) return '${h}h';
  return '${h}h ${m}m';
}
