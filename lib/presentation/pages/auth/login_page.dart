import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medtrace/core/extensions/extensions.dart';
import 'package:medtrace/presentation/providers/app_providers.dart';
import 'package:medtrace/presentation/router/app_router.dart';
import 'package:medtrace/presentation/widgets/medtrace_brand.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  static const _navy = Color(0xFF00436B);
  static const _teal = Color(0xFF12BFA4);
  static const _text = Color(0xFF1E2224);
  static const _muted = Color(0xFF6F777A);
  static const _border = Color(0xFFDDE3E3);
  static const _danger = Color(0xFFC5161D);

  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (!email.isValidEmail) {
      _showSnackBar('Please enter a valid email', isError: true);
      return;
    }

    if (!password.isValidPassword) {
      _showSnackBar('Password must be at least 6 characters', isError: true);
      return;
    }

    final success = await ref
        .read(authProvider.notifier)
        .login(email: email, password: password);

    if (!mounted) return;

    if (success) {
      final user = ref.read(authProvider).user;
      if (user?.isDoctor ?? false) {
        context.go(AppRoutes.doctorDashboard);
      } else {
        context.go(AppRoutes.patientDashboard);
      }
    } else {
      final error = ref.read(authProvider).error;
      _showSnackBar(error ?? 'Login failed', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? _danger : _teal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final availableHeight = MediaQuery.sizeOf(context).height -
        MediaQuery.paddingOf(context).vertical -
        52;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(32, 20, 32, 32),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: availableHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    tooltip: 'Back',
                    onPressed: authState.isLoading
                        ? null
                        : () => context.go(AppRoutes.register),
                    icon: const Icon(Icons.arrow_back, color: _navy),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(44, 44),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Center(child: MedTraceBrandMark(size: 132)),
                const SizedBox(height: 28),
                const Center(child: MedTraceWordmark(fontSize: 42)),
                const SizedBox(height: 76),
                _AuthTextField(
                  label: 'Email or Username',
                  hintText: 'Email',
                  controller: _emailController,
                  enabled: !authState.isLoading,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                _AuthTextField(
                  label: 'Password',
                  hintText: 'Password',
                  controller: _passwordController,
                  enabled: !authState.isLoading,
                  obscureText: !_showPassword,
                  suffixIcon: IconButton(
                    tooltip: _showPassword ? 'Hide password' : 'Show password',
                    icon: Icon(
                      _showPassword ? Icons.visibility : Icons.visibility_off,
                      color: _muted,
                    ),
                    onPressed: authState.isLoading
                        ? null
                        : () => setState(() => _showPassword = !_showPassword),
                  ),
                ),
                const SizedBox(height: 58),
                SizedBox(
                  height: 44,
                  child: FilledButton(
                    onPressed: authState.isLoading ? null : _handleLogin,
                    style: FilledButton.styleFrom(
                      elevation: 0,
                      backgroundColor: _navy,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      textStyle: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                    child: authState.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text('Log In'),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account? ",
                      style: TextStyle(color: _muted, fontSize: 13),
                    ),
                    TextButton(
                      onPressed: authState.isLoading
                          ? null
                          : () => context.go(AppRoutes.register),
                      child: const Text('Sign Up'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  final String label;
  final String hintText;
  final TextEditingController controller;
  final bool enabled;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;

  const _AuthTextField({
    required this.label,
    required this.hintText,
    required this.controller,
    required this.enabled,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      textField: true,
      label: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 42, bottom: 8),
            child: Text(
              label,
              style: const TextStyle(
                color: _LoginPageState._text,
                fontSize: 16,
                fontWeight: FontWeight.w400,
                letterSpacing: 0,
              ),
            ),
          ),
          SizedBox(
            height: 50,
            child: TextField(
              controller: controller,
              enabled: enabled,
              keyboardType: keyboardType,
              obscureText: obscureText,
              style: const TextStyle(
                color: _LoginPageState._text,
                fontSize: 16,
                letterSpacing: 0,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(
                  color: _LoginPageState._muted,
                  fontSize: 16,
                  letterSpacing: 0,
                ),
                suffixIcon: suffixIcon,
                filled: true,
                fillColor: const Color(0xFFFBFDFD),
                contentPadding: const EdgeInsets.symmetric(horizontal: 40),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: const BorderSide(color: _LoginPageState._border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: const BorderSide(
                    color: _LoginPageState._teal,
                    width: 1.4,
                  ),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: const BorderSide(color: _LoginPageState._border),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
