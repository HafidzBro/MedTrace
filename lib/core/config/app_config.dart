import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static const String appName = 'MedTrace';
  static const String appVersion = '1.0.0';

  // Supabase Config (loaded from .env or --dart-define without hardcoded defaults)
  static String get supabaseUrl {
    final envVal = dotenv.isInitialized ? dotenv.env['SUPABASE_URL'] : null;
    if (envVal != null && envVal.isNotEmpty) {
      return envVal;
    }
    return const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  }

  static String get supabaseAnonKey {
    final envVal = dotenv.isInitialized ? dotenv.env['SUPABASE_ANON_KEY'] : null;
    if (envVal != null && envVal.isNotEmpty) {
      return envVal;
    }
    return const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
  }

  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  // API Config
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Feature Flags
  static bool get enableLogging {
    final envVal = dotenv.isInitialized ? dotenv.env['ENABLE_LOGGING'] : null;
    if (envVal != null && envVal.isNotEmpty) {
      return envVal.toLowerCase() == 'true';
    }
    return const bool.fromEnvironment(
      'ENABLE_LOGGING',
      defaultValue: false,
    );
  }

  static bool get enableAnalytics {
    final envVal = dotenv.isInitialized ? dotenv.env['ENABLE_ANALYTICS'] : null;
    if (envVal != null && envVal.isNotEmpty) {
      return envVal.toLowerCase() == 'true';
    }
    return const bool.fromEnvironment(
      'ENABLE_ANALYTICS',
      defaultValue: true,
    );
  }

  // Pagination
  static const int pageSize = 20;

  // Cache Duration
  static const Duration cacheDuration = Duration(hours: 24);
}
