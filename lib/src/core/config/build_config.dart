import 'package:flutter/foundation.dart';

/// Build configuration that can be set at compile time
///
/// This class provides build-time configuration that can be overridden
/// using --dart-define flags during flutter build or run commands.
class BuildConfig {
  /// Environment override from build arguments
  /// Usage: flutter run --dart-define=ENVIRONMENT=production
  static const String _environmentOverride = String.fromEnvironment('ENVIRONMENT');

  /// Firebase emulator host override
  /// Usage: flutter run --dart-define=FIREBASE_EMULATOR_HOST=10.0.2.2
  static const String _firebaseEmulatorHost = String.fromEnvironment(
    'FIREBASE_EMULATOR_HOST',
    defaultValue: 'localhost',
  );

  /// Firebase Auth emulator port override
  /// Usage: flutter run --dart-define=FIREBASE_AUTH_EMULATOR_PORT=9099
  static const int _firebaseAuthEmulatorPort = int.fromEnvironment(
    'FIREBASE_AUTH_EMULATOR_PORT',
    defaultValue: 9099,
  );

  /// Force mock auth override
  /// Usage: flutter run --dart-define=FORCE_MOCK_AUTH=true
  static const bool _forceMockAuth = bool.fromEnvironment('FORCE_MOCK_AUTH');

  /// Disable Firebase override
  /// Usage: flutter run --dart-define=DISABLE_FIREBASE=true
  static const bool _disableFirebase = bool.fromEnvironment('DISABLE_FIREBASE');

  /// Get the current environment based on build configuration
  static String get environment {
    if (_environmentOverride.isNotEmpty) {
      return _environmentOverride;
    }
    return kDebugMode ? 'development' : 'production';
  }

  /// Get Firebase emulator host
  static String get firebaseEmulatorHost => _firebaseEmulatorHost;

  /// Get Firebase Auth emulator port
  static int get firebaseAuthEmulatorPort => _firebaseAuthEmulatorPort;

  /// Check if mock auth should be forced
  static bool get forceMockAuth => _forceMockAuth;

  /// Check if Firebase should be disabled
  static bool get disableFirebase => _disableFirebase;

  /// Check if we're in development mode
  static bool get isDevelopment => environment == 'development';

  /// Check if we're in production mode
  static bool get isProduction => environment == 'production';

  /// Print current build configuration (debug only)
  static void printConfig() {
    if (kDebugMode) {
      print('=== Build Configuration ===');
      print('Environment: $environment');
      print('Firebase Emulator Host: $firebaseEmulatorHost');
      print('Firebase Auth Emulator Port: $firebaseAuthEmulatorPort');
      print('Force Mock Auth: $forceMockAuth');
      print('Disable Firebase: $disableFirebase');
      print('Is Development: $isDevelopment');
      print('Is Production: $isProduction');
      print('========================');
    }
  }
}