import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../models/profile.dart';
import '../services/auth_service.dart';

enum AuthPhase { unauthorized, authenticating, authorized }

class AuthState {
  const AuthState({required this.phase, this.error});

  final AuthPhase phase;
  final String? error;

  AuthState copyWith({AuthPhase? phase, String? error}) =>
      AuthState(phase: phase ?? this.phase, error: error);
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._authService)
    : super(
        AuthState(
          phase: _authService.isAuthenticated
              ? AuthPhase.authorized
              : AuthPhase.unauthorized,
        ),
      ) {
    _listenToAuthChanges();
  }

  final AuthService _authService;
  bool _signedOutLocally = false;

  void _listenToAuthChanges() {
    try {
      sb.Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        final session = data.session;
        if (session != null) {
          if (_signedOutLocally) return;
          state = const AuthState(phase: AuthPhase.authorized);
        } else {
          _signedOutLocally = false;
          state = const AuthState(phase: AuthPhase.unauthorized);
        }
      });
    } catch (_) {
      // Supabase not initialized (e.g. in tests)
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    _signedOutLocally = false;
    state = const AuthState(phase: AuthPhase.authenticating);
    try {
      await _authService.signIn(email: email, password: password);
      state = const AuthState(phase: AuthPhase.authorized);
      return true;
    } on AuthException catch (e) {
      state = AuthState(phase: AuthPhase.unauthorized, error: e.message);
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required Profile profile,
  }) async {
    _signedOutLocally = false;
    state = const AuthState(phase: AuthPhase.authenticating);
    try {
      await _authService.signUp(
        email: email,
        password: password,
        profile: profile,
      );
      state = const AuthState(phase: AuthPhase.authorized);
      return true;
    } on AuthException catch (e) {
      state = AuthState(phase: AuthPhase.unauthorized, error: e.message);
      return false;
    }
  }

  Future<void> signOut() async {
    _signedOutLocally = true;
    state = const AuthState(phase: AuthPhase.unauthorized);
    try {
      await _authService.signOut();
    } catch (_) {
      // Keep the local app session closed even if the remote sign-out request
      // cannot complete, so the logout button always responds immediately.
    }
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  return SupabaseAuthService();
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
});
