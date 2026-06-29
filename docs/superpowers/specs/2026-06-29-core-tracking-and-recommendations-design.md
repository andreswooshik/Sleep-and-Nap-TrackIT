# Core Tracking, Healthy-Hours Recommendations & Reminders

## Overview

Extends the app beyond the live stopwatch with three capabilities from the
"Core Sleep & Nap Tracking" board card plus a healthy-living recommendation
engine and a user-set alarm:

1. **Manual log entry** — record a past sleep/nap with date & time pickers
   (no stopwatch required).
2. **Today's tracking status** — a dashboard card summarising what was logged
   today versus the user's recommended hours.
3. **Reminders & alarm** — local notifications for consistent tracking, plus a
   user-set wake/bedtime alarm.
4. **Healthy-hours recommendation** — age-based recommended sleep and nap
   durations (National Sleep Foundation guidance), surfaced on the dashboard.

The work is split into two phases by verifiability:

- **Phase A** (pure Dart + Flutter, fully unit/widget testable): recommendation
  engine, manual entry form, dashboard "Today" card.
- **Phase B** (native platform integration): local notifications + alarm,
  requiring `flutter_local_notifications` + `timezone` and Android/iOS config.

---

## Phase A

### 1. Recommendation engine — `lib/core/sleep_recommendation.dart`

Pure Dart, no Flutter dependency, so it is fully unit-testable.

```dart
class SleepRecommendation {
  final int ageYears;
  final double minSleepHours;
  final double maxSleepHours;
  final int recommendedNapMinutes;     // 0 when napping is not advised
  final String ageBandLabel;           // e.g. "Adult", "Teen"
  final String napAdvice;
}
```

- `recommendationForAge(int years)` → maps age to a National Sleep Foundation
  band (newborn → older adult) returning the sleep-hour range and a sensible
  nap range. Adults: 7–9 h sleep, ~10–20 min power nap. Older adults (65+):
  7–8 h. Teens (14–17): 8–10 h. Etc.
- `recommendationForBirthDate(DateTime dob, {DateTime? now})` → computes age and
  delegates. `now` is injectable for deterministic tests.
- `RecommendationStatus comparedTo(Duration actual)` → returns one of
  `below` / `within` / `above` for an actual average sleep duration, with a
  short human message. Used by the dashboard card.

### 2. Manual entry form — `lib/views/manual_log_view.dart`

A full-screen `ConsumerStatefulWidget` reachable from a dashboard "Add past
log" action.

- Type toggle: Sleep / Nap (segmented).
- Start date+time and End date+time, each via `showDatePicker` +
  `showTimePicker` (theme already styles both).
- Quality slider (0–100, default 80) reusing `kGoodQualityThreshold`.
- Validation: end must be after start; show inline error otherwise.
- Save: builds a `SleepLog` (userId from Supabase auth), calls
  `ref.read(sleepLogsProvider.notifier).add(log)`, pops on success, shows a
  SnackBar on failure (mirrors `TimerView` error handling).

Files touched:
- **Modify** `lib/views/home_view.dart` — add an "Add past log" entry point.

### 3. Dashboard "Today" card — `_TodayStatus` in `home_view.dart`

- New `todayStatusProvider` (in `dashboard_viewmodel.dart`) deriving today's
  logged sleep total + nap count from `sleepLogsProvider`, combined with the
  profile-derived `SleepRecommendation`.
- Card shows: today's logged sleep vs recommended range, today's nap count,
  and a one-line status ("On track" / "Below your 7–9 h goal", etc.).

---

## Phase B (native — requires on-device verification)

### Packages
- `flutter_local_notifications` (scheduling + display)
- `timezone` (correct local scheduling across DST)

### `lib/services/reminder_service.dart`
- `init()` — initialise plugin, request permissions, configure tz.
- `scheduleDailyReminder(TimeOfDay at)` — repeating daily "log your sleep"
  reminder.
- `scheduleAlarm(DateTime at, {required String label})` — one-shot or daily
  wake/bedtime alarm using a high-importance channel + full-screen intent.
- `cancelReminders()` / `cancelAlarm()`.

### Settings UI
- Extend `settings_view.dart`: the existing notifications switch gates the
  daily reminder; add a time picker for the reminder time and an alarm
  section (enable + time).

### Native config (manual, documented)
- Android: `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`/`USE_EXACT_ALARM`,
  `RECEIVE_BOOT_COMPLETED`; notification channel; min SDK check.
- iOS: notification capability + `UNUserNotificationCenter` permission prompt.

### Caveat
Notification/alarm runtime behaviour cannot be verified in CI or a headless
environment — it needs a real device/emulator. Phase B ships with the code and
a manual test checklist.

---

## Testing

- **Unit** `test/core/sleep_recommendation_test.dart`: age→band mapping at
  boundaries (17/18/25/26/64/65), nap advice presence, `comparedTo`
  below/within/above.
- **Widget** `test/views/manual_log_view_test.dart`: renders type toggle +
  Save; rejects end-before-start with an inline error.
- Phase B reminder scheduling: logic-level test of the next-fire computation
  where feasible; UI gated behind the existing notifications toggle.

## Styling

Reuses `LullabyColors`, `GlassCard`, `LullabyDecorations`, and the existing
date/time picker themes for visual consistency with the dashboard and timer.

---

## Phase B on-device verification checklist

The notification/alarm runtime cannot be exercised in CI. On a real device or
emulator, confirm:

- [ ] First launch with notifications enabled prompts for the OS notification
      permission (Android 13+ / iOS).
- [ ] Settings → "Reminders & alarm" toggle off cancels both schedules; on
      reschedules them.
- [ ] Editing the bedtime time reschedules the daily reminder; editing the
      wake-up time reschedules the alarm (check `adb shell dumpsys alarm`).
- [ ] The reminder fires daily at the chosen time; the alarm uses the
      high-importance channel (heads-up / full-screen).
- [ ] Schedules survive an app restart and a device reboot (boot receiver).
- [ ] **Timezone:** `tz.local` defaults to UTC. For DST-correct firing, set the
      device's real IANA zone in `LocalNotificationReminderService.init()`
      (e.g. add the `flutter_timezone` package and
      `tz.setLocalLocation(tz.getLocation(await FlutterTimezone.getLocalTimezone()))`).
- [ ] Android exact alarms: on Android 14+, `USE_EXACT_ALARM` is declared; if
      targeting stricter policies, fall back to inexact mode or request the
      exact-alarm special access.

## Implemented files (this change)

Phase A:
- `lib/core/sleep_recommendation.dart` (+ test)
- `lib/views/manual_log_view.dart` (+ test)
- `lib/viewmodels/dashboard_viewmodel.dart` — `TodayStatus` + `todayStatusProvider`
- `lib/views/home_view.dart` — Today card + "Add a past log" entry point

Phase B:
- `lib/core/reminder_schedule.dart` (+ test) — pure next-fire + `ClockTime`
- `lib/services/reminder_service.dart` — `ReminderService` interface,
  `LocalNotificationReminderService`, `NoopReminderService`
- `lib/viewmodels/reminder_settings_viewmodel.dart` (+ test)
- `lib/providers/service_providers.dart` — `reminderServiceProvider`
- `lib/views/settings_view.dart` — reminder/alarm tiles
- `lib/views/main_shell.dart` — sync schedules on profile load
- `lib/models/profile.dart` — `copyWith` extended for bedtime/wake-up time
- `pubspec.yaml`, `android/app/build.gradle.kts`,
  `android/app/src/main/AndroidManifest.xml`
