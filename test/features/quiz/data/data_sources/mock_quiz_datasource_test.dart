import 'package:flutter_test/flutter_test.dart';
import 'package:mabquiz/src/features/quiz/data/data_sources/mock_quiz_datasource.dart';
import 'package:mabquiz/src/features/quiz/data/models/question.dart';

void main() {
  group('MockQuizDataSource', () {
    late MockQuizDataSource dataSource;

    setUp(() {
      dataSource = MockQuizDataSource(
        simulatedDelay: const Duration(milliseconds: 10), // Faster for tests
      );
    });

    group('getQuestionsBySubject', () {
      test('should return questions for valid subject', () async {
        final questions = await dataSource.getQuestionsBySubject('Matematik');

        expect(questions, isNotEmpty);
        expect(questions.every((q) => q.subject == 'Matematik'), isTrue);
      });

      test('should return empty list for non-existent subject', () async {
        final questions = await dataSource.getQuestionsBySubject('NonExistent');

        expect(questions, isEmpty);
      });

      test('should be case insensitive', () async {
        final questions = await dataSource.getQuestionsBySubject('matematik');

        expect(questions, isNotEmpty);
        expect(questions.every((q) => q.subject == 'Matematik'), isTrue);
      });
    });

    group('getQuestionsByDifficulty', () {
      test('should return questions for beginner difficulty', () async {
        final questions = await dataSource.getQuestionsByDifficulty(DifficultyLevel.beginner);

        expect(questions, isNotEmpty);
        expect(questions.every((q) => q.difficulty == DifficultyLevel.beginner), isTrue);
      });

      test('should return questions for intermediate difficulty', () async {
        final questions = await dataSource.getQuestionsByDifficulty(DifficultyLevel.intermediate);

        expect(questions, isNotEmpty);
        expect(questions.every((q) => q.difficulty == DifficultyLevel.intermediate), isTrue);
      });

      test('should return questions for advanced difficulty', () async {
        final questions = await dataSource.getQuestionsByDifficulty(DifficultyLevel.advanced);

        expect(questions, isNotEmpty);
        expect(questions.every((q) => q.difficulty == DifficultyLevel.advanced), isTrue);
      });
    });

    group('getRandomQuestions', () {
      test('should return requested number of questions', () async {
        const limit = 5;
        final questions = await dataSource.getRandomQuestions(limit: limit);

        expect(questions.length, lessThanOrEqualTo(limit));
      });

      test('should filter by subject when provided', () async {
        final questions = await dataSource.getRandomQuestions(
          subject: 'Matematik',
          limit: 10,
        );

        expect(questions.every((q) => q.subject == 'Matematik'), isTrue);
      });

      test('should filter by difficulty when provided', () async {
        final questions = await dataSource.getRandomQuestions(
          difficulty: DifficultyLevel.beginner,
          limit: 10,
        );

        expect(questions.every((q) => q.difficulty == DifficultyLevel.beginner), isTrue);
      });

      test('should exclude specified question IDs', () async {
        final excludeIds = ['math_001', 'tr_001'];
        final questions = await dataSource.getRandomQuestions(
          excludeIds: excludeIds,
          limit: 10,
        );

        expect(questions.every((q) => !excludeIds.contains(q.id)), isTrue);
      });

      test('should handle multiple filters together', () async {
        final questions = await dataSource.getRandomQuestions(
          subject: 'Matematik',
          difficulty: DifficultyLevel.beginner,
          excludeIds: ['math_001'],
          limit: 5,
        );

        expect(questions.every((q) =>
          q.subject == 'Matematik' &&
          q.difficulty == DifficultyLevel.beginner &&
          q.id != 'math_001'
        ), isTrue);
      });
    });

    group('getQuestionById', () {
      test('should return question for valid ID', () async {
        final question = await dataSource.getQuestionById('math_001');

        expect(question, isNotNull);
        expect(question!.id, equals('math_001'));
      });

      test('should return null for non-existent ID', () async {
        final question = await dataSource.getQuestionById('non_existent');

        expect(question, isNull);
      });
    });

    group('getAvailableSubjects', () {
      test('should return all available subjects', () async {
        final subjects = await dataSource.getAvailableSubjects();

        expect(subjects, isNotEmpty);
        expect(subjects, contains('Matematik'));
        expect(subjects, contains('Türkçe'));
        expect(subjects, contains('Farmakoloji'));
        expect(subjects.toSet().length, equals(subjects.length)); // No duplicates
      });

      test('should return sorted subjects', () async {
        final subjects = await dataSource.getAvailableSubjects();

        final sortedSubjects = List<String>.from(subjects)..sort();
        expect(subjects, equals(sortedSubjects));
      });
    });

    group('test helper methods', () {
      test('should add question successfully', () {
        final initialCount = dataSource.getAllQuestions().length;

        final newQuestion = Question(
          id: 'test_001',
          text: 'Test question?',
          type: QuestionType.multipleChoice,
          difficulty: DifficultyLevel.beginner,
          options: ['A', 'B', 'C', 'D'],
          correctAnswer: 'A',
          subject: 'Test',
        );

        dataSource.addQuestion(newQuestion);

        expect(dataSource.getAllQuestions().length, equals(initialCount + 1));
        expect(dataSource.getAllQuestions().any((q) => q.id == 'test_001'), isTrue);
      });

      test('should clear all questions', () {
        dataSource.clearQuestions();

        expect(dataSource.getAllQuestions(), isEmpty);
      });

      test('should respect simulated delay', () async {
        final dataSourceWithDelay = MockQuizDataSource(
          simulatedDelay: const Duration(milliseconds: 100),
        );

        final stopwatch = Stopwatch()..start();
        await dataSourceWithDelay.getAvailableSubjects();
        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(90));
      });
    });

    group('edge cases', () {
      test('should handle empty exclude list', () async {
        final questions = await dataSource.getRandomQuestions(
          excludeIds: [],
          limit: 5,
        );

        expect(questions, isNotEmpty);
      });

      test('should handle zero limit gracefully', () async {
        final questions = await dataSource.getRandomQuestions(limit: 0);

        expect(questions, isEmpty);
      });

      test('should handle large limit gracefully', () async {
        final questions = await dataSource.getRandomQuestions(limit: 1000);

        // Should return all available questions or requested amount
        expect(questions.length, lessThanOrEqualTo(1000));
      });
    });
  });
}
