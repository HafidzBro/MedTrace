import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medtrace/presentation/pages/auth/login_page.dart';
import 'package:medtrace/presentation/pages/auth/patient_registration_page.dart';
import 'package:medtrace/presentation/pages/patient/patient_dashboard_page.dart';
import 'package:medtrace/presentation/pages/patient/treatment_details_page.dart';
import 'package:medtrace/presentation/pages/patient/medication_schedule_page.dart';
import 'package:medtrace/presentation/pages/patient/chatbot_page.dart';
import 'package:medtrace/presentation/pages/patient/tb_map_page.dart';
import 'package:medtrace/presentation/pages/patient/reminders_page.dart';
import 'package:medtrace/presentation/pages/doctor/doctor_dashboard_page.dart';
import 'package:medtrace/presentation/pages/doctor/patient_management_page.dart';
import 'package:medtrace/presentation/pages/doctor/alerts_page.dart';
import 'package:medtrace/presentation/providers/app_providers.dart';

// Router Routes
class AppRoutes {
  // Auth
  static const String splash = '/';
  static const String login = '/login';
  static const String patientRegister = '/patient-register';

  // Patient
  static const String patientDashboard = '/patient-dashboard';
  static const String treatment = '/patient/treatment';
  static const String medicationSchedule = '/patient/medications';
  static const String chatbot = '/patient/chatbot';
  static const String tbMap = '/patient/map';
  static const String reminders = '/patient/reminders';

  // Doctor
  static const String doctorDashboard = '/doctor-dashboard';
  static const String patientManagement = '/doctor/patients';
  static const String alerts = '/doctor/alerts';
}

// App Router Provider
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      // If not authenticated, redirect to login
      if (!authState.isAuthenticated) {
        if (state.uri.path == AppRoutes.patientRegister ||
            state.uri.path == AppRoutes.login) {
          return null;
        }
        return AppRoutes.login;
      }

      // If authenticated, redirect based on role
      final user = authState.user;
      if (user != null) {
        if (user.isDoctor && state.uri.path.startsWith('/doctor')) {
          return null;
        }
        if (user.isPatient && state.uri.path.startsWith('/patient')) {
          return null;
        }

        // Redirect to appropriate dashboard
        if (user.isDoctor) {
          return AppRoutes.doctorDashboard;
        } else {
          return AppRoutes.patientDashboard;
        }
      }

      return null;
    },
    routes: [
      // Auth routes
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginPage(),
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
        path: AppRoutes.alerts,
        name: 'alerts',
        builder: (context, state) => const AlertsPage(),
      ),
    ],
  );
});
