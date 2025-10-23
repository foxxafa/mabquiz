/// Database model for MAB question arms (Thompson Sampling state)
class MabQuestionArmDbModel {
  final int? id;
  final String userId;
  final String questionId;
  final String difficulty;
  final int attempts;
  final int successes;
  final int failures;
  final int totalResponseTime;
  final double userConfidence;
  final double alpha;
  final double beta;
  final int? lastAttempted; // When was this question last attempted
  final int lastUpdated;
  final int createdAt;
  final int? syncedAt;
  final bool isSynced;

  MabQuestionArmDbModel({
    this.id,
    required this.userId,
    required this.questionId,
    required this.difficulty,
    this.attempts = 0,
    this.successes = 0,
    this.failures = 0,
    this.totalResponseTime = 0,
    this.userConfidence = 0.5,
    this.alpha = 1.0,
    this.beta = 1.0,
    this.lastAttempted,
    required this.lastUpdated,
    required this.createdAt,
    this.syncedAt,
    this.isSynced = false,
  });

  /// Convert from database map
  factory MabQuestionArmDbModel.fromMap(Map<String, dynamic> map) {
    return MabQuestionArmDbModel(
      id: map['id'] as int?,
      userId: map['user_id'] as String,
      questionId: map['question_id'] as String,
      difficulty: map['difficulty'] as String,
      attempts: map['attempts'] as int? ?? 0,
      successes: map['successes'] as int? ?? 0,
      failures: map['failures'] as int? ?? 0,
      totalResponseTime: map['total_response_time'] as int? ?? 0,
      userConfidence: (map['user_confidence'] as num?)?.toDouble() ?? 0.5,
      alpha: (map['alpha'] as num?)?.toDouble() ?? 1.0,
      beta: (map['beta'] as num?)?.toDouble() ?? 1.0,
      lastAttempted: map['last_attempted'] as int?,
      lastUpdated: map['last_updated'] as int,
      createdAt: map['created_at'] as int,
      syncedAt: map['synced_at'] as int?,
      isSynced: (map['is_synced'] as int) == 1,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'question_id': questionId,
      'difficulty': difficulty,
      'attempts': attempts,
      'successes': successes,
      'failures': failures,
      'total_response_time': totalResponseTime,
      'user_confidence': userConfidence,
      'alpha': alpha,
      'beta': beta,
      'last_attempted': lastAttempted,
      'last_updated': lastUpdated,
      'created_at': createdAt,
      'synced_at': syncedAt,
      'is_synced': isSynced ? 1 : 0,
    };
  }

  /// Create a copy with modified fields
  MabQuestionArmDbModel copyWith({
    int? id,
    String? userId,
    String? questionId,
    String? difficulty,
    int? attempts,
    int? successes,
    int? failures,
    int? totalResponseTime,
    double? userConfidence,
    double? alpha,
    double? beta,
    int? lastAttempted,
    int? lastUpdated,
    int? createdAt,
    int? syncedAt,
    bool? isSynced,
  }) {
    return MabQuestionArmDbModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      questionId: questionId ?? this.questionId,
      difficulty: difficulty ?? this.difficulty,
      attempts: attempts ?? this.attempts,
      successes: successes ?? this.successes,
      failures: failures ?? this.failures,
      totalResponseTime: totalResponseTime ?? this.totalResponseTime,
      userConfidence: userConfidence ?? this.userConfidence,
      alpha: alpha ?? this.alpha,
      beta: beta ?? this.beta,
      lastAttempted: lastAttempted ?? this.lastAttempted,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      createdAt: createdAt ?? this.createdAt,
      syncedAt: syncedAt ?? this.syncedAt,
      isSynced: isSynced ?? this.isSynced,
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
