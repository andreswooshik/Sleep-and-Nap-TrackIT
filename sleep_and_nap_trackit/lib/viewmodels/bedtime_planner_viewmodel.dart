import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/bedtime_planner.dart';
import '../core/reminder_schedule.dart';

/// Reactive controller for the bedtime-planning feature.
///
/// Holds the three inputs (sleep goal, wake-up alarm, bedtime reminder) as an
/// immutable [BedtimePlan]; every derived value the UI needs — the calculated
/// target bedtime and `hasTimingConflict` — comes off that plan, so the view
/// stays a thin reflection of state (MVVM) and the validation logic lives in a
/// pure, testable core.
class BedtimePlannerNotifier extends StateNotifier<BedtimePlan> {
  BedtimePlannerNotifier({
    int sleepGoalHours = 8,
    ClockTime wakeUp = const ClockTime(7, 0),
    ClockTime? bedtimeReminder,
  }) : super(BedtimePlan(
          sleepGoalHours: sleepGoalHours,
          wakeUp: wakeUp,
          bedtimeReminder: bedtimeReminder,
        ));

  void setSleepGoalHours(int hours) =>
      state = state.copyWith(sleepGoalHours: hours);

  void setWakeUp(ClockTime time) => state = state.copyWith(wakeUp: time);

  void setBedtimeReminder(ClockTime time) =>
      state = state.copyWith(bedtimeReminder: time);

  void clearBedtimeReminder() =>
      state = state.copyWith(clearBedtimeReminder: true);

  /// Convenience: snap the bedtime reminder to the calculated ideal time,
  /// clearing any conflict in one tap.
  void useIdealBedtime() =>
      state = state.copyWith(bedtimeReminder: state.calculatedTargetBedtime);

  /// Accepts the AM/PM-flip suggestion when an [BedtimeConflict.ampmMismatch]
  /// is detected (no-op otherwise).
  void acceptAmPmSuggestion() {
    final reminder = state.bedtimeReminder;
    if (reminder == null || state.conflict != BedtimeConflict.ampmMismatch) {
      return;
    }
    state = state.copyWith(
      bedtimeReminder: ClockTime.fromMinutesOfDay(reminder.minutesOfDay + 720),
    );
  }
}

/// Family-free provider with sensible defaults. Seed from a profile by reading
/// this provider's notifier and calling the setters, or create a scoped
/// override with initial values.
final bedtimePlannerProvider =
    StateNotifierProvider<BedtimePlannerNotifier, BedtimePlan>(
  (ref) => BedtimePlannerNotifier(),
);
