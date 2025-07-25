/// Question types for the MAB quiz system
enum QuestionType {
  multipleChoice,
  trueFalse,
  fillInBlank,
  matching,
}

/// Difficulty levels for questions
enum DifficultyLevel {
  beginner,
  intermediate,
  advanced,
}

/// A single question in the quiz system - Domain Entity
///
/// This is the pure domain entity without any data-layer concerns.
/// Data models in the data layer will extend or convert to/from this entity.
class Question {
  final String id;
  final String text;
  final QuestionType type;
  final DifficultyLevel difficulty;
  final List<String> options;
  final String correctAnswer;
  final String? explanation;
  final List<String> tags;
  final String subject;
  final int points;

  /// For tracking bandit algorithm performance
  final double initialConfidence;

  const Question({
    required this.id,
    required this.text,
    required this.type,
    required this.difficulty,
    required this.options,
    required this.correctAnswer,
    this.explanation,
    this.tags = const [],
    required this.subject,
    this.points = 10,
    this.initialConfidence = 0.5,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Question && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Question(id: $id, text: $text, type: $type, difficulty: $difficulty, subject: $subject)';
  }

  /// Create a copy with modified properties
  Question copyWith({
    String? id,
    String? text,
    QuestionType? type,
    DifficultyLevel? difficulty,
    List<String>? options,
    String? correctAnswer,
    String? explanation,
    List<String>? tags,
    String? subject,
    int? points,
    double? initialConfidence,
  }) {
    return Question(
      id: id ?? this.id,
      text: text ?? this.text,
      type: type ?? this.type,
      difficulty: difficulty ?? this.difficulty,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      explanation: explanation ?? this.explanation,
      tags: tags ?? this.tags,
      subject: subject ?? this.subject,
      points: points ?? this.points,
      initialConfidence: initialConfidence ?? this.initialConfidence,
    );
  }
}
