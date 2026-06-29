import 'package:flutter_test/flutter_test.dart';
import 'package:sleep_and_nap_trackit/models/profile.dart';
import 'package:sleep_and_nap_trackit/services/auth_service.dart';

Profile _testProfile() => Profile(
      id: '',
      firstName: 'John',
      lastName: 'Doe',
      dateOfBirth: DateTime(2000, 1, 1),
      usualBedtime: '22:00:00',
      usualWakeUpTime: '07:00:00',
    );

void main() {
  group('MockAuthService', () {
    test('signIn succeeds with valid credentials', () async {
      final service = MockAuthService();
      await service.signIn(email: 'test@example.com', password: 'password123');
      expect(service.isAuthenticated, isTrue);
    });

    test('signIn throws on invalid credentials', () async {
      final service = MockAuthService();
      expect(
        () => service.signIn(email: 'wrong@example.com', password: 'bad'),
        throwsA(isA<AuthException>()),
      );
    });

    test('signUp succeeds', () async {
      final service = MockAuthService();
      await service.signUp(
        email: 'new@example.com',
        password: 'password123',
        profile: _testProfile(),
      );
      expect(service.isAuthenticated, isTrue);
    });

    test('signUp throws if email already taken', () async {
      final service = MockAuthService();
      expect(
        () => service.signUp(
          email: 'test@example.com',
          password: 'password123',
          profile: _testProfile(),
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('signOut clears authentication', () async {
      final service = MockAuthService();
      await service.signIn(email: 'test@example.com', password: 'password123');
      expect(service.isAuthenticated, isTrue);
      await service.signOut();
      expect(service.isAuthenticated, isFalse);
    });

    test('starts unauthenticated', () {
      final service = MockAuthService();
      expect(service.isAuthenticated, isFalse);
    });
  });
}
