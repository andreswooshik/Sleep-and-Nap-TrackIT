import 'package:get_it/get_it.dart';

import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../services/sleep_service.dart';

final locator = GetIt.instance;

void setupLocator() {
  locator.registerLazySingleton<AuthService>(() => SupabaseAuthService());
  locator.registerLazySingleton<SleepService>(() => SupabaseSleepService());
  locator.registerLazySingleton<ProfileService>(() => SupabaseProfileService());
}
