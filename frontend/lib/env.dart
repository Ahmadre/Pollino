// Supabase configuration with fallbacks for different environments
class Environment {
  // Default values for development/local testing
  static const String _defaultSupabaseUrl = 'http://localhost:8005';
  static const String _defaultAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InBvbGxpbm8tc3VwYWJhc2UiLCJpYXQiOjE3Mjg0MDMyMDAsImV4cCI6MjA0Mzk3OTIwMH0.Xj5K8mN2qP9sT7vY4bF1eH6gL3aR8cW0zI5uO7nM9xQ2';

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

    return 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoic2VydmljZV9yb2xlIiwiaXNzIjoicG9sbGluby1zdXBhYmFzZSIsImlhdCI6MTcyODQwMzIwMCwiZXhwIjoyMDQzOTc5MjAwfQ.F2aE8xK5nM9cV7wL3pR6tY4uI2oB8fG1hJ0qS7vZ9xN';
  }

  // Environment detection
  static bool get isProduction => const bool.fromEnvironment('dart.vm.product');
  static bool get isDevelopment => !isProduction;
}

// Backwards compatibility - maintain existing exports
const supabaseUrl = Environment._defaultSupabaseUrl;
const supabaseAnonKey = Environment._defaultAnonKey;
