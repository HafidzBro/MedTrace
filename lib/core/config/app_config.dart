class AppConfig {
  static const String appName = 'MedTrace';
  static const String appVersion = '1.0.0';

  // Supabase Config
  static const String supabaseUrl = 'https://wnpdpaiwescxkqigqlrt.supabase.co';
  static const String supabaseAnonKey =
      'sb_publishable_W-aXJzdqHDKE_ZNy4cLHGw_DLlxMQFr';

  // API Config
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // OpenAI Config
  static const String openaiApiKey = String.fromEnvironment('OPENAI_API_KEY');

  // Feature Flags
  static const bool enableLogging = bool.fromEnvironment(
    'ENABLE_LOGGING',
    defaultValue: false,
  );
  static const bool enableAnalytics = bool.fromEnvironment(
    'ENABLE_ANALYTICS',
    defaultValue: true,
  );

  // Pagination
  static const int pageSize = 20;

  // Cache Duration
  static const Duration cacheDuration = Duration(hours: 24);
}
