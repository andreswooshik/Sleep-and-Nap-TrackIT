import 'package:flutter/material.dart';

import '../core/locator.dart';
import '../services/auth_service.dart';

enum AuthMode { login, signUp }

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = locator<AuthService>();

  AuthMode _mode = AuthMode.login;
  AuthMode get mode => _mode;

  String _email = '';
  String get email => _email;

  String _password = '';
  String get password => _password;

  String _confirmPassword = '';
  String get confirmPassword => _confirmPassword;

  String? _emailError;
  String? get emailError => _emailError;

  String? _passwordError;
  String? get passwordError => _passwordError;

  String? _confirmPasswordError;
  String? get confirmPasswordError => _confirmPasswordError;

  String? _authError;
  String? get authError => _authError;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void toggleMode() {
    _mode = _mode == AuthMode.login ? AuthMode.signUp : AuthMode.login;
    _confirmPassword = '';
    _emailError = null;
    _passwordError = null;
    _confirmPasswordError = null;
    _authError = null;
    notifyListeners();
  }

  void setEmail(String value) {
    _email = value;
  }

  void setPassword(String value) {
    _password = value;
  }

  void setConfirmPassword(String value) {
    _confirmPassword = value;
  }

  bool _validate() {
    _emailError = null;
    _passwordError = null;
    _confirmPasswordError = null;
    bool valid = true;

    if (_email.isEmpty) {
      _emailError = 'Email is required';
      valid = false;
    } else if (!RegExp(r'^[\w.-]+@[\w-]+\.\w{2,}$').hasMatch(_email)) {
      _emailError = 'Enter a valid email';
      valid = false;
    }

    if (_password.isEmpty) {
      _passwordError = 'Password is required';
      valid = false;
    } else if (_password.length < 6) {
      _passwordError = 'Password must be at least 6 characters';
      valid = false;
    }

    if (_mode == AuthMode.signUp && _password != _confirmPassword) {
      _confirmPasswordError = 'Passwords do not match';
      valid = false;
    }

    return valid;
  }

  Future<bool> submit() async {
    _authError = null;

    if (!_validate()) {
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      if (_mode == AuthMode.login) {
        await _authService.signIn(email: _email, password: _password);
      } else {
        await _authService.signUp(email: _email, password: _password);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _authError = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
