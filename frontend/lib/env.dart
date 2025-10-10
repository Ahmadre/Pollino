// Supabase configuration with fallbacks for different environments
class Environment {
  // Default values for development/local testing
  static const String _defaultWebAppUrl = 'http://localhost:8080';
  static const String _defaultSupabaseUrl = 'https://supabase.asta.hn';
  static const String _defaultAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNzU5ODc0NDAwLCJleHAiOjE5MTc2NDA4MDB9.FHDDyOFtuQW9Xaaqrkx6LDamYcBD8FzCO8s_CeIGA54';

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

    return 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoic2VydmljZV9yb2xlIiwiaXNzIjoic3VwYWJhc2UiLCJpYXQiOjE3NTk4NzQ0MDAsImV4cCI6MTkxNzY0MDgwMH0.Ow0M97IuBRkJUK3Sim7gR4p9h8s66YfaaQZS40HcS78';
  }

  // Environment detection
  static bool get isProduction => const bool.fromEnvironment('dart.vm.product');
  static bool get isDevelopment => !isProduction;
}

// Backwards compatibility - maintain existing exports
const supabaseUrl = Environment._defaultSupabaseUrl;
const supabaseAnonKey = Environment._defaultAnonKey;
