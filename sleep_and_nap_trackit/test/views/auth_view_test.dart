import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:sleep_and_nap_trackit/services/auth_service.dart';
import 'package:sleep_and_nap_trackit/services/sleep_service.dart';
import 'package:sleep_and_nap_trackit/views/auth_view.dart';

void main() {
  setUp(() async {
    final locator = GetIt.instance;
    await locator.reset();
    locator.registerLazySingleton<AuthService>(() => MockAuthService());
    locator.registerLazySingleton<SleepService>(() => MockSleepService());
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  Widget buildApp() {
    return const MaterialApp(home: AuthView());
  }

  group('AuthView layout', () {
    testWidgets('shows header with app title', (tester) async {
      await tester.pumpWidget(buildApp());
      expect(find.text('Sleep and Nap TrackIT'), findsOneWidget);
      expect(find.text('Track your rest, improve your health'), findsOneWidget);
    });

    testWidgets('shows login form by default', (tester) async {
      await tester.pumpWidget(buildApp());
      expect(find.text('Log In'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('toggles to signup form', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(3));
    });

    testWidgets('toggles back to login form', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();
      expect(find.text('Log In'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
    });
  });

  group('AuthView validation', () {
    testWidgets('shows email error on empty submit', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.tap(find.text('Log In'));
      await tester.pump();
      expect(find.text('Email is required'), findsOneWidget);
    });

    testWidgets('shows malformed email error', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.enterText(find.byType(TextFormField).first, 'notanemail');
      await tester.tap(find.text('Log In'));
      await tester.pump();
      expect(find.text('Enter a valid email'), findsOneWidget);
    });

    testWidgets('shows password error on empty submit', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
      await tester.tap(find.text('Log In'));
      await tester.pump();
      expect(find.text('Password is required'), findsOneWidget);
    });
  });

  group('AuthView auth flow', () {
    testWidgets('navigates to HomeView on successful login', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();
      expect(find.text('Today\'s rest dashboard'), findsOneWidget);
    });

    testWidgets('shows auth error on failed login', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.enterText(find.byType(TextFormField).first, 'wrong@example.com');
      await tester.enterText(find.byType(TextFormField).last, 'wrongpassword');
      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();
      expect(find.text('Invalid email or password'), findsOneWidget);
    });
  });
}
