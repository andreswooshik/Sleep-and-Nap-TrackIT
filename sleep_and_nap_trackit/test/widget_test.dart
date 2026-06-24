import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleep_and_nap_trackit/main.dart';
import 'package:sleep_and_nap_trackit/providers/auth_provider.dart';
import 'package:sleep_and_nap_trackit/services/auth_service.dart';

void main() {
  testWidgets('renders auth view when not authenticated', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(MockAuthService()),
        ],
        child: const SleepTrackItApp(),
      ),
    );
    await tester.pump();

    expect(find.text('Sleep and Nap TrackIT'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
  });
}
