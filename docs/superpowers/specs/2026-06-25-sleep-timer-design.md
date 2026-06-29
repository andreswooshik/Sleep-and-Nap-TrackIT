# Real-Time Sleep Timer UI & Controller

## Overview

A live timer that records sleep or nap sessions in real time. Tapping "Log Sleep" or "Log Nap" on the dashboard opens a full-screen timer. When the user presses Stop, the app builds an accurate `SleepLog` package and (after a quality prompt) saves it to the Supabase `sleep_logs` table.

## Requirements

1. Timer runs smoothly without interrupting interface frame rates.
2. Pressing "Stop" captures an accurate timestamp package ready for backend transit.

## Key Technical Guarantees

### Accuracy (Requirement 2)

The timer records wall-clock timestamps, never accumulated ticks:

- On `start`: `startedAt = DateTime.now()`
- On `stop`: `endedAt = DateTime.now()`
- Saved duration is `endedAt - startedAt`

This is drift-free. If the display ticker stutters, is throttled, or the browser tab is backgrounded, the saved timestamps remain exact because they come from the system clock, not from counting ticks. No app-lifecycle handling is required for correctness.

### Smoothness (Requirement 1)

- A single `Timer.periodic(Duration(seconds: 1))` updates an `elapsed` value.
- The per-second rebuild is scoped with `ref.watch(sleepTimerProvider.select((s) => s.elapsed))` so only the time-display text rebuilds.
- The Scaffold, header, and Stop button do not rebuild on tick.
- Updating one `Text` widget at 1 Hz cannot drop frames.

## Architecture (Riverpod + MVVM)

### `SleepTimerState`

Immutable state object:

```dart
enum SleepTimerStatus { idle, running, stopped }

class SleepTimerState {
  final SleepLogType type;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final Duration elapsed;
  final SleepTimerStatus status;
}
```

### `SleepTimerNotifier extends StateNotifier<SleepTimerState>`

- `start(SleepLogType type)` — sets `startedAt = DateTime.now()`, `status = running`, starts the periodic timer that updates `elapsed = DateTime.now().difference(startedAt)`.
- `stop()` — cancels the timer, sets `endedAt = DateTime.now()`, recomputes final `elapsed` from timestamps, sets `status = stopped`.
- `reset()` — cancels the timer, returns to `idle`.
- `buildLog({required String userId, required int quality})` — returns a `SleepLog` from the captured timestamps. Throws/asserts if `startedAt`/`endedAt` are null.
- Overrides `dispose()` to cancel the timer.

### `sleepTimerProvider`

```dart
final sleepTimerProvider =
    StateNotifierProvider<SleepTimerNotifier, SleepTimerState>(
  (ref) => SleepTimerNotifier(),
);
```

This is app-scoped (not `autoDispose`) so a running session survives when the
user navigates back to the dashboard, and can be resumed later.

### `TimerView`

Full-screen page constructed with the session `type`:

- Calls `start(type)` once on init.
- Header showing the session type ("Sleep" / "Nap") and start time.
- Large elapsed-time display (HH:MM:SS), scoped to rebuild only on tick.
- A Stop button.

## Flow

1. Dashboard `_QuickActions` "Log Sleep" / "Log Nap" → `Navigator.push` to `TimerView(type: ...)`.
2. `TimerView` starts the timer only if no session is active (otherwise it resumes the running one); the display ticks each second (scoped rebuild).
3. **Go to dashboard** → the user can pop back at any time via the back button or "Keep running, go to dashboard". The session keeps running. The dashboard shows an active-session banner (type + live elapsed) with a **Resume** button that re-opens `TimerView`.
4. **Stop** → notifier cancels timer, captures `endedAt`, status becomes `stopped`. The final elapsed time is shown.
4. A quality dialog appears (slider 0–100, default 80) with **Save** and **Cancel**.
   - **Save**: build the `SleepLog` with `userId` (from `Supabase.instance.client.auth.currentUser`), call `sleepService.addSleepLog(log)`, then `ref.invalidate(sleepLogsProvider)`, then pop back to the dashboard.
   - **Cancel**: dismiss the dialog and stay on the stopped timer (final time still shown). The user can re-open the dialog via a "Save Session" button, or use a separate **Discard** button to leave without saving.
5. Discard / back from a stopped timer returns to the dashboard with nothing saved.

## Time Formatting

Elapsed display uses `HH:MM:SS`:

```
final h = elapsed.inHours.toString().padLeft(2, '0');
final m = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
final s = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
// "$h:$m:$s"
```

## Error Handling

- If the Supabase save fails, show a SnackBar with an error message and keep the user on the stopped timer so they can retry. Do not pop or lose the captured timestamps.
- `buildLog` asserts that `startedAt` and `endedAt` are non-null (only callable from the `stopped` state).

## Styling

Consistent with the existing palette: navy `#27374D` header, blue-grey `#526D82` accents, cream `#F6F3EC` background. The Stop button uses a prominent filled style; Discard uses an outlined/text style.

## Testing

- **Unit (`sleep_timer_provider_test.dart`):**
  - `start` sets status to running and a non-null `startedAt`.
  - After `stop`, status is `stopped`, `endedAt` is non-null, and `endedAt >= startedAt`.
  - `buildLog` returns a `SleepLog` whose `startedAt`/`endedAt` match the captured timestamps and whose `quality`/`userId` match the arguments.
  - `reset` returns to idle.
- **Widget (`timer_view_test.dart`):**
  - TimerView renders the session type and an initial `00:00:00`.
  - Tapping Stop reveals the quality dialog.

## Files

- **New:** `lib/providers/sleep_timer_provider.dart`
- **New:** `lib/views/timer_view.dart`
- **Modify:** `lib/views/home_view.dart` — wire the two `_QuickActions` buttons to push `TimerView`.
- **New tests:** `test/providers/sleep_timer_provider_test.dart`, `test/views/timer_view_test.dart`
