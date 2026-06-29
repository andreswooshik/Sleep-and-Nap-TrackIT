import 'package:flutter_test/flutter_test.dart';
import 'package:sleep_and_nap_trackit/core/bedtime_planner.dart';
import 'package:sleep_and_nap_trackit/core/reminder_schedule.dart';
import 'package:sleep_and_nap_trackit/viewmodels/bedtime_planner_viewmodel.dart';

void main() {
  test('setters recompute the derived target bedtime', () {
    final notifier = BedtimePlannerNotifier();
    addTearDown(notifier.dispose);

    notifier.setWakeUp(const ClockTime(6, 30));
    notifier.setSleepGoalHours(7);

    // 06:30 - 7h = 23:30.
    expect(notifier.state.calculatedTargetBedtime, const ClockTime(23, 30));
  });

  test('exposes hasTimingConflict reactively as inputs change', () {
    final notifier = BedtimePlannerNotifier(
      sleepGoalHours: 8,
      wakeUp: const ClockTime(11, 0),
    );
    addTearDown(notifier.dispose);

    notifier.setBedtimeReminder(const ClockTime(14, 30)); // PM slip
    expect(notifier.state.hasTimingConflict, isTrue);
    expect(notifier.state.conflict, BedtimeConflict.ampmMismatch);

    notifier.acceptAmPmSuggestion(); // -> 02:30
    expect(notifier.state.bedtimeReminder, const ClockTime(2, 30));
    expect(notifier.state.hasTimingConflict, isFalse);
  });

  test('useIdealBedtime snaps the reminder to the calculated target', () {
    final notifier = BedtimePlannerNotifier(
      sleepGoalHours: 8,
      wakeUp: const ClockTime(7, 0),
    );
    addTearDown(notifier.dispose);

    notifier.useIdealBedtime();
    expect(notifier.state.bedtimeReminder, const ClockTime(23, 0));
    expect(notifier.state.hasTimingConflict, isFalse);
  });

  test('clearBedtimeReminder removes the reminder', () {
    final notifier = BedtimePlannerNotifier(
      bedtimeReminder: const ClockTime(23, 0),
    );
    addTearDown(notifier.dispose);

    notifier.clearBedtimeReminder();
    expect(notifier.state.bedtimeReminder, isNull);
  });
}
