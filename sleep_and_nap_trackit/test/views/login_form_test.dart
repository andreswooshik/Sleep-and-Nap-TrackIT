import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleep_and_nap_trackit/providers/auth_provider.dart';
import 'package:sleep_and_nap_trackit/providers/service_providers.dart';
import 'package:sleep_and_nap_trackit/services/auth_service.dart';
import 'package:sleep_and_nap_trackit/services/sleep_service.dart';
import 'package:sleep_and_nap_trackit/viewmodels/auth_viewmodel.dart';
import 'package:sleep_and_nap_trackit/views/auth_view.dart';

void main() {
  // ─── Unit tests: email validation via the ViewModel ───────────────────────

  group('Login form — email unit tests', () {
    late ProviderContainer container;
    late AuthViewModel vm;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(MockAuthService()),
        ],
      );
      // Keep the autoDispose provider alive for the duration of each test.
      container.listen(authViewModelProvider, (_, __) {});
      vm = container.read(authViewModelProvider);
      vm.setPassword('password123');
    });

    tearDown(() => container.dispose());

    test('valid email passes validation without an email error', () async {
      // "hello" is 5 characters — meets the username minimum.
      vm.setEmail('hello@example.com');
      await vm.submit();
      expect(vm.emailError, isNull);
    });

    test('invalid email (username < 5 chars) shows error', () async {
      // "abc" is only 3 characters — below the 5-character minimum.
      vm.setEmail('abc@example.com');
      await vm.submit();
      expect(vm.emailError, 'Email username must be at least 5 characters');
    });

    test('empty email shows required error', () async {
      vm.setEmail('');
      await vm.submit();
      expect(vm.emailError, 'Email is required');
    });
  });

  // ─── Widget tests: UI element presence ────────────────────────────────────

  group('Login form — UI elements', () {
    Widget buildApp() => ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(MockAuthService()),
            sleepServiceProvider.overrideWithValue(MockSleepService()),
          ],
          child: const MaterialApp(home: AuthView()),
        );

    testWidgets('shows Email TextField', (tester) async {
      await tester.pumpWidget(buildApp());
      // The login form renders 2 TextFormFields; the first is the email field.
      expect(find.byType(TextFormField).first, findsOneWidget);
    });

    testWidgets('shows Password TextField', (tester) async {
      await tester.pumpWidget(buildApp());
      // The second TextFormField is the password field.
      expect(find.byType(TextFormField).last, findsOneWidget);
    });

    testWidgets('shows Login Button', (tester) async {
      await tester.pumpWidget(buildApp());
      expect(find.text('Log In'), findsOneWidget);
    });
  });

  // ─── Widget test: simulated user interactions ──────────────────────────────

  group('Login form — simulated actions', () {
    Widget buildApp() => ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(MockAuthService()),
            sleepServiceProvider.overrideWithValue(MockSleepService()),
          ],
          child: const MaterialApp(home: AuthView()),
        );

    testWidgets('enter email, enter password, press Login — no email error shown',
        (tester) async {
      await tester.pumpWidget(buildApp());

      // Enter email (username "hello" = 5 chars — valid).
      await tester.enterText(find.byType(TextFormField).first, 'hello@example.com');

      // Enter password.
      await tester.enterText(find.byType(TextFormField).last, 'password123');

      // Press the Login button.
      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();

      // Email validation passed — no email-specific error is displayed.
      expect(find.text('Email is required'), findsNothing);
      expect(find.text('Enter a valid email'), findsNothing);
      expect(find.text('Email username must be at least 5 characters'), findsNothing);
    });
  });
}
