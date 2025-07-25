import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_config.dart';

/// Provider for the application configuration
///
/// This provider automatically determines the environment and provides
/// the appropriate configuration for the current build mode.
final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig.auto();
});

/// Provider for the current environment
final environmentProvider = Provider<AppEnvironment>((ref) {
  final config = ref.watch(appConfigProvider);
  return config.environment;
});

/// Provider for Firebase configuration
final firebaseConfigProvider = Provider<FirebaseConfig>((ref) {
  final config = ref.watch(appConfigProvider);
  return config.firebase;
});

/// Provider for authentication configuration
final authConfigProvider = Provider<AuthConfig>((ref) {
  final config = ref.watch(appConfigProvider);
  return config.auth;
});

/// Provider that determines if we should use mock authentication
///
/// This is used by the auth repository provider to decide between
/// mock and Firebase authentication implementations.
final useMockAuthProvider = Provider<bool>((ref) {
  final authConfig = ref.watch(authConfigProvider);
  return authConfig.useMockAuth;
});

/// Provider that determines if Firebase emulator should be used
final useFirebaseEmulatorProvider = Provider<bool>((ref) {
  final firebaseConfig = ref.watch(firebaseConfigProvider);
  return firebaseConfig.useEmulator;
});