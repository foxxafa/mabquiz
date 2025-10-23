import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../models/mab_question_arm_db_model.dart';
import '../models/mab_topic_arm_db_model.dart';

/// Repository for MAB (Multi-Armed Bandit) state management
class MabRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ==================== Question Arms ====================

  /// Save or update a question arm
  Future<void> saveQuestionArm(MabQuestionArmDbModel arm) async {
    final db = await _dbHelper.database;
    await db.insert(
      'mab_question_arms',
      arm.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get a question arm for a specific user and question
  Future<MabQuestionArmDbModel?> getQuestionArm(
    String userId,
    String questionId,
  ) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'mab_question_arms',
      where: 'user_id = ? AND question_id = ?',
      whereArgs: [userId, questionId],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return MabQuestionArmDbModel.fromMap(results.first);
  }

  /// Get all question arms for a user
  Future<List<MabQuestionArmDbModel>> getAllQuestionArms(String userId) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'mab_question_arms',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'last_updated DESC',
    );

    return results.map((map) => MabQuestionArmDbModel.fromMap(map)).toList();
  }

  /// Update question arm statistics after user response
  Future<void> updateQuestionArmStats({
    required String userId,
    required String questionId,
    required String difficulty,
    required bool isCorrect,
    required int responseTimeMs,
    required double userConfidence,
    required double alpha,
    required double beta,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    // Try to get existing arm
    final existing = await getQuestionArm(userId, questionId);

    if (existing != null) {
      // Update existing arm
      final updated = existing.copyWith(
        attempts: existing.attempts + 1,
        successes: isCorrect ? existing.successes + 1 : existing.successes,
        failures: !isCorrect ? existing.failures + 1 : existing.failures,
        totalResponseTime: existing.totalResponseTime + responseTimeMs,
        userConfidence: userConfidence,
        alpha: alpha,
        beta: beta,
        lastAttempted: now, // Track when last attempted
        lastUpdated: now,
        isSynced: false,
      );
      await saveQuestionArm(updated);
    } else {
      // Create new arm
      final newArm = MabQuestionArmDbModel(
        userId: userId,
        questionId: questionId,
        difficulty: difficulty,
        attempts: 1,
        successes: isCorrect ? 1 : 0,
        failures: isCorrect ? 0 : 1,
        totalResponseTime: responseTimeMs,
        userConfidence: userConfidence,
        alpha: alpha,
        beta: beta,
        lastAttempted: now, // Track when last attempted
        lastUpdated: now,
        createdAt: now,
      );
      await saveQuestionArm(newArm);
    }
  }

  /// Delete a question arm
  Future<void> deleteQuestionArm(String userId, String questionId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'mab_question_arms',
      where: 'user_id = ? AND question_id = ?',
      whereArgs: [userId, questionId],
    );
  }

  /// Delete all question arms for a user
  Future<void> deleteAllQuestionArms(String userId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'mab_question_arms',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  // ==================== Topic Arms ====================

  /// Save or update a topic arm
  Future<void> saveTopicArm(MabTopicArmDbModel arm) async {
    final db = await _dbHelper.database;
    await db.insert(
      'mab_topic_arms',
      arm.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get a topic arm for a specific user and topic
  Future<MabTopicArmDbModel?> getTopicArm(
    String userId,
    String topicKey,
  ) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'mab_topic_arms',
      where: 'user_id = ? AND topic_key = ?',
      whereArgs: [userId, topicKey],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return MabTopicArmDbModel.fromMap(results.first);
  }

  /// Get all topic arms for a user
  Future<List<MabTopicArmDbModel>> getAllTopicArms(String userId) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'mab_topic_arms',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'last_updated DESC',
    );

    return results.map((map) => MabTopicArmDbModel.fromMap(map)).toList();
  }

  /// Get topic arms for a specific course
  Future<List<MabTopicArmDbModel>> getTopicArmsByCourse(
    String userId,
    String course,
  ) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'mab_topic_arms',
      where: 'user_id = ? AND course = ?',
      whereArgs: [userId, course],
      orderBy: 'last_updated DESC',
    );

    return results.map((map) => MabTopicArmDbModel.fromMap(map)).toList();
  }

  /// Update topic arm statistics
  Future<void> updateTopicArmStats({
    required String userId,
    required String topicKey,
    required String topic,
    required String knowledgeType,
    required String course,
    required bool isCorrect,
    required int responseTimeMs,
    required double alpha,
    required double beta,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    // Try to get existing arm
    final existing = await getTopicArm(userId, topicKey);

    if (existing != null) {
      // Update existing arm
      final updated = existing.copyWith(
        attempts: existing.attempts + 1,
        successes: isCorrect ? existing.successes + 1 : existing.successes,
        failures: !isCorrect ? existing.failures + 1 : existing.failures,
        totalResponseTime: existing.totalResponseTime + responseTimeMs,
        alpha: alpha,
        beta: beta,
        lastUpdated: now,
        isSynced: false,
      );
      await saveTopicArm(updated);
    } else {
      // Create new arm
      final newArm = MabTopicArmDbModel(
        userId: userId,
        topicKey: topicKey,
        topic: topic,
        knowledgeType: knowledgeType,
        course: course,
        attempts: 1,
        successes: isCorrect ? 1 : 0,
        failures: isCorrect ? 0 : 1,
        totalResponseTime: responseTimeMs,
        alpha: alpha,
        beta: beta,
        lastUpdated: now,
        createdAt: now,
      );
      await saveTopicArm(newArm);
    }
  }

  /// Delete a topic arm
  Future<void> deleteTopicArm(String userId, String topicKey) async {
    final db = await _dbHelper.database;
    await db.delete(
      'mab_topic_arms',
      where: 'user_id = ? AND topic_key = ?',
      whereArgs: [userId, topicKey],
    );
  }

  /// Delete all topic arms for a user
  Future<void> deleteAllTopicArms(String userId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'mab_topic_arms',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  // ==================== Statistics & Analytics ====================

  /// Get question arms with low success rate (need practice)
  Future<List<MabQuestionArmDbModel>> getWeakQuestions(
    String userId, {
    double threshold = 0.6,
    int minAttempts = 3,
  }) async {
    final db = await _dbHelper.database;
    final results = await db.rawQuery('''
      SELECT * FROM mab_question_arms
      WHERE user_id = ?
        AND attempts >= ?
        AND (CAST(successes AS REAL) / attempts) < ?
      ORDER BY (CAST(successes AS REAL) / attempts) ASC
    ''', [userId, minAttempts, threshold]);

    return results.map((map) => MabQuestionArmDbModel.fromMap(map)).toList();
  }

  /// Get topic arms with low success rate
  Future<List<MabTopicArmDbModel>> getWeakTopics(
    String userId, {
    double threshold = 0.6,
    int minAttempts = 5,
  }) async {
    final db = await _dbHelper.database;
    final results = await db.rawQuery('''
      SELECT * FROM mab_topic_arms
      WHERE user_id = ?
        AND attempts >= ?
        AND (CAST(successes AS REAL) / attempts) < ?
      ORDER BY (CAST(successes AS REAL) / attempts) ASC
    ''', [userId, minAttempts, threshold]);

    return results.map((map) => MabTopicArmDbModel.fromMap(map)).toList();
  }

  /// Get best performing topics
  Future<List<MabTopicArmDbModel>> getBestTopics(
    String userId, {
    int minAttempts = 5,
    int limit = 5,
  }) async {
    final db = await _dbHelper.database;
    final results = await db.rawQuery('''
      SELECT * FROM mab_topic_arms
      WHERE user_id = ?
        AND attempts >= ?
      ORDER BY (CAST(successes AS REAL) / attempts) DESC
      LIMIT ?
    ''', [userId, minAttempts, limit]);

    return results.map((map) => MabTopicArmDbModel.fromMap(map)).toList();
  }

  /// Get overall MAB statistics
  Future<Map<String, dynamic>> getMabStats(String userId) async {
    final db = await _dbHelper.database;

    // Question arms stats
    final questionStats = await db.rawQuery('''
      SELECT
        COUNT(*) as total_questions,
        SUM(attempts) as total_attempts,
        SUM(successes) as total_successes,
        SUM(failures) as total_failures,
        AVG(CAST(successes AS REAL) / NULLIF(attempts, 0)) as avg_success_rate
      FROM mab_question_arms
      WHERE user_id = ?
    ''', [userId]);

    // Topic arms stats
    final topicStats = await db.rawQuery('''
      SELECT
        COUNT(*) as total_topics,
        SUM(attempts) as total_attempts,
        SUM(successes) as total_successes,
        AVG(CAST(successes AS REAL) / NULLIF(attempts, 0)) as avg_success_rate
      FROM mab_topic_arms
      WHERE user_id = ?
    ''', [userId]);

    return {
      'questionArms': questionStats.first,
      'topicArms': topicStats.first,
    };
  }

  /// Get unsynced MAB data count
  Future<Map<String, int>> getUnsyncedCount(String userId) async {
    final db = await _dbHelper.database;

    final questionArms = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM mab_question_arms WHERE user_id = ? AND is_synced = 0',
        [userId],
      ),
    ) ?? 0;

    final topicArms = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM mab_topic_arms WHERE user_id = ? AND is_synced = 0',
        [userId],
      ),
    ) ?? 0;

    return {
      'questionArms': questionArms,
      'topicArms': topicArms,
      'total': questionArms + topicArms,
    };
  }

  /// Mark MAB data as synced
  Future<void> markAsSynced(String userId) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.update(
      'mab_question_arms',
      {'is_synced': 1, 'synced_at': now},
      where: 'user_id = ? AND is_synced = 0',
      whereArgs: [userId],
    );

    await db.update(
      'mab_topic_arms',
      {'is_synced': 1, 'synced_at': now},
      where: 'user_id = ? AND is_synced = 0',
      whereArgs: [userId],
    );
  }
}
