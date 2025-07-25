import 'dart:async';
import '../data_sources/firebase_quiz_datasource.dart';
import '../../domain/entities/question.dart';
import 'quiz_repository.dart';

/// Firebase implementation of QuizRepository
///
/// This class provides concrete implementation of quiz operations
/// using Firebase Firestore. It handles Firebase-specific operations and
/// maps Firebase exceptions to domain exceptions.
class FirebaseQuizRepository implements QuizRepository {
  final FirebaseQuizDataSource _dataSource;
  final StreamController<QuizSessionData?> _quizSessionController =
      StreamController<QuizSessionData?>.broadcast();

  QuizSessionData? _currentSession;

  FirebaseQuizRepository(this._dataSource) {
    // Initialize with no active session
    Future(() => _quizSessionController.add(null));
  }

  @override
  Future<List<Question>> getQuestionsBySubject(String subject) async {
    try {
      return await _dataSource.getQuestionsBySubject(subject);
    } on FirebaseQuizException catch (e) {
      throw QuizRepositoryException(
        'Failed to fetch questions by subject from Firebase',
        code: 'firebase-error',
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
    } on FirebaseQuizException catch (e) {
      throw QuizRepositoryException(
        'Failed to fetch questions by difficulty from Firebase',
        code: 'firebase-error',
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
    } on FirebaseQuizException catch (e) {
      throw QuizRepositoryException(
        'Failed to fetch random questions from Firebase',
        code: 'firebase-error',
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
    } on FirebaseQuizException catch (e) {
      throw QuizRepositoryException(
        'Failed to fetch question by ID from Firebase',
        code: 'firebase-error',
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
    } on FirebaseQuizException catch (e) {
      throw QuizRepositoryException(
        'Failed to fetch available subjects from Firebase',
        code: 'firebase-error',
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

  /// Create a new quiz session in Firebase
  Future<QuizSessionData> createQuizSession({
    required List<String> participantIds,
    String? firstQuestionId,
  }) async {
    try {
      final sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';

      _currentSession = QuizSessionData(
        sessionId: sessionId,
        participantIds: participantIds,
        currentQuestionId: firstQuestionId,
        scores: {for (final id in participantIds) id: 0},
        startTime: DateTime.now(),
        isActive: true,
      );

      // TODO: Save to Firebase when cloud_firestore is available
      // await _firestore.collection('quiz_sessions').doc(sessionId).set(_currentSession.toJson());

      _quizSessionController.add(_currentSession);
      return _currentSession!;
    } catch (e) {
      throw QuizRepositoryException(
        'Failed to create quiz session in Firebase: $e',
        code: 'firebase-error',
        cause: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Update quiz session in Firebase
  Future<void> updateQuizSession(QuizSessionData sessionData) async {
    try {
      _currentSession = sessionData;

      // TODO: Update in Firebase when cloud_firestore is available
      // await _firestore.collection('quiz_sessions').doc(sessionData.sessionId).update(sessionData.toJson());

      _quizSessionController.add(_currentSession);
    } catch (e) {
      throw QuizRepositoryException(
        'Failed to update quiz session in Firebase: $e',
        code: 'firebase-error',
        cause: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// End current quiz session
  Future<void> endQuizSession() async {
    try {
      if (_currentSession != null) {
        _currentSession = _currentSession!.copyWith(isActive: false);

        // TODO: Update in Firebase when cloud_firestore is available
        // await _firestore.collection('quiz_sessions').doc(_currentSession!.sessionId).update({'isActive': false});

        _quizSessionController.add(_currentSession);
      }
    } catch (e) {
      throw QuizRepositoryException(
        'Failed to end quiz session in Firebase: $e',
        code: 'firebase-error',
        cause: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Get current session
  QuizSessionData? get currentSession => _currentSession;

  /// Dispose the repository to prevent memory leaks
  void dispose() {
    _quizSessionController.close();
  }
}
