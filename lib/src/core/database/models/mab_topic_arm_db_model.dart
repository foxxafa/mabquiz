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
  final int lastUpdated;
  final int createdAt;
  final int? syncedAt;
  final bool isSynced;

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
    required this.lastUpdated,
    required this.createdAt,
    this.syncedAt,
    this.isSynced = false,
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
      'last_updated': lastUpdated,
      'created_at': createdAt,
      'synced_at': syncedAt,
      'is_synced': isSynced ? 1 : 0,
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
    int? lastUpdated,
    int? createdAt,
    int? syncedAt,
    bool? isSynced,
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
