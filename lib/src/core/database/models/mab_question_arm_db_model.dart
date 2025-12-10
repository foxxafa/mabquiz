/// Database model for MAB question arms (Thompson Sampling state)
class MabQuestionArmDbModel {
  final int? id;
  final String userId;
  final String questionId;
  final int attempts;
  final int successes;
  final int failures;
  final int totalResponseTime;
  final double userConfidence;
  final double alpha;
  final double beta;
  final int? lastAttempted;
  final int createdAt;
  final int updatedAt;

  MabQuestionArmDbModel({
    this.id,
    required this.userId,
    required this.questionId,
    this.attempts = 0,
    this.successes = 0,
    this.failures = 0,
    this.totalResponseTime = 0,
    this.userConfidence = 0.5,
    this.alpha = 1.0,
    this.beta = 1.0,
    this.lastAttempted,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convert from database map
  factory MabQuestionArmDbModel.fromMap(Map<String, dynamic> map) {
    return MabQuestionArmDbModel(
      id: map['id'] as int?,
      userId: map['user_id'] as String,
      questionId: map['question_id'] as String,
      attempts: map['attempts'] as int? ?? 0,
      successes: map['successes'] as int? ?? 0,
      failures: map['failures'] as int? ?? 0,
      totalResponseTime: map['total_response_time'] as int? ?? 0,
      userConfidence: (map['user_confidence'] as num?)?.toDouble() ?? 0.5,
      alpha: (map['alpha'] as num?)?.toDouble() ?? 1.0,
      beta: (map['beta'] as num?)?.toDouble() ?? 1.0,
      lastAttempted: map['last_attempted'] as int?,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'question_id': questionId,
      'attempts': attempts,
      'successes': successes,
      'failures': failures,
      'total_response_time': totalResponseTime,
      'user_confidence': userConfidence,
      'alpha': alpha,
      'beta': beta,
      'last_attempted': lastAttempted,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// Create a copy with modified fields
  MabQuestionArmDbModel copyWith({
    int? id,
    String? userId,
    String? questionId,
    int? attempts,
    int? successes,
    int? failures,
    int? totalResponseTime,
    double? userConfidence,
    double? alpha,
    double? beta,
    int? lastAttempted,
    int? createdAt,
    int? updatedAt,
  }) {
    return MabQuestionArmDbModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      questionId: questionId ?? this.questionId,
      attempts: attempts ?? this.attempts,
      successes: successes ?? this.successes,
      failures: failures ?? this.failures,
      totalResponseTime: totalResponseTime ?? this.totalResponseTime,
      userConfidence: userConfidence ?? this.userConfidence,
      alpha: alpha ?? this.alpha,
      beta: beta ?? this.beta,
      lastAttempted: lastAttempted ?? this.lastAttempted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Calculate success rate
  double get successRate => attempts > 0 ? successes / attempts : 0.0;

  /// Calculate average response time
  Duration get averageResponseTime =>
      attempts > 0
          ? Duration(milliseconds: totalResponseTime ~/ attempts)
          : Duration.zero;
}
