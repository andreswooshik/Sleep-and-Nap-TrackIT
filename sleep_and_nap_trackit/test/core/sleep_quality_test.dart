import 'package:flutter_test/flutter_test.dart';
import 'package:sleep_and_nap_trackit/core/sleep_insights.dart';
import 'package:sleep_and_nap_trackit/core/sleep_quality.dart';
import 'package:sleep_and_nap_trackit/core/sleep_recommendation.dart';
import 'package:sleep_and_nap_trackit/models/sleep_log.dart';

void main() {
  final adult = recommendationForAge(30); // 7–9 h

  group('rateSleepQuality - sleep', () {
    test('a duration within range with no factors scores 100 / Excellent', () {
      final r = rateSleepQuality(
        type: SleepLogType.sleep,
        duration: const Duration(hours: 8),
        recommendation: adult,
      );
      expect(r.score, 100);
      expect(r.label, 'Excellent');
    });

    test('sleeping well under the range is penalised', () {
      final r = rateSleepQuality(
        type: SleepLogType.sleep,
        duration: const Duration(hours: 4),
        recommendation: adult,
      );
      expect(r.score, lessThan(80));
      expect(r.criteria.first.label, 'Duration');
      expect(r.criteria.first.impact, lessThan(0));
    });

    test('severe deprivation bottoms out as Poor, not a mid-score', () {
      final twoHours = rateSleepQuality(
        type: SleepLogType.sleep,
        duration: const Duration(hours: 2),
        recommendation: adult,
      );
      expect(twoHours.score, lessThan(50));
      expect(twoHours.label, 'Poor');

      // A 4h sleep should not be flattered as "Good".
      final fourHours = rateSleepQuality(
        type: SleepLogType.sleep,
        duration: const Duration(hours: 4),
        recommendation: adult,
      );
      expect(fourHours.score, lessThan(70));
    });

    test('oversleeping is penalised more gently than undersleeping', () {
      final under = rateSleepQuality(
        type: SleepLogType.sleep,
        duration: const Duration(hours: 5), // 2h under
        recommendation: adult,
      );
      final over = rateSleepQuality(
        type: SleepLogType.sleep,
        duration: const Duration(hours: 11), // 2h over
        recommendation: adult,
      );
      expect(over.score, greaterThan(under.score));
    });

    test('negative factors lower the score', () {
      final clean = rateSleepQuality(
        type: SleepLogType.sleep,
        duration: const Duration(hours: 8),
        recommendation: adult,
      );
      final disrupted = rateSleepQuality(
        type: SleepLogType.sleep,
        duration: const Duration(hours: 8),
        factors: [SleepFactor.caffeine, SleepFactor.stress],
        recommendation: adult,
      );
      expect(disrupted.score, lessThan(clean.score));
    });

    test('falls back to a 7-9h default when no recommendation is given', () {
      final r = rateSleepQuality(
        type: SleepLogType.sleep,
        duration: const Duration(hours: 8),
      );
      expect(r.score, 100);
    });
  });

  group('rateSleepQuality - nap', () {
    test('an ideal-length nap scores full marks', () {
      final r = rateSleepQuality(
        type: SleepLogType.nap,
        duration: const Duration(minutes: 20),
      );
      expect(r.criteria.first.impact, 0);
      expect(r.label, 'Excellent');
    });

    test('a near-zero nap scores low, not high', () {
      final zero = rateSleepQuality(
        type: SleepLogType.nap,
        duration: Duration.zero,
      );
      expect(zero.score, lessThanOrEqualTo(40));
      expect(zero.label, anyOf('Poor', 'Fair'));

      // A short-but-real 5-min nap sits between zero and the ideal window.
      final five = rateSleepQuality(
        type: SleepLogType.nap,
        duration: const Duration(minutes: 5),
      );
      expect(five.score, greaterThan(zero.score));
      expect(five.score, lessThan(100));
    });

    test('an overly long nap is penalised for grogginess', () {
      final r = rateSleepQuality(
        type: SleepLogType.nap,
        duration: const Duration(minutes: 90),
      );
      expect(r.score, lessThan(85));
      expect(r.criteria.first.label, 'Nap length');
    });
  });

  group('labelForScore', () {
    test('maps score bands to labels', () {
      expect(labelForScore(90), 'Excellent');
      expect(labelForScore(75), 'Good');
      expect(labelForScore(55), 'Fair');
      expect(labelForScore(30), 'Poor');
    });
  });

  test('score never leaves the 0–100 range', () {
    final r = rateSleepQuality(
      type: SleepLogType.sleep,
      duration: const Duration(minutes: 1),
      factors: SleepFactor.values,
      recommendation: adult,
    );
    expect(r.score, inInclusiveRange(0, 100));
  });
}
