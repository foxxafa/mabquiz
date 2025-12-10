import 'dart:math';
import '../domain/entities/question.dart';
import '../../../core/database/repositories/mab_repository.dart';
import '../../../core/database/models/mab_question_arm_db_model.dart';
import '../../../core/database/models/mab_topic_arm_db_model.dart';

/// Multi-Armed Bandit algorithm for adaptive question selection
///
/// Uses Thompson Sampling algorithm to balance exploration vs exploitation
/// for optimal learning experience
class BanditManager {
  final Map<String, BanditArm> _questionArms = {};
  final Map<String, TopicArm> _topicArms = {};
  final Random _random = Random();

  /// Repository for persistent storage
  final MabRepository _repository = MabRepository();

  /// Current user ID for database operations
  String? _userId;

  /// Whether data has been loaded from database
  bool _isLoaded = false;

  /// Minimum number of attempts before algorithm becomes confident
  final int minAttempts;

  /// Learning rate for adapting to user performance
  final double learningRate;

  BanditManager({
    this.minAttempts = 3,
    this.learningRate = 0.1,
  });

  /// Set user ID and load existing data from database
  Future<void> setUserId(String userId) async {
    if (_userId == userId && _isLoaded) return;

    _userId = userId;
    await _loadFromDatabase();
  }

  /// Load MAB state from database
  Future<void> _loadFromDatabase() async {
    if (_userId == null) return;

    try {
      // Load question arms
      final questionArms = await _repository.getAllQuestionArms(_userId!);
      for (final dbArm in questionArms) {
        _questionArms[dbArm.questionId] = BanditArm.fromDbModel(dbArm);
      }

      // Load topic arms
      final topicArms = await _repository.getAllTopicArms(_userId!);
      for (final dbArm in topicArms) {
        _topicArms[dbArm.topicKey] = TopicArm.fromDbModel(dbArm);
      }

      _isLoaded = true;
    } catch (e) {
      // Log error but continue - will use in-memory state
      _isLoaded = true;
    }
  }

  /// Initialize bandit arms for a set of questions
  /// Only creates new arms if they don't already exist (preserves database data)
  void initializeQuestions(List<Question> questions) {
    for (final question in questions) {
      // Only create if not already loaded from database
      _questionArms.putIfAbsent(question.id, () => BanditArm(
        questionId: question.id,
        initialConfidence: question.initialConfidence,
      ));

      // Initialize topic-level arms (only if not exists)
      final topicKey = question.mabKey;
      _topicArms.putIfAbsent(topicKey, () => TopicArm(
        topicKey: topicKey,
        topic: question.topic,
        knowledgeType: question.knowledgeType,
        course: question.course,
      ));
    }
  }

  /// Select next question based on Thompson Sampling algorithm
  Question? selectNextQuestion(List<Question> availableQuestions) {
    if (availableQuestions.isEmpty) return null;

    // Ensure all questions are initialized
    for (final question in availableQuestions) {
      if (!_questionArms.containsKey(question.id)) {
        _questionArms[question.id] = BanditArm(
          questionId: question.id,
          initialConfidence: question.initialConfidence,
        );

        final topicKey = question.mabKey;
        _topicArms.putIfAbsent(topicKey, () => TopicArm(
          topicKey: topicKey,
          topic: question.topic,
          knowledgeType: question.knowledgeType,
          course: question.course,
        ));
      }
    }

    // Enhanced Thompson Sampling with topic-awareness
    return _selectQuestionWithTopicAwareness(availableQuestions);
  }

  /// Update bandit statistics based on user performance
  Future<void> updatePerformance({
    required String questionId,
    required bool isCorrect,
    required Duration responseTime,
    double? confidence,
    Question? question,
  }) async {
    final arm = _questionArms[questionId];
    if (arm == null) return;

    // Update question-level statistics
    if (isCorrect) {
      arm.successes++;
    } else {
      arm.failures++;
    }

    arm.attempts++;
    arm.totalResponseTime += responseTime.inMilliseconds;
    arm.lastAttempted = DateTime.now(); // Track last attempt time

    if (confidence != null) {
      arm.userConfidence = confidence;
    }

    _updateArmParameters(arm, isCorrect, responseTime);

    // Save to database
    if (question != null) {
      await _saveQuestionArmDirectly(arm, question, isCorrect, responseTime);
    }

    // Update topic-level statistics
    if (question != null) {
      await _updateTopicPerformance(question, isCorrect, responseTime);
    }
  }

  /// Save question arm directly to database with actual values
  Future<void> _saveQuestionArmDirectly(
    BanditArm arm,
    Question question,
    bool isCorrect,
    Duration responseTime,
  ) async {
    if (_userId == null) {
      print('⚠️ BanditManager: userId null, veritabanına kaydedilemiyor!');
      return;
    }

    try {
      print('💾 BanditManager: Veritabanına kaydediliyor - userId: $_userId, questionId: ${arm.questionId}, isCorrect: $isCorrect, responseTime: ${responseTime.inMilliseconds}ms');
      await _repository.updateQuestionArmStats(
        userId: _userId!,
        questionId: arm.questionId,
        isCorrect: isCorrect,
        responseTimeMs: responseTime.inMilliseconds,
        userConfidence: arm.userConfidence,
        alpha: arm.alpha,
        beta: arm.beta,
        // Pass already-calculated values to avoid double counting
        attempts: arm.attempts,
        successes: arm.successes,
        failures: arm.failures,
        totalResponseTime: arm.totalResponseTime,
      );
      print('✅ BanditManager: Soru performansı veritabanına kaydedildi! (attempts: ${arm.attempts}, successes: ${arm.successes})');
    } catch (e) {
      print('❌ BanditManager: Veritabanı kayıt hatası: $e');
    }
  }

  /// Get current statistics for a question
  QuestionStats? getQuestionStats(String questionId) {
    final arm = _questionArms[questionId];
    if (arm == null) return null;

    return QuestionStats(
      questionId: questionId,
      attempts: arm.attempts,
      successes: arm.successes,
      failures: arm.failures,
      averageResponseTime: arm.attempts > 0
          ? Duration(milliseconds: arm.totalResponseTime ~/ arm.attempts)
          : Duration.zero,
      successRate: arm.attempts > 0 ? arm.successes / arm.attempts : 0.0,
      confidence: _calculateConfidence(arm),
    );
  }
  
  /// Get topic-level statistics
  TopicStats? getTopicStats(String topicKey) {
    final arm = _topicArms[topicKey];
    if (arm == null) return null;

    return TopicStats(
      topicKey: topicKey,
      topic: arm.topic,
      knowledgeType: arm.knowledgeType,
      attempts: arm.attempts,
      successes: arm.successes,
      failures: arm.failures,
      averageResponseTime: arm.attempts > 0
          ? Duration(milliseconds: arm.totalResponseTime ~/ arm.attempts)
          : Duration.zero,
      successRate: arm.attempts > 0 ? arm.successes / arm.attempts : 0.0,
      confidence: _calculateTopicConfidence(arm),
    );
  }

  /// Get recommendations for next study session
  List<Question> getRecommendedQuestions(
    List<Question> allQuestions, {
    int count = 5,
    DifficultyLevel? targetDifficulty,
  }) {
    // Sort questions by learning priority
    final sortedQuestions = allQuestions.where((q) {
      if (targetDifficulty != null && q.difficulty != targetDifficulty) {
        return false;
      }
      return true;
    }).toList();

    sortedQuestions.sort((a, b) {
      final armA = _questionArms[a.id];
      final armB = _questionArms[b.id];
      final topicA = _topicArms[a.mabKey];
      final topicB = _topicArms[b.mabKey];

      if (armA == null && armB == null) return 0;
      if (armA == null) return 1;
      if (armB == null) return -1;

      // Combined priority: question-level + topic-level
      final priorityA = _calculateCombinedPriority(armA, topicA);
      final priorityB = _calculateCombinedPriority(armB, topicB);

      return priorityB.compareTo(priorityA); // Higher priority first
    });

    return sortedQuestions.take(count).toList();
  }

  /// Get overall learning statistics
  LearningStats getOverallStats() {
    int totalAttempts = 0;
    int totalSuccesses = 0;
    Duration totalTime = Duration.zero;

    for (final arm in _questionArms.values) {
      totalAttempts += arm.attempts;
      totalSuccesses += arm.successes;
      totalTime += Duration(milliseconds: arm.totalResponseTime);
    }

    return LearningStats(
      totalQuestions: _questionArms.length,
      totalAttempts: totalAttempts,
      totalSuccesses: totalSuccesses,
      overallSuccessRate: totalAttempts > 0 ? totalSuccesses / totalAttempts : 0.0,
      averageResponseTime: totalAttempts > 0
          ? Duration(milliseconds: totalTime.inMilliseconds ~/ totalAttempts)
          : Duration.zero,
      questionsAttempted: _questionArms.values.where((arm) => arm.attempts > 0).length,
    );
  }

  // Private helper methods

  double _sampleFromBeta(double alpha, double beta) {
    if (alpha <= 1 && beta <= 1) {
      // Use uniform distribution for insufficient data
      return _random.nextDouble();
    }

    // Simplified Beta distribution sampling using Gamma distributions
    final x = _sampleFromGamma(alpha);
    final y = _sampleFromGamma(beta);
    return x / (x + y);
  }

  double _sampleFromGamma(double shape) {
    if (shape < 1) {
      return _sampleFromGamma(shape + 1) * pow(_random.nextDouble(), 1 / shape);
    }

    // Marsaglia and Tsang's algorithm
    final d = shape - 1.0 / 3.0;
    final c = 1.0 / sqrt(9.0 * d);

    while (true) {
      double x, v;
      do {
        x = _randomNormal();
        v = 1.0 + c * x;
      } while (v <= 0);

      v = v * v * v;
      final u = _random.nextDouble();

      if (u < 1.0 - 0.0331 * x * x * x * x) {
        return d * v;
      }

      if (log(u) < 0.5 * x * x + d * (1.0 - v + log(v))) {
        return d * v;
      }
    }
  }

  double? _spare; // Instance variable for Box-Muller

  double _randomNormal() {
    // Box-Muller transform
    if (_spare != null) {
      final result = _spare!;
      _spare = null;
      return result;
    }

    final u = _random.nextDouble();
    final v = _random.nextDouble();
    final mag = sqrt(-2.0 * log(u));
    _spare = mag * cos(2.0 * pi * v);
    return mag * sin(2.0 * pi * v);
  }

  void _updateArmParameters(BanditArm arm, bool isCorrect, Duration responseTime) {
    // Expected time (default: 15 seconds)
    const expectedTime = Duration(seconds: 15);

    if (isCorrect) {
      // Correct answer
      arm.alpha += 1;

      // Bonus for fast correct answers
      if (responseTime < expectedTime) {
        final timeBonus = (expectedTime.inMilliseconds - responseTime.inMilliseconds) /
                         expectedTime.inMilliseconds;
        arm.alpha += timeBonus * learningRate;
      }
    } else {
      // Wrong answer
      arm.beta += 1;

      // Extra penalty for slow wrong answers (indicates struggling)
      if (responseTime > expectedTime) {
        arm.beta += 0.3;
      }
    }
  }

  double _calculateConfidence(BanditArm arm) {
    if (arm.attempts < minAttempts) {
      return 0.5; // Neutral confidence
    }

    // Use Wilson score interval for confidence
    final successRate = arm.successes / arm.attempts;
    final n = arm.attempts.toDouble();
    final z = 1.96; // 95% confidence

    final center = successRate + z * z / (2 * n);
    final margin = z * sqrt((successRate * (1 - successRate) + z * z / (4 * n)) / n);
    final denominator = 1 + z * z / n;

    return (center - margin) / denominator;
  }

  double _calculateLearningPriority(BanditArm arm) {
    if (arm.attempts == 0) return 1.0; // Highest priority for unattempted

    final successRate = arm.successes / arm.attempts;
    final confidence = _calculateConfidence(arm);

    // Higher priority for:
    // 1. Low success rate (need more practice)
    // 2. Low confidence (uncertainty)
    // 3. Few attempts (exploration)

    final errorRate = 1.0 - successRate;
    final uncertainty = 1.0 - confidence;
    final exploration = max(0.0, 1.0 - arm.attempts / 10.0);

    return (errorRate * 0.4) + (uncertainty * 0.4) + (exploration * 0.2);
  }

  // New methods for topic-aware MAB
  
  Question? _selectQuestionWithTopicAwareness(List<Question> availableQuestions) {
    // Group questions by topic
    final topicGroups = <String, List<Question>>{};
    for (final question in availableQuestions) {
      topicGroups.putIfAbsent(question.mabKey, () => []).add(question);
    }

    // Select topic first using Thompson Sampling
    String? bestTopicKey;
    double bestTopicSample = -1;

    for (final topicKey in topicGroups.keys) {
      final topicArm = _topicArms[topicKey];
      if (topicArm == null) continue;

      final sample = _sampleFromBeta(topicArm.alpha, topicArm.beta);
      if (sample > bestTopicSample) {
        bestTopicSample = sample;
        bestTopicKey = topicKey;
      }
    }

    if (bestTopicKey == null) {
      return availableQuestions.first;
    }

    // Select best question from chosen topic
    final topicQuestions = topicGroups[bestTopicKey]!;
    String? bestQuestionId;
    double bestQuestionSample = -1;

    for (final question in topicQuestions) {
      final arm = _questionArms[question.id]!;
      // Use decayed parameters for temporal forgetting
      final decayedAlpha = arm.getDecayedAlpha();
      final decayedBeta = arm.getDecayedBeta();
      final sample = _sampleFromBeta(decayedAlpha, decayedBeta);

      if (sample > bestQuestionSample) {
        bestQuestionSample = sample;
        bestQuestionId = question.id;
      }
    }

    return topicQuestions.firstWhere((q) => q.id == bestQuestionId);
  }

  Future<void> _updateTopicPerformance(Question question, bool isCorrect, Duration responseTime) async {
    final topicArm = _topicArms[question.mabKey];
    if (topicArm == null) return;

    if (isCorrect) {
      topicArm.successes++;
      topicArm.alpha += 1;
    } else {
      topicArm.failures++;
      topicArm.beta += 1;
    }

    topicArm.attempts++;
    topicArm.totalResponseTime += responseTime.inMilliseconds;

    // Save to database
    await _saveTopicArmDirectly(topicArm, isCorrect, responseTime);
  }

  /// Save topic arm directly to database with actual values
  Future<void> _saveTopicArmDirectly(
    TopicArm arm,
    bool isCorrect,
    Duration responseTime,
  ) async {
    if (_userId == null) return;

    try {
      await _repository.updateTopicArmStats(
        userId: _userId!,
        topicKey: arm.topicKey,
        topic: arm.topic,
        knowledgeType: arm.knowledgeType,
        course: arm.course,
        isCorrect: isCorrect,
        responseTimeMs: responseTime.inMilliseconds,
        alpha: arm.alpha,
        beta: arm.beta,
      );
    } catch (e) {
      // Log error but continue
    }
  }

  double _calculateTopicConfidence(TopicArm arm) {
    if (arm.attempts < minAttempts) {
      return 0.5;
    }

    final successRate = arm.successes / arm.attempts;
    final n = arm.attempts.toDouble();
    final z = 1.96;

    final center = successRate + z * z / (2 * n);
    final margin = z * sqrt((successRate * (1 - successRate) + z * z / (4 * n)) / n);
    final denominator = 1 + z * z / n;

    return (center - margin) / denominator;
  }

  double _calculateCombinedPriority(BanditArm questionArm, TopicArm? topicArm) {
    final questionPriority = _calculateLearningPriority(questionArm);
    
    if (topicArm == null) return questionPriority;
    
    final topicPriority = topicArm.attempts == 0 
        ? 1.0 
        : (1.0 - (topicArm.successes / topicArm.attempts)) * 0.6;
    
    return (questionPriority * 0.7) + (topicPriority * 0.3);
  }

  LearningInsights _calculateRealLearningInsights() {
    if (_topicArms.isEmpty) {
      return LearningInsights(
        bestCategory: 'Henüz veri yok',
        improvementArea: 'Daha fazla soru çözün',
        recommendedDifficulty: 'intermediate',
        overallProgress: 0.0,
      );
    }

    // Find best and worst performing topics
    TopicArm? bestTopic;
    TopicArm? worstTopic;
    double bestRate = -1;
    double worstRate = 2;
    double totalProgress = 0;
    int totalAttempts = 0;

    for (final arm in _topicArms.values) {
      if (arm.attempts < 3) continue; // Need minimum attempts

      final rate = arm.successes / arm.attempts;
      if (rate > bestRate) {
        bestRate = rate;
        bestTopic = arm;
      }
      if (rate < worstRate) {
        worstRate = rate;
        worstTopic = arm;
      }
      
      totalProgress += rate;
      totalAttempts++;
    }

    return LearningInsights(
      bestCategory: bestTopic?.topic ?? 'Henüz belirlenmedi',
      improvementArea: worstTopic?.topic ?? 'Daha fazla pratik',
      recommendedDifficulty: _getRecommendedDifficulty(),
      overallProgress: totalAttempts > 0 ? (totalProgress / totalAttempts) * 100 : 0.0,
    );
  }

  String _getRecommendedDifficulty() {
    final overallStats = getOverallStats();
    if (overallStats.overallSuccessRate > 0.8) return 'advanced';
    if (overallStats.overallSuccessRate > 0.6) return 'intermediate';
    return 'beginner';
  }
}

/// Represents a single arm in the multi-armed bandit
class BanditArm {
  final String questionId;

  int attempts = 0;
  int successes = 0;
  int failures = 0;
  int totalResponseTime = 0; // in milliseconds
  double userConfidence = 0.5;
  DateTime? lastAttempted;

  // Beta distribution parameters for Thompson Sampling
  // Neutral prior: α=1, β=1 (uniform distribution)
  double alpha = 1.0;
  double beta = 1.0;

  BanditArm({
    required this.questionId,
    double initialConfidence = 0.5,
  }) {
    userConfidence = initialConfidence;
    // Neutral prior - no assumptions about difficulty
    alpha = 1.0;
    beta = 1.0;
  }

  /// Create from database model
  factory BanditArm.fromDbModel(MabQuestionArmDbModel dbModel) {
    final arm = BanditArm(
      questionId: dbModel.questionId,
      initialConfidence: dbModel.userConfidence,
    );

    // Restore state from database
    arm.attempts = dbModel.attempts;
    arm.successes = dbModel.successes;
    arm.failures = dbModel.failures;
    arm.totalResponseTime = dbModel.totalResponseTime;
    arm.userConfidence = dbModel.userConfidence;
    arm.alpha = dbModel.alpha;
    arm.beta = dbModel.beta;
    arm.lastAttempted = dbModel.lastAttempted != null
        ? DateTime.fromMillisecondsSinceEpoch(dbModel.lastAttempted!)
        : null;

    return arm;
  }

  /// Get success rate with temporal decay (forgetting curve)
  double getDecayedSuccessRate() {
    if (attempts == 0) return alpha / (alpha + beta);

    final rawSuccessRate = successes / attempts;

    // If never attempted or very recent, no decay
    if (lastAttempted == null) return rawSuccessRate;

    final daysSinceLastAttempt =
        DateTime.now().difference(lastAttempted!).inDays;

    // Ebbinghaus forgetting curve: decay over 30 days
    final decayFactor = exp(-daysSinceLastAttempt / 30.0);

    // Blend between current performance and neutral (0.5)
    return rawSuccessRate * decayFactor + 0.5 * (1 - decayFactor);
  }

  /// Get alpha parameter with temporal decay
  double getDecayedAlpha() {
    if (lastAttempted == null) return alpha;

    final daysSinceLastAttempt =
        DateTime.now().difference(lastAttempted!).inDays;
    final decayFactor = exp(-daysSinceLastAttempt / 30.0);

    // Regress toward neutral prior (1.0)
    return alpha * decayFactor + 1.0 * (1 - decayFactor);
  }

  /// Get beta parameter with temporal decay
  double getDecayedBeta() {
    if (lastAttempted == null) return beta;

    final daysSinceLastAttempt =
        DateTime.now().difference(lastAttempted!).inDays;
    final decayFactor = exp(-daysSinceLastAttempt / 30.0);

    // Regress toward neutral prior (1.0)
    return beta * decayFactor + 1.0 * (1 - decayFactor);
  }
}

/// Represents a topic-level arm for hierarchical MAB
class TopicArm {
  final String topicKey;
  final String topic;
  final String knowledgeType;
  final String course;

  int attempts = 0;
  int successes = 0;
  int failures = 0;
  int totalResponseTime = 0;

  // Beta distribution parameters for Thompson Sampling
  double alpha = 1.0;
  double beta = 1.0;

  TopicArm({
    required this.topicKey,
    required this.topic,
    required this.knowledgeType,
    required this.course,
  });

  /// Create from database model
  factory TopicArm.fromDbModel(MabTopicArmDbModel dbModel) {
    final arm = TopicArm(
      topicKey: dbModel.topicKey,
      topic: dbModel.topic,
      knowledgeType: dbModel.knowledgeType,
      course: dbModel.course,
    );

    // Restore state from database
    arm.attempts = dbModel.attempts;
    arm.successes = dbModel.successes;
    arm.failures = dbModel.failures;
    arm.totalResponseTime = dbModel.totalResponseTime;
    arm.alpha = dbModel.alpha;
    arm.beta = dbModel.beta;

    return arm;
  }
}

/// Statistics for a specific question
class QuestionStats {
  final String questionId;
  final int attempts;
  final int successes;
  final int failures;
  final Duration averageResponseTime;
  final double successRate;
  final double confidence;

  const QuestionStats({
    required this.questionId,
    required this.attempts,
    required this.successes,
    required this.failures,
    required this.averageResponseTime,
    required this.successRate,
    required this.confidence,
  });
}

/// Statistics for a specific topic
class TopicStats {
  final String topicKey;
  final String topic;
  final String knowledgeType;
  final int attempts;
  final int successes;
  final int failures;
  final Duration averageResponseTime;
  final double successRate;
  final double confidence;

  const TopicStats({
    required this.topicKey,
    required this.topic,
    required this.knowledgeType,
    required this.attempts,
    required this.successes,
    required this.failures,
    required this.averageResponseTime,
    required this.successRate,
    required this.confidence,
  });
}

/// Overall learning statistics
class LearningStats {
  final int totalQuestions;
  final int totalAttempts;
  final int totalSuccesses;
  final double overallSuccessRate;
  final Duration averageResponseTime;
  final int questionsAttempted;

  const LearningStats({
    required this.totalQuestions,
    required this.totalAttempts,
    required this.totalSuccesses,
    required this.overallSuccessRate,
    required this.averageResponseTime,
    required this.questionsAttempted,
  });
}

extension BanditManagerExtensions on BanditManager {
  /// Recommend a question based on current learning state
  Question? recommendQuestion(List<String> answeredQuestionIds) {
    // For now, use simple question selection until we integrate with actual questions
    // This is a placeholder implementation
    return null;
  }

  /// Report the result of answering a question
  void reportResult(String questionId, bool isCorrect) {
    // Update the bandit with the result using the existing methods
    updatePerformance(
      questionId: questionId,
      isCorrect: isCorrect,
      responseTime: const Duration(seconds: 1), // Default response time
    );
  }

  /// Get comprehensive learning insights
  LearningInsights getLearningInsights() {
    return _calculateRealLearningInsights();
  }
}

/// Learning insights for user feedback
class LearningInsights {
  final String bestCategory;
  final String improvementArea;
  final String recommendedDifficulty;
  final double overallProgress;

  LearningInsights({
    required this.bestCategory,
    required this.improvementArea,
    required this.recommendedDifficulty,
    required this.overallProgress,
  });
}
