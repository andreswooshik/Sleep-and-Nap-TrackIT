import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../models/profile.dart';

class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

abstract class AuthService {
  Future<void> signIn({required String email, required String password});
  Future<void> signUp({
    required String email,
    required String password,
    required Profile profile,
  });
  Future<void> signOut();
  bool get isAuthenticated;
  String? get currentUserId;
  String? get currentUserEmail;
}

class SupabaseAuthService implements AuthService {
  sb.SupabaseClient get _client => sb.Supabase.instance.client;

  @override
  bool get isAuthenticated => _client.auth.currentSession != null;

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  String? get currentUserEmail => _client.auth.currentUser?.email;

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } on sb.AuthException catch (e) {
      throw AuthException(e.message);
    }
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required Profile profile,
  }) async {
    try {
      final response = await _client.auth.signUp(email: email, password: password);
      if (response.user == null) {
        throw AuthException('Sign up failed. Please try again.');
      }

      final profileWithId = Profile(
        id: response.user!.id,
        firstName: profile.firstName,
        lastName: profile.lastName,
        middleInitial: profile.middleInitial,
        dateOfBirth: profile.dateOfBirth,
        usualBedtime: profile.usualBedtime,
        usualWakeUpTime: profile.usualWakeUpTime,
        gender: profile.gender,
        sleepGoalHours: profile.sleepGoalHours,
        napHabit: profile.napHabit,
        notificationsEnabled: profile.notificationsEnabled,
      );

      await _client.from('profiles').insert(profileWithId.toJson());
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

  static const _validEmail = 'hello@example.com';
  static const _validPassword = 'password123';

  @override
  bool get isAuthenticated => _authenticated;

  @override
  String? get currentUserId => _authenticated ? 'mock-user-id' : null;

  @override
  String? get currentUserEmail => _authenticated ? _validEmail : null;

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
  Future<void> signUp({
    required String email,
    required String password,
    required Profile profile,
  }) async {
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
