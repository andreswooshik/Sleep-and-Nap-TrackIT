/// How an actual sleep duration compares to the recommended range.
enum RecommendationStatus { below, within, above }

/// Age-based healthy sleep & nap guidance, following the National Sleep
/// Foundation's recommended duration bands.
///
/// Pure Dart (no Flutter import) so it is fully unit-testable.
class SleepRecommendation {
  const SleepRecommendation({
    required this.ageYears,
    required this.minSleepHours,
    required this.maxSleepHours,
    required this.recommendedNapMinutes,
    required this.ageBandLabel,
    required this.napAdvice,
  });

  final int ageYears;
  final double minSleepHours;
  final double maxSleepHours;

  /// Suggested power-nap length. `0` means napping is not generally advised
  /// for this age band (it can mask a nighttime sleep problem).
  final int recommendedNapMinutes;

  /// Human label for the age band, e.g. "Adult", "Teen".
  final String ageBandLabel;

  /// One-line, age-appropriate nap guidance.
  final String napAdvice;

  /// Midpoint of the recommended range — a convenient single "target".
  double get targetSleepHours => (minSleepHours + maxSleepHours) / 2;

  /// A compact "7–9 h" style label for the recommended range.
  String get sleepRangeLabel {
    String fmt(double h) =>
        h == h.roundToDouble() ? h.toInt().toString() : h.toString();
    return '${fmt(minSleepHours)}–${fmt(maxSleepHours)} h';
  }

  /// Classifies an actual (e.g. averaged or today's total) sleep [duration]
  /// against the recommended range. A 15-minute grace band keeps trivially
  /// short/long sessions from flipping to below/above.
  RecommendationStatus comparedTo(Duration duration) {
    final hours = duration.inMinutes / 60.0;
    const grace = 0.25; // 15 minutes
    if (hours < minSleepHours - grace) return RecommendationStatus.below;
    if (hours > maxSleepHours + grace) return RecommendationStatus.above;
    return RecommendationStatus.within;
  }

  /// A short message describing where [duration] sits relative to the range.
  String statusMessage(Duration duration) {
    switch (comparedTo(duration)) {
      case RecommendationStatus.below:
        return 'Below your $sleepRangeLabel range — try to rest more.';
      case RecommendationStatus.within:
        return "On track — you're within your $sleepRangeLabel range.";
      case RecommendationStatus.above:
        return 'Above your $sleepRangeLabel range — plenty of rest.';
    }
  }
}

/// Returns the recommendation for a person of [years] of age (clamped at 0).
SleepRecommendation recommendationForAge(int years) {
  final age = years < 0 ? 0 : years;

  if (age < 1) {
    return SleepRecommendation(
      ageYears: age,
      minSleepHours: 12,
      maxSleepHours: 16,
      recommendedNapMinutes: 0,
      ageBandLabel: 'Infant',
      napAdvice: 'Infants nap frequently throughout the day.',
    );
  }
  if (age <= 2) {
    return SleepRecommendation(
      ageYears: age,
      minSleepHours: 11,
      maxSleepHours: 14,
      recommendedNapMinutes: 0,
      ageBandLabel: 'Toddler',
      napAdvice: 'Daily naps (1–3 h) are an important part of total sleep.',
    );
  }
  if (age <= 5) {
    return SleepRecommendation(
      ageYears: age,
      minSleepHours: 10,
      maxSleepHours: 13,
      recommendedNapMinutes: 60,
      ageBandLabel: 'Preschool',
      napAdvice: 'An early-afternoon nap supports the daily sleep total.',
    );
  }
  if (age <= 13) {
    return SleepRecommendation(
      ageYears: age,
      minSleepHours: 9,
      maxSleepHours: 11,
      recommendedNapMinutes: 0,
      ageBandLabel: 'School age',
      napAdvice: 'Most school-age children no longer need regular naps.',
    );
  }
  if (age <= 17) {
    return SleepRecommendation(
      ageYears: age,
      minSleepHours: 8,
      maxSleepHours: 10,
      recommendedNapMinutes: 20,
      ageBandLabel: 'Teen',
      napAdvice: 'A short 20-min nap can help, but protect nighttime sleep.',
    );
  }
  if (age <= 64) {
    return SleepRecommendation(
      ageYears: age,
      minSleepHours: 7,
      maxSleepHours: 9,
      recommendedNapMinutes: 20,
      ageBandLabel: 'Adult',
      napAdvice: 'Keep naps to 10–20 min and before mid-afternoon.',
    );
  }
  return SleepRecommendation(
    ageYears: age,
    minSleepHours: 7,
    maxSleepHours: 8,
    recommendedNapMinutes: 30,
    ageBandLabel: 'Older adult',
    napAdvice: 'A brief nap up to 30 min can be restorative.',
  );
}

/// Computes age from [dob] (using [now], default `DateTime.now()`) and returns
/// the matching recommendation.
SleepRecommendation recommendationForBirthDate(DateTime dob, {DateTime? now}) {
  final today = now ?? DateTime.now();
  var age = today.year - dob.year;
  final hadBirthdayThisYear = today.month > dob.month ||
      (today.month == dob.month && today.day >= dob.day);
  if (!hadBirthdayThisYear) age -= 1;
  return recommendationForAge(age);
}
