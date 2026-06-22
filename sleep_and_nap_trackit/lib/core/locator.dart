import 'package:get_it/get_it.dart';
import '../services/sleep_service.dart';
// Import your services and viewmodels here as you create them

final locator = GetIt.instance;

void setupLocator() {
  // Register Services (Backend Scaffold)
  locator.registerLazySingleton<SleepService>(() => MockSleepService());
  // locator.registerLazySingleton<SleepService>(() => SleepServiceImpl());

  // Register ViewModels (Factories so we get a new instance per screen)
  // locator.registerFactory<HomeViewModel>(() => HomeViewModel(locator<SleepService>()));
}