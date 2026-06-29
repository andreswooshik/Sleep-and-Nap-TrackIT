import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/reminder_schedule.dart';
import '../models/profile.dart';
import '../providers/profile_provider.dart';
import '../providers/service_providers.dart';
import '../services/reminder_service.dart';

/// Orchestrates the reminder/alarm settings: persists the user's choices to the
/// profile and (re)schedules notifications through [ReminderService].
///
/// Keeps scheduling + persistence logic out of the view (MVVM) and depends on
/// the [ReminderService] abstraction rather than the plugin (DIP).
class ReminderSettingsController {
  ReminderSettingsController(this._ref);

  final Ref _ref;

  ReminderService get _reminders => _ref.read(reminderServiceProvider);
  ProfileController get _profiles => _ref.read(profileControllerProvider);

  static const String alarmLabel = 'Wake up — Sleep & Nap TrackIT';

  /// Brings the OS schedule in line with [profile]: when notifications are on,
  /// schedules the bedtime reminder and wake-up alarm from the stored times;
  /// otherwise cancels both. Safe to call on app start and after any change.
  Future<void> sync(Profile profile) async {
    await _reminders.init();

    if (!profile.notificationsEnabled) {
      await _reminders.cancelDailyReminder();
      await _reminders.cancelAlarm();
      return;
    }

    await _reminders.requestPermissions();

    final bedtime = ClockTime.tryParse(profile.usualBedtime);
    if (bedtime != null) {
      await _reminders.scheduleDailyReminder(
        hour: bedtime.hour,
        minute: bedtime.minute,
      );
    }

    final wake = ClockTime.tryParse(profile.usualWakeUpTime);
    if (wake != null) {
      await _reminders.scheduleAlarm(
        hour: wake.hour,
        minute: wake.minute,
        label: alarmLabel,
      );
    }
  }

  /// Toggles all reminders/alarms on or off and persists the preference.
  Future<void> setEnabled(Profile profile, bool enabled) async {
    final updated = profile.copyWith(notificationsEnabled: enabled);
    await _profiles.update(updated);
    await sync(updated);
  }

  /// Updates the bedtime reminder time and reschedules.
  Future<void> setBedtime(Profile profile, ClockTime time) async {
    final updated = profile.copyWith(usualBedtime: time.toStorageString());
    await _profiles.update(updated);
    await sync(updated);
  }

  /// Updates the wake-up alarm time and reschedules.
  Future<void> setWakeTime(Profile profile, ClockTime time) async {
    final updated = profile.copyWith(usualWakeUpTime: time.toStorageString());
    await _profiles.update(updated);
    await sync(updated);
  }
}

final reminderSettingsControllerProvider =
    Provider<ReminderSettingsController>((ref) {
  return ReminderSettingsController(ref);
});
