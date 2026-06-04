import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:medtrace/core/config/app_config.dart';
import 'package:medtrace/presentation/providers/app_providers.dart';
import 'package:medtrace/presentation/router/app_router.dart';
import 'package:medtrace/presentation/widgets/offline_indicator.dart';
import 'package:medtrace/services/notification_service.dart';
import 'package:medtrace/services/connectivity_service.dart';
import 'package:medtrace/services/cache_service.dart';
import 'package:medtrace/services/offline_queue_service.dart';
import 'package:logger/logger.dart';

final logger = Logger();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );

    await CacheService.instance.initialize();
    await OfflineQueueService.instance.initialize();
    await NotificationService.instance.initialize();
    ConnectivityService.instance.initialize();

    NotificationService.onNotificationTap = _handleNotificationTap;
  } catch (e) {
    logger.e('Initialization error: $e');
    rethrow;
  }

  runApp(const ProviderScope(child: MedTraceApp()));
}

GoRouter? _appRouter;

void _handleNotificationTap(String? payload) {
  if (payload == null) return;
  try {
    final data = jsonDecode(payload) as Map<String, dynamic>;
    final route = data['route'] as String?;
    if (route != null) {
      _appRouter?.go(route);
    }
  } catch (_) {}
}

class MedTraceApp extends ConsumerWidget {
  const MedTraceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    _appRouter = router;
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
      builder: (context, child) => OfflineIndicator(child: child ?? const SizedBox()),
    );
  }
}
