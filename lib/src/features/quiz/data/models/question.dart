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

/// A single question in the quiz system
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

  /// Create from JSON (for firebase/API integration)
  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      text: json['text'] as String,
      type: QuestionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => QuestionType.multipleChoice,
      ),
      difficulty: DifficultyLevel.values.firstWhere(
        (e) => e.name == json['difficulty'],
        orElse: () => DifficultyLevel.intermediate,
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

  /// Create a copy with updated properties
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Question && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Question(id: $id, text: $text, type: $type, difficulty: $difficulty)';
  }
}

/// Sample questions for testing
class SampleQuestions {
  static List<Question> getMathQuestions() {
    return [
      Question(
        id: 'math_001',
        text: '2 + 2 = ?',
        type: QuestionType.multipleChoice,
        difficulty: DifficultyLevel.beginner,
        options: ['3', '4', '5', '6'],
        correctAnswer: '4',
        explanation: '2 + 2 = 4. Temel toplama işlemi.',
        tags: ['toplama', 'temel'],
        subject: 'Matematik',
        points: 5,
      ),
      Question(
        id: 'math_002',
        text: '√16 = ?',
        type: QuestionType.multipleChoice,
        difficulty: DifficultyLevel.intermediate,
        options: ['2', '4', '8', '16'],
        correctAnswer: '4',
        explanation: '16\'nın karekökü 4\'tür çünkü 4 × 4 = 16.',
        tags: ['karekök', 'orta'],
        subject: 'Matematik',
        points: 15,
      ),
      Question(
        id: 'math_003',
        text: 'x² - 5x + 6 = 0 denkleminin kökleri toplamı kaçtır?',
        type: QuestionType.multipleChoice,
        difficulty: DifficultyLevel.advanced,
        options: ['5', '6', '-5', '-6'],
        correctAnswer: '5',
        explanation: 'Vieta formülüne göre köklerin toplamı -b/a = -(-5)/1 = 5\'tir.',
        tags: ['denklem', 'ileri'],
        subject: 'Matematik',
        points: 25,
      ),
    ];
  }

  static List<Question> getTurkishQuestions() {
    return [
      Question(
        id: 'tr_001',
        text: '"Kitap" kelimesinin çoğul hali nedir?',
        type: QuestionType.multipleChoice,
        difficulty: DifficultyLevel.beginner,
        options: ['Kitaplar', 'Kitapları', 'Kitaba', 'Kitaptan'],
        correctAnswer: 'Kitaplar',
        explanation: '"Kitap" kelimesinin çoğul hali "+lar" eki alarak "kitaplar" olur.',
        tags: ['çoğul', 'isim'],
        subject: 'Türkçe',
        points: 5,
      ),
      Question(
        id: 'tr_002',
        text: 'Aşağıdakilerden hangisi mecaz anlamlı kullanılmıştır?',
        type: QuestionType.multipleChoice,
        difficulty: DifficultyLevel.intermediate,
        options: [
          'Elma ağacından düştü',
          'Kalbi taş gibi sert',
          'Okula yürüdü',
          'Dün geldi'
        ],
        correctAnswer: 'Kalbi taş gibi sert',
        explanation: '"Kalbi taş gibi sert" ifadesinde "taş" mecazi olarak sertlik anlamında kullanılmıştır.',
        tags: ['mecaz', 'anlam'],
        subject: 'Türkçe',
        points: 15,
      ),
    ];
  }

  static List<Question> getAllSampleQuestions() {
    return [
      ...getMathQuestions(),
      ...getTurkishQuestions(),
    ];
  }
}

/// Export sample questions for easy access
final List<Question> sampleQuestions = SampleQuestions.getAllSampleQuestions();
