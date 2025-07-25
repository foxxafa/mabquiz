import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:mabquiz/src/features/quiz/application/quiz_service.dart';
import 'package:mabquiz/src/features/quiz/data/models/question.dart';
import 'package:mabquiz/src/features/quiz/data/repositories/quiz_repository.dart';

import 'quiz_service_test.mocks.dart';

@GenerateMocks([QuizRepository])
void main() {
  group('QuizService', () {
    late MockQuizRepository mockRepository;
    late QuizService quizService;

    setUp(() {
      mockRepository = MockQuizRepository();
      quizService = QuizService(mockRepository);
    });

    group('getQuizQuestions', () {
      test('should return questions successfully', () async {
        final expectedQuestions = [
          Question(
            id: 'test_1',
            text: 'Test question 1',
            type: QuestionType.multipleChoice,
            difficulty: DifficultyLevel.beginner,
            options: ['A', 'B', 'C', 'D'],
            correctAnswer: 'A',
            subject: 'Test',
          ),
        ];

        when(mockRepository.getRandomQuestions(
          limit: anyNamed('limit'),
          subject: anyNamed('subject'),
          difficulty: anyNamed('difficulty'),
          excludeIds: anyNamed('excludeIds'),
        )).thenAnswer((_) async => expectedQuestions);

        final result = await quizService.getQuizQuestions(limit: 5);

        expect(result, equals(expectedQuestions));
        verify(mockRepository.getRandomQuestions(
          limit: 5,
          subject: null,
          difficulty: null,
          excludeIds: null,
        )).called(1);
      });

      test('should validate quiz parameters', () async {
        expect(
          () => quizService.getQuizQuestions(limit: 0),
          throwsA(isA<QuizServiceException>()),
        );

        expect(
          () => quizService.getQuizQuestions(limit: 101),
          throwsA(isA<QuizServiceException>()),
        );

        verifyNever(mockRepository.getRandomQuestions(
          limit: anyNamed('limit'),
          subject: anyNamed('subject'),
          difficulty: anyNamed('difficulty'),
          excludeIds: anyNamed('excludeIds'),
        ));
      });

      test('should propagate repository exceptions', () async {
        when(mockRepository.getRandomQuestions(
          limit: anyNamed('limit'),
          subject: anyNamed('subject'),
          difficulty: anyNamed('difficulty'),
          excludeIds: anyNamed('excludeIds'),
        )).thenThrow(const QuizRepositoryException('Repository error'));

        expect(
          () => quizService.getQuizQuestions(),
          throwsA(isA<QuizRepositoryException>()),
        );
      });

      test('should wrap unknown exceptions', () async {
        when(mockRepository.getRandomQuestions(
          limit: anyNamed('limit'),
          subject: anyNamed('subject'),
          difficulty: anyNamed('difficulty'),
          excludeIds: anyNamed('excludeIds'),
        )).thenThrow(Exception('Unknown error'));

        expect(
          () => quizService.getQuizQuestions(),
          throwsA(isA<QuizServiceException>()),
        );
      });
    });

    group('getQuestionsBySubject', () {
      test('should return questions for valid subject', () async {
        final expectedQuestions = [
          Question(
            id: 'math_1',
            text: 'Math question',
            type: QuestionType.multipleChoice,
            difficulty: DifficultyLevel.beginner,
            options: ['A', 'B', 'C', 'D'],
            correctAnswer: 'A',
            subject: 'Matematik',
          ),
        ];

        when(mockRepository.getQuestionsBySubject('Matematik'))
            .thenAnswer((_) async => expectedQuestions);

        final result = await quizService.getQuestionsBySubject('Matematik');

        expect(result, equals(expectedQuestions));
        verify(mockRepository.getQuestionsBySubject('Matematik')).called(1);
      });

      test('should validate subject parameter', () async {
        expect(
          () => quizService.getQuestionsBySubject(''),
          throwsA(isA<QuizServiceException>()),
        );

        expect(
          () => quizService.getQuestionsBySubject('   '),
          throwsA(isA<QuizServiceException>()),
        );

        verifyNever(mockRepository.getQuestionsBySubject(any));
      });
    });

    group('getQuestionsByDifficulty', () {
      test('should return questions for difficulty level', () async {
        final expectedQuestions = [
          Question(
            id: 'beginner_1',
            text: 'Easy question',
            type: QuestionType.multipleChoice,
            difficulty: DifficultyLevel.beginner,
            options: ['A', 'B', 'C', 'D'],
            correctAnswer: 'A',
            subject: 'Test',
          ),
        ];

        when(mockRepository.getQuestionsByDifficulty(DifficultyLevel.beginner))
            .thenAnswer((_) async => expectedQuestions);

        final result = await quizService.getQuestionsByDifficulty(DifficultyLevel.beginner);

        expect(result, equals(expectedQuestions));
        verify(mockRepository.getQuestionsByDifficulty(DifficultyLevel.beginner)).called(1);
      });
    });

    group('getQuestionById', () {
      test('should return question for valid ID', () async {
        final expectedQuestion = Question(
          id: 'test_1',
          text: 'Test question',
          type: QuestionType.multipleChoice,
          difficulty: DifficultyLevel.beginner,
          options: ['A', 'B', 'C', 'D'],
          correctAnswer: 'A',
          subject: 'Test',
        );

        when(mockRepository.getQuestionById('test_1'))
            .thenAnswer((_) async => expectedQuestion);

        final result = await quizService.getQuestionById('test_1');

        expect(result, equals(expectedQuestion));
        verify(mockRepository.getQuestionById('test_1')).called(1);
      });

      test('should validate question ID parameter', () async {
        expect(
          () => quizService.getQuestionById(''),
          throwsA(isA<QuizServiceException>()),
        );

        expect(
          () => quizService.getQuestionById('   '),
          throwsA(isA<QuizServiceException>()),
        );

        verifyNever(mockRepository.getQuestionById(any));
      });
    });

    group('getAvailableSubjects', () {
      test('should return available subjects', () async {
        final expectedSubjects = ['Matematik', 'Türkçe', 'Farmakoloji'];

        when(mockRepository.getAvailableSubjects())
            .thenAnswer((_) async => expectedSubjects);

        final result = await quizService.getAvailableSubjects();

        expect(result, equals(expectedSubjects));
        verify(mockRepository.getAvailableSubjects()).called(1);
      });
    });

    group('calculateScore', () {
      late List<Question> testQuestions;
      late Map<String, String> testAnswers;

      setUp(() {
        testQuestions = [
          Question(
            id: 'q1',
            text: 'Question 1',
            type: QuestionType.multipleChoice,
            difficulty: DifficultyLevel.beginner,
            options: ['A', 'B', 'C', 'D'],
            correctAnswer: 'A',
            subject: 'Test',
            points: 10,
          ),
          Question(
            id: 'q2',
            text: 'Question 2',
            type: QuestionType.multipleChoice,
            difficulty: DifficultyLevel.intermediate,
            options: ['A', 'B', 'C', 'D'],
            correctAnswer: 'B',
            subject: 'Test',
            points: 15,
          ),
          Question(
            id: 'q3',
            text: 'Question 3',
            type: QuestionType.multipleChoice,
            difficulty: DifficultyLevel.advanced,
            options: ['A', 'B', 'C', 'D'],
            correctAnswer: 'C',
            subject: 'Test',
            points: 20,
          ),
        ];
      });

      test('should calculate perfect score correctly', () {
        testAnswers = {
          'q1': 'A',
          'q2': 'B',
          'q3': 'C',
        };

        final score = quizService.calculateScore(testQuestions, testAnswers);

        expect(score.totalQuestions, equals(3));
        expect(score.correctAnswers, equals(3));
        expect(score.totalPoints, equals(45));
        expect(score.earnedPoints, equals(45));
        expect(score.percentage, equals(100.0));
        expect(score.performanceLevel, equals(QuizPerformanceLevel.excellent));
        expect(score.questionResults.length, equals(3));
        expect(score.questionResults.every((r) => r.isCorrect), isTrue);
      });

      test('should calculate partial score correctly', () {
        testAnswers = {
          'q1': 'A', // Correct
          'q2': 'A', // Wrong
          'q3': 'C', // Correct
        };

        final score = quizService.calculateScore(testQuestions, testAnswers);

        expect(score.totalQuestions, equals(3));
        expect(score.correctAnswers, equals(2));
        expect(score.totalPoints, equals(45));
        expect(score.earnedPoints, equals(30));
        expect(score.percentage, closeTo(66.67, 0.01));
        expect(score.performanceLevel, equals(QuizPerformanceLevel.needsImprovement));
      });

      test('should handle zero score correctly', () {
        testAnswers = {
          'q1': 'B', // Wrong
          'q2': 'A', // Wrong
          'q3': 'A', // Wrong
        };

        final score = quizService.calculateScore(testQuestions, testAnswers);

        expect(score.totalQuestions, equals(3));
        expect(score.correctAnswers, equals(0));
        expect(score.totalPoints, equals(45));
        expect(score.earnedPoints, equals(0));
        expect(score.percentage, equals(0.0));
        expect(score.performanceLevel, equals(QuizPerformanceLevel.poor));
      });

      test('should handle missing answers', () {
        testAnswers = {
          'q1': 'A', // Correct
          // q2 missing
          'q3': 'C', // Correct
        };

        final score = quizService.calculateScore(testQuestions, testAnswers);

        expect(score.totalQuestions, equals(3));
        expect(score.correctAnswers, equals(2));
        expect(score.questionResults[1].userAnswer, isNull);
        expect(score.questionResults[1].isCorrect, isFalse);
      });

      test('should handle empty questions list', () {
        final score = quizService.calculateScore([], {});

        expect(score.totalQuestions, equals(0));
        expect(score.correctAnswers, equals(0));
        expect(score.totalPoints, equals(0));
        expect(score.earnedPoints, equals(0));
        expect(score.percentage, equals(0.0));
        expect(score.questionResults, isEmpty);
      });
    });

    group('performance levels', () {
      test('should categorize performance levels correctly', () {
        expect(QuizPerformanceLevel.excellent.description, equals('Mükemmel'));
        expect(QuizPerformanceLevel.good.description, equals('İyi'));
        expect(QuizPerformanceLevel.satisfactory.description, equals('Yeterli'));
        expect(QuizPerformanceLevel.needsImprovement.description, equals('Geliştirilmeli'));
        expect(QuizPerformanceLevel.poor.description, equals('Yetersiz'));

        expect(QuizPerformanceLevel.excellent.message, contains('Tebrikler'));
        expect(QuizPerformanceLevel.poor.message, contains('daha fazla çalış'));
      });
    });

    group('quizSessionStream', () {
      test('should return repository quiz session stream', () {
        when(mockRepository.quizSessionStream)
            .thenAnswer((_) => Stream.value(null));

        final stream = quizService.quizSessionStream;

        expect(stream, isA<Stream<QuizSessionData?>>());
        verify(mockRepository.quizSessionStream).called(1);
      });
    });
  });
}
