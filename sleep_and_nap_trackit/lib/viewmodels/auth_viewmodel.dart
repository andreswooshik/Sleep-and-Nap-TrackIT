import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/profile.dart';
import '../providers/auth_provider.dart';

enum AuthMode { login, signUp }

final authViewModelProvider = ChangeNotifierProvider.autoDispose<AuthViewModel>((ref) {
  return AuthViewModel(ref);
});

class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._ref);

  final Ref _ref;

  AuthMode _mode = AuthMode.login;
  AuthMode get mode => _mode;

  String _email = '';
  String get email => _email;

  String _password = '';
  String get password => _password;

  String _confirmPassword = '';
  String get confirmPassword => _confirmPassword;

  String _firstName = '';
  String get firstName => _firstName;

  String _lastName = '';
  String get lastName => _lastName;

  String _middleInitial = '';
  String get middleInitial => _middleInitial;

  DateTime? _dateOfBirth;
  DateTime? get dateOfBirth => _dateOfBirth;

  TimeOfDay? _usualBedtime;
  TimeOfDay? get usualBedtime => _usualBedtime;

  TimeOfDay? _usualWakeUpTime;
  TimeOfDay? get usualWakeUpTime => _usualWakeUpTime;

  String? _gender;
  String? get gender => _gender;

  int _sleepGoalHours = 8;
  int get sleepGoalHours => _sleepGoalHours;

  String _napHabit = 'Sometimes';
  String get napHabit => _napHabit;

  bool _notificationsEnabled = true;
  bool get notificationsEnabled => _notificationsEnabled;

  String? _emailError;
  String? get emailError => _emailError;

  String? _passwordError;
  String? get passwordError => _passwordError;

  String? _confirmPasswordError;
  String? get confirmPasswordError => _confirmPasswordError;

  String? _firstNameError;
  String? get firstNameError => _firstNameError;

  String? _lastNameError;
  String? get lastNameError => _lastNameError;

  String? _dateOfBirthError;
  String? get dateOfBirthError => _dateOfBirthError;

  String? _bedtimeError;
  String? get bedtimeError => _bedtimeError;

  String? _wakeUpTimeError;
  String? get wakeUpTimeError => _wakeUpTimeError;

  String? _authError;
  String? get authError => _authError;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void toggleMode() {
    _mode = _mode == AuthMode.login ? AuthMode.signUp : AuthMode.login;
    _clearErrors();
    _confirmPassword = '';
    notifyListeners();
  }

  void _clearErrors() {
    _emailError = null;
    _passwordError = null;
    _confirmPasswordError = null;
    _firstNameError = null;
    _lastNameError = null;
    _dateOfBirthError = null;
    _bedtimeError = null;
    _wakeUpTimeError = null;
    _authError = null;
  }

  void setEmail(String value) => _email = value;
  void setPassword(String value) => _password = value;
  void setConfirmPassword(String value) => _confirmPassword = value;
  void setFirstName(String value) => _firstName = value;
  void setLastName(String value) => _lastName = value;
  void setMiddleInitial(String value) => _middleInitial = value;

  void setDateOfBirth(DateTime? value) {
    _dateOfBirth = value;
    notifyListeners();
  }

  void setUsualBedtime(TimeOfDay? value) {
    _usualBedtime = value;
    notifyListeners();
  }

  void setUsualWakeUpTime(TimeOfDay? value) {
    _usualWakeUpTime = value;
    notifyListeners();
  }

  void setGender(String? value) {
    _gender = value;
    notifyListeners();
  }

  void setSleepGoalHours(int value) {
    _sleepGoalHours = value;
    notifyListeners();
  }

  void setNapHabit(String value) {
    _napHabit = value;
    notifyListeners();
  }

  void setNotificationsEnabled(bool value) {
    _notificationsEnabled = value;
    notifyListeners();
  }

  bool _validate() {
    _clearErrors();
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

    if (_mode == AuthMode.signUp) {
      if (_password != _confirmPassword) {
        _confirmPasswordError = 'Passwords do not match';
        valid = false;
      }
      if (_firstName.isEmpty) {
        _firstNameError = 'First name is required';
        valid = false;
      }
      if (_lastName.isEmpty) {
        _lastNameError = 'Last name is required';
        valid = false;
      }
      if (_dateOfBirth == null) {
        _dateOfBirthError = 'Date of birth is required';
        valid = false;
      }
      if (_usualBedtime == null) {
        _bedtimeError = 'Bedtime is required';
        valid = false;
      }
      if (_usualWakeUpTime == null) {
        _wakeUpTimeError = 'Wake-up time is required';
        valid = false;
      }
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

    final authNotifier = _ref.read(authProvider.notifier);
    bool success;

    if (_mode == AuthMode.login) {
      success = await authNotifier.signIn(email: _email, password: _password);
    } else {
      String formatTime(TimeOfDay t) =>
          '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

      final profile = Profile(
        id: '',
        firstName: _firstName,
        lastName: _lastName,
        middleInitial: _middleInitial.isNotEmpty ? _middleInitial : null,
        dateOfBirth: _dateOfBirth!,
        usualBedtime: formatTime(_usualBedtime!),
        usualWakeUpTime: formatTime(_usualWakeUpTime!),
        gender: _gender,
        sleepGoalHours: _sleepGoalHours,
        napHabit: _napHabit,
        notificationsEnabled: _notificationsEnabled,
      );

      success = await authNotifier.signUp(
        email: _email,
        password: _password,
        profile: profile,
      );
    }

    if (!success) {
      final authState = _ref.read(authProvider);
      _authError = authState.error;
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }
}
