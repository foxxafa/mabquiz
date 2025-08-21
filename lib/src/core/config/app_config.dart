import 'package:flutter/foundation.dart';
import 'build_config.dart';

/// Application configuration class that manages environment-specific settings
class AppConfig {
  /// Current environment mode
  final AppEnvironment environment;

  /// Authentication configuration
  final AuthConfig auth;

  /// Quiz configuration
  final QuizConfig quiz;

  const AppConfig({
    required this.environment,
    required this.auth,
    required this.quiz,
  });

  /// Factory constructor for development environment
  factory AppConfig.development() {
    return AppConfig(
      environment: AppEnvironment.development,
      auth: AuthConfig.development(),
      quiz: QuizConfig.development(),
    );
  }

  /// Factory constructor for production environment
  factory AppConfig.production() {
    return AppConfig(
      environment: AppEnvironment.production,
      auth: AuthConfig.production(),
      quiz: QuizConfig.production(),
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
      useMockAuth: true, // Always use mock in development
      mockAuthDelay: 1000,
      enablePersistence: true,
    );
  }

  /// Production configuration with Railway auth
  factory AuthConfig.production() {
    return AuthConfig(
      useMockAuth: false, // Use Railway auth in production
      mockAuthDelay: 0,
      enablePersistence: true,
    );
  }
  
  /// Helper getter for production check
  bool get useProduction => !useMockAuth;
}

/// Quiz-specific configuration
class QuizConfig {
  /// Whether to use mock quiz data
  final bool useMockData;

  /// Mock data delay in milliseconds
  final int mockDataDelay;

  /// Maximum number of questions per quiz
  final int maxQuestionsPerQuiz;

  const QuizConfig({
    required this.useMockData,
    required this.mockDataDelay,
    required this.maxQuestionsPerQuiz,
  });

  /// Development configuration with mock data
  factory QuizConfig.development() {
    return const QuizConfig(
      useMockData: true,
      mockDataDelay: 1000,
      maxQuestionsPerQuiz: 10,
    );
  }

  /// Production configuration with API data
  factory QuizConfig.production() {
    return const QuizConfig(
      useMockData: false,
      mockDataDelay: 0,
      maxQuestionsPerQuiz: 20,
    );
  }
}
