import 'package:flutter/foundation.dart';

/// Build configuration that can be set at compile time
///
/// This class provides build-time configuration that can be overridden
/// using --dart-define flags during flutter build or run commands.
class BuildConfig {
  /// Environment override from build arguments
  /// Usage: flutter run --dart-define=ENVIRONMENT=production
  static const String _environmentOverride = String.fromEnvironment('ENVIRONMENT');

  /// Force mock auth override
  /// Usage: flutter run --dart-define=FORCE_MOCK_AUTH=true
  static const bool _forceMockAuth = bool.fromEnvironment('FORCE_MOCK_AUTH');

  /// Get the current environment based on build configuration
  static String get environment {
    if (_environmentOverride.isNotEmpty) {
      return _environmentOverride;
    }
    return kDebugMode ? 'development' : 'production';
  }

  /// Check if mock auth should be forced
  static bool get forceMockAuth => _forceMockAuth;

  /// Check if we're in development mode
  static bool get isDevelopment => environment == 'development';

  /// Check if we're in production mode
  static bool get isProduction => environment == 'production';

  /// Print current build configuration (debug only)
  static void printConfig() {
    if (kDebugMode) {
      print('=== Build Configuration ===');
      print('Environment: $environment');
      print('Force Mock Auth: $forceMockAuth');
      print('Is Development: $isDevelopment');
      print('Is Production: $isProduction');
      print('========================');
    }
  }
}