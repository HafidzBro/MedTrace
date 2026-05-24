import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medtrace/presentation/router/app_router.dart';
import 'package:medtrace/presentation/widgets/medtrace_brand.dart';

class RegisterEntryPage extends StatelessWidget {
  const RegisterEntryPage({super.key});

  static const _navy = Color(0xFF00436B);
  static const _teal = Color(0xFF12BFA4);
  static const _text = Color(0xFF1E2224);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              const MedTraceBrandMark(size: 190),
              const Spacer(flex: 2),
              const Text(
                'Track treatment, reminders, and care support with your healthcare provider.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _text,
                  fontSize: 12,
                  height: 1.25,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 36),
              _AuthButton(
                label: 'Log In',
                color: _navy,
                onPressed: () => context.go(AppRoutes.login),
              ),
              const SizedBox(height: 10),
              _AuthButton(
                label: 'Sign Up',
                color: _teal,
                onPressed: () => context.go(AppRoutes.patientRegister),
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _AuthButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}
