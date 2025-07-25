import '../../domain/entities/question.dart';

/// Abstract repository interface for quiz operations
///
/// This interface defines the contract for quiz data operations
/// and provides abstraction between the UI layer and concrete implementations
/// (Firebase, Mock, etc.)
abstract class QuizRepository {
  /// Fetch questions by subject
  ///
  /// Returns a list of questions for the specified subject.
  /// Throws [QuizRepositoryException] if the operation fails.
  Future<List<Question>> getQuestionsBySubject(String subject);

  /// Fetch questions by difficulty level
  ///
  /// Returns a list of questions for the specified difficulty level.
  /// Throws [QuizRepositoryException] if the operation fails.
  Future<List<Question>> getQuestionsByDifficulty(DifficultyLevel difficulty);

  /// Fetch random questions with optional filters
  ///
  /// Parameters:
  /// - [limit]: Maximum number of questions to return (default: 10)
  /// - [subject]: Filter by subject (optional)
  /// - [difficulty]: Filter by difficulty level (optional)
  /// - [excludeIds]: List of question IDs to exclude (optional)
  ///
  /// Returns a list of random questions matching the criteria.
  /// Throws [QuizRepositoryException] if the operation fails.
  Future<List<Question>> getRandomQuestions({
    int limit = 10,
    String? subject,
    DifficultyLevel? difficulty,
    List<String>? excludeIds,
  });

  /// Fetch a single question by ID
  ///
  /// Returns the question with the specified ID, or null if not found.
  /// Throws [QuizRepositoryException] if the operation fails.
  Future<Question?> getQuestionById(String id);

  /// Get available subjects
  ///
  /// Returns a list of all available subjects in the question database.
  /// Throws [QuizRepositoryException] if the operation fails.
  Future<List<String>> getAvailableSubjects();

  /// Stream of quiz session updates (for real-time features)
  ///
  /// This can be used for features like live competitions, progress tracking, etc.
  /// Returns a stream that emits quiz session data.
  Stream<QuizSessionData?> get quizSessionStream;
}

/// Data class for quiz session information
class QuizSessionData {
  final String sessionId;
  final List<String> participantIds;
  final String? currentQuestionId;
  final Map<String, int> scores;
  final DateTime startTime;
  final bool isActive;

  const QuizSessionData({
    required this.sessionId,
    required this.participantIds,
    this.currentQuestionId,
    required this.scores,
    required this.startTime,
    required this.isActive,
  });

  /// Create from JSON (for Firebase integration)
  factory QuizSessionData.fromJson(Map<String, dynamic> json) {
    return QuizSessionData(
      sessionId: json['sessionId'] as String,
      participantIds: List<String>.from(json['participantIds'] ?? []),
      currentQuestionId: json['currentQuestionId'] as String?,
      scores: Map<String, int>.from(json['scores'] ?? {}),
      startTime: DateTime.parse(json['startTime'] as String),
      isActive: json['isActive'] as bool? ?? false,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'participantIds': participantIds,
      'currentQuestionId': currentQuestionId,
      'scores': scores,
      'startTime': startTime.toIso8601String(),
      'isActive': isActive,
    };
  }

  QuizSessionData copyWith({
    String? sessionId,
    List<String>? participantIds,
    String? currentQuestionId,
    Map<String, int>? scores,
    DateTime? startTime,
    bool? isActive,
  }) {
    return QuizSessionData(
      sessionId: sessionId ?? this.sessionId,
      participantIds: participantIds ?? this.participantIds,
      currentQuestionId: currentQuestionId ?? this.currentQuestionId,
      scores: scores ?? this.scores,
      startTime: startTime ?? this.startTime,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QuizSessionData && other.sessionId == sessionId;
  }

  @override
  int get hashCode => sessionId.hashCode;

  @override
  String toString() => 'QuizSessionData(sessionId: $sessionId, isActive: $isActive)';
}

/// Exception thrown when quiz repository operations fail
class QuizRepositoryException implements Exception {
  final String message;
  final String? code;
  final Exception? cause;

  const QuizRepositoryException(
    this.message, {
    this.code,
    this.cause,
  });

  @override
  String toString() {
    final buffer = StringBuffer('QuizRepositoryException: $message');
    if (code != null) {
      buffer.write(' (Code: $code)');
    }
    if (cause != null) {
      buffer.write(' Caused by: $cause');
    }
    return buffer.toString();
  }
}
