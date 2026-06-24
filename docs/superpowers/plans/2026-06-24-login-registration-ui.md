# Login & Registration UI Views — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a single-page authentication screen with animated Login/Signup toggle, Supabase backend, and input validation — gating access to the existing HomeView dashboard.

**Architecture:** MVVM with Provider + get_it (matches existing codebase). New AuthService abstraction wraps Supabase auth. AuthViewModel manages form state and validation. AuthView is a single screen with AnimatedSwitcher toggling between Login and Signup forms. App startup checks Supabase session and routes accordingly.

**Tech Stack:** Flutter 3.12+, supabase_flutter, provider, get_it

## Global Constraints

- Dart SDK `^3.12.2`
- Follow existing MVVM + Provider + get_it patterns exactly
- Color palette: navy `#27374D`, blue-grey `#526D82`, cream bg `#F6F3EC`, border `#E3DED4`, muted text `#6A7473`
- All files under `sleep_and_nap_trackit/lib/` and `sleep_and_nap_trackit/test/`
- Do not include Claude in commit messages

---

### Task 1: Add supabase_flutter dependency and Supabase config

**Files:**
- Modify: `sleep_and_nap_trackit/pubspec.yaml` (line 38, after `provider`)
- Create: `sleep_and_nap_trackit/lib/core/supabase_config.dart`

**Interfaces:**
- Consumes: nothing
- Produces: `supabaseUrl` (String constant), `supabaseAnonKey` (String constant) used by Task 4 (`main.dart`)

- [ ] **Step 1: Add supabase_flutter to pubspec.yaml**

In `sleep_and_nap_trackit/pubspec.yaml`, add after the `provider` line:

```yaml
  supabase_flutter: ^2.8.4
```

- [ ] **Step 2: Create Supabase config file**

Create `sleep_and_nap_trackit/lib/core/supabase_config.dart`:

```dart
const supabaseUrl = 'YOUR_SUPABASE_URL';
const supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

- [ ] **Step 3: Run flutter pub get**

```bash
cd sleep_and_nap_trackit && flutter pub get
```

Expected: resolves successfully, `pubspec.lock` updated with `supabase_flutter` and its transitive dependencies.

- [ ] **Step 4: Commit**

```bash
git add sleep_and_nap_trackit/pubspec.yaml sleep_and_nap_trackit/pubspec.lock sleep_and_nap_trackit/lib/core/supabase_config.dart
git commit -m "feat: add supabase_flutter dependency and config placeholder"
```

---

### Task 2: AuthService — interface and Supabase implementation

**Files:**
- Create: `sleep_and_nap_trackit/lib/services/auth_service.dart`
- Create: `sleep_and_nap_trackit/test/services/auth_service_test.dart`

**Interfaces:**
- Consumes: `supabase_flutter` package (`Supabase.instance.client.auth`)
- Produces: `AuthService` abstract class with `signIn({required String email, required String password}) → Future<void>`, `signUp({required String email, required String password}) → Future<void>`, `signOut() → Future<void>`, `bool get isAuthenticated`. `SupabaseAuthService` implementation. Used by Task 3 (`AuthViewModel`), Task 4 (`locator.dart`, `main.dart`).

- [ ] **Step 1: Write the failing test**

Create `sleep_and_nap_trackit/test/services/auth_service_test.dart`:

```dart
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
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd sleep_and_nap_trackit && flutter test test/services/auth_service_test.dart
```

Expected: compilation error — `AuthService`, `MockAuthService`, `AuthException` not found.

- [ ] **Step 3: Write the implementation**

Create `sleep_and_nap_trackit/lib/services/auth_service.dart`:

```dart
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
```

- [ ] **Step 4: Run test to verify it passes**

```bash
cd sleep_and_nap_trackit && flutter test test/services/auth_service_test.dart
```

Expected: all 6 tests pass.

- [ ] **Step 5: Commit**

```bash
git add sleep_and_nap_trackit/lib/services/auth_service.dart sleep_and_nap_trackit/test/services/auth_service_test.dart
git commit -m "feat: add AuthService interface with Supabase and mock implementations"
```

---

### Task 3: AuthViewModel — form state, validation, and auth logic

**Files:**
- Create: `sleep_and_nap_trackit/lib/viewmodels/auth_viewmodel.dart`
- Create: `sleep_and_nap_trackit/test/viewmodels/auth_viewmodel_test.dart`

**Interfaces:**
- Consumes: `AuthService` from Task 2 (via `locator<AuthService>()`), `locator` from `core/locator.dart`
- Produces: `AuthMode` enum (`login`, `signUp`). `AuthViewModel extends ChangeNotifier` with properties: `AuthMode mode`, `String email`, `String password`, `String confirmPassword`, `String? emailError`, `String? passwordError`, `String? confirmPasswordError`, `String? authError`, `bool isLoading`. Methods: `toggleMode()`, `setEmail(String)`, `setPassword(String)`, `setConfirmPassword(String)`, `Future<bool> submit()`. Used by Task 5 (`AuthView`).

- [ ] **Step 1: Write the failing tests**

Create `sleep_and_nap_trackit/test/viewmodels/auth_viewmodel_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:sleep_and_nap_trackit/services/auth_service.dart';
import 'package:sleep_and_nap_trackit/viewmodels/auth_viewmodel.dart';

void main() {
  late AuthViewModel vm;

  setUp(() {
    final locator = GetIt.instance;
    locator.reset();
    locator.registerLazySingleton<AuthService>(() => MockAuthService());
    vm = AuthViewModel();
  });

  tearDown(() {
    GetIt.instance.reset();
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
      vm.setPassword('wrong');
      final result = await vm.submit();
      expect(result, isFalse);
      expect(vm.authError, isNotNull);
    });
  });

  group('submit — signUp', () {
    test('successful signUp returns true', () async {
      vm.toggleMode();
      vm.setEmail('new@example.com');
      vm.setPassword('password123');
      vm.setConfirmPassword('password123');
      final result = await vm.submit();
      expect(result, isTrue);
    });

    test('duplicate email sets authError', () async {
      vm.toggleMode();
      vm.setEmail('test@example.com');
      vm.setPassword('password123');
      vm.setConfirmPassword('password123');
      final result = await vm.submit();
      expect(result, isFalse);
      expect(vm.authError, isNotNull);
    });
  });

  group('loading state', () {
    test('isLoading is true during submit', () async {
      vm.setEmail('test@example.com');
      vm.setPassword('password123');
      final future = vm.submit();
      expect(vm.isLoading, isTrue);
      await future;
      expect(vm.isLoading, isFalse);
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd sleep_and_nap_trackit && flutter test test/viewmodels/auth_viewmodel_test.dart
```

Expected: compilation error — `AuthViewModel`, `AuthMode` not found.

- [ ] **Step 3: Write the implementation**

Create `sleep_and_nap_trackit/lib/viewmodels/auth_viewmodel.dart`:

```dart
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
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd sleep_and_nap_trackit && flutter test test/viewmodels/auth_viewmodel_test.dart
```

Expected: all 13 tests pass.

- [ ] **Step 5: Commit**

```bash
git add sleep_and_nap_trackit/lib/viewmodels/auth_viewmodel.dart sleep_and_nap_trackit/test/viewmodels/auth_viewmodel_test.dart
git commit -m "feat: add AuthViewModel with form validation and auth logic"
```

---

### Task 4: Wire up Supabase init, locator registration, and app routing

**Files:**
- Modify: `sleep_and_nap_trackit/lib/core/locator.dart`
- Modify: `sleep_and_nap_trackit/lib/main.dart`

**Interfaces:**
- Consumes: `supabaseUrl`, `supabaseAnonKey` from Task 1 (`core/supabase_config.dart`). `AuthService`, `SupabaseAuthService` from Task 2. `AuthView` from Task 5 (forward reference — `AuthView` will exist by the time the app runs, but we import it here).
- Produces: updated `main()` that initializes Supabase and routes to `AuthView` or `HomeView`. Updated `setupLocator()` that registers `AuthService`.

- [ ] **Step 1: Update locator.dart**

Replace the full content of `sleep_and_nap_trackit/lib/core/locator.dart` with:

```dart
import 'package:get_it/get_it.dart';

import '../services/auth_service.dart';
import '../services/sleep_service.dart';

final locator = GetIt.instance;

void setupLocator() {
  locator.registerLazySingleton<SleepService>(() => MockSleepService());
  locator.registerLazySingleton<AuthService>(() => SupabaseAuthService());
}
```

- [ ] **Step 2: Update main.dart**

Replace the full content of `sleep_and_nap_trackit/lib/main.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/locator.dart';
import 'core/supabase_config.dart';
import 'services/auth_service.dart';
import 'views/auth_view.dart';
import 'views/home_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  setupLocator();
  runApp(const SleepTrackItApp());
}

class SleepTrackItApp extends StatelessWidget {
  const SleepTrackItApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF526D82);
    final authService = locator<AuthService>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sleep and Nap TrackIT',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F3EC),
        useMaterial3: true,
      ),
      home: authService.isAuthenticated ? const HomeView() : const AuthView(),
    );
  }
}
```

- [ ] **Step 3: Update the existing widget test**

Replace the full content of `sleep_and_nap_trackit/test/widget_test.dart` with:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:sleep_and_nap_trackit/main.dart';
import 'package:sleep_and_nap_trackit/services/auth_service.dart';
import 'package:sleep_and_nap_trackit/services/sleep_service.dart';

void main() {
  setUp(() async {
    final locator = GetIt.instance;
    await locator.reset();
    locator.registerLazySingleton<SleepService>(() => MockSleepService());
    locator.registerLazySingleton<AuthService>(() => MockAuthService());
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  testWidgets('renders auth view when not authenticated', (tester) async {
    await tester.pumpWidget(const SleepTrackItApp());
    await tester.pump();

    expect(find.text('Sleep and Nap TrackIT'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
  });
}
```

- [ ] **Step 4: Commit**

```bash
git add sleep_and_nap_trackit/lib/core/locator.dart sleep_and_nap_trackit/lib/main.dart sleep_and_nap_trackit/test/widget_test.dart
git commit -m "feat: wire Supabase init, register AuthService, route by session"
```

Note: the widget test and full app won't compile until Task 5 creates `AuthView`. That's expected — this commit captures the wiring changes and will compile after Task 5.

---

### Task 5: AuthView — the login/signup UI

**Files:**
- Create: `sleep_and_nap_trackit/lib/views/auth_view.dart`
- Create: `sleep_and_nap_trackit/test/views/auth_view_test.dart`

**Interfaces:**
- Consumes: `AuthViewModel`, `AuthMode` from Task 3. `HomeView` from existing `views/home_view.dart`.
- Produces: `AuthView` widget (const constructor, `StatelessWidget`). Used by Task 4 (`main.dart`).

- [ ] **Step 1: Write the failing widget test**

Create `sleep_and_nap_trackit/test/views/auth_view_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:sleep_and_nap_trackit/services/auth_service.dart';
import 'package:sleep_and_nap_trackit/services/sleep_service.dart';
import 'package:sleep_and_nap_trackit/views/auth_view.dart';

void main() {
  setUp(() {
    final locator = GetIt.instance;
    locator.reset();
    locator.registerLazySingleton<AuthService>(() => MockAuthService());
    locator.registerLazySingleton<SleepService>(() => MockSleepService());
  });

  tearDown(() {
    GetIt.instance.reset();
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
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd sleep_and_nap_trackit && flutter test test/views/auth_view_test.dart
```

Expected: compilation error — `AuthView` not found.

- [ ] **Step 3: Write the AuthView implementation**

Create `sleep_and_nap_trackit/lib/views/auth_view.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_viewmodel.dart';
import 'home_view.dart';

class AuthView extends StatelessWidget {
  const AuthView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthViewModel(),
      child: const _AuthContent(),
    );
  }
}

class _AuthContent extends StatelessWidget {
  const _AuthContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Header(),
              const SizedBox(height: 28),
              const _ModeToggle(),
              const SizedBox(height: 20),
              const _AuthForm(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF27374D),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFDDE6ED),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.bedtime_rounded,
              color: Color(0xFF27374D),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sleep and Nap TrackIT',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Track your rest, improve your health',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFDDE6ED),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AuthViewModel>();
    final isLogin = viewModel.mode == AuthMode.login;

    return Row(
      children: [
        Expanded(
          child: isLogin
              ? FilledButton(
                  onPressed: null,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF526D82),
                    disabledBackgroundColor: const Color(0xFF526D82),
                    disabledForegroundColor: Colors.white,
                  ),
                  child: const Text('Login'),
                )
              : OutlinedButton(
                  onPressed: viewModel.toggleMode,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF526D82)),
                  ),
                  child: const Text('Login'),
                ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: !isLogin
              ? FilledButton(
                  onPressed: null,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF526D82),
                    disabledBackgroundColor: const Color(0xFF526D82),
                    disabledForegroundColor: Colors.white,
                  ),
                  child: const Text('Sign Up'),
                )
              : OutlinedButton(
                  onPressed: viewModel.toggleMode,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF526D82)),
                  ),
                  child: const Text('Sign Up'),
                ),
        ),
      ],
    );
  }
}

class _AuthForm extends StatefulWidget {
  const _AuthForm();

  @override
  State<_AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<_AuthForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit(AuthViewModel viewModel) async {
    final success = await viewModel.submit();
    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const HomeView()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AuthViewModel>();
    final isLogin = viewModel.mode == AuthMode.login;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.05),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: Column(
        key: ValueKey(viewModel.mode),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            onChanged: viewModel.setEmail,
            decoration: InputDecoration(
              labelText: 'Email',
              errorText: viewModel.emailError,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE3DED4)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF526D82), width: 2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: isLogin ? TextInputAction.done : TextInputAction.next,
            onChanged: viewModel.setPassword,
            decoration: InputDecoration(
              labelText: 'Password',
              errorText: viewModel.passwordError,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE3DED4)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF526D82), width: 2),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
            ),
          ),
          if (!isLogin) ...[
            const SizedBox(height: 14),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              textInputAction: TextInputAction.done,
              onChanged: viewModel.setConfirmPassword,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                errorText: viewModel.confirmPasswordError,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE3DED4)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF526D82), width: 2),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                  },
                ),
              ),
            ),
          ],
          if (viewModel.authError != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade700),
              ),
              child: Text(
                viewModel.authError!,
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: viewModel.isLoading ? null : () => _handleSubmit(viewModel),
              child: viewModel.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(isLogin ? 'Log In' : 'Create Account'),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run all tests**

```bash
cd sleep_and_nap_trackit && flutter test
```

Expected: all tests across all test files pass (auth_service, auth_viewmodel, auth_view, widget_test).

- [ ] **Step 5: Commit**

```bash
git add sleep_and_nap_trackit/lib/views/auth_view.dart sleep_and_nap_trackit/test/views/auth_view_test.dart
git commit -m "feat: add AuthView with animated login/signup toggle and validation"
```

---

### Task 6: Final integration — run all tests and verify

**Files:**
- No new files

**Interfaces:**
- Consumes: all files from Tasks 1–5
- Produces: verified, passing test suite

- [ ] **Step 1: Run the full test suite**

```bash
cd sleep_and_nap_trackit && flutter test
```

Expected: all tests pass across all files.

- [ ] **Step 2: Run flutter analyze**

```bash
cd sleep_and_nap_trackit && flutter analyze
```

Expected: no issues found.

- [ ] **Step 3: Fix any issues found in steps 1–2 and re-run**

If any tests fail or analysis issues arise, fix them and re-run until clean.

- [ ] **Step 4: Final commit (if any fixes were needed)**

```bash
git add -A
git commit -m "fix: resolve lint/test issues from integration"
```

Only commit if changes were needed. Skip if steps 1–2 were clean.
