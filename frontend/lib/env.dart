/// Application environment configuration.
/// All values can be overridden via compile-time --dart-define flags.
class Environment {
  static const String _defaultWebAppUrl = 'http://localhost:3001';
  static const String _defaultApiBaseUrl = 'http://localhost:8080';

  static String get webAppUrl {
    const compileTimeUrl = String.fromEnvironment('WEB_APP_URL');
    if (compileTimeUrl.isNotEmpty) return compileTimeUrl;
    return _defaultWebAppUrl;
  }

  static String get apiBaseUrl {
    const compileTimeUrl = String.fromEnvironment('API_BASE_URL');
    if (compileTimeUrl.isNotEmpty) return compileTimeUrl;
    return _defaultApiBaseUrl;
  }

  static bool get isProduction => const bool.fromEnvironment('dart.vm.product');
  static bool get isDevelopment => !isProduction;
}
