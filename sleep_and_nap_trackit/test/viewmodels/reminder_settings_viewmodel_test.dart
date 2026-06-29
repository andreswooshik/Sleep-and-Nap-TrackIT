import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleep_and_nap_trackit/core/reminder_schedule.dart';
import 'package:sleep_and_nap_trackit/models/profile.dart';
import 'package:sleep_and_nap_trackit/providers/service_providers.dart';
import 'package:sleep_and_nap_trackit/services/profile_service.dart';
import 'package:sleep_and_nap_trackit/services/reminder_service.dart';
import 'package:sleep_and_nap_trackit/viewmodels/reminder_settings_viewmodel.dart';

/// Records calls so we can assert on scheduling behaviour without a device.
class FakeReminderService implements ReminderService {
  bool initialised = false;
  ({int hour, int minute})? scheduledReminder;
  ({int hour, int minute, String label})? scheduledAlarm;
  int reminderCancels = 0;
  int alarmCancels = 0;

  @override
  Future<void> init() async => initialised = true;

  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    scheduledReminder = (hour: hour, minute: minute);
  }

  @override
  Future<void> cancelDailyReminder() async => reminderCancels++;

  @override
  Future<void> scheduleAlarm({
    required int hour,
    required int minute,
    required String label,
  }) async {
    scheduledAlarm = (hour: hour, minute: minute, label: label);
  }

  @override
  Future<void> cancelAlarm() async => alarmCancels++;
}

Profile buildProfile({bool notificationsEnabled = true}) => Profile(
      id: 'u1',
      firstName: 'Ada',
      lastName: 'Lovelace',
      dateOfBirth: DateTime(1990, 1, 1),
      usualBedtime: '22:30:00',
      usualWakeUpTime: '07:00:00',
      notificationsEnabled: notificationsEnabled,
    );

void main() {
  late FakeReminderService reminders;
  late MockProfileService profiles;
  late ProviderContainer container;

  setUp(() {
    reminders = FakeReminderService();
    profiles = MockProfileService();
    container = ProviderContainer(overrides: [
      reminderServiceProvider.overrideWithValue(reminders),
      profileServiceProvider.overrideWithValue(profiles),
    ]);
    addTearDown(container.dispose);
  });

  ReminderSettingsController controller() =>
      container.read(reminderSettingsControllerProvider);

  test('sync schedules reminder and alarm from the stored times when enabled',
      () async {
    await controller().sync(buildProfile());

    expect(reminders.initialised, isTrue);
    expect(reminders.scheduledReminder, (hour: 22, minute: 30));
    expect(reminders.scheduledAlarm?.hour, 7);
    expect(reminders.scheduledAlarm?.minute, 0);
  });

  test('sync cancels both when notifications are disabled', () async {
    await controller().sync(buildProfile(notificationsEnabled: false));

    expect(reminders.scheduledReminder, isNull);
    expect(reminders.scheduledAlarm, isNull);
    expect(reminders.reminderCancels, 1);
    expect(reminders.alarmCancels, 1);
  });

  test('setBedtime persists the new time and reschedules', () async {
    final profile = buildProfile();
    profiles.createProfile(profile);

    await controller().setBedtime(profile, const ClockTime(21, 15));

    final saved = await profiles.getProfile();
    expect(saved?.usualBedtime, '21:15:00');
    expect(reminders.scheduledReminder, (hour: 21, minute: 15));
  });

  test('setEnabled(false) persists the flag and cancels schedules', () async {
    final profile = buildProfile();
    profiles.createProfile(profile);

    await controller().setEnabled(profile, false);

    final saved = await profiles.getProfile();
    expect(saved?.notificationsEnabled, isFalse);
    expect(reminders.reminderCancels, 1);
    expect(reminders.alarmCancels, 1);
  });
}
