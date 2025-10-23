/// Database model for quiz sessions
class QuizSessionDbModel {
  final String id;
  final String userId;
  final String course;
  final String? topic;
  final String? difficulty;
  final int totalQuestions;
  final int correctAnswers;
  final int totalTimeMs;
  final int startedAt;
  final int? completedAt;
  final bool isCompleted;
  final int? syncedAt;
  final bool isSynced;

  QuizSessionDbModel({
    required this.id,
    required this.userId,
    required this.course,
    this.topic,
    this.difficulty,
    required this.totalQuestions,
    this.correctAnswers = 0,
    this.totalTimeMs = 0,
    required this.startedAt,
    this.completedAt,
    this.isCompleted = false,
    this.syncedAt,
    this.isSynced = false,
  });

  /// Convert from database map
  factory QuizSessionDbModel.fromMap(Map<String, dynamic> map) {
    return QuizSessionDbModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      course: map['course'] as String,
      topic: map['topic'] as String?,
      difficulty: map['difficulty'] as String?,
      totalQuestions: map['total_questions'] as int,
      correctAnswers: map['correct_answers'] as int? ?? 0,
      totalTimeMs: map['total_time_ms'] as int? ?? 0,
      startedAt: map['started_at'] as int,
      completedAt: map['completed_at'] as int?,
      isCompleted: (map['is_completed'] as int) == 1,
      syncedAt: map['synced_at'] as int?,
      isSynced: (map['is_synced'] as int) == 1,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'course': course,
      'topic': topic,
      'difficulty': difficulty,
      'total_questions': totalQuestions,
      'correct_answers': correctAnswers,
      'total_time_ms': totalTimeMs,
      'started_at': startedAt,
      'completed_at': completedAt,
      'is_completed': isCompleted ? 1 : 0,
      'synced_at': syncedAt,
      'is_synced': isSynced ? 1 : 0,
    };
  }

  /// Create a copy with modified fields
  QuizSessionDbModel copyWith({
    String? id,
    String? userId,
    String? course,
    String? topic,
    String? difficulty,
    int? totalQuestions,
    int? correctAnswers,
    int? totalTimeMs,
    int? startedAt,
    int? completedAt,
    bool? isCompleted,
    int? syncedAt,
    bool? isSynced,
  }) {
    return QuizSessionDbModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      course: course ?? this.course,
      topic: topic ?? this.topic,
      difficulty: difficulty ?? this.difficulty,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      totalTimeMs: totalTimeMs ?? this.totalTimeMs,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      isCompleted: isCompleted ?? this.isCompleted,
      syncedAt: syncedAt ?? this.syncedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  /// Calculate success rate (0.0 to 1.0)
  double get successRate =>
      totalQuestions > 0 ? correctAnswers / totalQuestions : 0.0;

  /// Calculate success percentage (0 to 100)
  double get successPercentage => successRate * 100;

  /// Get average time per question
  Duration get averageTimePerQuestion =>
      totalQuestions > 0
          ? Duration(milliseconds: totalTimeMs ~/ totalQuestions)
          : Duration.zero;

  /// Get total duration
  Duration get totalDuration => Duration(milliseconds: totalTimeMs);

  /// Get session duration (from start to completion)
  Duration? get sessionDuration =>
      completedAt != null
          ? Duration(milliseconds: completedAt! - startedAt)
          : null;
}
