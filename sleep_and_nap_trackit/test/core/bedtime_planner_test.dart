import 'package:flutter_test/flutter_test.dart';
import 'package:sleep_and_nap_trackit/core/bedtime_planner.dart';
import 'package:sleep_and_nap_trackit/core/reminder_schedule.dart';

void main() {
  group('calculatedTargetBedtime', () {
    test('subtracts the goal from the wake-up time', () {
      final plan = BedtimePlan(
        sleepGoalHours: 8,
        wakeUp: const ClockTime(7, 0),
      );
      // 07:00 - 8h = 23:00 the night before.
      expect(plan.calculatedTargetBedtime, const ClockTime(23, 0));
    });

    test('wraps correctly when the result is in the afternoon', () {
      final plan = BedtimePlan(
        sleepGoalHours: 8,
        wakeUp: const ClockTime(11, 0),
      );
      // 11:00 - 8h = 03:00.
      expect(plan.calculatedTargetBedtime, const ClockTime(3, 0));
    });
  });

  group('plannedSleep', () {
    test('measures forward across midnight', () {
      final plan = BedtimePlan(
        sleepGoalHours: 8,
        wakeUp: const ClockTime(7, 0),
        bedtimeReminder: const ClockTime(23, 0),
      );
      expect(plan.plannedSleep, const Duration(hours: 8));
    });

    test('is null when no reminder is set', () {
      final plan = BedtimePlan(sleepGoalHours: 8, wakeUp: const ClockTime(7, 0));
      expect(plan.plannedSleep, isNull);
      expect(plan.hasTimingConflict, isFalse);
    });
  });

  group('conflict detection', () {
    test('no conflict when reminder matches the goal', () {
      final plan = BedtimePlan(
        sleepGoalHours: 8,
        wakeUp: const ClockTime(7, 0),
        bedtimeReminder: const ClockTime(23, 0),
      );
      expect(plan.conflict, BedtimeConflict.none);
      expect(plan.hasTimingConflict, isFalse);
      expect(plan.conflictMessage, isNull);
      expect(plan.reminderMatchesIdeal, isTrue);
    });

    test('flags the classic AM/PM mix-up (2:30 PM vs 2:30 AM)', () {
      // Wake 11:00 AM, goal 8h -> ideal bedtime 03:00 AM.
      // User sets 2:30 PM (14:30) instead of 2:30 AM (02:30).
      final plan = BedtimePlan(
        sleepGoalHours: 8,
        wakeUp: const ClockTime(11, 0),
        bedtimeReminder: const ClockTime(14, 30),
      );
      expect(plan.conflict, BedtimeConflict.ampmMismatch);
      expect(plan.hasTimingConflict, isTrue);
      expect(plan.conflictMessage, contains('2:30 AM'));
    });

    test('the corrected AM time is conflict-free', () {
      final plan = BedtimePlan(
        sleepGoalHours: 8,
        wakeUp: const ClockTime(11, 0),
        bedtimeReminder: const ClockTime(2, 30),
      );
      expect(plan.conflict, BedtimeConflict.none);
    });

    test('flags too little sleep', () {
      // Ideal 23:00; reminder at 03:00 leaves only 4h before a 07:00 alarm.
      final plan = BedtimePlan(
        sleepGoalHours: 8,
        wakeUp: const ClockTime(7, 0),
        bedtimeReminder: const ClockTime(3, 0),
      );
      expect(plan.conflict, BedtimeConflict.tooLittleSleep);
      expect(plan.conflictMessage, contains('under your 8h goal'));
    });

    test('flags too much sleep', () {
      // 11h before a 07:00 alarm (reminder 20:00) exceeds an 8h goal.
      final plan = BedtimePlan(
        sleepGoalHours: 8,
        wakeUp: const ClockTime(7, 0),
        bedtimeReminder: const ClockTime(20, 0),
      );
      expect(plan.conflict, BedtimeConflict.tooMuchSleep);
    });

    test('a small drift within tolerance is not a conflict', () {
      // 8h15m before the alarm, goal 8h, tolerance 90m -> fine.
      final plan = BedtimePlan(
        sleepGoalHours: 8,
        wakeUp: const ClockTime(7, 0),
        bedtimeReminder: const ClockTime(22, 45),
      );
      expect(plan.hasTimingConflict, isFalse);
    });
  });
}
