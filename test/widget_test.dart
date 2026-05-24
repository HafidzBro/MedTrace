import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medtrace/core/config/app_config.dart';
import 'package:medtrace/presentation/pages/auth/login_page.dart';
import 'package:medtrace/presentation/pages/auth/patient_registration/patient_registration_page.dart';
import 'package:medtrace/presentation/pages/auth/register_entry_page.dart';
import 'package:medtrace/presentation/pages/auth/splash_page.dart';
import 'package:medtrace/presentation/providers/app_providers.dart';
import 'package:medtrace/presentation/widgets/medtrace_brand.dart';
import 'package:medtrace/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('login screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => TestAuthNotifier()),
        ],
        child: const MaterialApp(home: LoginPage()),
      ),
    );

    await tester.pump();

    expect(find.byType(MedTraceWordmark), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
    expect(find.text("Don't have an account? "), findsOneWidget);
  });

  testWidgets('register entry screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: RegisterEntryPage()),
    );

    expect(find.text('Log In'), findsOneWidget);
    expect(find.text('Sign Up'), findsOneWidget);
  });

  testWidgets('splash screen renders brand', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => TestAuthNotifier()),
        ],
        child: const MaterialApp(home: SplashPage()),
      ),
    );

    expect(find.byType(MedTraceWordmark), findsOneWidget);
    expect(find.text('Medical Care Tracer'), findsOneWidget);
  });

  testWidgets(
      'patient registration shows identity, medical, and treatment steps',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => TestAuthNotifier()),
          doctorCodeProvider.overrideWith((ref) => TestDoctorCodeNotifier()),
        ],
        child: const MaterialApp(home: PatientRegistrationPage()),
      ),
    );

    expect(find.text('Patient Registration'), findsOneWidget);
    expect(find.text('Personal Details'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Sarah Jenkins');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'sarah@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(2), 'secret123');
    await tester.enterText(find.byType(TextFormField).at(3), 'secret123');
    await tester.tap(find.text('Continue to Medical History'));
    await tester.pumpAndSettle();

    expect(find.text('Medical Information'), findsOneWidget);

    await tester.tap(find.text('Continue to Step 3'));
    await tester.pumpAndSettle();

    expect(find.text('Treatment Setup'), findsWidgets);
    expect(find.text('Complete Registration'), findsOneWidget);
  });
}

class TestAuthNotifier extends AuthNotifier {
  TestAuthNotifier()
      : super(
          SupabaseService(
            client: SupabaseClient(
              AppConfig.supabaseUrl,
              AppConfig.supabaseAnonKey,
              authOptions: const AuthClientOptions(autoRefreshToken: false),
            ),
          ),
        );

  @override
  Future<void> checkAuthStatus() async {
    state = AuthState();
  }
}

class TestDoctorCodeNotifier extends DoctorCodeNotifier {
  TestDoctorCodeNotifier()
      : super(
          SupabaseService(
            client: SupabaseClient(
              AppConfig.supabaseUrl,
              AppConfig.supabaseAnonKey,
              authOptions: const AuthClientOptions(autoRefreshToken: false),
            ),
          ),
        );
}
