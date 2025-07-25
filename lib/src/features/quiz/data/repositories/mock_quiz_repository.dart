import 'dart:async';
import '../data_sources/mock_quiz_datasource.dart';
import '../../domain/entities/question.dart';
import 'quiz_repository.dart';

/// Mock implementation of QuizRepository for testing and development
///
/// This class provides a fake quiz system that simulates real repository behavior
/// with realistic delays and test data. It's useful for development when Firebase
/// is not available or for testing.
class MockQuizRepository implements QuizRepository {
  final QuizDataSource _dataSource;
  final StreamController<QuizSessionData?> _quizSessionController =
      StreamController<QuizSessionData?>.broadcast();

  QuizSessionData? _currentSession;

  MockQuizRepository(this._dataSource) {
    // Initialize with no active session
    Future(() => _quizSessionController.add(null));
  }

  @override
  Future<List<Question>> getQuestionsBySubject(String subject) async {
    try {
      return await _dataSource.getQuestionsBySubject(subject);
    } on QuizDataException catch (e) {
      throw QuizRepositoryException(
        'Failed to fetch questions by subject',
        code: e.code,
        cause: e,
      );
    } catch (e) {
      throw QuizRepositoryException(
        'Unexpected error while fetching questions by subject: $e',
        cause: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  @override
  Future<List<Question>> getQuestionsByDifficulty(DifficultyLevel difficulty) async {
    try {
      return await _dataSource.getQuestionsByDifficulty(difficulty);
    } on QuizDataException catch (e) {
      throw QuizRepositoryException(
        'Failed to fetch questions by difficulty',
        code: e.code,
        cause: e,
      );
    } catch (e) {
      throw QuizRepositoryException(
        'Unexpected error while fetching questions by difficulty: $e',
        cause: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  @override
  Future<List<Question>> getRandomQuestions({
    int limit = 10,
    String? subject,
    DifficultyLevel? difficulty,
    List<String>? excludeIds,
  }) async {
    try {
      return await _dataSource.getRandomQuestions(
        limit: limit,
        subject: subject,
        difficulty: difficulty,
        excludeIds: excludeIds,
      );
    } on QuizDataException catch (e) {
      throw QuizRepositoryException(
        'Failed to fetch random questions',
        code: e.code,
        cause: e,
      );
    } catch (e) {
      throw QuizRepositoryException(
        'Unexpected error while fetching random questions: $e',
        cause: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  @override
  Future<Question?> getQuestionById(String id) async {
    try {
      return await _dataSource.getQuestionById(id);
    } on QuizDataException catch (e) {
      throw QuizRepositoryException(
        'Failed to fetch question by ID',
        code: e.code,
        cause: e,
      );
    } catch (e) {
      throw QuizRepositoryException(
        'Unexpected error while fetching question by ID: $e',
        cause: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  @override
  Future<List<String>> getAvailableSubjects() async {
    try {
      return await _dataSource.getAvailableSubjects();
    } on QuizDataException catch (e) {
      throw QuizRepositoryException(
        'Failed to fetch available subjects',
        code: e.code,
        cause: e,
      );
    } catch (e) {
      throw QuizRepositoryException(
        'Unexpected error while fetching available subjects: $e',
        cause: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  @override
  Stream<QuizSessionData?> get quizSessionStream => _quizSessionController.stream;

  /// Create a new quiz session (for testing purposes)
  Future<QuizSessionData> createQuizSession({
    required List<String> participantIds,
    String? firstQuestionId,
  }) async {
    final sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';

    _currentSession = QuizSessionData(
      sessionId: sessionId,
      participantIds: participantIds,
      currentQuestionId: firstQuestionId,
      scores: {for (final id in participantIds) id: 0},
      startTime: DateTime.now(),
      isActive: true,
    );

    _quizSessionController.add(_currentSession);
    return _currentSession!;
  }

  /// Update quiz session (for testing purposes)
  Future<void> updateQuizSession(QuizSessionData sessionData) async {
    _currentSession = sessionData;
    _quizSessionController.add(_currentSession);
  }

  /// End current quiz session (for testing purposes)
  Future<void> endQuizSession() async {
    if (_currentSession != null) {
      _currentSession = _currentSession!.copyWith(isActive: false);
      _quizSessionController.add(_currentSession);
    }
  }

  /// Get current session (for testing purposes)
  QuizSessionData? get currentSession => _currentSession;

  /// Dispose the repository to prevent memory leaks
  void dispose() {
    _quizSessionController.close();
  }

  /// Test helper methods for integration tests

  /// Simulate network error for testing
  Future<void> simulateNetworkError() async {
    await Future.delayed(const Duration(milliseconds: 500));
    throw const QuizRepositoryException(
      'Network error occurred',
      code: 'network-error',
    );
  }

  /// Simulate service unavailable for testing
  Future<void> simulateServiceUnavailable() async {
    await Future.delayed(const Duration(milliseconds: 500));
    throw const QuizRepositoryException(
      'Service temporarily unavailable',
      code: 'service-unavailable',
    );
  }

  /// Add question to data source (for testing)
  void addQuestion(Question question) {
    final mockDataSource = _dataSource;
    if (mockDataSource is MockQuizDataSource) {
      mockDataSource.addQuestion(question);
    }
  }

  /// Clear all questions (for testing)
  void clearQuestions() {
    final mockDataSource = _dataSource;
    if (mockDataSource is MockQuizDataSource) {
      mockDataSource.clearQuestions();
    }
  }

  /// Get all questions (for testing)
  Future<List<Question>> getAllQuestions() async {
    final mockDataSource = _dataSource;
    if (mockDataSource is MockQuizDataSource) {
      return await mockDataSource.getAllQuestions();
    }
    return [];
  }
}
