// Supabase configuration with fallbacks for different environments
class Environment {
  // Default values for development/local testing
  static const String _defaultWebAppUrl = 'http://localhost:8080';
  static const String _defaultSupabaseUrl = 'http://localhost:8000';
  static const String _defaultAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyAgCiAgICAicm9sZSI6ICJhbm9uIiwKICAgICJpc3MiOiAic3VwYWJhc2UtZGVtbyIsCiAgICAiaWF0IjogMTY0MTc2OTIwMCwKICAgICJleHAiOiAxNzk5NTM1NjAwCn0.dc_X5iR_VP_qT0zsiyj_I_OZ2T9FtRU2BBNWN8Bu4GE';

  // Web App URL for generating shareable links

  static String get webAppUrl {
    // Try compile-time environment first
    const compileTimeUrl = String.fromEnvironment('WEB_APP_URL');
    if (compileTimeUrl.isNotEmpty) {
      return compileTimeUrl;
    }

    // For Docker builds, use Kong service URL
    return _defaultWebAppUrl;
  }

  // Get configuration from compile-time or runtime environment
  static String get supabaseUrl {
    // Try compile-time environment first
    const compileTimeUrl = String.fromEnvironment('SUPABASE_URL');
    if (compileTimeUrl.isNotEmpty) {
      return compileTimeUrl;
    }

    // For Docker builds, use Kong service URL
    return _defaultSupabaseUrl;
  }

  static String get supabaseAnonKey {
    // Try compile-time environment first
    const compileTimeKey = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (compileTimeKey.isNotEmpty) {
      return compileTimeKey;
    }

    return _defaultAnonKey;
  }

  // Service role key for admin operations
  static String get supabaseServiceRoleKey {
    const compileTimeKey = String.fromEnvironment('SUPABASE_SERVICE_ROLE_KEY');
    if (compileTimeKey.isNotEmpty) {
      return compileTimeKey;
    }

    return 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyAgCiAgICAicm9sZSI6ICJzZXJ2aWNlX3JvbGUiLAogICAgImlzcyI6ICJzdXBhYmFzZS1kZW1vIiwKICAgICJpYXQiOiAxNjQxNzY5MjAwLAogICAgImV4cCI6IDE3OTk1MzU2MDAKfQ.DaYlNEoUrrEn2Ig7tqibS-PHK5vgusbcbo7X36XVt4Q';
  }

  // Environment detection
  static bool get isProduction => const bool.fromEnvironment('dart.vm.product');
  static bool get isDevelopment => !isProduction;
}

// Backwards compatibility - maintain existing exports
const supabaseUrl = Environment._defaultSupabaseUrl;
const supabaseAnonKey = Environment._defaultAnonKey;
