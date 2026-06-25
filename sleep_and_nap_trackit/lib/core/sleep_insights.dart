import 'package:flutter/material.dart';

/// Quality at or above this is considered a good rest; below triggers the
/// reflection + insights flow.
const int kGoodQualityThreshold = 60;

/// A factor that may have affected the quality of a sleep or nap session.
enum SleepFactor {
  caffeine('Caffeine', Icons.local_cafe_outlined),
  lateScreens('Late screens', Icons.phone_iphone_outlined),
  stress('Stress', Icons.psychology_outlined),
  noise('Noise', Icons.volume_up_outlined),
  light('Light', Icons.lightbulb_outline),
  temperature('Temperature', Icons.thermostat_outlined),
  ateLate('Ate late', Icons.restaurant_outlined),
  alcohol('Alcohol', Icons.wine_bar_outlined),
  irregularSchedule('Irregular schedule', Icons.schedule_outlined),
  lateExercise('Late exercise', Icons.fitness_center_outlined);

  const SleepFactor(this.label, this.icon);

  final String label;
  final IconData icon;

  /// Stable key persisted to the database.
  String get key => name;

  /// A concrete tip to address this factor.
  String get tip {
    switch (this) {
      case SleepFactor.caffeine:
        return 'Avoid caffeine within 6 hours of bedtime.';
      case SleepFactor.lateScreens:
        return 'Dim screens and enable night mode an hour before bed.';
      case SleepFactor.stress:
        return 'Try a 5-minute breathing exercise to wind down.';
      case SleepFactor.noise:
        return 'Use earplugs or white noise to mask disruptions.';
      case SleepFactor.light:
        return 'Block light with curtains or a sleep mask.';
      case SleepFactor.temperature:
        return 'Keep your room cool — around 18°C (65°F) is ideal.';
      case SleepFactor.ateLate:
        return 'Finish heavy meals at least 3 hours before bed.';
      case SleepFactor.alcohol:
        return 'Limit alcohol in the evening — it fragments deep sleep.';
      case SleepFactor.irregularSchedule:
        return 'Aim for the same sleep and wake times every day.';
      case SleepFactor.lateExercise:
        return 'Finish intense workouts at least 2 hours before bed.';
    }
  }

  static SleepFactor? fromKey(String key) {
    for (final f in SleepFactor.values) {
      if (f.key == key) return f;
    }
    return null;
  }
}

/// General sleep-hygiene tips shown when a poor session has no factors picked.
const List<String> kGeneralTips = [
  'Keep a consistent sleep schedule, even on weekends.',
  'Reserve your bed for sleep to build a strong association.',
];

/// Tips tailored to the picked factors, or general tips if none were picked.
List<String> tipsForFactors(Set<SleepFactor> factors) {
  if (factors.isEmpty) return kGeneralTips;
  return factors.map((f) => f.tip).toList();
}
