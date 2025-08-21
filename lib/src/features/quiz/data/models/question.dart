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
    required super.course,
    required super.topic,
    super.subtopic,
    required super.knowledgeType,
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
      course: question.course,
      topic: question.topic,
      subtopic: question.subtopic,
      knowledgeType: question.knowledgeType,
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
      course: course,
      topic: topic,
      subtopic: subtopic,
      knowledgeType: knowledgeType,
      points: points,
      initialConfidence: initialConfidence,
    );
  }

  /// Create from JSON (for API integration)
  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    final knowledgeType = json['knowledgeType']?.toString() ?? 'general';
    
    return QuestionModel(
      id: json['id'] as String,
      text: json['prompt']?.toString() ?? json['text'] as String,
      type: entities.QuestionType.fromJson(json['type']?.toString()),
      difficulty: json['difficulty'] != null 
        ? entities.DifficultyLevel.values.firstWhere(
            (e) => e.name == json['difficulty'],
            orElse: () => entities.DifficultyLevel.intermediate,
          )
        : entities.DifficultyLevel.fromKnowledgeType(knowledgeType),
      options: List<String>.from(json['options'] ?? []),
      correctAnswer: json['correctAnswer'] as String,
      explanation: json['explanation'] as String?,
      tags: List<String>.from(json['tags'] ?? json['metadata']?['tags'] ?? []),
      subject: json['subject']?.toString() ?? json['course']?.toString() ?? '',
      course: json['course']?.toString() ?? json['subject']?.toString() ?? '',
      topic: json['topic']?.toString() ?? 'general',
      subtopic: json['subtopic']?.toString(),
      knowledgeType: knowledgeType,
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
