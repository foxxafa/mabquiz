/// Question types for the MAB quiz system
enum QuestionType {
  multipleChoice('multiple_choice'),
  trueFalse('true_false'),
  fillInBlank('fill_in_blank'),
  matching('match_text_text');

  const QuestionType(this.jsonValue);
  final String jsonValue;

  static QuestionType fromJson(String? value) {
    return QuestionType.values.firstWhere(
      (e) => e.jsonValue == value || e.name == value,
      orElse: () => QuestionType.multipleChoice,
    );
  }
}

/// Difficulty levels for questions
enum DifficultyLevel {
  beginner,
  intermediate,
  advanced;

  static DifficultyLevel fromKnowledgeType(String knowledgeType) {
    switch (knowledgeType.toLowerCase()) {
      case 'terminology':
        return DifficultyLevel.beginner;
      case 'dosage':
      case 'side_effect':
        return DifficultyLevel.intermediate;
      case 'pharmacodynamics':
      case 'pharmacokinetics':
        return DifficultyLevel.advanced;
      default:
        return DifficultyLevel.intermediate;
    }
  }
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

  // Enhanced metadata for MAB
  final String course;
  final String topic;
  final String? subtopic;
  final String knowledgeType;

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
    required this.course,
    required this.topic,
    this.subtopic,
    required this.knowledgeType,
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
    String? course,
    String? topic,
    String? subtopic,
    String? knowledgeType,
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
      course: course ?? this.course,
      topic: topic ?? this.topic,
      subtopic: subtopic ?? this.subtopic,
      knowledgeType: knowledgeType ?? this.knowledgeType,
      initialConfidence: initialConfidence ?? this.initialConfidence,
    );
  }

  /// Check if the given answer is correct
  bool isCorrectAnswer(String answer) {
    return answer.trim().toLowerCase() == correctAnswer.trim().toLowerCase();
  }

  /// Create a Question from JSON data
  factory Question.fromJson(Map<String, dynamic> json) {
    final knowledgeType = json['knowledgeType']?.toString() ?? 'general';
    
    return Question(
      id: json['id']?.toString() ?? '',
      text: json['prompt']?.toString() ?? json['text']?.toString() ?? '',
      type: QuestionType.fromJson(json['type']?.toString()),
      difficulty: json['difficulty'] != null 
        ? DifficultyLevel.values.firstWhere(
            (e) => e.name == json['difficulty'],
            orElse: () => DifficultyLevel.intermediate,
          )
        : DifficultyLevel.fromKnowledgeType(knowledgeType),
      options: List<String>.from(json['options'] ?? []),
      correctAnswer: json['correctAnswer']?.toString() ?? '',
      explanation: json['explanation']?.toString(),
      tags: List<String>.from(json['tags'] ?? json['metadata']?['tags'] ?? []),
      subject: json['subject']?.toString() ?? json['course']?.toString() ?? '',
      course: json['course']?.toString() ?? json['subject']?.toString() ?? '',
      topic: json['topic']?.toString() ?? 'general',
      subtopic: json['subtopic']?.toString(),
      knowledgeType: knowledgeType,
      points: json['points']?.toInt() ?? 10,
      initialConfidence: json['initialConfidence']?.toDouble() ?? 0.5,
    );
  }

  /// Convert Question to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'prompt': text,
      'type': type.jsonValue,
      'difficulty': difficulty.name,
      'options': options,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'tags': tags,
      'course': course,
      'topic': topic,
      'subtopic': subtopic,
      'knowledgeType': knowledgeType,
      'subject': subject,
      'points': points,
      'initialConfidence': initialConfidence,
    };
  }

  /// Get composite key for MAB grouping
  String get mabKey => '${topic}_$knowledgeType';
  
  /// Get hierarchical context for learning analytics
  Map<String, String> get learningContext => {
    'course': course,
    'topic': topic,
    'subtopic': subtopic ?? '',
    'knowledgeType': knowledgeType,
  };
}
