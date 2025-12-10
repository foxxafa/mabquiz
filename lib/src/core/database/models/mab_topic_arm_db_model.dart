/// Database model for MAB topic arms (hierarchical MAB state)
class MabTopicArmDbModel {
  final int? id;
  final String userId;
  final String topicKey;
  final String topic;
  final String knowledgeType;
  final String course;
  final int attempts;
  final int successes;
  final int failures;
  final int totalResponseTime;
  final double alpha;
  final double beta;
  final int createdAt;
  final int updatedAt;

  MabTopicArmDbModel({
    this.id,
    required this.userId,
    required this.topicKey,
    required this.topic,
    required this.knowledgeType,
    required this.course,
    this.attempts = 0,
    this.successes = 0,
    this.failures = 0,
    this.totalResponseTime = 0,
    this.alpha = 1.0,
    this.beta = 1.0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convert from database map
  factory MabTopicArmDbModel.fromMap(Map<String, dynamic> map) {
    return MabTopicArmDbModel(
      id: map['id'] as int?,
      userId: map['user_id'] as String,
      topicKey: map['topic_key'] as String,
      topic: map['topic'] as String,
      knowledgeType: map['knowledge_type'] as String,
      course: map['course'] as String,
      attempts: map['attempts'] as int? ?? 0,
      successes: map['successes'] as int? ?? 0,
      failures: map['failures'] as int? ?? 0,
      totalResponseTime: map['total_response_time'] as int? ?? 0,
      alpha: (map['alpha'] as num?)?.toDouble() ?? 1.0,
      beta: (map['beta'] as num?)?.toDouble() ?? 1.0,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'topic_key': topicKey,
      'topic': topic,
      'knowledge_type': knowledgeType,
      'course': course,
      'attempts': attempts,
      'successes': successes,
      'failures': failures,
      'total_response_time': totalResponseTime,
      'alpha': alpha,
      'beta': beta,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// Create a copy with modified fields
  MabTopicArmDbModel copyWith({
    int? id,
    String? userId,
    String? topicKey,
    String? topic,
    String? knowledgeType,
    String? course,
    int? attempts,
    int? successes,
    int? failures,
    int? totalResponseTime,
    double? alpha,
    double? beta,
    int? createdAt,
    int? updatedAt,
  }) {
    return MabTopicArmDbModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      topicKey: topicKey ?? this.topicKey,
      topic: topic ?? this.topic,
      knowledgeType: knowledgeType ?? this.knowledgeType,
      course: course ?? this.course,
      attempts: attempts ?? this.attempts,
      successes: successes ?? this.successes,
      failures: failures ?? this.failures,
      totalResponseTime: totalResponseTime ?? this.totalResponseTime,
      alpha: alpha ?? this.alpha,
      beta: beta ?? this.beta,
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
