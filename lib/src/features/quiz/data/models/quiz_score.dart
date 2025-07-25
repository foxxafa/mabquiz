/// Quiz score calculation result
class QuizScore {
  final int totalQuestions;
  final int correctAnswers;
  final int totalPoints;
  final int earnedPoints;
  final double percentage;
  final List<QuestionResult> questionResults;

  const QuizScore({
    required this.totalQuestions,
    required this.correctAnswers,
    required this.totalPoints,
    required this.earnedPoints,
    required this.percentage,
    required this.questionResults,
  });

  @override
  String toString() {
    return 'QuizScore(correct: $correctAnswers/$totalQuestions, percentage: ${percentage.toStringAsFixed(1)}%)';
  }
}

/// Result for individual question
class QuestionResult {
  final String questionId;
  final String? userAnswer;
  final String correctAnswer;
  final bool isCorrect;
  final int pointsEarned;
  final int maxPoints;

  const QuestionResult({
    required this.questionId,
    required this.userAnswer,
    required this.correctAnswer,
    required this.isCorrect,
    required this.pointsEarned,
    required this.maxPoints,
  });

  @override
  String toString() {
    return 'QuestionResult(id: $questionId, correct: $isCorrect, points: $pointsEarned/$maxPoints)';
  }
}
