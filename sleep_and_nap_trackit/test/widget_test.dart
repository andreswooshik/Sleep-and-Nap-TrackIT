import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleep_and_nap_trackit/main.dart';
import 'package:sleep_and_nap_trackit/providers/auth_provider.dart';
import 'package:sleep_and_nap_trackit/providers/service_providers.dart';
import 'package:sleep_and_nap_trackit/services/auth_service.dart';
import 'package:sleep_and_nap_trackit/services/profile_service.dart';
import 'package:sleep_and_nap_trackit/services/sleep_service.dart';

void main() {
  testWidgets('renders auth view when not authenticated', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authServiceProvider.overrideWithValue(MockAuthService())],
        child: const SleepTrackItApp(),
      ),
    );
    await tester.pump();

    expect(find.text('Sleep and Nap TrackIT'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
  });

  testWidgets('logs out from the profile tab', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(MockAuthService()),
          sleepServiceProvider.overrideWithValue(MockSleepService()),
          profileServiceProvider.overrideWithValue(MockProfileService()),
        ],
        child: const SleepTrackItApp(),
      ),
    );

    await tester.enterText(find.byType(EditableText).at(0), 'hello@example.com');
    await tester.enterText(find.byType(EditableText).at(1), 'password123');
    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();

    expect(find.text('Today\'s rest dashboard'), findsOneWidget);

    // Navigate to the Profile tab, then log out.
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();

    expect(find.text('Log In'), findsOneWidget);
    expect(find.text('Today\'s rest dashboard'), findsNothing);
  });
}
