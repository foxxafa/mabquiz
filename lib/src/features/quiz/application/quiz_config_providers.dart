import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/config_providers.dart';
import '../data/services/firebase_quiz_config_service.dart';

/// Provider for Quiz configuration
///
/// This provider manages quiz-specific configuration settings
/// and provides access to the Firebase Quiz Config Service
final quizConfigProvider = Provider<QuizConfig>((ref) {
  final useMockAuth = ref.watch(useMockAuthProvider);
  
  if (useMockAuth) {
    return QuizConfig.development();
  } else {
    return QuizConfig.production();
  }
});

/// Provider for Firebase Quiz Config Service
///
/// This provides access to the Firebase Quiz Configuration Service
/// for initializing and managing quiz data in Firebase
final firebaseQuizConfigServiceProvider = Provider<FirebaseQuizConfigService>((ref) {
  return FirebaseQuizConfigService.instance;
});

/// Provider for quiz initialization status
///
/// Tracks whether Firebase quiz service has been initialized
final quizInitializationProvider = StateProvider<bool>((ref) => false);

/// Quiz-specific configuration class
class QuizConfig {
  /// Whether to use mock quiz data
  final bool useMockData;
  
  /// Mock data delay in milliseconds
  final int mockDataDelay;
  
  /// Maximum number of questions per quiz
  final int maxQuestionsPerQuiz;
  
  /// Whether to enable caching
  final bool enableCaching;
  
  /// Cache TTL in minutes
  final int cacheTtlMinutes;
  
  /// Whether to enable offline mode
  final bool enableOfflineMode;

  const QuizConfig({
    required this.useMockData,
    required this.mockDataDelay,
    required this.maxQuestionsPerQuiz,
    required this.enableCaching,
    required this.cacheTtlMinutes,
    required this.enableOfflineMode,
  });

  /// Development configuration with mock data
  factory QuizConfig.development() {
    return const QuizConfig(
      useMockData: true,
      mockDataDelay: 1000,
      maxQuestionsPerQuiz: 10,
      enableCaching: true,
      cacheTtlMinutes: 5,
      enableOfflineMode: true,
    );
  }

  /// Production configuration with Firebase
  factory QuizConfig.production() {
    return const QuizConfig(
      useMockData: false,
      mockDataDelay: 0,
      maxQuestionsPerQuiz: 20,
      enableCaching: true,
      cacheTtlMinutes: 10,
      enableOfflineMode: true,
    );
  }

  /// Test configuration
  factory QuizConfig.test() {
    return const QuizConfig(
      useMockData: true,
      mockDataDelay: 0,
      maxQuestionsPerQuiz: 5,
      enableCaching: false,
      cacheTtlMinutes: 0,
      enableOfflineMode: false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QuizConfig &&
        other.useMockData == useMockData &&
        other.mockDataDelay == mockDataDelay &&
        other.maxQuestionsPerQuiz == maxQuestionsPerQuiz &&
        other.enableCaching == enableCaching &&
        other.cacheTtlMinutes == cacheTtlMinutes &&
        other.enableOfflineMode == enableOfflineMode;
  }

  @override
  int get hashCode {
    return Object.hash(
      useMockData,
      mockDataDelay,
      maxQuestionsPerQuiz,
      enableCaching,
      cacheTtlMinutes,
      enableOfflineMode,
    );
  }

  @override
  String toString() {
    return 'QuizConfig('
        'useMockData: $useMockData, '
        'mockDataDelay: $mockDataDelay, '
        'maxQuestionsPerQuiz: $maxQuestionsPerQuiz, '
        'enableCaching: $enableCaching, '
        'cacheTtlMinutes: $cacheTtlMinutes, '
        'enableOfflineMode: $enableOfflineMode'
        ')';
  }
}
