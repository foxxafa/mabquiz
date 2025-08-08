import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/config_providers.dart';
import '../data/data_sources/mock_quiz_datasource.dart';
import '../data/services/asset_question_loader.dart';
import '../domain/entities/question.dart';
import '../domain/entities/quiz_score.dart';
import '../data/repositories/mock_quiz_repository.dart';
import '../data/repositories/quiz_repository.dart';
import 'quiz_service.dart';

/// Provider for the quiz data source implementation
///
/// Currently uses MockQuizDataSource for development
/// based on the application configuration
final quizDataSourceProvider = Provider<QuizDataSource>((ref) {
  final quizConfig = ref.watch(quizConfigProvider);
  // Firebase kaldırıldığı için şimdilik sadece mock veri kaynağı
  return MockQuizDataSource(
    simulatedDelay: Duration(milliseconds: quizConfig.mockDataDelay),
  );
});

/// Provider for the quiz repository implementation
///
/// Currently uses MockQuizRepository for development
final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  final dataSource = ref.watch(quizDataSourceProvider);
  return MockQuizRepository(dataSource);
});

/// Provider for the quiz service facade
///
/// Creates a QuizService instance with the appropriate repository
/// based on the current environment
final quizServiceProvider = Provider<QuizService>((ref) {
  final repository = ref.watch(quizRepositoryProvider);
  return QuizService(repository);
});

// Firebase konfigürasyonu kaldırıldı

/// Stream provider for quiz session changes
///
/// Provides a stream that emits quiz session data updates
/// This provider automatically disposes when not in use but keeps alive
/// to maintain session state across the app
final quizSessionProvider = StreamProvider.autoDispose<QuizSessionData?>((ref) async* {
  // Keep the provider alive to maintain session state
  ref.keepAlive();

  final service = ref.watch(quizServiceProvider);
  yield* service.quizSessionStream;
});

/// Provider for available subjects
///
/// Fetches and provides the list of available quiz subjects
final availableSubjectsProvider = FutureProvider<List<String>>((ref) async {
  // In development (mock data) mode, use static asset subjects
  final quizConfig = ref.watch(quizConfigProvider);
  if (quizConfig.useMockData) {
    final subjects = AssetQuestionLoader.getAvailableSubjects()
        .map((s) => s[0].toUpperCase() + s.substring(1))
        .toList();
    return subjects;
  }
  // Production: fetch from service
  final service = ref.watch(quizServiceProvider);
  return await service.getAvailableSubjects();
});

/// Provider for asset-based subject questions
///
/// Fetches questions from assets for a specific subject
final assetQuestionsBySubjectProvider = FutureProvider.family<List<Question>, String>((ref, subject) async {
  return await AssetQuestionLoader.loadAllQuestionsForSubject(subject);
});

/// Provider for available asset subjects
///
/// Provides available subjects from assets
final availableAssetSubjectsProvider = FutureProvider<List<String>>((ref) async {
  // Sağlık öğrencilerine yönelik dersler
  return ['farmakoloji', 'terminoloji'];
});

/// Provider family for questions by subject
///
/// Fetches questions for a specific subject
final questionsBySubjectProvider = FutureProvider.family<List<Question>, String>((ref, subject) async {
  final service = ref.watch(quizServiceProvider);
  return await service.getQuestionsBySubject(subject);
});

/// Provider family for questions by difficulty
///
/// Fetches questions for a specific difficulty level
final questionsByDifficultyProvider = FutureProvider.family<List<Question>, DifficultyLevel>((ref, difficulty) async {
  final service = ref.watch(quizServiceProvider);
  return await service.getQuestionsByDifficulty(difficulty);
});

/// Provider family for a specific question by ID
///
/// Fetches a single question by its ID
final questionByIdProvider = FutureProvider.family<Question?, String>((ref, id) async {
  final service = ref.watch(quizServiceProvider);
  return await service.getQuestionById(id);
});

/// Provider family for quiz questions with filters
///
/// Fetches quiz questions with optional filters
final quizQuestionsProvider = FutureProvider.family<List<Question>, QuizQuestionsParams>((ref, params) async {
  final service = ref.watch(quizServiceProvider);
  return await service.getQuizQuestions(
    limit: params.limit,
    subject: params.subject,
    difficulty: params.difficulty,
    excludeIds: params.excludeIds,
  );
});

/// Provider for current quiz state
///
/// Manages the current quiz session state
final currentQuizProvider = StateNotifierProvider<CurrentQuizNotifier, CurrentQuizState>((ref) {
  final service = ref.watch(quizServiceProvider);
  return CurrentQuizNotifier(service);
});

/// Provider for quiz loading state
///
/// Can be used by UI components to show loading indicators
/// during quiz operations
final quizLoadingProvider = StateProvider<bool>((ref) => false);

/// Provider for quiz error state
///
/// Can be used by UI components to display quiz errors
final quizErrorProvider = StateProvider<String?>((ref) => null);

/// Data class for quiz questions parameters
class QuizQuestionsParams {
  final int limit;
  final String? subject;
  final DifficultyLevel? difficulty;
  final List<String>? excludeIds;

  const QuizQuestionsParams({
    this.limit = 10,
    this.subject,
    this.difficulty,
    this.excludeIds,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QuizQuestionsParams &&
        other.limit == limit &&
        other.subject == subject &&
        other.difficulty == difficulty &&
        _listEquals(other.excludeIds, excludeIds);
  }

  @override
  int get hashCode {
    return Object.hash(
      limit,
      subject,
      difficulty,
      excludeIds?.join(','),
    );
  }

  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// State class for current quiz
class CurrentQuizState {
  final List<Question> questions;
  final int currentQuestionIndex;
  final Map<String, String> answers;
  final QuizScore? score;
  final bool isCompleted;
  final bool isLoading;
  final String? error;

  const CurrentQuizState({
    this.questions = const [],
    this.currentQuestionIndex = 0,
    this.answers = const {},
    this.score,
    this.isCompleted = false,
    this.isLoading = false,
    this.error,
  });

  CurrentQuizState copyWith({
    List<Question>? questions,
    int? currentQuestionIndex,
    Map<String, String>? answers,
    QuizScore? score,
    bool? isCompleted,
    bool? isLoading,
    String? error,
  }) {
    return CurrentQuizState(
      questions: questions ?? this.questions,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      answers: answers ?? this.answers,
      score: score ?? this.score,
      isCompleted: isCompleted ?? this.isCompleted,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  Question? get currentQuestion {
    if (currentQuestionIndex < questions.length) {
      return questions[currentQuestionIndex];
    }
    return null;
  }

  bool get hasNextQuestion => currentQuestionIndex + 1 < questions.length;
  bool get hasPreviousQuestion => currentQuestionIndex > 0;
  int get totalQuestions => questions.length;
  int get answeredQuestions => answers.length;
  double get progress => totalQuestions > 0 ? answeredQuestions / totalQuestions : 0.0;
}

/// State notifier for current quiz management
class CurrentQuizNotifier extends StateNotifier<CurrentQuizState> {
  final QuizService _service;

  CurrentQuizNotifier(this._service) : super(const CurrentQuizState());

  /// Start a new quiz with the given parameters
  Future<void> startQuiz({
    int limit = 10,
    String? subject,
    DifficultyLevel? difficulty,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final questions = await _service.getQuizQuestions(
        limit: limit,
        subject: subject,
        difficulty: difficulty,
      );

      state = state.copyWith(
        questions: questions,
        currentQuestionIndex: 0,
        answers: {},
        score: null,
        isCompleted: false,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Answer the current question
  void answerQuestion(String answer) {
    final currentQuestion = state.currentQuestion;
    if (currentQuestion == null) return;

    final newAnswers = Map<String, String>.from(state.answers);
    newAnswers[currentQuestion.id] = answer;

    state = state.copyWith(answers: newAnswers);
  }

  /// Move to the next question
  void nextQuestion() {
    if (state.hasNextQuestion) {
      state = state.copyWith(
        currentQuestionIndex: state.currentQuestionIndex + 1,
      );
    }
  }

  /// Move to the previous question
  void previousQuestion() {
    if (state.hasPreviousQuestion) {
      state = state.copyWith(
        currentQuestionIndex: state.currentQuestionIndex - 1,
      );
    }
  }

  /// Complete the quiz and calculate score
  void completeQuiz() {
    final score = _service.calculateScore(state.questions, state.answers);
    state = state.copyWith(
      score: score,
      isCompleted: true,
    );
  }

  /// Reset the quiz state
  void resetQuiz() {
    state = const CurrentQuizState();
  }

  /// Jump to a specific question by index
  void goToQuestion(int index) {
    if (index >= 0 && index < state.questions.length) {
      state = state.copyWith(currentQuestionIndex: index);
    }
  }
}
