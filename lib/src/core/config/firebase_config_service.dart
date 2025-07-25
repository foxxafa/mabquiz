import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'app_config.dart';

/// Service for configuring Firebase based on environment settings
class FirebaseConfigService {
  static bool _initialized = false;

  /// Initialize Firebase with the given configuration
  static Future<void> initialize(AppConfig config) async {
    if (_initialized) {
      return;
    }

    try {
      // Initialize Firebase Core
      if (config.firebase.enabled) {
        await Firebase.initializeApp();

        // Configure emulator if in development mode
        if (config.firebase.useEmulator && kDebugMode) {
          await _configureEmulator(config.firebase);
        }
      }

      _initialized = true;

      if (kDebugMode) {
        print('Firebase initialized successfully');
        print('Environment: ${config.environment}');
        print('Using emulator: ${config.firebase.useEmulator}');
        print('Using mock auth: ${config.auth.useMockAuth}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Firebase initialization failed: $e');
        print('Falling back to mock authentication');
      }

      // Don't throw error, let the app continue with mock auth
      _initialized = true;
    }
  }

  /// Configure Firebase emulator settings
  static Future<void> _configureEmulator(FirebaseConfig config) async {
    try {
      // Configure Auth emulator
      await FirebaseAuth.instance.useAuthEmulator(
        config.emulatorHost,
        config.authEmulatorPort,
      );

      if (kDebugMode) {
        print('Firebase Auth emulator configured: ${config.emulatorHost}:${config.authEmulatorPort}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to configure Firebase emulator: $e');
      }
      // Don't rethrow, emulator configuration is optional
    }
  }

  /// Check if Firebase is properly initialized
  static bool get isInitialized => _initialized;

  /// Reset initialization state (useful for testing)
  static void reset() {
    _initialized = false;
  }
}