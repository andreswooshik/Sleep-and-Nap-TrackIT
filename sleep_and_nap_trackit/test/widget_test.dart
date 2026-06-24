import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:sleep_and_nap_trackit/main.dart';
import 'package:sleep_and_nap_trackit/services/auth_service.dart';
import 'package:sleep_and_nap_trackit/services/sleep_service.dart';

void main() {
  setUp(() async {
    final locator = GetIt.instance;
    await locator.reset();
    locator.registerLazySingleton<SleepService>(() => MockSleepService());
    locator.registerLazySingleton<AuthService>(() => MockAuthService());
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  testWidgets('renders auth view when not authenticated', (tester) async {
    await tester.pumpWidget(const SleepTrackItApp());
    await tester.pump();

    expect(find.text('Sleep and Nap TrackIT'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
  });
}
