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
