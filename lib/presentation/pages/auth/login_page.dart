import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medtrace/core/extensions/extensions.dart';
import 'package:medtrace/presentation/providers/app_providers.dart';
import 'package:medtrace/presentation/router/app_router.dart';
import 'package:medtrace/shared/theme/app_theme.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
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

    if (mounted) {
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
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.errorRed : AppColors.successGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.patientPrimary.withOpacity(0.1),
              AppColors.patientSecondary.withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo & App Name
                const SizedBox(height: 40),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.patientPrimary,
                  ),
                  child: const Icon(
                    Icons.medical_services_outlined,
                    color: AppColors.white,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'MedTrace',
                  style: AppTypography.headline1.copyWith(
                    color: AppColors.patientPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'TB Monitoring & Management',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.mediumGrey,
                  ),
                ),
                const SizedBox(height: 48),

                // Email Input
                TextField(
                  controller: _emailController,
                  enabled: !authState.isLoading,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Password Input
                TextField(
                  controller: _passwordController,
                  enabled: !authState.isLoading,
                  obscureText: !_showPassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _showPassword = !_showPassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: authState.isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.patientPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: authState.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation(
                                AppColors.white,
                              ),
                            ),
                          )
                        : Text(
                            'Login',
                            style: AppTypography.labelLarge.copyWith(
                              color: AppColors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Register Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: AppTypography.bodySmall,
                    ),
                    TextButton(
                      onPressed: authState.isLoading
                          ? null
                          : () {
                              context.push(AppRoutes.patientRegister);
                            },
                      child: Text(
                        'Register',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.patientPrimary,
                        ),
                      ),
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
