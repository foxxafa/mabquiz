import 'dart:async';
import 'dart:math';
import '../../domain/entities/question.dart';
import '../models/sample_questions.dart';

/// Mock data source for quiz questions - simulates Firebase behavior
///
/// This class provides a mock implementation that can be used during
/// development and testing when Firebase is not available.
abstract class QuizDataSource {
  /// Fetch questions by subject
  Future<List<Question>> getQuestionsBySubject(String subject);

  /// Fetch questions by difficulty level
  Future<List<Question>> getQuestionsByDifficulty(DifficultyLevel difficulty);

  /// Fetch random questions with optional filters
  Future<List<Question>> getRandomQuestions({
    int limit = 10,
    String? subject,
    DifficultyLevel? difficulty,
    List<String>? excludeIds,
  });

  /// Fetch a single question by ID
  Future<Question?> getQuestionById(String id);

  /// Get available subjects
  Future<List<String>> getAvailableSubjects();
  
  /// Get all questions
  Future<List<Question>> getAllQuestions();
}

/// Mock implementation of QuizDataSource
class MockQuizDataSource implements QuizDataSource {
  final Duration simulatedDelay;
  final Random _random = Random();

  /// In-memory storage of questions
  static final List<Question> _allQuestions = [
    // Matematik soruları
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
    Question(
      id: 'math_004',
      text: '15 × 8 = ?',
      type: QuestionType.multipleChoice,
      difficulty: DifficultyLevel.beginner,
      options: ['110', '120', '130', '140'],
      correctAnswer: '120',
      explanation: '15 × 8 = 120',
      tags: ['çarpma', 'temel'],
      subject: 'Matematik',
      points: 5,
    ),
    Question(
      id: 'math_005',
      text: 'Bir üçgenin iç açıları toplamı kaç derecedir?',
      type: QuestionType.multipleChoice,
      difficulty: DifficultyLevel.intermediate,
      options: ['90', '180', '270', '360'],
      correctAnswer: '180',
      explanation: 'Herhangi bir üçgenin iç açıları toplamı her zaman 180 derecedir.',
      tags: ['geometri', 'üçgen'],
      subject: 'Matematik',
      points: 15,
    ),
    
    // Türkçe soruları
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
    Question(
      id: 'tr_003',
      text: '"Güneş" kelimesinde kaç sesli harf vardır?',
      type: QuestionType.multipleChoice,
      difficulty: DifficultyLevel.beginner,
      options: ['2', '3', '4', '5'],
      correctAnswer: '3',
      explanation: '"Güneş" kelimesinde ü, e, ş sesli harfleri vardır.',
      tags: ['sesli harf', 'temel'],
      subject: 'Türkçe',
      points: 5,
    ),
    
    // Farmakoloji soruları
    ...SampleQuestions.getFarmakolojiQuestions(),
    
    // Doğru-Yanlış soruları
    Question(
      id: 'tf_001',
      text: 'Türkiye\'nin başkenti Ankara\'dır.',
      type: QuestionType.trueFalse,
      difficulty: DifficultyLevel.beginner,
      options: ['Doğru', 'Yanlış'],
      correctAnswer: 'Doğru',
      explanation: 'Türkiye Cumhuriyeti\'nin başkenti Ankara\'dır.',
      tags: ['genel kültür', 'başkent'],
      subject: 'Genel Kültür',
      points: 5,
    ),
    Question(
      id: 'tf_002',
      text: 'Su 0 derecede donar.',
      type: QuestionType.trueFalse,
      difficulty: DifficultyLevel.beginner,
      options: ['Doğru', 'Yanlış'],
      correctAnswer: 'Doğru',
      explanation: 'Su deniz seviyesinde 0°C\'de donar.',
      tags: ['fizik', 'hal değişimi'],
      subject: 'Fen Bilgisi',
      points: 5,
    ),
    
    // Boşluk doldurma soruları
    Question(
      id: 'fill_001',
      text: 'Türkiye\'nin en uzun nehri _____ nehridir.',
      type: QuestionType.fillInBlank,
      difficulty: DifficultyLevel.intermediate,
      options: ['Kızılırmak', 'Sakarya', 'Fırat', 'Dicle'],
      correctAnswer: 'Kızılırmak',
      explanation: 'Kızılırmak, Türkiye\'nin en uzun nehridir (1355 km).',
      tags: ['coğrafya', 'nehir'],
      subject: 'Coğrafya',
      points: 15,
    ),
  ];

  MockQuizDataSource({
    this.simulatedDelay = const Duration(milliseconds: 500),
  });

  @override
  Future<List<Question>> getQuestionsBySubject(String subject) async {
    await Future.delayed(simulatedDelay);
    
    return _allQuestions
        .where((question) => question.subject.toLowerCase() == subject.toLowerCase())
        .toList();
  }

  @override
  Future<List<Question>> getQuestionsByDifficulty(DifficultyLevel difficulty) async {
    await Future.delayed(simulatedDelay);
    
    return _allQuestions
        .where((question) => question.difficulty == difficulty)
        .toList();
  }

  @override
  Future<List<Question>> getRandomQuestions({
    int limit = 10,
    String? subject,
    DifficultyLevel? difficulty,
    List<String>? excludeIds,
  }) async {
    await Future.delayed(simulatedDelay);
    
    var filteredQuestions = List<Question>.from(_allQuestions);
    
    // Apply filters
    if (subject != null) {
      filteredQuestions = filteredQuestions
          .where((q) => q.subject.toLowerCase() == subject.toLowerCase())
          .toList();
    }
    
    if (difficulty != null) {
      filteredQuestions = filteredQuestions
          .where((q) => q.difficulty == difficulty)
          .toList();
    }
    
    if (excludeIds != null && excludeIds.isNotEmpty) {
      filteredQuestions = filteredQuestions
          .where((q) => !excludeIds.contains(q.id))
          .toList();
    }
    
    // Shuffle and return requested amount
    filteredQuestions.shuffle(_random);
    return filteredQuestions.take(limit).toList();
  }

  @override
  Future<Question?> getQuestionById(String id) async {
    await Future.delayed(simulatedDelay);
    
    try {
      return _allQuestions.firstWhere((question) => question.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<String>> getAvailableSubjects() async {
    await Future.delayed(simulatedDelay);
    
    final subjects = _allQuestions
        .map((question) => question.subject)
        .toSet()
        .toList();
    
    subjects.sort();
    return subjects;
  }

  /// Get all questions for testing and initialization purposes
  @override
  Future<List<Question>> getAllQuestions() async {
    await Future.delayed(simulatedDelay);
    return List.unmodifiable(_allQuestions);
  }
  
  /// Add a question (for testing purposes)
  void addQuestion(Question question) {
    _allQuestions.add(question);
  }
  
  /// Clear all questions (for testing purposes)
  void clearQuestions() {
    _allQuestions.clear();
  }
  
  /// Reset to default questions (for testing purposes)
  void resetToDefaults() {
    // This would reset to the original hardcoded questions
    // Implementation depends on how you want to handle this
  }
}

/// Exception thrown when quiz data operations fail
class QuizDataException implements Exception {
  final String message;
  final String? code;

  const QuizDataException(this.message, [this.code]);

  @override
  String toString() => 'QuizDataException: $message${code != null ? ' (Code: $code)' : ''}';
}
