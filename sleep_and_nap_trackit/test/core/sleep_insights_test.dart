import 'package:flutter_test/flutter_test.dart';
import 'package:sleep_and_nap_trackit/core/sleep_insights.dart';

void main() {
  group('sleep insights', () {
    test('empty factors return the general tips', () {
      expect(tipsForFactors({}), kGeneralTips);
    });

    test('selected factors map to their specific tips', () {
      final tips = tipsForFactors({SleepFactor.caffeine, SleepFactor.noise});
      expect(tips, contains(SleepFactor.caffeine.tip));
      expect(tips, contains(SleepFactor.noise.tip));
      expect(tips.length, 2);
    });

    test('every factor has a non-empty tip and label', () {
      for (final f in SleepFactor.values) {
        expect(f.tip, isNotEmpty);
        expect(f.label, isNotEmpty);
      }
    });

    test('fromKey round-trips with key', () {
      for (final f in SleepFactor.values) {
        expect(SleepFactor.fromKey(f.key), f);
      }
      expect(SleepFactor.fromKey('nonsense'), isNull);
    });

    test('good quality threshold is 60', () {
      expect(kGoodQualityThreshold, 60);
    });
  });
}
