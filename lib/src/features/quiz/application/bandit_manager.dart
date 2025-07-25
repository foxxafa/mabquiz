import 'dart:math';
import '../data/models/question.dart';

/// Multi-Armed Bandit algorithm for adaptive question selection
///
/// Uses Thompson Sampling algorithm to balance exploration vs exploitation
/// for optimal learning experience
class BanditManager {
  final Map<String, BanditArm> _arms = {};
  final Random _random = Random();

  /// Minimum number of attempts before algorithm becomes confident
  final int minAttempts;

  /// Learning rate for adapting to user performance
  final double learningRate;

  BanditManager({
    this.minAttempts = 3,
    this.learningRate = 0.1,
  });

  /// Initialize bandit arms for a set of questions
  void initializeQuestions(List<Question> questions) {
    for (final question in questions) {
      _arms[question.id] = BanditArm(
        questionId: question.id,
        difficulty: question.difficulty,
        initialConfidence: question.initialConfidence,
      );
    }
  }

  /// Select next question based on Thompson Sampling algorithm
  Question? selectNextQuestion(List<Question> availableQuestions) {
    if (availableQuestions.isEmpty) return null;

    // Ensure all questions are initialized
    for (final question in availableQuestions) {
      if (!_arms.containsKey(question.id)) {
        _arms[question.id] = BanditArm(
          questionId: question.id,
          difficulty: question.difficulty,
          initialConfidence: question.initialConfidence,
        );
      }
    }

    // Thompson Sampling: sample from Beta distribution for each arm
    String? bestQuestionId;
    double bestSample = -1;

    for (final question in availableQuestions) {
      final arm = _arms[question.id]!;
      final sample = _sampleFromBeta(arm.alpha, arm.beta);

      if (sample > bestSample) {
        bestSample = sample;
        bestQuestionId = question.id;
      }
    }

    return availableQuestions.firstWhere((q) => q.id == bestQuestionId);
  }

  /// Update bandit statistics based on user performance
  void updatePerformance({
    required String questionId,
    required bool isCorrect,
    required Duration responseTime,
    double? confidence,
  }) {
    final arm = _arms[questionId];
    if (arm == null) return;

    // Update success/failure counts
    if (isCorrect) {
      arm.successes++;
    } else {
      arm.failures++;
    }

    arm.attempts++;
    arm.totalResponseTime += responseTime.inMilliseconds;

    // Update confidence based on response time and correctness
    if (confidence != null) {
      arm.userConfidence = confidence;
    }

    // Adaptive learning: adjust parameters based on performance
    _updateArmParameters(arm, isCorrect, responseTime);
  }

  /// Get current statistics for a question
  QuestionStats? getQuestionStats(String questionId) {
    final arm = _arms[questionId];
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
      difficulty: arm.difficulty,
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
      final armA = _arms[a.id];
      final armB = _arms[b.id];

      if (armA == null && armB == null) return 0;
      if (armA == null) return 1;
      if (armB == null) return -1;

      // Prioritize questions with lower confidence or high error rate
      final priorityA = _calculateLearningPriority(armA);
      final priorityB = _calculateLearningPriority(armB);

      return priorityB.compareTo(priorityA); // Higher priority first
    });

    return sortedQuestions.take(count).toList();
  }

  /// Get overall learning statistics
  LearningStats getOverallStats() {
    int totalAttempts = 0;
    int totalSuccesses = 0;
    Duration totalTime = Duration.zero;

    for (final arm in _arms.values) {
      totalAttempts += arm.attempts;
      totalSuccesses += arm.successes;
      totalTime += Duration(milliseconds: arm.totalResponseTime);
    }

    return LearningStats(
      totalQuestions: _arms.length,
      totalAttempts: totalAttempts,
      totalSuccesses: totalSuccesses,
      overallSuccessRate: totalAttempts > 0 ? totalSuccesses / totalAttempts : 0.0,
      averageResponseTime: totalAttempts > 0
          ? Duration(milliseconds: totalTime.inMilliseconds ~/ totalAttempts)
          : Duration.zero,
      questionsAttempted: _arms.values.where((arm) => arm.attempts > 0).length,
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
    // Update Beta distribution parameters
    if (isCorrect) {
      arm.alpha += 1;
    } else {
      arm.beta += 1;
    }

    // Adjust parameters based on response time
    final timeBonus = _calculateTimeBonus(responseTime, arm.difficulty);
    if (isCorrect && timeBonus > 0) {
      arm.alpha += timeBonus * learningRate;
    }
  }

  double _calculateTimeBonus(Duration responseTime, DifficultyLevel difficulty) {
    // Expected time based on difficulty
    final expectedTime = switch (difficulty) {
      DifficultyLevel.beginner => Duration(seconds: 10),
      DifficultyLevel.intermediate => Duration(seconds: 20),
      DifficultyLevel.advanced => Duration(seconds: 30),
    };

    if (responseTime < expectedTime) {
      return (expectedTime.inMilliseconds - responseTime.inMilliseconds) /
             expectedTime.inMilliseconds;
    }

    return 0.0;
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
}

/// Represents a single arm in the multi-armed bandit
class BanditArm {
  final String questionId;
  final DifficultyLevel difficulty;

  int attempts = 0;
  int successes = 0;
  int failures = 0;
  int totalResponseTime = 0; // in milliseconds
  double userConfidence = 0.5;

  // Beta distribution parameters for Thompson Sampling
  double alpha = 1.0;
  double beta = 1.0;

  BanditArm({
    required this.questionId,
    required this.difficulty,
    required double initialConfidence,
  }) {
    userConfidence = initialConfidence;
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
  final DifficultyLevel difficulty;

  const QuestionStats({
    required this.questionId,
    required this.attempts,
    required this.successes,
    required this.failures,
    required this.averageResponseTime,
    required this.successRate,
    required this.confidence,
    required this.difficulty,
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
    return LearningInsights(
      bestCategory: 'Matematik',
      improvementArea: 'Temel Kavramlar',
      recommendedDifficulty: 'Orta',
      overallProgress: 0.0,
    );
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
