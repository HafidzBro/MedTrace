import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medtrace/presentation/pages/auth/login_page.dart';
import 'package:medtrace/presentation/pages/auth/patient_registration_page.dart';
import 'package:medtrace/presentation/pages/auth/register_entry_page.dart';
import 'package:medtrace/presentation/pages/auth/splash_page.dart';
import 'package:medtrace/presentation/pages/patient/patient_dashboard_page.dart';
import 'package:medtrace/presentation/pages/patient/treatment_details_page.dart';
import 'package:medtrace/presentation/pages/patient/medication_schedule_page.dart';
import 'package:medtrace/presentation/pages/patient/chatbot_page.dart';
import 'package:medtrace/presentation/pages/patient/tb_map_page.dart';
import 'package:medtrace/presentation/pages/patient/reminders_page.dart';
import 'package:medtrace/presentation/pages/doctor/doctor_dashboard_page.dart';
import 'package:medtrace/presentation/pages/doctor/patient_management_page.dart';
import 'package:medtrace/presentation/pages/doctor/alerts_page.dart';
import 'package:medtrace/presentation/pages/doctor/patient_detail_page.dart';
import 'package:medtrace/presentation/pages/doctor/analytics_page.dart';
import 'package:medtrace/presentation/pages/doctor/doctor_map_page.dart';
import 'package:medtrace/presentation/providers/app_providers.dart';
import 'package:medtrace/presentation/router/app_routes.dart';
import 'package:medtrace/presentation/router/auth_redirect_policy.dart';

export 'package:medtrace/presentation/router/app_routes.dart';

// App Router Provider
final appRouterProvider = Provider<GoRouter>((ref) {
  late final GoRouter router;

  ref.listen(authProvider, (_, __) {
    router.refresh();
  });

  router = GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final authState = ref.read(authProvider);

      return resolveAuthRedirect(
        path: state.uri.path,
        auth: AuthRedirectState(
          isAuthenticated: authState.isAuthenticated,
          role: authState.user?.role,
        ),
      );
    },
    errorBuilder: (context, state) => _UnknownRoutePage(
      isAuthenticated: ref.read(authProvider).isAuthenticated,
      isDoctor: ref.read(authProvider).user?.isDoctor ?? false,
    ),
    routes: [
      // Auth routes
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterEntryPage(),
      ),
      GoRoute(
        path: AppRoutes.patientRegister,
        name: 'patient_register',
        builder: (context, state) => const PatientRegistrationPage(),
      ),

      // Patient routes
      GoRoute(
        path: AppRoutes.patientDashboard,
        name: 'patient_dashboard',
        builder: (context, state) => const PatientDashboardPage(),
      ),
      GoRoute(
        path: AppRoutes.treatment,
        name: 'treatment',
        builder: (context, state) => const TreatmentDetailsPage(),
      ),
      GoRoute(
        path: AppRoutes.medicationSchedule,
        name: 'medication_schedule',
        builder: (context, state) => const MedicationSchedulePage(),
      ),
      GoRoute(
        path: AppRoutes.chatbot,
        name: 'chatbot',
        builder: (context, state) => const ChatbotPage(),
      ),
      GoRoute(
        path: AppRoutes.tbMap,
        name: 'tb_map',
        builder: (context, state) => const TbMapPage(),
      ),
      GoRoute(
        path: AppRoutes.reminders,
        name: 'reminders',
        builder: (context, state) => const RemindersPage(),
      ),

      // Doctor routes
      GoRoute(
        path: AppRoutes.doctorDashboard,
        name: 'doctor_dashboard',
        builder: (context, state) => const DoctorDashboardPage(),
      ),
      GoRoute(
        path: AppRoutes.patientManagement,
        name: 'patient_management',
        builder: (context, state) => const PatientManagementPage(),
      ),
      GoRoute(
        path: AppRoutes.patientDetail,
        name: 'patient_detail',
        builder: (context, state) {
          final extra = state.extra as Map<String, String>? ?? {};
          return PatientDetailPage(
            patientId: extra['patientId'] ?? '',
            patientName: extra['patientName'] ?? 'Patient',
          );
        },
      ),
      GoRoute(
        path: AppRoutes.alerts,
        name: 'alerts',
        builder: (context, state) => const AlertsPage(),
      ),
      GoRoute(
        path: AppRoutes.analytics,
        name: 'analytics',
        builder: (context, state) => const AnalyticsPage(),
      ),
      GoRoute(
        path: AppRoutes.doctorMap,
        name: 'doctor_map',
        builder: (context, state) => const DoctorMapPage(),
      ),
    ],
  );

  return router;
});

class _UnknownRoutePage extends StatelessWidget {
  final bool isAuthenticated;
  final bool isDoctor;

  const _UnknownRoutePage({
    required this.isAuthenticated,
    required this.isDoctor,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = !isAuthenticated
        ? AppRoutes.login
        : isDoctor
            ? AppRoutes.doctorDashboard
            : AppRoutes.patientDashboard;

    return Scaffold(
      appBar: AppBar(title: const Text('Page not found')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.route_outlined, size: 56),
              const SizedBox(height: 16),
              const Text(
                'This page is not available.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => context.go(fallback),
                child: const Text('Go back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
