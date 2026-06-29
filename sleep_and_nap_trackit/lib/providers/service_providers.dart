import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/profile_service.dart';
import '../services/reminder_service.dart';
import '../services/sleep_service.dart';

final sleepServiceProvider = Provider<SleepService>((ref) {
  return SupabaseSleepService();
});

final profileServiceProvider = Provider<ProfileService>((ref) {
  return SupabaseProfileService();
});

/// Notifications are unsupported on web, so fall back to a no-op there.
final reminderServiceProvider = Provider<ReminderService>((ref) {
  if (kIsWeb) return const NoopReminderService();
  return LocalNotificationReminderService();
});
