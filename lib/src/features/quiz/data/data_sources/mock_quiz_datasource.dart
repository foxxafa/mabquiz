import 'dart:async';
import 'dart:math';
import '../../domain/entities/question.dart';
import '../services/asset_question_loader.dart';

/// Mock data source for quiz questions - simulates Firebase behavior
///
/// This class provides a mock implementation that can be used during
/// development and testing when Firebase is not available.
abstract class QuizDataSource {
  /// Fetch questions by subject
  Future<List<Question>> getQuestionsBySubject(String subject);

  /// Fetch questions by difficulty level
  Future<List<Question>> getQuestionsByDifficulty(DifficultyLevel difficulty);

  /// Fetch random questions with optional filters
  Future<List<Question>> getRandomQuestions({
    int limit = 10,
    String? subject,
    DifficultyLevel? difficulty,
    List<String>? excludeIds,
  });

  /// Fetch a single question by ID
  Future<Question?> getQuestionById(String id);

  /// Get available subjects
  Future<List<String>> getAvailableSubjects();

  /// Get all questions
  Future<List<Question>> getAllQuestions();
}

/// Mock implementation of QuizDataSource
class MockQuizDataSource implements QuizDataSource {
  final Duration simulatedDelay;
  final Random _random = Random();

  /// In-memory storage of questions
  List<Question> _allQuestions = [];
  bool _isInitialized = false;
  Future<void>? _initializationFuture;

  MockQuizDataSource({
    this.simulatedDelay = const Duration(milliseconds: 300),
  });

  /// Initialize the data source with questions from assets
  Future<void> initialize() async {
    await _ensureInitialized();
  }

  Future<void> _initialize() async {
    if (_isInitialized) return;

        // print('MockQuizDataSource: getQuestionsBySubject called with subject: $subject');

    // Load farmakoloji questions from assets
    final farmakolojiQuestions =
        await AssetQuestionLoader.loadAllQuestionsForSubject('farmakoloji');
        // print('MockQuizDataSource: getSubjects called');

    // Load terminoloji questions from assets
    final terminolojiQuestions =
        await AssetQuestionLoader.loadAllQuestionsForSubject('terminoloji');
        // print('MockQuizDataSource: Returning ${subjects.length} subjects');

    _allQuestions = [
      // Farmakoloji soruları
      ...farmakolojiQuestions,

      // Terminoloji soruları
      ...terminolojiQuestions,
    ];

        // print('MockQuizDataSource: Found ${questions.length} questions');
        // print('MockQuizDataSource: Returning ${randomQuestions.length} random questions');

    _isInitialized = true;
  }

  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;

    // Prevent multiple concurrent initializations
    if (_initializationFuture != null) {
      return _initializationFuture!;
    }

    _initializationFuture = _initialize();
    await _initializationFuture!;
    _initializationFuture = null;
  }

  @override
  Future<List<Question>> getQuestionsBySubject(String subject) async {
    await _ensureInitialized();
    await Future.delayed(simulatedDelay);
    return _allQuestions
        .where((q) => q.subject.toLowerCase() == subject.toLowerCase())
        .toList();
  }

  @override
  Future<List<Question>> getQuestionsByDifficulty(
      DifficultyLevel difficulty) async {
    await _ensureInitialized();
    await Future.delayed(simulatedDelay);
    return _allQuestions
        .where((question) => question.difficulty == difficulty)
        .toList();
  }

  @override
  Future<List<Question>> getRandomQuestions({
    int limit = 10,
    String? subject,
    DifficultyLevel? difficulty,
    List<String>? excludeIds,
  }) async {
    await _ensureInitialized();
    await Future.delayed(simulatedDelay);

    var filteredQuestions = List<Question>.from(_allQuestions);

    // Apply filters
    if (subject != null) {
      filteredQuestions = filteredQuestions
          .where((q) => q.subject.toLowerCase() == subject.toLowerCase())
          .toList();
    }

    if (difficulty != null) {
      filteredQuestions =
          filteredQuestions.where((q) => q.difficulty == difficulty).toList();
    }

    if (excludeIds != null && excludeIds.isNotEmpty) {
      filteredQuestions =
          filteredQuestions.where((q) => !excludeIds.contains(q.id)).toList();
    }

    // Shuffle and return requested amount
    filteredQuestions.shuffle(_random);
    return filteredQuestions.take(limit).toList();
  }

  @override
  Future<Question?> getQuestionById(String id) async {
    await _ensureInitialized();
    await Future.delayed(simulatedDelay);

    try {
      return _allQuestions.firstWhere((question) => question.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<String>> getAvailableSubjects() async {
    await _ensureInitialized();
    await Future.delayed(simulatedDelay);

    final subjects =
        _allQuestions.map((question) => question.subject).toSet().toList();

    subjects.sort();
    return subjects;
  }

  /// Get all questions for testing and initialization purposes
  @override
  Future<List<Question>> getAllQuestions() async {
    await _ensureInitialized();
    await Future.delayed(simulatedDelay);
    return List.unmodifiable(_allQuestions);
  }

  /// Add a question (for testing purposes)
  void addQuestion(Question question) {
    _allQuestions.add(question);
  }

  /// Clear all questions (for testing purposes)
  void clearQuestions() {
    _allQuestions.clear();
    _isInitialized = false;
  }

  /// Reset to default questions (for testing purposes)
  void resetToDefaults() {
    _allQuestions.clear();
    _isInitialized = false;
    _initialize();
  }
}

/// Exception thrown when quiz data operations fail
class QuizDataException implements Exception {
  final String message;
  final String? code;

  const QuizDataException(this.message, [this.code]);

  @override
  String toString() => 'QuizDataException: $message${code != null ? ' (Code: $code)' : ''}';
}
