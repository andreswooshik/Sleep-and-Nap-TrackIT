# Login & Registration UI Views

## Overview

Single-page authentication screen with an animated toggle between Login and Signup forms. Uses Supabase for backend auth and follows the existing MVVM + Provider + get_it architecture.

## Requirements

1. Input validation logic prevents empty submissions or malformed emails.
2. Smooth navigation transitions exist between the Login and Signup layout views.

## Architecture

### New Files

| Layer | File | Purpose |
|---|---|---|
| Service | `lib/services/auth_service.dart` | Abstract `AuthService` interface + `SupabaseAuthService` implementation |
| ViewModel | `lib/viewmodels/auth_viewmodel.dart` | Form state, validation logic, auth calls, error/loading state |
| View | `lib/views/auth_view.dart` | Single screen with animated Login/Signup toggle |

### Modified Files

| File | Change |
|---|---|
| `pubspec.yaml` | Add `supabase_flutter` dependency |
| `lib/main.dart` | Initialize Supabase before `runApp`, route to `AuthView` or `HomeView` based on session |
| `lib/core/locator.dart` | Register `AuthService` with `SupabaseAuthService` implementation |

## Service Layer — `AuthService`

```dart
abstract class AuthService {
  Future<void> signIn({required String email, required String password});
  Future<void> signUp({required String email, required String password});
  Future<void> signOut();
  bool get isAuthenticated;
}
```

`SupabaseAuthService` wraps `Supabase.instance.client.auth` and delegates to:
- `signInWithPassword` for login
- `signUp` for registration
- `signOut` for logout
- Checks `currentSession != null` for `isAuthenticated`

Auth errors (invalid credentials, email taken, weak password) are caught and rethrown as descriptive strings for the ViewModel to surface.

## ViewModel — `AuthViewModel`

Extends `ChangeNotifier` (matches `HomeViewModel` pattern).

### State

- `AuthMode mode` — enum `{ login, signUp }`, defaults to `login`
- `String email`, `String password`, `String confirmPassword`
- `String? emailError`, `String? passwordError`, `String? confirmPasswordError`
- `String? authError` — server-side error message
- `bool isLoading`

### Validation Rules

| Field | Rule |
|---|---|
| Email | Non-empty, matches `^[\w.-]+@[\w-]+\.\w{2,}$` |
| Password | Non-empty, minimum 6 characters |
| Confirm password | (Signup only) Must match password |

Validation runs on submit. Each field gets an inline error message if invalid. Submission is blocked if any field is invalid.

### Methods

- `toggleMode()` — switches between login/signUp, clears errors and confirm password
- `setEmail(String)`, `setPassword(String)`, `setConfirmPassword(String)` — update fields
- `submit()` — validates, calls `AuthService.signIn` or `signUp`, sets `isLoading`/`authError`
- Returns `true` on success, `false` on failure (so the View knows to navigate)

## View — `AuthView`

### Layout (top to bottom)

1. **Header banner** — navy container (`#27374D`) with app icon + "Sleep and Nap TrackIT" title + subtitle "Track your rest, improve your health". Matches `HomeView` header style.

2. **Mode toggle** — two-button row (Login | Sign Up). Active button uses filled style, inactive uses outlined. Tapping calls `viewModel.toggleMode()`.

3. **Form area** — wrapped in `AnimatedSwitcher` with `crossFadeState` for smooth transition between:
   - **Login form**: Email field, Password field, Submit button ("Log In")
   - **Signup form**: Email field, Password field, Confirm Password field, Submit button ("Create Account")

4. **Auth error banner** — if `authError` is non-null, show a styled error container below the form.

### Input Fields

- Use `TextFormField` with `OutlineInputBorder`, rounded corners (8px)
- Email field: `keyboardType: TextInputType.emailAddress`, `textInputAction: TextInputAction.next`
- Password fields: `obscureText: true`, visibility toggle suffix icon
- Error text shown via `errorText` property on `InputDecoration`

### Submit Button

- Full-width `FilledButton`
- Shows `CircularProgressIndicator` when `isLoading`
- Disabled when `isLoading`

### Transitions

- `AnimatedSwitcher` with `duration: Duration(milliseconds: 300)` and `Curves.easeInOut`
- Form fields use a `FadeTransition` + `SlideTransition` combo for polish

## Supabase Configuration

Supabase requires a project URL and anon key. These are passed to `Supabase.initialize()` in `main.dart`. For now, they are hardcoded as constants in a `lib/core/supabase_config.dart` file. The user must create a Supabase project and supply their own values.

```dart
// lib/core/supabase_config.dart
const supabaseUrl = 'YOUR_SUPABASE_URL';
const supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

## Navigation Flow

### App Startup (`main.dart`)

```
Supabase.initialize(url, anonKey) → setupLocator() → runApp()
```

The `MaterialApp.home` checks `AuthService.isAuthenticated`:
- If authenticated → `HomeView`
- If not → `AuthView`

### After Successful Auth

`Navigator.pushReplacement` from `AuthView` to `HomeView` — prevents back-navigation to auth screen.

## Styling

Consistent with existing palette:

| Element | Color |
|---|---|
| Header background | `#27374D` |
| Header text | white / `#DDE6ED` |
| Active toggle button | `#526D82` (filled) |
| Inactive toggle button | outlined, `#526D82` border |
| Input borders | `#E3DED4` |
| Input focus border | `#526D82` |
| Error text/border | `Colors.red.shade700` |
| Scaffold background | `#F6F3EC` |
| Submit button | theme's primary filled style |

## Error Handling

| Scenario | Behavior |
|---|---|
| Empty email | Inline error: "Email is required" |
| Malformed email | Inline error: "Enter a valid email" |
| Empty password | Inline error: "Password is required" |
| Short password | Inline error: "Password must be at least 6 characters" |
| Password mismatch (signup) | Inline error: "Passwords do not match" |
| Invalid credentials (server) | Auth error banner: "Invalid email or password" |
| Email already registered | Auth error banner: "An account with this email already exists" |
| Network/unknown error | Auth error banner: "Something went wrong. Please try again." |

## Testing Considerations

- `AuthViewModel` unit tests: validation logic, mode toggling, error states
- Widget tests: form renders correctly per mode, validation errors display, toggle animation works
- Integration: mock `AuthService` in tests via get_it override
