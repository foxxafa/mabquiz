import 'package:flutter/foundation.dart';
import 'build_config.dart';

/// Application configuration class that manages environment-specific settings
class AppConfig {
  /// Current environment mode
  final AppEnvironment environment;

  /// Firebase configuration
  final FirebaseConfig firebase;

  /// Authentication configuration
  final AuthConfig auth;

  const AppConfig({
    required this.environment,
    required this.firebase,
    required this.auth,
  });

  /// Factory constructor for development environment
  factory AppConfig.development() {
    return AppConfig(
      environment: AppEnvironment.development,
      firebase: FirebaseConfig.development(),
      auth: AuthConfig.development(),
    );
  }

  /// Factory constructor for production environment
  factory AppConfig.production() {
    return AppConfig(
      environment: AppEnvironment.production,
      firebase: FirebaseConfig.production(),
      auth: AuthConfig.production(),
    );
  }

  /// Factory constructor that automatically determines environment
  /// Uses build configuration to override default behavior
  factory AppConfig.auto() {
    // Print build configuration in debug mode
    if (kDebugMode) {
      BuildConfig.printConfig();
    }

    return BuildConfig.isDevelopment ? AppConfig.development() : AppConfig.production();
  }
}

/// Application environment enumeration
enum AppEnvironment {
  development,
  production,
}

/// Firebase-specific configuration
class FirebaseConfig {
  /// Whether to use Firebase emulator
  final bool useEmulator;

  /// Emulator host (only used when useEmulator is true)
  final String emulatorHost;

  /// Auth emulator port
  final int authEmulatorPort;

  /// Whether Firebase is enabled
  final bool enabled;

  const FirebaseConfig({
    required this.useEmulator,
    required this.emulatorHost,
    required this.authEmulatorPort,
    required this.enabled,
  });

  /// Development configuration with emulator
  factory FirebaseConfig.development() {
    return FirebaseConfig(
      useEmulator: !BuildConfig.disableFirebase, // Use emulator unless explicitly disabled
      emulatorHost: BuildConfig.firebaseEmulatorHost,
      authEmulatorPort: BuildConfig.firebaseAuthEmulatorPort,
      enabled: !BuildConfig.disableFirebase,
    );
  }

  /// Production configuration with real Firebase
  factory FirebaseConfig.production() {
    return FirebaseConfig(
      useEmulator: false,
      emulatorHost: '',
      authEmulatorPort: 0,
      enabled: !BuildConfig.disableFirebase,
    );
  }
}

/// Authentication-specific configuration
class AuthConfig {
  /// Whether to use mock authentication
  final bool useMockAuth;

  /// Mock authentication delay in milliseconds
  final int mockAuthDelay;

  /// Whether to enable authentication persistence
  final bool enablePersistence;

  const AuthConfig({
    required this.useMockAuth,
    required this.mockAuthDelay,
    required this.enablePersistence,
  });

  /// Development configuration with mock auth
  factory AuthConfig.development() {
    return AuthConfig(
      useMockAuth: BuildConfig.forceMockAuth || BuildConfig.disableFirebase || true, // Always use mock in development
      mockAuthDelay: 1000,
      enablePersistence: true,
    );
  }

  /// Production configuration with real auth
  factory AuthConfig.production() {
    return AuthConfig(
      useMockAuth: BuildConfig.forceMockAuth || BuildConfig.disableFirebase,
      mockAuthDelay: 0,
      enablePersistence: true,
    );
  }
}