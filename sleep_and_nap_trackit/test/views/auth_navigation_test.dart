import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleep_and_nap_trackit/main.dart';
import 'package:sleep_and_nap_trackit/providers/auth_provider.dart';
import 'package:sleep_and_nap_trackit/providers/service_providers.dart';
import 'package:sleep_and_nap_trackit/services/auth_service.dart';
import 'package:sleep_and_nap_trackit/services/profile_service.dart';
import 'package:sleep_and_nap_trackit/services/sleep_service.dart';

/// Auth component widget tests focused on the navigation gate: deliberately
/// corrupted inputs must keep the user on the auth screen and never reach the
/// authenticated dashboard.
void main() {
  Widget buildApp() {
    return ProviderScope(
      overrides: [
        authServiceProvider.overrideWithValue(MockAuthService()),
        sleepServiceProvider.overrideWithValue(MockSleepService()),
        profileServiceProvider.overrideWithValue(MockProfileService()),
      ],
      child: const SleepTrackItApp(),
    );
  }

  // The dashboard header only renders once the user is authorized.
  final dashboard = find.text("Today's rest dashboard");
  final onAuthScreen = find.text('Sleep and Nap TrackIT');

  Future<void> submitLogin(
    WidgetTester tester, {
    required String email,
    required String password,
  }) async {
    await tester.pumpWidget(buildApp());
    if (email.isNotEmpty) {
      await tester.enterText(find.byType(TextFormField).first, email);
    }
    if (password.isNotEmpty) {
      await tester.enterText(find.byType(TextFormField).last, password);
    }
    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();
  }

  group('login navigation gate', () {
    testWidgets('empty submit stays on the auth screen', (tester) async {
      await submitLogin(tester, email: '', password: '');
      expect(dashboard, findsNothing);
      expect(onAuthScreen, findsOneWidget);
      expect(find.text('Email is required'), findsOneWidget);
    });

    testWidgets('malformed email blocks navigation', (tester) async {
      await submitLogin(tester, email: 'notanemail', password: 'password123');
      expect(dashboard, findsNothing);
      expect(onAuthScreen, findsOneWidget);
      expect(find.text('Enter a valid email'), findsOneWidget);
    });

    testWidgets('too-short password blocks navigation', (tester) async {
      await submitLogin(tester, email: 'hello@example.com', password: 'abc');
      expect(dashboard, findsNothing);
      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    });

    testWidgets('wrong credentials block navigation', (tester) async {
      await submitLogin(tester, email: 'wrong@example.com', password: 'wrongpassword');
      expect(dashboard, findsNothing);
      expect(onAuthScreen, findsOneWidget);
      expect(find.text('Invalid email or password'), findsOneWidget);
    });

    testWidgets('valid credentials DO navigate to the dashboard', (tester) async {
      // Control case: proves the gate opens for good input, so the blocking
      // tests above are meaningful and not just always-failing navigation.
      await submitLogin(tester, email: 'hello@example.com', password: 'password123');
      expect(dashboard, findsOneWidget);
    });
  });

  group('sign-up navigation gate', () {
    testWidgets('mismatched passwords block navigation', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      // Sign-up field order: Last, First, M.I., Email, Password, Confirm.
      await tester.enterText(fields.at(0), 'Doe');
      await tester.enterText(fields.at(1), 'John');
      await tester.enterText(fields.at(3), 'newuser@example.com');
      await tester.enterText(fields.at(4), 'password123');
      await tester.enterText(fields.at(5), 'different456');
      // The submit button sits below the fold on the long sign-up form.
      await tester.ensureVisible(find.text('Create Account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      expect(dashboard, findsNothing);
      expect(find.text('Passwords do not match'), findsOneWidget);
    });
  });
}
