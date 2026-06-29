import 'package:flutter_test/flutter_test.dart';
import 'package:sleep_and_nap_trackit/core/sleep_recommendation.dart';

void main() {
  group('recommendationForAge', () {
    test('maps adult ages to 7-9 h', () {
      final r = recommendationForAge(30);
      expect(r.ageBandLabel, 'Adult');
      expect(r.minSleepHours, 7);
      expect(r.maxSleepHours, 9);
    });

    test('band boundaries flip at the right ages', () {
      expect(recommendationForAge(17).ageBandLabel, 'Teen');
      expect(recommendationForAge(18).ageBandLabel, 'Adult');
      expect(recommendationForAge(64).ageBandLabel, 'Adult');
      expect(recommendationForAge(65).ageBandLabel, 'Older adult');
    });

    test('older adults get the narrower 7-8 h range', () {
      final r = recommendationForAge(70);
      expect(r.minSleepHours, 7);
      expect(r.maxSleepHours, 8);
    });

    test('teens are advised short naps; school-age are not', () {
      expect(recommendationForAge(15).recommendedNapMinutes, greaterThan(0));
      expect(recommendationForAge(10).recommendedNapMinutes, 0);
    });

    test('every band provides nap advice text', () {
      for (final age in [0, 2, 4, 10, 16, 40, 80]) {
        expect(recommendationForAge(age).napAdvice, isNotEmpty);
      }
    });

    test('negative ages are clamped to 0', () {
      expect(recommendationForAge(-5).ageYears, 0);
      expect(recommendationForAge(-5).ageBandLabel, 'Infant');
    });

    test('sleepRangeLabel renders whole numbers without decimals', () {
      expect(recommendationForAge(30).sleepRangeLabel, '7–9 h');
    });
  });

  group('recommendationForBirthDate', () {
    test('computes age accounting for birthday not yet reached this year', () {
      final now = DateTime(2026, 6, 29);
      // Born late in the year -> birthday not yet passed.
      final r = recommendationForBirthDate(DateTime(2009, 12, 1), now: now);
      expect(r.ageYears, 16); // turns 17 in December
      expect(r.ageBandLabel, 'Teen');
    });

    test('counts the birthday on the day it occurs', () {
      final now = DateTime(2026, 6, 29);
      final r = recommendationForBirthDate(DateTime(2008, 6, 29), now: now);
      expect(r.ageYears, 18);
      expect(r.ageBandLabel, 'Adult');
    });
  });

  group('comparedTo', () {
    final adult = recommendationForAge(30); // 7-9 h

    test('flags durations clearly under the range as below', () {
      expect(adult.comparedTo(const Duration(hours: 5)),
          RecommendationStatus.below);
    });

    test('treats a duration inside the range as within', () {
      expect(adult.comparedTo(const Duration(hours: 8)),
          RecommendationStatus.within);
    });

    test('flags durations clearly over the range as above', () {
      expect(adult.comparedTo(const Duration(hours: 11)),
          RecommendationStatus.above);
    });

    test('a 15-minute grace band keeps edge values within', () {
      expect(adult.comparedTo(const Duration(hours: 6, minutes: 50)),
          RecommendationStatus.within);
      expect(adult.comparedTo(const Duration(hours: 9, minutes: 10)),
          RecommendationStatus.within);
    });

    test('statusMessage mentions the range', () {
      expect(adult.statusMessage(const Duration(hours: 5)), contains('7–9 h'));
    });
  });
}
