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

/// Provider for authentication configuration
final authConfigProvider = Provider<AuthConfig>((ref) {
  final config = ref.watch(appConfigProvider);
  return config.auth;
});

/// QuizConfig provider
final quizConfigProvider = Provider<QuizConfig>((ref) {
  final config = ref.watch(appConfigProvider);
  return config.quiz;
});

/// Provider that determines if we should use mock authentication
///
/// This is used by the auth repository provider to decide between
/// mock and Firebase authentication implementations.
final useMockAuthProvider = Provider<bool>((ref) {
  final authConfig = ref.watch(authConfigProvider);
  return authConfig.useMockAuth;
});

/// Provider that determines if we should use mock quiz data
///
/// This is used by the quiz repository provider to decide between
/// mock and Firebase quiz implementations.
final useMockQuizProvider = Provider<bool>((ref) {
  final quizConfig = ref.watch(quizConfigProvider);
  return quizConfig.useMockData;
});