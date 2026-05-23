import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medtrace/core/config/app_config.dart';
import 'package:medtrace/presentation/pages/auth/login_page.dart';
import 'package:medtrace/presentation/providers/app_providers.dart';
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

    expect(find.text('MedTrace'), findsWidgets);
    expect(find.text('Login'), findsWidgets);
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
