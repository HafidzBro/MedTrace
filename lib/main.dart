import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:medtrace/core/config/app_config.dart';
import 'package:medtrace/presentation/providers/app_providers.dart';
import 'package:medtrace/presentation/router/app_router.dart';
import 'package:medtrace/services/notification_service.dart';
import 'package:logger/logger.dart';

final logger = Logger();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Supabase
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
    logger.i('Supabase initialized successfully');

    await NotificationService.instance.initialize();
    logger.i('Notification service initialized successfully');
  } catch (e) {
    logger.e('Supabase initialization error: $e');
    rethrow;
  }

  runApp(const ProviderScope(child: MedTraceApp()));
}

class MedTraceApp extends ConsumerWidget {
  const MedTraceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final theme = ref.watch(appThemeProvider);

    return MaterialApp.router(
      title: 'MedTrace',
      debugShowCheckedModeBanner: false,
      theme: theme.lightTheme,
      darkTheme: theme.darkTheme,
      themeMode: ThemeMode.light,
      routerDelegate: router.routerDelegate,
      routeInformationParser: router.routeInformationParser,
      routeInformationProvider: router.routeInformationProvider,
    );
  }
}
