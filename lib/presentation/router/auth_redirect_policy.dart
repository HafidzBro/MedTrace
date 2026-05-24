import 'package:medtrace/presentation/router/app_routes.dart';

class AuthRedirectState {
  final bool isAuthenticated;
  final String? role;

  const AuthRedirectState({
    required this.isAuthenticated,
    this.role,
  });
}

String? resolveAuthRedirect({
  required String path,
  required AuthRedirectState auth,
}) {
  if (!auth.isAuthenticated) {
    if (path == AppRoutes.splash ||
        path == AppRoutes.register ||
        path == AppRoutes.patientRegister ||
        path == AppRoutes.login) {
      return null;
    }
    return AppRoutes.login;
  }

  return switch (auth.role) {
    'doctor' => _resolveDoctorRedirect(path),
    'patient' => _resolvePatientRedirect(path),
    _ => AppRoutes.login,
  };
}

String? _resolveDoctorRedirect(String path) {
  if (_isDoctorRoute(path)) return null;
  return AppRoutes.doctorDashboard;
}

String? _resolvePatientRedirect(String path) {
  if (_isPatientRoute(path)) return null;
  return AppRoutes.patientDashboard;
}

bool _isDoctorRoute(String path) {
  return path == AppRoutes.doctorDashboard || path.startsWith('/doctor/');
}

bool _isPatientRoute(String path) {
  return path == AppRoutes.patientDashboard || path.startsWith('/patient/');
}
