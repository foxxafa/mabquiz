/// Quiz score entity for tracking quiz performance
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

  /// Check if quiz was passed (assuming 60% is passing)
  bool get isPassed => percentage >= 60.0;

  /// Get grade based on percentage
  String get grade {
    if (percentage >= 90) return 'A';
    if (percentage >= 80) return 'B';
    if (percentage >= 70) return 'C';
    if (percentage >= 60) return 'D';
    return 'F';
  }

  @override
  String toString() {
    return 'QuizScore(correct: $correctAnswers/$totalQuestions, percentage: ${percentage.toStringAsFixed(1)}%)';
  }

  /// Create QuizScore from JSON
  factory QuizScore.fromJson(Map<String, dynamic> json) {
    final questionResults = <QuestionResult>[];
    if (json['questionResults'] != null) {
      for (final result in json['questionResults']) {
        questionResults.add(QuestionResult.fromJson(result));
      }
    }

    return QuizScore(
      totalQuestions: json['totalQuestions']?.toInt() ?? 0,
      correctAnswers: json['correctAnswers']?.toInt() ?? 0,
      totalPoints: json['totalPoints']?.toInt() ?? 0,
      earnedPoints: json['earnedPoints']?.toInt() ?? 0,
      percentage: json['percentage']?.toDouble() ?? 0.0,
      questionResults: questionResults,
    );
  }

  /// Convert QuizScore to JSON
  Map<String, dynamic> toJson() {
    return {
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'totalPoints': totalPoints,
      'earnedPoints': earnedPoints,
      'percentage': percentage,
      'questionResults': questionResults.map((r) => r.toJson()).toList(),
    };
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

  /// Create QuestionResult from JSON
  factory QuestionResult.fromJson(Map<String, dynamic> json) {
    return QuestionResult(
      questionId: json['questionId']?.toString() ?? '',
      userAnswer: json['userAnswer']?.toString(),
      correctAnswer: json['correctAnswer']?.toString() ?? '',
      isCorrect: json['isCorrect'] ?? false,
      pointsEarned: json['pointsEarned']?.toInt() ?? 0,
      maxPoints: json['maxPoints']?.toInt() ?? 0,
    );
  }

  /// Convert QuestionResult to JSON
  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'userAnswer': userAnswer,
      'correctAnswer': correctAnswer,
      'isCorrect': isCorrect,
      'pointsEarned': pointsEarned,
      'maxPoints': maxPoints,
    };
  }
}
