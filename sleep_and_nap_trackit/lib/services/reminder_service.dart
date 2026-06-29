import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../core/reminder_schedule.dart';

/// Schedules local reminders and alarms. A focused interface (ISP) so views and
/// view-models depend on the capability, not on the notification plugin (DIP).
///
/// All times are expressed as a wall-clock [hour]/[minute] that recur daily.
abstract class ReminderService {
  /// Prepares the platform plugin. Safe to call more than once.
  Future<void> init();

  /// Requests OS notification/alarm permission. Returns whether it was granted.
  Future<bool> requestPermissions();

  /// Schedules a daily "log your sleep" reminder at [hour]:[minute].
  Future<void> scheduleDailyReminder({required int hour, required int minute});

  /// Cancels the daily reminder, if any.
  Future<void> cancelDailyReminder();

  /// Schedules a daily wake/bedtime alarm at [hour]:[minute] with [label].
  Future<void> scheduleAlarm({
    required int hour,
    required int minute,
    required String label,
  });

  /// Cancels the alarm, if any.
  Future<void> cancelAlarm();
}

/// Stable notification ids so each schedule replaces its predecessor rather
/// than stacking duplicates.
class _NotificationIds {
  static const reminder = 1001;
  static const alarm = 1002;
}

/// Concrete [ReminderService] backed by `flutter_local_notifications`.
/// Single responsibility: translate reminder/alarm intents into scheduled OS
/// notifications. Holds no UI or persistence logic.
class LocalNotificationReminderService implements ReminderService {
  LocalNotificationReminderService([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialised = false;

  static const _reminderChannel = AndroidNotificationDetails(
    'sleep_reminders',
    'Sleep reminders',
    channelDescription: 'Daily reminders to log your sleep',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  static const _alarmChannel = AndroidNotificationDetails(
    'sleep_alarms',
    'Sleep alarms',
    channelDescription: 'Wake-up and bedtime alarms',
    importance: Importance.max,
    priority: Priority.high,
    fullScreenIntent: true,
    category: AndroidNotificationCategory.alarm,
  );

  @override
  Future<void> init() async {
    if (_initialised || kIsWeb) return;
    tz_data.initializeTimeZones();
    // Set the device's real IANA zone so daily schedules fire at the correct
    // wall-clock time across DST transitions (tz.local otherwise defaults UTC).
    try {
      final localZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localZone));
    } catch (_) {
      // Fall back to the default (UTC) if the platform can't report a zone.
    }
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _initialised = true;
  }

  @override
  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(alert: true, sound: true);
      return granted ?? false;
    }
    return false;
  }

  @override
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    await _scheduleDaily(
      id: _NotificationIds.reminder,
      hour: hour,
      minute: minute,
      title: 'Time to log your sleep',
      body: 'Keep your streak going — record last night\'s rest.',
      details: const NotificationDetails(android: _reminderChannel),
    );
  }

  @override
  Future<void> cancelDailyReminder() async {
    if (kIsWeb) return;
    await _plugin.cancel(_NotificationIds.reminder);
  }

  @override
  Future<void> scheduleAlarm({
    required int hour,
    required int minute,
    required String label,
  }) async {
    await _scheduleDaily(
      id: _NotificationIds.alarm,
      hour: hour,
      minute: minute,
      title: label,
      body: 'Your scheduled alarm',
      details: const NotificationDetails(android: _alarmChannel),
    );
  }

  @override
  Future<void> cancelAlarm() async {
    if (kIsWeb) return;
    await _plugin.cancel(_NotificationIds.alarm);
  }

  Future<void> _scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
    required NotificationDetails details,
  }) async {
    if (kIsWeb) return;
    await init();
    final next = nextDailyOccurrence(hour, minute, DateTime.now());
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(next, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      // Repeat every day at the same wall-clock time.
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}

/// No-op implementation for tests, web, and platforms without notifications.
/// Satisfies [ReminderService] without touching any plugin (LSP-safe).
class NoopReminderService implements ReminderService {
  const NoopReminderService();

  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermissions() async => false;

  @override
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {}

  @override
  Future<void> cancelDailyReminder() async {}

  @override
  Future<void> scheduleAlarm({
    required int hour,
    required int minute,
    required String label,
  }) async {}

  @override
  Future<void> cancelAlarm() async {}
}
