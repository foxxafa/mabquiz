/// Database model for questions
class QuestionDbModel {
  final String id;
  final String text;
  final String course;
  final String topic;
  final String knowledgeType;
  final String difficulty;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String? optionE;
  final String correctAnswer;
  final String? explanation;
  final String? tags;
  final double initialConfidence;
  final int createdAt;
  final int updatedAt;
  final int? syncedAt;
  final bool isSynced;

  QuestionDbModel({
    required this.id,
    required this.text,
    required this.course,
    required this.topic,
    required this.knowledgeType,
    required this.difficulty,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    this.optionE,
    required this.correctAnswer,
    this.explanation,
    this.tags,
    this.initialConfidence = 0.5,
    required this.createdAt,
    required this.updatedAt,
    this.syncedAt,
    this.isSynced = false,
  });

  /// Convert from database map
  factory QuestionDbModel.fromMap(Map<String, dynamic> map) {
    return QuestionDbModel(
      id: map['id'] as String,
      text: map['text'] as String,
      course: map['course'] as String,
      topic: map['topic'] as String,
      knowledgeType: map['knowledge_type'] as String,
      difficulty: map['difficulty'] as String,
      optionA: map['option_a'] as String,
      optionB: map['option_b'] as String,
      optionC: map['option_c'] as String,
      optionD: map['option_d'] as String,
      optionE: map['option_e'] as String?,
      correctAnswer: map['correct_answer'] as String,
      explanation: map['explanation'] as String?,
      tags: map['tags'] as String?,
      initialConfidence: (map['initial_confidence'] as num?)?.toDouble() ?? 0.5,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
      syncedAt: map['synced_at'] as int?,
      isSynced: (map['is_synced'] as int) == 1,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'course': course,
      'topic': topic,
      'knowledge_type': knowledgeType,
      'difficulty': difficulty,
      'option_a': optionA,
      'option_b': optionB,
      'option_c': optionC,
      'option_d': optionD,
      'option_e': optionE,
      'correct_answer': correctAnswer,
      'explanation': explanation,
      'tags': tags,
      'initial_confidence': initialConfidence,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'synced_at': syncedAt,
      'is_synced': isSynced ? 1 : 0,
    };
  }

  /// Create a copy with modified fields
  QuestionDbModel copyWith({
    String? id,
    String? text,
    String? course,
    String? topic,
    String? knowledgeType,
    String? difficulty,
    String? optionA,
    String? optionB,
    String? optionC,
    String? optionD,
    String? optionE,
    String? correctAnswer,
    String? explanation,
    String? tags,
    double? initialConfidence,
    int? createdAt,
    int? updatedAt,
    int? syncedAt,
    bool? isSynced,
  }) {
    return QuestionDbModel(
      id: id ?? this.id,
      text: text ?? this.text,
      course: course ?? this.course,
      topic: topic ?? this.topic,
      knowledgeType: knowledgeType ?? this.knowledgeType,
      difficulty: difficulty ?? this.difficulty,
      optionA: optionA ?? this.optionA,
      optionB: optionB ?? this.optionB,
      optionC: optionC ?? this.optionC,
      optionD: optionD ?? this.optionD,
      optionE: optionE ?? this.optionE,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      explanation: explanation ?? this.explanation,
      tags: tags ?? this.tags,
      initialConfidence: initialConfidence ?? this.initialConfidence,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
