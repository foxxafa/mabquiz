import '../../domain/entities/question.dart' as entities;

/// Question data model for data layer
///
/// This model extends the domain entity with data-specific functionality
/// like JSON serialization and additional metadata for persistence.
class QuestionModel extends entities.Question {
  const QuestionModel({
    required super.id,
    required super.text,
    required super.type,
    required super.difficulty,
    required super.options,
    required super.correctAnswer,
    super.explanation,
    super.tags = const [],
    required super.subject,
    super.points = 10,
    super.initialConfidence = 0.5,
  });

  /// Create from domain entity
  factory QuestionModel.fromEntity(entities.Question question) {
    return QuestionModel(
      id: question.id,
      text: question.text,
      type: question.type,
      difficulty: question.difficulty,
      options: question.options,
      correctAnswer: question.correctAnswer,
      explanation: question.explanation,
      tags: question.tags,
      subject: question.subject,
      points: question.points,
      initialConfidence: question.initialConfidence,
    );
  }

  /// Convert to domain entity
  entities.Question toEntity() {
    return entities.Question(
      id: id,
      text: text,
      type: type,
      difficulty: difficulty,
      options: options,
      correctAnswer: correctAnswer,
      explanation: explanation,
      tags: tags,
      subject: subject,
      points: points,
      initialConfidence: initialConfidence,
    );
  }

  /// Create from JSON (for firebase/API integration)
  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'] as String,
      text: json['text'] as String,
      type: entities.QuestionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => entities.QuestionType.multipleChoice,
      ),
      difficulty: entities.DifficultyLevel.values.firstWhere(
        (e) => e.name == json['difficulty'],
        orElse: () => entities.DifficultyLevel.intermediate,
      ),
      options: List<String>.from(json['options'] ?? []),
      correctAnswer: json['correctAnswer'] as String,
      explanation: json['explanation'] as String?,
      tags: List<String>.from(json['tags'] ?? []),
      subject: json['subject'] as String,
      points: json['points'] as int? ?? 10,
      initialConfidence: json['initialConfidence'] as double? ?? 0.5,
    );
  }

  /// Convert to JSON
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'type': type.name,
      'difficulty': difficulty.name,
      'options': options,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'tags': tags,
      'subject': subject,
      'points': points,
      'initialConfidence': initialConfidence,
    };
  }
}
