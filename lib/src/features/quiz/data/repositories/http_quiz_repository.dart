import '../../domain/entities/question.dart';
import '../../domain/entities/quiz_score.dart';
import '../repositories/quiz_repository.dart';
import '../data_sources/http_quiz_datasource.dart';

/// HTTP implementation of QuizRepository
/// Uses HTTP data source to communicate with backend API
class HttpQuizRepository implements QuizRepository {
  final HttpQuizDataSource _dataSource;

  HttpQuizRepository(this._dataSource);

  @override
  Future<List<Question>> getQuestionsBySubject(String subject) async {
    return await _dataSource.getQuestionsBySubject(subject);
  }

  @override
  Future<List<Question>> getQuestionsByDifficulty(DifficultyLevel difficulty) async {
    return await _dataSource.getQuestionsByDifficulty(difficulty);
  }

  @override
  Future<Question?> getQuestionById(String id) async {
    return await _dataSource.getQuestionById(id);
  }

  @override
  Future<List<Question>> getRandomQuestions({
    int limit = 10,
    String? subject,
    DifficultyLevel? difficulty,
    List<String>? excludeIds,
  }) async {
    return await _dataSource.getRandomQuestions(
      limit: limit,
      subject: subject,
      difficulty: difficulty,
      excludeIds: excludeIds,
    );
  }

  @override
  Future<List<String>> getAvailableSubjects() async {
    return await _dataSource.getAvailableSubjects();
  }

  @override
  Stream<QuizSessionData?> get quizSessionStream async* {
    // HTTP tabanlı gerçek zamanlı session yönetimi henüz yok
    // İleride WebSocket ile implement edilebilir
    yield null;
  }

  /// Tüm soruları getir (yardımcı method)
  Future<List<Question>> getAllQuestions() async {
    return await _dataSource.getAllQuestions();
  }

  /// Quiz skorunu hesapla (yardımcı method)
  QuizScore calculateScore(List<Question> questions, Map<String, String> answers) {
    final questionResults = <QuestionResult>[];
    int correctAnswers = 0;
    int totalPoints = 0;
    int earnedPoints = 0;

    for (final question in questions) {
      final userAnswer = answers[question.id];
      final isCorrect = userAnswer != null && question.isCorrectAnswer(userAnswer);
      
      if (isCorrect) {
        correctAnswers++;
        earnedPoints += question.points;
      }
      
      totalPoints += question.points;

      questionResults.add(QuestionResult(
        questionId: question.id,
        userAnswer: userAnswer,
        correctAnswer: question.correctAnswer,
        isCorrect: isCorrect,
        pointsEarned: isCorrect ? question.points : 0,
        maxPoints: question.points,
      ));
    }

    final percentage = totalPoints > 0 ? (earnedPoints / totalPoints) * 100 : 0.0;

    return QuizScore(
      totalQuestions: questions.length,
      correctAnswers: correctAnswers,
      totalPoints: totalPoints,
      earnedPoints: earnedPoints,
      percentage: percentage,
      questionResults: questionResults,
    );
  }
}
