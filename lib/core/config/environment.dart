import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration class
/// Manages environment-specific variables loaded from .env files
class Environment {
  /// Current environment name (development, test, production)
  static String get environment => dotenv.env['ENVIRONMENT'] ?? 'development';

  /// API base URL
  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? 'http://127.0.0.1:5000';

  /// API timeout in milliseconds
  static int get apiTimeout => int.tryParse(dotenv.env['API_TIMEOUT'] ?? '30000') ?? 30000;

  /// App name with environment suffix
  static String get appName => dotenv.env['APP_NAME'] ?? 'V6 Mobile';

  /// Whether logging is enabled
  static bool get enableLogging => dotenv.env['ENABLE_LOGGING']?.toLowerCase() == 'true';

  /// Whether debug tools are enabled
  static bool get enableDebugTools => dotenv.env['ENABLE_DEBUG_TOOLS']?.toLowerCase() == 'true';

  /// Check if current environment is development
  static bool get isDevelopment => environment == 'development';

  /// Check if current environment is test
  static bool get isTest => environment == 'test';

  /// Check if current environment is production
  static bool get isProduction => environment == 'production';

  /// Print current environment configuration (for debugging)
  static void printConfig() {
    if (enableLogging) {
      print('=== Environment Configuration ===');
      print('Environment: $environment');
      print('API Base URL: $apiBaseUrl');
      print('API Timeout: ${apiTimeout}ms');
      print('App Name: $appName');
      print('Logging: $enableLogging');
      print('Debug Tools: $enableDebugTools');
      print('================================');
    }
  }
}
