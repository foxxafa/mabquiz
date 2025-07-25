import 'dart:convert';
import 'package:flutter/services.dart';
import '../../domain/entities/question.dart';

/// Service for loading questions from assets
class AssetQuestionLoader {
  static const String _basePath = 'assets/questions';

  /// Load questions from a specific subject and question type
  static Future<List<Question>> loadQuestions({
    required String subject,
    required String questionType,
  }) async {
    try {
      final path = '$_basePath/$subject/$questionType.json';
      final jsonString = await rootBundle.loadString(path);
      final jsonList = json.decode(jsonString) as List;
      
      return jsonList.map((questionJson) => _parseAssetQuestion(questionJson)).toList();
    } catch (e) {
      print('Error loading questions from $subject/$questionType: $e');
      return [];
    }
  }

  /// Load all questions for a subject
  static Future<List<Question>> loadAllQuestionsForSubject(String subject) async {
    final List<Question> allQuestions = [];
    
    // Farklı soru tiplerini yükle
    final questionTypes = ['multiple_choice', 'true_false', 'fill_in_blank', 'match_text_text'];
    
    for (final type in questionTypes) {
      final questions = await loadQuestions(subject: subject, questionType: type);
      allQuestions.addAll(questions);
    }
    
    return allQuestions;
  }

  /// Get available subjects
  static List<String> getAvailableSubjects() {
    return ['farmakoloji']; // Şimdilik sadece farmakoloji
  }

  /// Parse asset question JSON to Question entity
  static Question _parseAssetQuestion(Map<String, dynamic> json) {
    // Asset formatını domain entity formatına çevir
    return Question(
      id: json['id'] as String,
      text: json['prompt'] as String? ?? json['text'] as String,
      type: _parseQuestionType(json['type'] as String),
      difficulty: _parseDifficulty(json),
      options: _parseOptions(json),
      correctAnswer: json['correctAnswer'] as String,
      explanation: json['explanation'] as String? ?? '',
      tags: _parseTags(json),
      subject: _parseSubject(json['course'] as String? ?? 'Unknown'),
      points: _calculatePoints(json),
    );
  }

  static QuestionType _parseQuestionType(String type) {
    switch (type) {
      case 'multiple_choice':
        return QuestionType.multipleChoice;
      case 'true_false':
        return QuestionType.trueFalse;
      case 'fill_in_blank':
        return QuestionType.fillInBlank;
      case 'match_text':
      case 'match_text_text':
        return QuestionType.matching;
      default:
        return QuestionType.multipleChoice;
    }
  }

  static DifficultyLevel _parseDifficulty(Map<String, dynamic> json) {
    final knowledgeType = json['knowledgeType'] as String?;
    
    // Asset dosyalarında difficulty yok, knowledge type'a göre belirle
    if (knowledgeType == 'dosage' || knowledgeType == 'active_ingredient') {
      return DifficultyLevel.beginner;
    } else if (knowledgeType == 'pharmacodynamics' || knowledgeType == 'pharmacokinetics') {
      return DifficultyLevel.intermediate;
    } else {
      return DifficultyLevel.advanced;
    }
  }

  static List<String> _parseOptions(Map<String, dynamic> json) {
    if (json['options'] != null) {
      return List<String>.from(json['options']);
    } else if (json['type'] == 'true_false') {
      return ['Doğru', 'Yanlış'];
    } else if (json['matchPairs'] != null) {
      // Matching questions için sol taraftaki seçenekleri al
      final pairs = json['matchPairs'] as List;
      return pairs.map((pair) => pair['left'] as String).toList();
    }
    return [];
  }

  static List<String> _parseTags(Map<String, dynamic> json) {
    final tags = <String>[];
    
    if (json['tags'] != null) {
      tags.addAll(List<String>.from(json['tags']));
    }
    
    // Metadata'dan ek tag'ler ekle
    if (json['topic'] != null) tags.add(json['topic'] as String);
    if (json['subtopic'] != null) tags.add(json['subtopic'] as String);
    if (json['knowledgeType'] != null) tags.add(json['knowledgeType'] as String);
    
    return tags;
  }

  static String _parseSubject(String course) {
    switch (course.toLowerCase()) {
      case 'farmakoloji':
        return 'Farmakoloji';
      default:
        return course;
    }
  }

  static int _calculatePoints(Map<String, dynamic> json) {
    final knowledgeType = json['knowledgeType'] as String?;
    
    switch (knowledgeType) {
      case 'dosage':
      case 'active_ingredient':
        return 10;
      case 'pharmacodynamics':
      case 'pharmacokinetics':
        return 15;
      case 'side_effect':
      case 'contraindication':
        return 20;
      default:
        return 15;
    }
  }
}
