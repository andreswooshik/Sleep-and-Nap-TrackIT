import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/profile_service.dart';
import '../services/sleep_service.dart';

final sleepServiceProvider = Provider<SleepService>((ref) {
  return SupabaseSleepService();
});

final profileServiceProvider = Provider<ProfileService>((ref) {
  return SupabaseProfileService();
});
