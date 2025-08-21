import '../../domain/entities/question.dart';

/// Sample questions for testing and development
class SampleQuestions {
  /// Get mathematics sample questions
  static List<Question> getMathQuestions() {
    return [
      Question(
        id: 'math_001',
        text: '2 + 2 = ?',
        type: QuestionType.multipleChoice,
        difficulty: DifficultyLevel.beginner,
        options: ['3', '4', '5', '6'],
        correctAnswer: '4',
        explanation: '2 artı 2 eşittir 4\'tür.',
        tags: ['toplama', 'temel matematik'],
        subject: 'Matematik',
        course: 'matematik',
        topic: 'temel_matematik',
        knowledgeType: 'hesaplama',
        points: 5,
      ),
      Question(
        id: 'math_002',
        text: '10 ÷ 2 = ?',
        type: QuestionType.multipleChoice,
        difficulty: DifficultyLevel.beginner,
        options: ['3', '4', '5', '6'],
        correctAnswer: '5',
        explanation: '10 bölü 2 eşittir 5\'tir.',
        tags: ['bölme', 'temel matematik'],
        subject: 'Matematik',
        course: 'matematik',
        topic: 'temel_matematik',
        knowledgeType: 'hesaplama',
        points: 5,
      ),
      Question(
        id: 'math_003',
        text: '3 × 7 = ?',
        type: QuestionType.multipleChoice,
        difficulty: DifficultyLevel.intermediate,
        options: ['20', '21', '22', '23'],
        correctAnswer: '21',
        explanation: '3 çarpı 7 eşittir 21\'dir.',
        tags: ['çarpma', 'temel matematik'],
        subject: 'Matematik',
        course: 'matematik',
        topic: 'temel_matematik',
        knowledgeType: 'hesaplama',
        points: 10,
      ),
      Question(
        id: 'math_004',
        text: 'x² = 16 ise x = ?',
        type: QuestionType.multipleChoice,
        difficulty: DifficultyLevel.advanced,
        options: ['2', '4', '±4', '8'],
        correctAnswer: '±4',
        explanation: 'x² = 16 denkleminin çözümü x = ±4\'tür.',
        tags: ['denklem', 'karekok'],
        subject: 'Matematik',
        course: 'matematik',
        topic: 'denklemler',
        knowledgeType: 'problem_cozme',
        points: 20,
      ),
    ];
  }

  /// Get Turkish language sample questions
  static List<Question> getTurkishQuestions() {
    return [
      Question(
        id: 'tr_001',
        text: '"Kitap" kelimesinin çoğulu nedir?',
        type: QuestionType.multipleChoice,
        difficulty: DifficultyLevel.beginner,
        options: ['Kitaplar', 'Kitapları', 'Kitablar', 'Kitaptan'],
        correctAnswer: 'Kitaplar',
        explanation: '"Kitap" kelimesinin çoğulu "kitaplar"dır.',
        tags: ['dilbilgisi', 'çoğul'],
        subject: 'Türkçe',
        course: 'turkce',
        topic: 'dilbilgisi',
        knowledgeType: 'terminology',
        points: 5,
      ),
      Question(
        id: 'tr_002',
        text: 'Hangisi bir deyimdir?',
        type: QuestionType.multipleChoice,
        difficulty: DifficultyLevel.intermediate,
        options: ['Kedi uyuyor', 'Gözü tok', 'Ev güzel', 'Araba kırmızı'],
        correctAnswer: 'Gözü tok',
        explanation: '"Gözü tok" bir deyimdir, az ile yetinen anlamına gelir.',
        tags: ['deyim', 'anlam'],
        subject: 'Türkçe',
        course: 'turkce',
        topic: 'deyimler',
        knowledgeType: 'terminology',
        points: 10,
      ),
    ];
  }

  /// Get Pharmacology (Farmakoloji) sample questions
  static List<Question> getFarmakolojiQuestions() {
    return [
      Question(
        id: 'pharm_001',
        text: 'Aşağıdakilerden hangisi NSAID (Nonsteroid Anti-inflamatuar İlaç) sınıfına aittir?',
        type: QuestionType.multipleChoice,
        difficulty: DifficultyLevel.intermediate,
        options: ['Paracetamol', 'Ibuprofen', 'Kodein', 'Diphenhydramine'],
        correctAnswer: 'Ibuprofen',
        explanation: 'Ibuprofen, NSAID sınıfına ait bir anti-inflamatuar ve analjezik ilaçtır.',
        tags: ['NSAID', 'anti-inflamatuar', 'analjezi'],
        subject: 'Farmakoloji',
        course: 'farmakoloji',
        topic: 'analjezikler',
        knowledgeType: 'side_effect',
        points: 15,
      ),
      Question(
        id: 'pharm_002',
        text: 'Hangi reseptör tipi kalp hızını düzenlemede rol oynar?',
        type: QuestionType.multipleChoice,
        difficulty: DifficultyLevel.advanced,
        options: ['α1-adrenerjik', 'β1-adrenerjik', 'Muskarinik', 'GABA'],
        correctAnswer: 'β1-adrenerjik',
        explanation: 'β1-adrenerjik reseptörler kalp kasında bulunur ve kalp hızını artırır.',
        tags: ['adrenerjik', 'kalp', 'reseptör'],
        subject: 'Farmakoloji',
        course: 'farmakoloji',
        topic: 'kardiyovaskuler',
        knowledgeType: 'pharmacodynamics',
        points: 20,
      ),
      Question(
        id: 'pharm_003',
        text: 'Parasetamolün primer etki mekanizması nedir?',
        type: QuestionType.multipleChoice,
        difficulty: DifficultyLevel.intermediate,
        options: ['COX-1 inhibisyonu', 'COX-2 inhibisyonu', 'Santral prostaglandin inhibisyonu', 'Opioid reseptör agonizmi'],
        correctAnswer: 'Santral prostaglandin inhibisyonu',
        explanation: 'Parasetamol primer olarak merkezi sinir sisteminde prostaglandin sentezini inhibe eder.',
        tags: ['paracetamol', 'analjezi', 'prostaglandin'],
        subject: 'Farmakoloji',
        course: 'farmakoloji',
        topic: 'analjezikler',
        knowledgeType: 'pharmacodynamics',
        points: 18,
      ),
      Question(
        id: 'pharm_004',
        text: 'Hangisi beta-bloker ilaç sınıfına aittir?',
        type: QuestionType.multipleChoice,
        difficulty: DifficultyLevel.intermediate,
        options: ['Amlodipine', 'Enalapril', 'Metoprolol', 'Furosemide'],
        correctAnswer: 'Metoprolol',
        explanation: 'Metoprolol, kardiyoselektif beta-1 bloker olarak kullanılan bir ilaçtır.',
        tags: ['beta-bloker', 'kardiyovasküler', 'hipertansiyon'],
        subject: 'Farmakoloji',
        course: 'farmakoloji',
        topic: 'kardiyovaskuler',
        knowledgeType: 'dosage',
        points: 15,
      ),
      Question(
        id: 'pharm_005',
        text: 'Morphine hangi reseptör tipine bağlanarak analjezik etki gösterir?',
        type: QuestionType.multipleChoice,
        difficulty: DifficultyLevel.advanced,
        options: ['μ-opioid reseptör', 'NMDA reseptör', 'GABA-A reseptör', 'Glycine reseptör'],
        correctAnswer: 'μ-opioid reseptör',
        explanation: 'Morphine, μ-opioid reseptörlerine bağlanarak güçlü analjezik etki gösterir.',
        tags: ['morphine', 'opioid', 'analjezi', 'reseptör'],
        subject: 'Farmakoloji',
        course: 'farmakoloji',
        topic: 'analjezikler',
        knowledgeType: 'pharmacodynamics',
        points: 22,
      ),
    ];
  }

  /// Get all sample questions
  static List<Question> getAllSampleQuestions() {
    return [
      ...getMathQuestions(),
      ...getTurkishQuestions(),
      ...getFarmakolojiQuestions(),
    ];
  }
}

/// Convenience variable for accessing sample questions
final List<Question> sampleQuestions = SampleQuestions.getAllSampleQuestions();
