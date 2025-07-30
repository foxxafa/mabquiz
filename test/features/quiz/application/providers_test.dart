import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:mabquiz/src/core/config/app_config.dart';
import 'package:mabquiz/src/core/config/config_providers.dart';
import 'package:mabquiz/src/features/quiz/application/providers.dart';
import 'package:mabquiz/src/features/quiz/application/quiz_service.dart';
import 'package:mabquiz/src/features/quiz/data/data_sources/mock_quiz_datasource.dart';
import 'package:mabquiz/src/features/quiz/domain/entities/question.dart';
import 'package:mabquiz/src/features/quiz/domain/entities/quiz_score.dart';
import 'package:mabquiz/src/features/quiz/data/repositories/quiz_repository.dart';

import 'providers_test.mocks.dart';

@GenerateMocks([QuizRepository, QuizService])
void main() {
  group('Quiz Providers', () {
    late ProviderContainer container;
    late MockQuizRepository mockRepository;
    late MockQuizService mockService;

    setUp(() {
      mockRepository = MockQuizRepository();
      mockService = MockQuizService();
    });

    tearDown(() {
      container.dispose();
    });

    group('quizDataSourceProvider', () {
      test('should return MockQuizDataSource when useMockAuth is true', () {
        container = ProviderContainer(
          overrides: [
            useMockAuthProvider.overrideWithValue(true),
            authConfigProvider.overrideWithValue(
              const AuthConfig(
                useMockAuth: true,
                mockAuthDelay: 500,
                enablePersistence: true,
              ),
            ),
          ],
        );

        final dataSource = container.read(quizDataSourceProvider);

        expect(dataSource, isA<MockQuizDataSource>());
      });

      test('should configure MockQuizDataSource with correct delay', () {
        const expectedDelay = 1000;
        container = ProviderContainer(
          overrides: [
            useMockAuthProvider.overrideWithValue(true),
            authConfigProvider.overrideWithValue(
              const AuthConfig(
                useMockAuth: true,
                mockAuthDelay: expectedDelay,
                enablePersistence: true,
              ),
            ),
          ],
        );

        final dataSource = container.read(quizDataSourceProvider) as MockQuizDataSource;

        expect(dataSource.simulatedDelay, const Duration(milliseconds: expectedDelay));
      });
    });

    group('quizRepositoryProvider', () {
      test('should create repository with correct data source', () {
        container = ProviderContainer(
          overrides: [
            useMockAuthProvider.overrideWithValue(true),
            authConfigProvider.overrideWithValue(
              const AuthConfig(
                useMockAuth: true,
                mockAuthDelay: 500,
                enablePersistence: true,
              ),
            ),
          ],
        );

        final repository = container.read(quizRepositoryProvider);

        expect(repository, isA<QuizRepository>());
      });

      test('should be a singleton within the container', () {
        container = ProviderContainer(
          overrides: [
            useMockAuthProvider.overrideWithValue(true),
          ],
        );

        final repository1 = container.read(quizRepositoryProvider);
        final repository2 = container.read(quizRepositoryProvider);

        expect(identical(repository1, repository2), isTrue);
      });
    });

    group('quizServiceProvider', () {
      test('should create QuizService with correct repository', () {
        container = ProviderContainer(
          overrides: [
            quizRepositoryProvider.overrideWithValue(mockRepository),
          ],
        );

        final service = container.read(quizServiceProvider);

        expect(service, isA<QuizService>());
      });

      test('should recreate service when repository changes', () {
        final mockRepository2 = MockQuizRepository();

        container = ProviderContainer(
          overrides: [
            quizRepositoryProvider.overrideWithValue(mockRepository),
          ],
        );

        final service1 = container.read(quizServiceProvider);

        // Change repository
        container.updateOverrides([
          quizRepositoryProvider.overrideWithValue(mockRepository2),
        ]);

        final service2 = container.read(quizServiceProvider);

        expect(identical(service1, service2), isFalse);
      });
    });

    group('quizSessionProvider', () {
      test('should emit session data when available', () async {
        final testSession = QuizSessionData(
          sessionId: 'test-session',
          participantIds: ['user1'],
          scores: {'user1': 0},
          startTime: DateTime.now(),
          isActive: true,
        );

        when(mockService.quizSessionStream)
            .thenAnswer((_) => Stream.value(testSession));

        container = ProviderContainer(
          overrides: [
            quizServiceProvider.overrideWithValue(mockService),
          ],
        );

        // Wait for the stream to emit
        await container.read(quizSessionProvider.future);
        final sessionState = container.read(quizSessionProvider);

        expect(sessionState.hasValue, isTrue);
        expect(sessionState.value, testSession);
      });

      test('should emit null when no session is active', () async {
        when(mockService.quizSessionStream)
            .thenAnswer((_) => Stream.value(null));

        container = ProviderContainer(
          overrides: [
            quizServiceProvider.overrideWithValue(mockService),
          ],
        );

        // Wait for the stream to emit
        await container.read(quizSessionProvider.future);
        final sessionState = container.read(quizSessionProvider);

        expect(sessionState.hasValue, isTrue);
        expect(sessionState.value, isNull);
      });
    });

    group('availableSubjectsProvider', () {
      test('should fetch available subjects', () async {
        final expectedSubjects = ['Matematik', 'Türkçe', 'Farmakoloji'];
        when(mockService.getAvailableSubjects())
            .thenAnswer((_) async => expectedSubjects);

        container = ProviderContainer(
          overrides: [
            quizServiceProvider.overrideWithValue(mockService),
          ],
        );

        final subjects = await container.read(availableSubjectsProvider.future);

        expect(subjects, equals(expectedSubjects));
        verify(mockService.getAvailableSubjects()).called(1);
      });

      test('should handle errors', () async {
        when(mockService.getAvailableSubjects())
            .thenThrow(QuizServiceException('Failed to fetch subjects', 'fetch-error'));

        container = ProviderContainer(
          overrides: [
            quizServiceProvider.overrideWithValue(mockService),
          ],
        );

        final subjectsState = container.read(availableSubjectsProvider);

        expect(subjectsState.hasError, isTrue);
        expect(subjectsState.error, isA<QuizServiceException>());
      });
    });

    group('questionsBySubjectProvider', () {
      test('should fetch questions for subject', () async {
        final expectedQuestions = [
          Question(
            id: 'math_1',
            text: 'Test math question',
            type: QuestionType.multipleChoice,
            difficulty: DifficultyLevel.beginner,
            options: ['A', 'B', 'C', 'D'],
            correctAnswer: 'A',
            subject: 'Matematik',
          ),
        ];

        when(mockService.getQuestionsBySubject('Matematik'))
            .thenAnswer((_) async => expectedQuestions);

        container = ProviderContainer(
          overrides: [
            quizServiceProvider.overrideWithValue(mockService),
          ],
        );

        final questions = await container.read(questionsBySubjectProvider('Matematik').future);

        expect(questions, equals(expectedQuestions));
        verify(mockService.getQuestionsBySubject('Matematik')).called(1);
      });
    });

    group('questionsByDifficultyProvider', () {
      test('should fetch questions for difficulty', () async {
        final expectedQuestions = [
          Question(
            id: 'easy_1',
            text: 'Easy question',
            type: QuestionType.multipleChoice,
            difficulty: DifficultyLevel.beginner,
            options: ['A', 'B', 'C', 'D'],
            correctAnswer: 'A',
            subject: 'Test',
          ),
        ];

        when(mockService.getQuestionsByDifficulty(DifficultyLevel.beginner))
            .thenAnswer((_) async => expectedQuestions);

        container = ProviderContainer(
          overrides: [
            quizServiceProvider.overrideWithValue(mockService),
          ],
        );

        final questions = await container.read(questionsByDifficultyProvider(DifficultyLevel.beginner).future);

        expect(questions, equals(expectedQuestions));
        verify(mockService.getQuestionsByDifficulty(DifficultyLevel.beginner)).called(1);
      });
    });

    group('questionByIdProvider', () {
      test('should fetch question by ID', () async {
        final expectedQuestion = Question(
          id: 'test_1',
          text: 'Test question',
          type: QuestionType.multipleChoice,
          difficulty: DifficultyLevel.beginner,
          options: ['A', 'B', 'C', 'D'],
          correctAnswer: 'A',
          subject: 'Test',
        );

        when(mockService.getQuestionById('test_1'))
            .thenAnswer((_) async => expectedQuestion);

        container = ProviderContainer(
          overrides: [
            quizServiceProvider.overrideWithValue(mockService),
          ],
        );

        final question = await container.read(questionByIdProvider('test_1').future);

        expect(question, equals(expectedQuestion));
        verify(mockService.getQuestionById('test_1')).called(1);
      });

      test('should return null for non-existent question', () async {
        when(mockService.getQuestionById('non_existent'))
            .thenAnswer((_) async => null);

        container = ProviderContainer(
          overrides: [
            quizServiceProvider.overrideWithValue(mockService),
          ],
        );

        final question = await container.read(questionByIdProvider('non_existent').future);

        expect(question, isNull);
      });
    });

    group('quizQuestionsProvider', () {
      test('should fetch quiz questions with parameters', () async {
        final params = QuizQuestionsParams(
          limit: 5,
          subject: 'Matematik',
          difficulty: DifficultyLevel.beginner,
          excludeIds: ['math_001'],
        );

        final expectedQuestions = [
          Question(
            id: 'math_2',
            text: 'Math question 2',
            type: QuestionType.multipleChoice,
            difficulty: DifficultyLevel.beginner,
            options: ['A', 'B', 'C', 'D'],
            correctAnswer: 'A',
            subject: 'Matematik',
          ),
        ];

        when(mockService.getQuizQuestions(
          limit: params.limit,
          subject: params.subject,
          difficulty: params.difficulty,
          excludeIds: params.excludeIds,
        )).thenAnswer((_) async => expectedQuestions);

        container = ProviderContainer(
          overrides: [
            quizServiceProvider.overrideWithValue(mockService),
          ],
        );

        final questions = await container.read(quizQuestionsProvider(params).future);

        expect(questions, equals(expectedQuestions));
        verify(mockService.getQuizQuestions(
          limit: params.limit,
          subject: params.subject,
          difficulty: params.difficulty,
          excludeIds: params.excludeIds,
        )).called(1);
      });
    });

    group('currentQuizProvider', () {
      test('should start quiz successfully', () async {
        final expectedQuestions = [
          Question(
            id: 'q1',
            text: 'Question 1',
            type: QuestionType.multipleChoice,
            difficulty: DifficultyLevel.beginner,
            options: ['A', 'B', 'C', 'D'],
            correctAnswer: 'A',
            subject: 'Test',
          ),
        ];

        when(mockService.getQuizQuestions(
          limit: anyNamed('limit'),
          subject: anyNamed('subject'),
          difficulty: anyNamed('difficulty'),
        )).thenAnswer((_) async => expectedQuestions);

        container = ProviderContainer(
          overrides: [
            quizServiceProvider.overrideWithValue(mockService),
          ],
        );

        final notifier = container.read(currentQuizProvider.notifier);
        await notifier.startQuiz(limit: 5);

        final state = container.read(currentQuizProvider);

        expect(state.questions, equals(expectedQuestions));
        expect(state.currentQuestionIndex, equals(0));
        expect(state.isLoading, isFalse);
        expect(state.error, isNull);
      });

      test('should handle start quiz errors', () async {
        when(mockService.getQuizQuestions(
          limit: anyNamed('limit'),
          subject: anyNamed('subject'),
          difficulty: anyNamed('difficulty'),
        )).thenThrow(QuizServiceException('Failed to load questions', 'load-error'));

        container = ProviderContainer(
          overrides: [
            quizServiceProvider.overrideWithValue(mockService),
          ],
        );

        final notifier = container.read(currentQuizProvider.notifier);
        await notifier.startQuiz();

        final state = container.read(currentQuizProvider);

        expect(state.isLoading, isFalse);
        expect(state.error, isNotNull);
        expect(state.questions, isEmpty);
      });

      test('should answer question correctly', () {
        final testQuestion = Question(
          id: 'q1',
          text: 'Question 1',
          type: QuestionType.multipleChoice,
          difficulty: DifficultyLevel.beginner,
          options: ['A', 'B', 'C', 'D'],
          correctAnswer: 'A',
          subject: 'Test',
        );

        container = ProviderContainer(
          overrides: [
            quizServiceProvider.overrideWithValue(mockService),
          ],
        );

        final notifier = container.read(currentQuizProvider.notifier);

        // Manually set initial state with a question
        notifier.state = CurrentQuizState(
          questions: [testQuestion],
          currentQuestionIndex: 0,
        );

        notifier.answerQuestion('A');

        final state = container.read(currentQuizProvider);

        expect(state.answers['q1'], equals('A'));
      });

      test('should navigate questions correctly', () {
        final testQuestions = [
          Question(
            id: 'q1',
            text: 'Question 1',
            type: QuestionType.multipleChoice,
            difficulty: DifficultyLevel.beginner,
            options: ['A', 'B', 'C', 'D'],
            correctAnswer: 'A',
            subject: 'Test',
          ),
          Question(
            id: 'q2',
            text: 'Question 2',
            type: QuestionType.multipleChoice,
            difficulty: DifficultyLevel.beginner,
            options: ['A', 'B', 'C', 'D'],
            correctAnswer: 'B',
            subject: 'Test',
          ),
        ];

        container = ProviderContainer(
          overrides: [
            quizServiceProvider.overrideWithValue(mockService),
          ],
        );

        final notifier = container.read(currentQuizProvider.notifier);

        // Set initial state
        notifier.state = CurrentQuizState(
          questions: testQuestions,
          currentQuestionIndex: 0,
        );

        // Test next question
        notifier.nextQuestion();
        expect(container.read(currentQuizProvider).currentQuestionIndex, equals(1));

        // Test previous question
        notifier.previousQuestion();
        expect(container.read(currentQuizProvider).currentQuestionIndex, equals(0));

        // Test go to specific question
        notifier.goToQuestion(1);
        expect(container.read(currentQuizProvider).currentQuestionIndex, equals(1));
      });

      test('should complete quiz and calculate score', () {
        final testQuestions = [
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
        ];

        final testAnswers = {'q1': 'A'};

        when(mockService.calculateScore(testQuestions, testAnswers))
            .thenReturn(QuizScore(
              totalQuestions: 1,
              correctAnswers: 1,
              totalPoints: 10,
              earnedPoints: 10,
              percentage: 100.0,
              questionResults: [],
            ));

        container = ProviderContainer(
          overrides: [
            quizServiceProvider.overrideWithValue(mockService),
          ],
        );

        final notifier = container.read(currentQuizProvider.notifier);

        // Set initial state
        notifier.state = CurrentQuizState(
          questions: testQuestions,
          answers: testAnswers,
        );

        notifier.completeQuiz();

        final state = container.read(currentQuizProvider);

        expect(state.isCompleted, isTrue);
        expect(state.score, isNotNull);
        expect(state.score!.percentage, equals(100.0));
      });

      test('should reset quiz state', () {
        container = ProviderContainer(
          overrides: [
            quizServiceProvider.overrideWithValue(mockService),
          ],
        );

        final notifier = container.read(currentQuizProvider.notifier);

        // Set some state
        notifier.state = const CurrentQuizState(
          currentQuestionIndex: 5,
          isCompleted: true,
        );

        notifier.resetQuiz();

        final state = container.read(currentQuizProvider);

        expect(state.currentQuestionIndex, equals(0));
        expect(state.isCompleted, isFalse);
        expect(state.questions, isEmpty);
        expect(state.answers, isEmpty);
      });
    });

    group('QuizQuestionsParams', () {
      test('should handle equality correctly', () {
        const params1 = QuizQuestionsParams(
          limit: 10,
          subject: 'Matematik',
          difficulty: DifficultyLevel.beginner,
          excludeIds: ['q1', 'q2'],
        );

        const params2 = QuizQuestionsParams(
          limit: 10,
          subject: 'Matematik',
          difficulty: DifficultyLevel.beginner,
          excludeIds: ['q1', 'q2'],
        );

        const params3 = QuizQuestionsParams(
          limit: 5,
          subject: 'Matematik',
          difficulty: DifficultyLevel.beginner,
          excludeIds: ['q1', 'q2'],
        );

        expect(params1, equals(params2));
        expect(params1, isNot(equals(params3)));
      });

      test('should handle null values in equality', () {
        const params1 = QuizQuestionsParams(limit: 10);
        const params2 = QuizQuestionsParams(limit: 10);
        const params3 = QuizQuestionsParams(limit: 10, subject: 'Matematik');

        expect(params1, equals(params2));
        expect(params1, isNot(equals(params3)));
      });
    });

    group('loading and error providers', () {
      test('should handle loading state', () {
        container = ProviderContainer();

        expect(container.read(quizLoadingProvider), isFalse);

        container.read(quizLoadingProvider.notifier).state = true;
        expect(container.read(quizLoadingProvider), isTrue);
      });

      test('should handle error state', () {
        container = ProviderContainer();

        expect(container.read(quizErrorProvider), isNull);

        container.read(quizErrorProvider.notifier).state = 'Error message';
        expect(container.read(quizErrorProvider), equals('Error message'));
      });
    });
  });
}
