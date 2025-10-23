/// Database model for user responses
class UserResponseDbModel {
  final int? id;
  final String userId;
  final String questionId;
  final String sessionId;
  final String selectedAnswer;
  final bool isCorrect;
  final int responseTimeMs;
  final double? confidenceLevel;
  final int timestamp;
  final int? syncedAt;
  final bool isSynced;

  UserResponseDbModel({
    this.id,
    required this.userId,
    required this.questionId,
    required this.sessionId,
    required this.selectedAnswer,
    required this.isCorrect,
    required this.responseTimeMs,
    this.confidenceLevel,
    required this.timestamp,
    this.syncedAt,
    this.isSynced = false,
  });

  /// Convert from database map
  factory UserResponseDbModel.fromMap(Map<String, dynamic> map) {
    return UserResponseDbModel(
      id: map['id'] as int?,
      userId: map['user_id'] as String,
      questionId: map['question_id'] as String,
      sessionId: map['session_id'] as String,
      selectedAnswer: map['selected_answer'] as String,
      isCorrect: (map['is_correct'] as int) == 1,
      responseTimeMs: map['response_time_ms'] as int,
      confidenceLevel: (map['confidence_level'] as num?)?.toDouble(),
      timestamp: map['timestamp'] as int,
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
      'session_id': sessionId,
      'selected_answer': selectedAnswer,
      'is_correct': isCorrect ? 1 : 0,
      'response_time_ms': responseTimeMs,
      'confidence_level': confidenceLevel,
      'timestamp': timestamp,
      'synced_at': syncedAt,
      'is_synced': isSynced ? 1 : 0,
    };
  }

  /// Create a copy with modified fields
  UserResponseDbModel copyWith({
    int? id,
    String? userId,
    String? questionId,
    String? sessionId,
    String? selectedAnswer,
    bool? isCorrect,
    int? responseTimeMs,
    double? confidenceLevel,
    int? timestamp,
    int? syncedAt,
    bool? isSynced,
  }) {
    return UserResponseDbModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      questionId: questionId ?? this.questionId,
      sessionId: sessionId ?? this.sessionId,
      selectedAnswer: selectedAnswer ?? this.selectedAnswer,
      isCorrect: isCorrect ?? this.isCorrect,
      responseTimeMs: responseTimeMs ?? this.responseTimeMs,
      confidenceLevel: confidenceLevel ?? this.confidenceLevel,
      timestamp: timestamp ?? this.timestamp,
      syncedAt: syncedAt ?? this.syncedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
