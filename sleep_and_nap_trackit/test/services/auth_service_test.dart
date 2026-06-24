import 'package:flutter_test/flutter_test.dart';
import 'package:sleep_and_nap_trackit/services/auth_service.dart';

void main() {
  group('AuthService interface', () {
    test('MockAuthService signIn succeeds with valid credentials', () async {
      final service = MockAuthService();
      await service.signIn(email: 'test@example.com', password: 'password123');
      expect(service.isAuthenticated, isTrue);
    });

    test('MockAuthService signIn throws on invalid credentials', () async {
      final service = MockAuthService();
      expect(
        () => service.signIn(email: 'wrong@example.com', password: 'bad'),
        throwsA(isA<AuthException>()),
      );
    });

    test('MockAuthService signUp succeeds', () async {
      final service = MockAuthService();
      await service.signUp(email: 'new@example.com', password: 'password123');
      expect(service.isAuthenticated, isTrue);
    });

    test('MockAuthService signUp throws if email already taken', () async {
      final service = MockAuthService();
      expect(
        () => service.signUp(email: 'test@example.com', password: 'password123'),
        throwsA(isA<AuthException>()),
      );
    });

    test('MockAuthService signOut clears authentication', () async {
      final service = MockAuthService();
      await service.signIn(email: 'test@example.com', password: 'password123');
      expect(service.isAuthenticated, isTrue);
      await service.signOut();
      expect(service.isAuthenticated, isFalse);
    });

    test('MockAuthService starts unauthenticated', () {
      final service = MockAuthService();
      expect(service.isAuthenticated, isFalse);
    });
  });
}
