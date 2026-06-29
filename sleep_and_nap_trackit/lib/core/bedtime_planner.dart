import 'reminder_schedule.dart';
import 'sleep_format.dart';

/// The kind of timing problem detected between the user's bedtime reminder and
/// their wake-up alarm + sleep goal.
enum BedtimeConflict {
  /// Reminder, goal and alarm are consistent.
  none,

  /// The reminder appears to be set to the wrong half of the day (AM↔PM):
  /// flipping it by 12h makes the numbers line up with the goal.
  ampmMismatch,

  /// The reminder leaves materially less than the sleep goal before the alarm.
  tooLittleSleep,

  /// The reminder leaves materially more than the sleep goal before the alarm.
  tooMuchSleep,
}

/// Immutable, fully-derived plan for a night's sleep. Pure value object — all
/// outputs (`calculatedTargetBedtime`, `hasTimingConflict`, …) are computed
/// from the three inputs, so it is trivially testable and UI-agnostic.
class BedtimePlan {
  const BedtimePlan({
    required this.sleepGoalHours,
    required this.wakeUp,
    this.bedtimeReminder,
    this.toleranceMinutes = 90,
  });

  /// Target nightly sleep, in whole hours.
  final int sleepGoalHours;

  /// When the user wants to wake up.
  final ClockTime wakeUp;

  /// When the user has set their bedtime reminder (null = not set yet).
  final ClockTime? bedtimeReminder;

  /// How far the planned sleep may drift from the goal before it's a conflict.
  final int toleranceMinutes;

  /// Ideal bedtime = wake-up minus the sleep goal, wrapping across midnight.
  ClockTime get calculatedTargetBedtime =>
      ClockTime.fromMinutesOfDay(wakeUp.minutesOfDay - sleepGoalHours * 60);

  /// Sleep the user would actually get from their reminder to their alarm
  /// (measured forward across midnight). Null when no reminder is set.
  Duration? get plannedSleep {
    final reminder = bedtimeReminder;
    if (reminder == null) return null;
    return Duration(minutes: _forwardMinutes(reminder, wakeUp));
  }

  /// The detected conflict category between reminder, goal and alarm.
  BedtimeConflict get conflict {
    final planned = plannedSleep;
    if (planned == null) return BedtimeConflict.none;

    final goal = sleepGoalHours * 60;
    final delta = planned.inMinutes - goal;
    if (delta.abs() <= toleranceMinutes) return BedtimeConflict.none;

    // Would flipping the reminder by 12h (an AM/PM slip) reconcile it?
    final flipped = ClockTime.fromMinutesOfDay(bedtimeReminder!.minutesOfDay + 720);
    final flippedDelta = _forwardMinutes(flipped, wakeUp) - goal;
    if (flippedDelta.abs() <= toleranceMinutes) {
      return BedtimeConflict.ampmMismatch;
    }

    return delta < 0
        ? BedtimeConflict.tooLittleSleep
        : BedtimeConflict.tooMuchSleep;
  }

  /// Clean boolean for the UI.
  bool get hasTimingConflict => conflict != BedtimeConflict.none;

  /// A human-readable explanation of the conflict, or null when there is none.
  String? get conflictMessage {
    final planned = plannedSleep;
    switch (conflict) {
      case BedtimeConflict.none:
        return null;
      case BedtimeConflict.ampmMismatch:
        final suggestion =
            ClockTime.fromMinutesOfDay(bedtimeReminder!.minutesOfDay + 720);
        return 'Your bedtime reminder looks like an AM/PM mix-up — '
            'did you mean ${suggestion.label12h}? As set it gives '
            '${formatDuration(planned!)} before your alarm, not your '
            '${sleepGoalHours}h goal.';
      case BedtimeConflict.tooLittleSleep:
        return 'That reminder leaves only ${formatDuration(planned!)} before '
            'your alarm — under your ${sleepGoalHours}h goal.';
      case BedtimeConflict.tooMuchSleep:
        return 'That reminder leaves ${formatDuration(planned!)} before your '
            'alarm — more than your ${sleepGoalHours}h goal.';
    }
  }

  /// True when the bedtime reminder matches the calculated ideal bedtime
  /// (within tolerance) — handy for showing an "on track" affirmation.
  bool get reminderMatchesIdeal =>
      bedtimeReminder != null && !hasTimingConflict;

  BedtimePlan copyWith({
    int? sleepGoalHours,
    ClockTime? wakeUp,
    ClockTime? bedtimeReminder,
    bool clearBedtimeReminder = false,
    int? toleranceMinutes,
  }) {
    return BedtimePlan(
      sleepGoalHours: sleepGoalHours ?? this.sleepGoalHours,
      wakeUp: wakeUp ?? this.wakeUp,
      bedtimeReminder:
          clearBedtimeReminder ? null : (bedtimeReminder ?? this.bedtimeReminder),
      toleranceMinutes: toleranceMinutes ?? this.toleranceMinutes,
    );
  }

  /// Forward distance in minutes from [from] to [to], wrapping across midnight
  /// (so 23:00 -> 07:00 is 8h, not -16h).
  static int _forwardMinutes(ClockTime from, ClockTime to) {
    return ((to.minutesOfDay - from.minutesOfDay) % 1440 + 1440) % 1440;
  }
}
