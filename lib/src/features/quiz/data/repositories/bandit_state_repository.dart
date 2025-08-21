import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../application/bandit_manager.dart';
import '../../domain/entities/question.dart';

/// Repository for persisting MAB state
class BanditStateRepository {
  static const String _questionArmsFile = 'question_arms.json';
  static const String _topicArmsFile = 'topic_arms.json';

  /// Save question arm state
  Future<void> saveQuestionArmState(String questionId, BanditArm arm) async {
    try {
      final file = await _getQuestionArmsFile();
      final existingData = await _loadJsonFile(file);
      
      existingData[questionId] = {
        'questionId': arm.questionId,
        'difficulty': arm.difficulty.name,
        'attempts': arm.attempts,
        'successes': arm.successes,
        'failures': arm.failures,
        'totalResponseTime': arm.totalResponseTime,
        'userConfidence': arm.userConfidence,
        'alpha': arm.alpha,
        'beta': arm.beta,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
      
      await _saveJsonFile(file, existingData);
    } catch (e) {
      // Silent fail for persistence - don't break the app
      // ignore: avoid_print  
      print('Warning: Failed to save question arm state: $e');
    }
  }

  /// Save topic arm state
  Future<void> saveTopicArmState(String topicKey, TopicArm arm) async {
    try {
      final file = await _getTopicArmsFile();
      final existingData = await _loadJsonFile(file);
      
      existingData[topicKey] = {
        'topicKey': arm.topicKey,
        'topic': arm.topic,
        'knowledgeType': arm.knowledgeType,
        'course': arm.course,
        'attempts': arm.attempts,
        'successes': arm.successes,
        'failures': arm.failures,
        'totalResponseTime': arm.totalResponseTime,
        'alpha': arm.alpha,
        'beta': arm.beta,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
      
      await _saveJsonFile(file, existingData);
    } catch (e) {
      // ignore: avoid_print
      print('Warning: Failed to save topic arm state: $e');
    }
  }

  /// Load question arm state
  Future<BanditArm?> loadQuestionArmState(String questionId) async {
    try {
      final file = await _getQuestionArmsFile();
      final data = await _loadJsonFile(file);
      final armData = data[questionId];
      
      if (armData == null) return null;
      
      final arm = BanditArm(
        questionId: armData['questionId'] ?? questionId,
        difficulty: DifficultyLevel.values.firstWhere(
          (e) => e.name == armData['difficulty'],
          orElse: () => DifficultyLevel.intermediate,
        ),
        initialConfidence: (armData['userConfidence'] ?? 0.5).toDouble(),
      );
      
      // Restore state
      arm.attempts = armData['attempts'] ?? 0;
      arm.successes = armData['successes'] ?? 0;
      arm.failures = armData['failures'] ?? 0;
      arm.totalResponseTime = armData['totalResponseTime'] ?? 0;
      arm.userConfidence = (armData['userConfidence'] ?? 0.5).toDouble();
      arm.alpha = (armData['alpha'] ?? 1.0).toDouble();
      arm.beta = (armData['beta'] ?? 1.0).toDouble();
      
      return arm;
    } catch (e) {
      // ignore: avoid_print
      print('Warning: Failed to load question arm state: $e');
      return null;
    }
  }

  /// Load topic arm state
  Future<TopicArm?> loadTopicArmState(String topicKey) async {
    try {
      final file = await _getTopicArmsFile();
      final data = await _loadJsonFile(file);
      final armData = data[topicKey];
      
      if (armData == null) return null;
      
      final arm = TopicArm(
        topicKey: armData['topicKey'] ?? topicKey,
        topic: armData['topic'] ?? 'unknown',
        knowledgeType: armData['knowledgeType'] ?? 'general',
        course: armData['course'] ?? 'unknown',
      );
      
      // Restore state
      arm.attempts = armData['attempts'] ?? 0;
      arm.successes = armData['successes'] ?? 0;
      arm.failures = armData['failures'] ?? 0;
      arm.totalResponseTime = armData['totalResponseTime'] ?? 0;
      arm.alpha = (armData['alpha'] ?? 1.0).toDouble();
      arm.beta = (armData['beta'] ?? 1.0).toDouble();
      
      return arm;
    } catch (e) {
      // ignore: avoid_print
      print('Warning: Failed to load topic arm state: $e');
      return null;
    }
  }

  /// Clear all persisted data
  Future<void> clearAllState() async {
    try {
      final questionFile = await _getQuestionArmsFile();
      final topicFile = await _getTopicArmsFile();
      
      if (await questionFile.exists()) {
        await questionFile.delete();
      }
      if (await topicFile.exists()) {
        await topicFile.delete();
      }
    } catch (e) {
      // ignore: avoid_print
      print('Warning: Failed to clear state: $e');
    }
  }

  // Private helper methods

  Future<File> _getQuestionArmsFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_questionArmsFile');
  }

  Future<File> _getTopicArmsFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_topicArmsFile');
  }

  Future<Map<String, dynamic>> _loadJsonFile(File file) async {
    if (!await file.exists()) {
      return {};
    }
    
    final content = await file.readAsString();
    if (content.trim().isEmpty) {
      return {};
    }
    
    return Map<String, dynamic>.from(jsonDecode(content));
  }

  Future<void> _saveJsonFile(File file, Map<String, dynamic> data) async {
    await file.writeAsString(jsonEncode(data));
  }
}