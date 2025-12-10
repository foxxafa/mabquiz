import '../../../../core/database/repositories/mab_repository.dart';
import '../../application/bandit_manager.dart';

/// Repository for persisting MAB state using SQLite
class BanditStateRepository {
  final MabRepository _mabRepository = MabRepository();

  // Get current user ID (should be injected or retrieved from auth state)
  String _getCurrentUserId() {
    // TODO: Get from actual auth service
    // For now, return a default user ID
    return 'default_user';
  }

  /// Save question arm state to SQLite
  Future<void> saveQuestionArmState(String questionId, BanditArm arm) async {
    try {
      final userId = _getCurrentUserId();
      await _mabRepository.updateQuestionArmStats(
        userId: userId,
        questionId: questionId,
        isCorrect: arm.successes > 0, // Simplified logic
        responseTimeMs: arm.totalResponseTime,
        userConfidence: arm.userConfidence,
        alpha: arm.alpha,
        beta: arm.beta,
      );
    } catch (e) {
      // Silent fail for persistence - don't break the app
      // ignore: avoid_print
      print('Warning: Failed to save question arm state: $e');
    }
  }

  /// Save topic arm state to SQLite
  Future<void> saveTopicArmState(String topicKey, TopicArm arm) async {
    try {
      final userId = _getCurrentUserId();
      await _mabRepository.updateTopicArmStats(
        userId: userId,
        topicKey: topicKey,
        topic: arm.topic,
        knowledgeType: arm.knowledgeType,
        course: arm.course,
        isCorrect: arm.successes > 0, // Simplified logic
        responseTimeMs: arm.totalResponseTime,
        alpha: arm.alpha,
        beta: arm.beta,
      );
    } catch (e) {
      // ignore: avoid_print
      print('Warning: Failed to save topic arm state: $e');
    }
  }

  /// Load question arm state from SQLite
  Future<BanditArm?> loadQuestionArmState(String questionId) async {
    try {
      final userId = _getCurrentUserId();
      final dbArm = await _mabRepository.getQuestionArm(userId, questionId);

      if (dbArm == null) return null;

      final arm = BanditArm(
        questionId: dbArm.questionId,
        initialConfidence: dbArm.userConfidence,
      );

      // Restore state from database
      arm.attempts = dbArm.attempts;
      arm.successes = dbArm.successes;
      arm.failures = dbArm.failures;
      arm.totalResponseTime = dbArm.totalResponseTime;
      arm.userConfidence = dbArm.userConfidence;
      arm.alpha = dbArm.alpha;
      arm.beta = dbArm.beta;
      arm.lastAttempted = dbArm.lastAttempted != null
          ? DateTime.fromMillisecondsSinceEpoch(dbArm.lastAttempted!)
          : null;

      return arm;
    } catch (e) {
      // ignore: avoid_print
      print('Warning: Failed to load question arm state: $e');
      return null;
    }
  }

  /// Load topic arm state from SQLite
  Future<TopicArm?> loadTopicArmState(String topicKey) async {
    try {
      final userId = _getCurrentUserId();
      final dbArm = await _mabRepository.getTopicArm(userId, topicKey);

      if (dbArm == null) return null;

      final arm = TopicArm(
        topicKey: dbArm.topicKey,
        topic: dbArm.topic,
        knowledgeType: dbArm.knowledgeType,
        course: dbArm.course,
      );

      // Restore state from database
      arm.attempts = dbArm.attempts;
      arm.successes = dbArm.successes;
      arm.failures = dbArm.failures;
      arm.totalResponseTime = dbArm.totalResponseTime;
      arm.alpha = dbArm.alpha;
      arm.beta = dbArm.beta;

      return arm;
    } catch (e) {
      // ignore: avoid_print
      print('Warning: Failed to load topic arm state: $e');
      return null;
    }
  }

  /// Load all question arms for current user
  Future<Map<String, BanditArm>> loadAllQuestionArms() async {
    try {
      final userId = _getCurrentUserId();
      final dbArms = await _mabRepository.getAllQuestionArms(userId);

      final arms = <String, BanditArm>{};
      for (final dbArm in dbArms) {
        final arm = BanditArm(
          questionId: dbArm.questionId,
          initialConfidence: dbArm.userConfidence,
        );

        arm.attempts = dbArm.attempts;
        arm.successes = dbArm.successes;
        arm.failures = dbArm.failures;
        arm.totalResponseTime = dbArm.totalResponseTime;
        arm.userConfidence = dbArm.userConfidence;
        arm.alpha = dbArm.alpha;
        arm.beta = dbArm.beta;
        arm.lastAttempted = dbArm.lastAttempted != null
            ? DateTime.fromMillisecondsSinceEpoch(dbArm.lastAttempted!)
            : null;

        arms[dbArm.questionId] = arm;
      }

      return arms;
    } catch (e) {
      // ignore: avoid_print
      print('Warning: Failed to load all question arms: $e');
      return {};
    }
  }

  /// Load all topic arms for current user
  Future<Map<String, TopicArm>> loadAllTopicArms() async {
    try {
      final userId = _getCurrentUserId();
      final dbArms = await _mabRepository.getAllTopicArms(userId);

      final arms = <String, TopicArm>{};
      for (final dbArm in dbArms) {
        final arm = TopicArm(
          topicKey: dbArm.topicKey,
          topic: dbArm.topic,
          knowledgeType: dbArm.knowledgeType,
          course: dbArm.course,
        );

        arm.attempts = dbArm.attempts;
        arm.successes = dbArm.successes;
        arm.failures = dbArm.failures;
        arm.totalResponseTime = dbArm.totalResponseTime;
        arm.alpha = dbArm.alpha;
        arm.beta = dbArm.beta;

        arms[dbArm.topicKey] = arm;
      }

      return arms;
    } catch (e) {
      // ignore: avoid_print
      print('Warning: Failed to load all topic arms: $e');
      return {};
    }
  }

  /// Clear all persisted MAB data for current user
  Future<void> clearAllState() async {
    try {
      final userId = _getCurrentUserId();
      await _mabRepository.deleteAllQuestionArms(userId);
      await _mabRepository.deleteAllTopicArms(userId);
    } catch (e) {
      // ignore: avoid_print
      print('Warning: Failed to clear state: $e');
    }
  }

  /// Get MAB statistics
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final userId = _getCurrentUserId();
      return await _mabRepository.getMabStats(userId);
    } catch (e) {
      // ignore: avoid_print
      print('Warning: Failed to get statistics: $e');
      return {};
    }
  }

  /// Get questions that need practice
  Future<List<String>> getWeakQuestionIds({
    double threshold = 0.6,
    int minAttempts = 3,
  }) async {
    try {
      final userId = _getCurrentUserId();
      final weakQuestions = await _mabRepository.getWeakQuestions(
        userId,
        threshold: threshold,
        minAttempts: minAttempts,
      );
      return weakQuestions.map((q) => q.questionId).toList();
    } catch (e) {
      // ignore: avoid_print
      print('Warning: Failed to get weak questions: $e');
      return [];
    }
  }

  /// Get topics that need practice
  Future<List<String>> getWeakTopicKeys({
    double threshold = 0.6,
    int minAttempts = 5,
  }) async {
    try {
      final userId = _getCurrentUserId();
      final weakTopics = await _mabRepository.getWeakTopics(
        userId,
        threshold: threshold,
        minAttempts: minAttempts,
      );
      return weakTopics.map((t) => t.topicKey).toList();
    } catch (e) {
      // ignore: avoid_print
      print('Warning: Failed to get weak topics: $e');
      return [];
    }
  }
}