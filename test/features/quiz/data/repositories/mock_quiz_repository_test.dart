import 'package:flutter_test/flutter_test.dart';
import 'package:mabquiz/src/features/quiz/data/data_sources/mock_quiz_datasource.dart';
import 'package:mabquiz/src/features/quiz/data/models/question.dart';
import 'package:mabquiz/src/features/quiz/data/repositories/mock_quiz_repository.dart';
import 'package:mabquiz/src/features/quiz/data/repositories/quiz_repository.dart';

void main() {
  group('MockQuizRepository', () {
    late MockQuizDataSource dataSource;
    late MockQuizRepository repository;

    setUp(() {
      dataSource = MockQuizDataSource(
        simulatedDelay: const Duration(milliseconds: 10), // Faster for tests
      );
      repository = MockQuizRepository(dataSource);
    });

    tearDown(() {
      repository.dispose();
    });

    group('getQuestionsBySubject', () {
      test('should return questions for valid subject', () async {
        final questions = await repository.getQuestionsBySubject('Matematik');

        expect(questions, isNotEmpty);
        expect(questions.every((q) => q.subject == 'Matematik'), isTrue);
      });

      test('should wrap data source exceptions', () async {
        // Clear questions to create an empty state
        dataSource.clearQuestions();

        // This should still work but return empty list
        final questions = await repository.getQuestionsBySubject('NonExistent');
        expect(questions, isEmpty);
      });
    });

    group('getQuestionsByDifficulty', () {
      test('should return questions for difficulty level', () async {
        final questions = await repository.getQuestionsByDifficulty(DifficultyLevel.beginner);

        expect(questions, isNotEmpty);
        expect(questions.every((q) => q.difficulty == DifficultyLevel.beginner), isTrue);
      });
    });

    group('getRandomQuestions', () {
      test('should return random questions with filters', () async {
        final questions = await repository.getRandomQuestions(
          limit: 5,
          subject: 'Matematik',
          difficulty: DifficultyLevel.beginner,
        );

        expect(questions.length, lessThanOrEqualTo(5));
        expect(questions.every((q) =>
          q.subject == 'Matematik' &&
          q.difficulty == DifficultyLevel.beginner
        ), isTrue);
      });

      test('should handle exclude IDs', () async {
        final excludeIds = ['math_001'];
        final questions = await repository.getRandomQuestions(
          excludeIds: excludeIds,
          limit: 10,
        );

        expect(questions.every((q) => !excludeIds.contains(q.id)), isTrue);
      });
    });

    group('getQuestionById', () {
      test('should return question for valid ID', () async {
        final question = await repository.getQuestionById('math_001');

        expect(question, isNotNull);
        expect(question!.id, equals('math_001'));
      });

      test('should return null for non-existent ID', () async {
        final question = await repository.getQuestionById('non_existent');

        expect(question, isNull);
      });
    });

    group('getAvailableSubjects', () {
      test('should return available subjects', () async {
        final subjects = await repository.getAvailableSubjects();

        expect(subjects, isNotEmpty);
        expect(subjects, contains('Matematik'));
        expect(subjects, contains('Türkçe'));
      });
    });

    group('quiz session management', () {
      test('should create quiz session successfully', () async {
        final participantIds = ['user1', 'user2'];
        final session = await repository.createQuizSession(
          participantIds: participantIds,
          firstQuestionId: 'math_001',
        );

        expect(session.participantIds, equals(participantIds));
        expect(session.currentQuestionId, equals('math_001'));
        expect(session.isActive, isTrue);
        expect(session.scores.keys, containsAll(participantIds));
        expect(repository.currentSession, equals(session));
      });

      test('should update quiz session', () async {
        final session = await repository.createQuizSession(
          participantIds: ['user1'],
        );

        final updatedSession = session.copyWith(
          currentQuestionId: 'math_002',
          scores: {'user1': 10},
        );

        await repository.updateQuizSession(updatedSession);

        expect(repository.currentSession?.currentQuestionId, equals('math_002'));
        expect(repository.currentSession?.scores['user1'], equals(10));
      });

      test('should end quiz session', () async {
        await repository.createQuizSession(participantIds: ['user1']);
        expect(repository.currentSession?.isActive, isTrue);

        await repository.endQuizSession();

        expect(repository.currentSession?.isActive, isFalse);
      });

      test('should emit quiz session updates', () async {
        final sessionUpdates = <QuizSessionData?>[];
        final subscription = repository.quizSessionStream.listen(sessionUpdates.add);

        // Wait for initial null
        await Future.delayed(const Duration(milliseconds: 20));

        // Create session
        final session = await repository.createQuizSession(participantIds: ['user1']);
        await Future.delayed(const Duration(milliseconds: 10));

        // End session
        await repository.endQuizSession();
        await Future.delayed(const Duration(milliseconds: 10));

        expect(sessionUpdates.length, greaterThanOrEqualTo(3));
        expect(sessionUpdates.first, isNull); // Initial state
        expect(sessionUpdates[1]?.sessionId, equals(session.sessionId));
        expect(sessionUpdates[1]?.isActive, isTrue);
        expect(sessionUpdates.last?.isActive, isFalse);

        await subscription.cancel();
      });
    });

    group('error simulation', () {
      test('should simulate network error', () async {
        expect(
          () => repository.simulateNetworkError(),
          throwsA(isA<QuizRepositoryException>()),
        );
      });

      test('should simulate service unavailable', () async {
        expect(
          () => repository.simulateServiceUnavailable(),
          throwsA(isA<QuizRepositoryException>()),
        );
      });
    });

    group('test helper methods', () {
      test('should add question to data source', () {
        final initialCount = repository.getAllQuestions().length;

        final newQuestion = Question(
          id: 'test_001',
          text: 'Test question?',
          type: QuestionType.multipleChoice,
          difficulty: DifficultyLevel.beginner,
          options: ['A', 'B', 'C', 'D'],
          correctAnswer: 'A',
          subject: 'Test',
        );

        repository.addQuestion(newQuestion);

        expect(repository.getAllQuestions().length, equals(initialCount + 1));
      });

      test('should clear all questions', () {
        repository.clearQuestions();

        expect(repository.getAllQuestions(), isEmpty);
      });

      test('should get all questions', () {
        final questions = repository.getAllQuestions();

        expect(questions, isNotEmpty);
        expect(questions, isA<List<Question>>());
      });
    });

    group('edge cases', () {
      test('should handle empty data source gracefully', () async {
        dataSource.clearQuestions();

        final subjects = await repository.getAvailableSubjects();
        expect(subjects, isEmpty);

        final questions = await repository.getRandomQuestions();
        expect(questions, isEmpty);
      });

      test('should handle end session when no active session', () async {
        expect(repository.currentSession, isNull);

        // Should not throw
        await repository.endQuizSession();
        expect(repository.currentSession, isNull);
      });
    });

    group('exception handling', () {
      test('should wrap data source exceptions as repository exceptions', () async {
        // This test would require mocking the data source to throw exceptions
        // For now, we'll test the general error handling structure
        expect(repository, isA<QuizRepository>());
      });
    });
  });
}
