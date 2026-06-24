import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../viewmodels/auth_viewmodel.dart';
import 'home_view.dart';

class AuthView extends ConsumerWidget {
  const AuthView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const _AuthContent();
  }
}

class _AuthContent extends ConsumerWidget {
  const _AuthContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF27374D), Color(0xFF1D2B3A), Color(0xFFF6F3EC)],
            stops: [0.0, 0.32, 0.32],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 32),
                const _Header(),
                const SizedBox(height: 32),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: const Column(
                    children: [
                      _ModeToggle(),
                      SizedBox(height: 24),
                      _AuthForm(),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
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

    return Column(
      children: [
        Container(
          height: 64,
          width: 64,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.bedtime_rounded,
            color: Colors.white,
            size: 32,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Sleep and Nap TrackIT',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Track your rest, improve your health',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

class _ModeToggle extends ConsumerWidget {
  const _ModeToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(authViewModelProvider);
    final isLogin = viewModel.mode == AuthMode.login;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF6F3EC),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: isLogin ? null : viewModel.toggleMode,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isLogin ? const Color(0xFF27374D) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    'Login',
                    style: TextStyle(
                      color: isLogin ? Colors.white : const Color(0xFF6A7473),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: !isLogin ? null : viewModel.toggleMode,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !isLogin ? const Color(0xFF27374D) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    'Sign Up',
                    style: TextStyle(
                      color: !isLogin ? Colors.white : const Color(0xFF6A7473),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthForm extends ConsumerStatefulWidget {
  const _AuthForm();

  @override
  ConsumerState<_AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends ConsumerState<_AuthForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _middleInitialController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _middleInitialController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration({
    required String label,
    String? errorText,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      errorText: errorText,
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, size: 20, color: const Color(0xFF526D82))
          : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFFAF9F6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE3DED4), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF526D82), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade400, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade400, width: 2),
      ),
      labelStyle: const TextStyle(
        color: Color(0xFF9AA3A2),
        fontSize: 14,
      ),
    );
  }

  Future<void> _handleSubmit(AuthViewModel viewModel) async {
    final success = await viewModel.submit();
    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const HomeView()),
      );
    }
  }

  Future<void> _pickDate(AuthViewModel viewModel) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: viewModel.dateOfBirth ?? DateTime(now.year - 20),
      firstDate: DateTime(1920),
      lastDate: now,
    );
    if (picked != null) {
      viewModel.setDateOfBirth(picked);
    }
  }

  Future<void> _pickTime(AuthViewModel viewModel, bool isBedtime) async {
    final initial = isBedtime
        ? (viewModel.usualBedtime ?? const TimeOfDay(hour: 22, minute: 0))
        : (viewModel.usualWakeUpTime ?? const TimeOfDay(hour: 7, minute: 0));
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      if (isBedtime) {
        viewModel.setUsualBedtime(picked);
      } else {
        viewModel.setUsualWakeUpTime(picked);
      }
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(authViewModelProvider);
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
              begin: const Offset(0, 0.03),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: isLogin
          ? _buildLoginForm(viewModel)
          : _buildSignUpForm(viewModel),
    );
  }

  Widget _buildLoginForm(AuthViewModel viewModel) {
    return Column(
      key: const ValueKey(AuthMode.login),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          onChanged: viewModel.setEmail,
          decoration: _inputDecoration(
            label: 'Email',
            errorText: viewModel.emailError,
            prefixIcon: Icons.email_outlined,
          ),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          onChanged: viewModel.setPassword,
          decoration: _inputDecoration(
            label: 'Password',
            errorText: viewModel.passwordError,
            prefixIcon: Icons.lock_outline_rounded,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
                color: const Color(0xFF9AA3A2),
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        if (viewModel.authError != null) ...[
          const SizedBox(height: 14),
          _buildErrorBanner(viewModel.authError!),
        ],
        const SizedBox(height: 24),
        _buildSubmitButton(viewModel, 'Log In'),
      ],
    );
  }

  Widget _buildSignUpForm(AuthViewModel viewModel) {
    return Column(
      key: const ValueKey(AuthMode.signUp),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // --- Name row ---
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _lastNameController,
                textInputAction: TextInputAction.next,
                onChanged: viewModel.setLastName,
                decoration: _inputDecoration(
                  label: 'Last Name',
                  errorText: viewModel.lastNameError,
                  prefixIcon: Icons.person_outline_rounded,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _firstNameController,
                textInputAction: TextInputAction.next,
                onChanged: viewModel.setFirstName,
                decoration: _inputDecoration(
                  label: 'First Name',
                  errorText: viewModel.firstNameError,
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 56,
              child: TextFormField(
                controller: _middleInitialController,
                textInputAction: TextInputAction.next,
                maxLength: 1,
                onChanged: viewModel.setMiddleInitial,
                decoration: _inputDecoration(label: 'M.I.').copyWith(
                  counterText: '',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // --- Email ---
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          onChanged: viewModel.setEmail,
          decoration: _inputDecoration(
            label: 'Email',
            errorText: viewModel.emailError,
            prefixIcon: Icons.email_outlined,
          ),
        ),
        const SizedBox(height: 14),

        // --- Password ---
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.next,
          onChanged: viewModel.setPassword,
          decoration: _inputDecoration(
            label: 'Password',
            errorText: viewModel.passwordError,
            prefixIcon: Icons.lock_outline_rounded,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
                color: const Color(0xFF9AA3A2),
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // --- Confirm Password ---
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          textInputAction: TextInputAction.next,
          onChanged: viewModel.setConfirmPassword,
          decoration: _inputDecoration(
            label: 'Confirm Password',
            errorText: viewModel.confirmPasswordError,
            prefixIcon: Icons.lock_outline_rounded,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
                color: const Color(0xFF9AA3A2),
              ),
              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // --- Date of Birth ---
        _buildPickerField(
          label: viewModel.dateOfBirth != null
              ? _formatDate(viewModel.dateOfBirth!)
              : 'Date of Birth',
          icon: Icons.cake_outlined,
          errorText: viewModel.dateOfBirthError,
          hasValue: viewModel.dateOfBirth != null,
          onTap: () => _pickDate(viewModel),
        ),
        const SizedBox(height: 14),

        // --- Bedtime & Wake-up row ---
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildPickerField(
                label: viewModel.usualBedtime != null
                    ? _formatTime(viewModel.usualBedtime!)
                    : 'Usual Bedtime',
                icon: Icons.nightlight_round_outlined,
                errorText: viewModel.bedtimeError,
                hasValue: viewModel.usualBedtime != null,
                onTap: () => _pickTime(viewModel, true),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildPickerField(
                label: viewModel.usualWakeUpTime != null
                    ? _formatTime(viewModel.usualWakeUpTime!)
                    : 'Usual Wake-up',
                icon: Icons.wb_sunny_outlined,
                errorText: viewModel.wakeUpTimeError,
                hasValue: viewModel.usualWakeUpTime != null,
                onTap: () => _pickTime(viewModel, false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // --- Optional divider ---
        Row(
          children: [
            const Expanded(child: Divider(color: Color(0xFFE3DED4))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Optional',
                style: TextStyle(
                  color: const Color(0xFF9AA3A2),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ),
            const Expanded(child: Divider(color: Color(0xFFE3DED4))),
          ],
        ),
        const SizedBox(height: 20),

        // --- Gender ---
        DropdownButtonFormField<String>(
          initialValue: viewModel.gender,
          decoration: _inputDecoration(
            label: 'Gender',
            prefixIcon: Icons.wc_outlined,
          ),
          items: const [
            DropdownMenuItem(value: 'Male', child: Text('Male')),
            DropdownMenuItem(value: 'Female', child: Text('Female')),
            DropdownMenuItem(value: 'Prefer not to say', child: Text('Prefer not to say')),
          ],
          onChanged: viewModel.setGender,
        ),
        const SizedBox(height: 14),

        // --- Sleep Goal ---
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                initialValue: viewModel.sleepGoalHours,
                decoration: _inputDecoration(
                  label: 'Sleep Goal',
                  prefixIcon: Icons.schedule_outlined,
                ),
                items: List.generate(5, (i) {
                  final h = i + 6;
                  return DropdownMenuItem(value: h, child: Text('$h hours'));
                }),
                onChanged: (v) {
                  if (v != null) viewModel.setSleepGoalHours(v);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: viewModel.napHabit,
                decoration: _inputDecoration(
                  label: 'Nap Habit',
                  prefixIcon: Icons.airline_seat_individual_suite_outlined,
                ),
                items: const [
                  DropdownMenuItem(value: 'Never', child: Text('Never')),
                  DropdownMenuItem(value: 'Sometimes', child: Text('Sometimes')),
                  DropdownMenuItem(value: 'Daily', child: Text('Daily')),
                ],
                onChanged: (v) {
                  if (v != null) viewModel.setNapHabit(v);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // --- Notifications toggle ---
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFAF9F6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE3DED4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.notifications_outlined, size: 20, color: Color(0xFF526D82)),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Enable notifications',
                  style: TextStyle(fontSize: 14, color: Color(0xFF1D2B2A)),
                ),
              ),
              Switch.adaptive(
                value: viewModel.notificationsEnabled,
                onChanged: viewModel.setNotificationsEnabled,
                activeTrackColor: const Color(0xFF526D82),
              ),
            ],
          ),
        ),

        if (viewModel.authError != null) ...[
          const SizedBox(height: 14),
          _buildErrorBanner(viewModel.authError!),
        ],
        const SizedBox(height: 24),
        _buildSubmitButton(viewModel, 'Create Account'),
      ],
    );
  }

  Widget _buildPickerField({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required bool hasValue,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF9F6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: errorText != null ? Colors.red.shade400 : const Color(0xFFE3DED4),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: const Color(0xFF526D82)),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: hasValue ? const Color(0xFF1D2B2A) : const Color(0xFF9AA3A2),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 6),
            child: Text(
              errorText,
              style: TextStyle(fontSize: 12, color: Colors.red.shade700),
            ),
          ),
      ],
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, size: 20, color: Colors.red.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(AuthViewModel viewModel, String label) {
    return SizedBox(
      height: 52,
      child: FilledButton(
        onPressed: viewModel.isLoading ? null : () => _handleSubmit(viewModel),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF27374D),
          disabledBackgroundColor: const Color(0xFF27374D).withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: viewModel.isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }
}
