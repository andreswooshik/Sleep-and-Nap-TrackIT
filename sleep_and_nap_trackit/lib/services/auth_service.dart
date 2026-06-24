import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

abstract class AuthService {
  Future<void> signIn({required String email, required String password});
  Future<void> signUp({required String email, required String password});
  Future<void> signOut();
  bool get isAuthenticated;
}

class SupabaseAuthService implements AuthService {
  sb.SupabaseClient get _client => sb.Supabase.instance.client;

  @override
  bool get isAuthenticated => _client.auth.currentSession != null;

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } on sb.AuthException catch (e) {
      throw AuthException(e.message);
    }
  }

  @override
  Future<void> signUp({required String email, required String password}) async {
    try {
      final response = await _client.auth.signUp(email: email, password: password);
      if (response.user == null) {
        throw AuthException('Sign up failed. Please try again.');
      }
    } on sb.AuthException catch (e) {
      throw AuthException(e.message);
    }
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}

class MockAuthService implements AuthService {
  bool _authenticated = false;

  static const _validEmail = 'test@example.com';
  static const _validPassword = 'password123';

  @override
  bool get isAuthenticated => _authenticated;

  @override
  Future<void> signIn({required String email, required String password}) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (email == _validEmail && password == _validPassword) {
      _authenticated = true;
      return;
    }
    throw AuthException('Invalid email or password');
  }

  @override
  Future<void> signUp({required String email, required String password}) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (email == _validEmail) {
      throw AuthException('An account with this email already exists');
    }
    _authenticated = true;
  }

  @override
  Future<void> signOut() async {
    _authenticated = false;
  }
}
