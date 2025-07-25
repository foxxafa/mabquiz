import '../domain/entities/question.dart';
import '../domain/entities/quiz_score.dart';
import '../data/repositories/quiz_repository.dart';

/// Facade service for quiz operations
///
/// This service provides a simplified interface for quiz operations
/// and handles business logic while delegating actual data operations to the repository.
/// It follows the Facade pattern to hide complexity from the UI layer.
class QuizService {
  final QuizRepository _repository;

  const QuizService(this._repository);

  /// Stream that emits quiz session changes
  Stream<QuizSessionData?> get quizSessionStream => _repository.quizSessionStream;

  /// Get questions for a quiz session
  ///
  /// Parameters:
  /// - [limit]: Number of questions to fetch (default: 10)
  /// - [subject]: Optional subject filter
  /// - [difficulty]: Optional difficulty filter
  /// - [excludeIds]: List of question IDs to exclude
  ///
  /// Returns a list of questions for the quiz session
  /// Throws [QuizServiceException] if the operation fails
  Future<List<Question>> getQuizQuestions({
    int limit = 10,
    String? subject,
    DifficultyLevel? difficulty,
    List<String>? excludeIds,
  }) async {
    try {
      _validateQuizParameters(limit: limit);
      
      return await _repository.getRandomQuestions(
        limit: limit,
        subject: subject,
        difficulty: difficulty,
        excludeIds: excludeIds,
      );
    } on QuizRepositoryException {
      rethrow;
    } catch (e) {
      throw QuizServiceException(
        'Failed to get quiz questions: ${e.toString()}',
        'get-questions-failed',
      );
    }
  }

  /// Get questions by subject
  ///
  /// Parameters:
  /// - [subject]: The subject to filter by
  ///
  /// Returns a list of questions for the specified subject
  /// Throws [QuizServiceException] if the operation fails
  Future<List<Question>> getQuestionsBySubject(String subject) async {
    try {
      _validateSubject(subject);
      
      return await _repository.getQuestionsBySubject(subject);
    } on QuizRepositoryException {
      rethrow;
    } catch (e) {
      throw QuizServiceException(
        'Failed to get questions by subject: ${e.toString()}',
        'get-questions-by-subject-failed',
      );
    }
  }

  /// Get questions by difficulty level
  ///
  /// Parameters:
  /// - [difficulty]: The difficulty level to filter by
  ///
  /// Returns a list of questions for the specified difficulty
  /// Throws [QuizServiceException] if the operation fails
  Future<List<Question>> getQuestionsByDifficulty(DifficultyLevel difficulty) async {
    try {
      return await _repository.getQuestionsByDifficulty(difficulty);
    } on QuizRepositoryException {
      rethrow;
    } catch (e) {
      throw QuizServiceException(
        'Failed to get questions by difficulty: ${e.toString()}',
        'get-questions-by-difficulty-failed',
      );
    }
  }

  /// Get a specific question by ID
  ///
  /// Parameters:
  /// - [id]: The question ID to fetch
  ///
  /// Returns the question with the specified ID, or null if not found
  /// Throws [QuizServiceException] if the operation fails
  Future<Question?> getQuestionById(String id) async {
    try {
      _validateQuestionId(id);
      
      return await _repository.getQuestionById(id);
    } on QuizRepositoryException {
      rethrow;
    } catch (e) {
      throw QuizServiceException(
        'Failed to get question by ID: ${e.toString()}',
        'get-question-by-id-failed',
      );
    }
  }

  /// Get all available subjects
  ///
  /// Returns a list of all available subjects in the question database
  /// Throws [QuizServiceException] if the operation fails
  Future<List<String>> getAvailableSubjects() async {
    try {
      return await _repository.getAvailableSubjects();
    } on QuizRepositoryException {
      rethrow;
    } catch (e) {
      throw QuizServiceException(
        'Failed to get available subjects: ${e.toString()}',
        'get-subjects-failed',
      );
    }
  }

  /// Calculate quiz score based on answers
  ///
  /// Parameters:
  /// - [questions]: List of questions in the quiz
  /// - [answers]: Map of question ID to user's answer
  ///
  /// Returns the calculated score information
  QuizScore calculateScore(List<Question> questions, Map<String, String> answers) {
    if (questions.isEmpty) {
      return QuizScore(
        totalQuestions: 0,
        correctAnswers: 0,
        totalPoints: 0,
        earnedPoints: 0,
        percentage: 0.0,
        questionResults: [],
      );
    }

    var correctAnswers = 0;
    var earnedPoints = 0;
    final totalPoints = questions.fold<int>(0, (sum, q) => sum + q.points);
    final questionResults = <QuestionResult>[];

    for (final question in questions) {
      final userAnswer = answers[question.id];
      final isCorrect = userAnswer == question.correctAnswer;
      
      if (isCorrect) {
        correctAnswers++;
        earnedPoints += question.points;
      }

      questionResults.add(QuestionResult(
        questionId: question.id,
        userAnswer: userAnswer,
        correctAnswer: question.correctAnswer,
        isCorrect: isCorrect,
        pointsEarned: isCorrect ? question.points : 0,
        maxPoints: question.points,
      ));
    }

    final percentage = (correctAnswers / questions.length) * 100;

    return QuizScore(
      totalQuestions: questions.length,
      correctAnswers: correctAnswers,
      totalPoints: totalPoints,
      earnedPoints: earnedPoints,
      percentage: percentage,
      questionResults: questionResults,
    );
  }

  /// Validate quiz parameters
  void _validateQuizParameters({required int limit}) {
    if (limit <= 0) {
      throw QuizServiceException(
        'Question limit must be greater than 0',
        'invalid-limit',
      );
    }
    if (limit > 100) {
      throw QuizServiceException(
        'Question limit cannot exceed 100',
        'limit-too-high',
      );
    }
  }

  /// Validate subject parameter
  void _validateSubject(String subject) {
    if (subject.trim().isEmpty) {
      throw QuizServiceException(
        'Subject cannot be empty',
        'invalid-subject',
      );
    }
  }

  /// Validate question ID parameter
  void _validateQuestionId(String id) {
    if (id.trim().isEmpty) {
      throw QuizServiceException(
        'Question ID cannot be empty',
        'invalid-question-id',
      );
    }
  }
}

/// Enum for quiz performance levels
enum QuizPerformanceLevel {
  excellent,
  good,
  satisfactory,
  needsImprovement,
  poor,
}

/// Extension for performance level descriptions
extension QuizPerformanceLevelExtension on QuizPerformanceLevel {
  String get description {
    switch (this) {
      case QuizPerformanceLevel.excellent:
        return 'Mükemmel';
      case QuizPerformanceLevel.good:
        return 'İyi';
      case QuizPerformanceLevel.satisfactory:
        return 'Yeterli';
      case QuizPerformanceLevel.needsImprovement:
        return 'Geliştirilmeli';
      case QuizPerformanceLevel.poor:
        return 'Yetersiz';
    }
  }

  String get message {
    switch (this) {
      case QuizPerformanceLevel.excellent:
        return 'Tebrikler! Harika bir performans sergiledingiz.';
      case QuizPerformanceLevel.good:
        return 'Çok iyi! Başarılı bir performans gösterdingiz.';
      case QuizPerformanceLevel.satisfactory:
        return 'İyi bir performans. Biraz daha çalışarak daha da iyileştirebilirsingz.';
      case QuizPerformanceLevel.needsImprovement:
        return 'Performansınızı geliştirebilirsingz. Daha fazla pratik yapın.';
      case QuizPerformanceLevel.poor:
        return 'Bu konularda daha fazla çalışmanıza ihtiyaç var.';
    }
  }
}

/// Exception thrown when quiz service operations fail
class QuizServiceException implements Exception {
  final String message;
  final String code;

  const QuizServiceException(this.message, this.code);

  @override
  String toString() => 'QuizServiceException: $message (Code: $code)';
}
