import 'package:flutter_test/flutter_test.dart';
import 'package:medtrace/presentation/router/app_routes.dart';
import 'package:medtrace/presentation/router/auth_redirect_policy.dart';

void main() {
  group('resolveAuthRedirect', () {
    test('keeps unauthenticated users on public auth routes', () {
      const auth = AuthRedirectState(isAuthenticated: false);

      expect(
        resolveAuthRedirect(path: AppRoutes.login, auth: auth),
        isNull,
      );
      expect(
        resolveAuthRedirect(path: AppRoutes.patientRegister, auth: auth),
        isNull,
      );
    });

    test('sends unauthenticated users away from protected routes', () {
      const auth = AuthRedirectState(isAuthenticated: false);

      expect(
        resolveAuthRedirect(path: AppRoutes.patientDashboard, auth: auth),
        AppRoutes.login,
      );
      expect(
        resolveAuthRedirect(path: AppRoutes.doctorDashboard, auth: auth),
        AppRoutes.login,
      );
    });

    test('keeps doctors inside doctor routes only', () {
      const auth = AuthRedirectState(
        isAuthenticated: true,
        role: 'doctor',
      );

      expect(
        resolveAuthRedirect(path: AppRoutes.doctorDashboard, auth: auth),
        isNull,
      );
      expect(
        resolveAuthRedirect(path: AppRoutes.patientDashboard, auth: auth),
        AppRoutes.doctorDashboard,
      );
      expect(
        resolveAuthRedirect(path: AppRoutes.patientRegister, auth: auth),
        AppRoutes.doctorDashboard,
      );
    });

    test('keeps patients inside patient routes only', () {
      const auth = AuthRedirectState(
        isAuthenticated: true,
        role: 'patient',
      );

      expect(
        resolveAuthRedirect(path: AppRoutes.patientDashboard, auth: auth),
        isNull,
      );
      expect(
        resolveAuthRedirect(path: AppRoutes.doctorDashboard, auth: auth),
        AppRoutes.patientDashboard,
      );
      expect(
        resolveAuthRedirect(path: AppRoutes.patientRegister, auth: auth),
        AppRoutes.patientDashboard,
      );
    });
  });
}
