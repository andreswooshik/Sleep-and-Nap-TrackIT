import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleep_and_nap_trackit/providers/auth_provider.dart';
import 'package:sleep_and_nap_trackit/services/auth_service.dart';
import 'package:sleep_and_nap_trackit/viewmodels/auth_viewmodel.dart';

void main() {
  late ProviderContainer container;
  late AuthViewModel vm;

  setUp(() {
    container = ProviderContainer(
      overrides: [
        authServiceProvider.overrideWithValue(MockAuthService()),
      ],
    );
    // Listen to keep autoDispose alive during tests
    container.listen(authViewModelProvider, (_, _) {});
    vm = container.read(authViewModelProvider);
  });

  tearDown(() {
    container.dispose();
  });

  group('initial state', () {
    test('starts in login mode', () {
      expect(vm.mode, AuthMode.login);
    });

    test('starts with empty fields and no errors', () {
      expect(vm.email, '');
      expect(vm.password, '');
      expect(vm.confirmPassword, '');
      expect(vm.emailError, isNull);
      expect(vm.passwordError, isNull);
      expect(vm.confirmPasswordError, isNull);
      expect(vm.authError, isNull);
      expect(vm.isLoading, isFalse);
    });
  });

  group('toggleMode', () {
    test('switches from login to signUp', () {
      vm.toggleMode();
      expect(vm.mode, AuthMode.signUp);
    });

    test('switches from signUp back to login', () {
      vm.toggleMode();
      vm.toggleMode();
      expect(vm.mode, AuthMode.login);
    });

    test('clears errors and confirmPassword on toggle', () {
      vm.setConfirmPassword('abc');
      vm.toggleMode();
      expect(vm.confirmPassword, '');
      expect(vm.emailError, isNull);
      expect(vm.passwordError, isNull);
      expect(vm.confirmPasswordError, isNull);
      expect(vm.authError, isNull);
    });
  });

  group('validation — login mode', () {
    test('empty email shows error', () async {
      vm.setPassword('password123');
      final result = await vm.submit();
      expect(result, isFalse);
      expect(vm.emailError, 'Email is required');
    });

    test('malformed email shows error', () async {
      vm.setEmail('not-an-email');
      vm.setPassword('password123');
      final result = await vm.submit();
      expect(result, isFalse);
      expect(vm.emailError, 'Enter a valid email');
    });

    test('empty password shows error', () async {
      vm.setEmail('test@example.com');
      final result = await vm.submit();
      expect(result, isFalse);
      expect(vm.passwordError, 'Password is required');
    });

    test('short password shows error', () async {
      vm.setEmail('test@example.com');
      vm.setPassword('abc');
      final result = await vm.submit();
      expect(result, isFalse);
      expect(vm.passwordError, 'Password must be at least 6 characters');
    });
  });

  group('validation — signUp mode', () {
    test('mismatched passwords shows error', () async {
      vm.toggleMode();
      vm.setEmail('new@example.com');
      vm.setPassword('password123');
      vm.setConfirmPassword('different');
      final result = await vm.submit();
      expect(result, isFalse);
      expect(vm.confirmPasswordError, 'Passwords do not match');
    });
  });

  group('submit — signUp', () {
    test('missing first name shows error', () async {
      vm.toggleMode();
      vm.setEmail('new@example.com');
      vm.setPassword('password123');
      vm.setConfirmPassword('password123');
      vm.setLastName('Doe');
      vm.setDateOfBirth(DateTime(2000, 1, 1));
      vm.setUsualBedtime(const TimeOfDay(hour: 22, minute: 0));
      vm.setUsualWakeUpTime(const TimeOfDay(hour: 7, minute: 0));
      final result = await vm.submit();
      expect(result, isFalse);
      expect(vm.firstNameError, 'First name is required');
    });

    test('missing date of birth shows error', () async {
      vm.toggleMode();
      vm.setEmail('new@example.com');
      vm.setPassword('password123');
      vm.setConfirmPassword('password123');
      vm.setFirstName('John');
      vm.setLastName('Doe');
      vm.setUsualBedtime(const TimeOfDay(hour: 22, minute: 0));
      vm.setUsualWakeUpTime(const TimeOfDay(hour: 7, minute: 0));
      final result = await vm.submit();
      expect(result, isFalse);
      expect(vm.dateOfBirthError, 'Date of birth is required');
    });
  });

  group('submit — login', () {
    test('successful login returns true', () async {
      vm.setEmail('test@example.com');
      vm.setPassword('password123');
      final result = await vm.submit();
      expect(result, isTrue);
      expect(vm.authError, isNull);
    });

    test('failed login sets authError', () async {
      vm.setEmail('wrong@example.com');
      vm.setPassword('wrongpassword');
      final result = await vm.submit();
      expect(result, isFalse);
      expect(vm.authError, isNotNull);
    });
  });
}
