import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/question.dart';
import '../models/question.dart';
import 'mock_quiz_datasource.dart';

/// Firebase data source for quiz questions
///
/// This class handles Firebase Firestore operations for quiz questions
/// with proper error handling and data mapping
abstract class FirebaseQuizDataSource extends QuizDataSource {
  /// Initialize quiz data in Firebase
  Future<void> initializeQuestions();

  /// Check if questions exist in Firebase
  Future<bool> questionsExist();

  /// Upload sample questions to Firebase
  Future<void> uploadSampleQuestions();
}

/// Firebase implementation of QuizDataSource
///
/// Handles all Firebase Firestore operations for quiz questions
/// with comprehensive error handling and caching strategies
class FirebaseQuizDataSourceImpl extends QuizDataSource implements FirebaseQuizDataSource {
  final FirebaseFirestore _firestore;
  final Duration simulatedDelay;

  // Cache for better performance
  final Map<String, List<Question>> _cache = {};
  final Duration _cacheExpiry = const Duration(minutes: 10);
  DateTime? _lastCacheUpdate;

  FirebaseQuizDataSourceImpl({
    FirebaseFirestore? firestore,
    this.simulatedDelay = const Duration(milliseconds: 500),
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> initializeQuestions() async {
    try {
      final exists = await questionsExist();
      if (!exists) {
        await uploadSampleQuestions();
      }
    } catch (e) {
      throw FirebaseQuizException('Failed to initialize questions: $e');
    }
  }

  @override
  Future<bool> questionsExist() async {
    try {
      final snapshot = await _firestore
          .collection('questions')
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      throw FirebaseQuizException('Failed to check if questions exist: $e');
    }
  }

  @override
  Future<void> uploadSampleQuestions() async {
    try {
      final batch = _firestore.batch();
      final mockDataSource = MockQuizDataSource();

      // Get all sample questions from the mock data source
      final allQuestions = await mockDataSource.getAllQuestions();

      for (final question in allQuestions) {
        final docRef = _firestore.collection('questions').doc(question.id);
        final questionModel = QuestionModel.fromEntity(question);
        batch.set(docRef, questionModel.toJson());
      }

      await batch.commit();
    } catch (e) {
      throw FirebaseQuizException('Failed to upload sample questions: $e');
    }
  }

  @override
  Future<List<Question>> getQuestionsBySubject(String subject) async {
    try {
      // Check cache first
      final cacheKey = 'subject_$subject';
      if (_isCacheValid() && _cache.containsKey(cacheKey)) {
        return _cache[cacheKey]!;
      }

      await Future.delayed(simulatedDelay);

      final querySnapshot = await _firestore
          .collection('questions')
          .where('subject', isEqualTo: subject)
          .orderBy('id')
          .get();

      final questions = querySnapshot.docs
          .map((doc) => QuestionModel.fromJson(doc.data()).toEntity())
          .toList();

      // Update cache
      _cache[cacheKey] = questions;
      _lastCacheUpdate = DateTime.now();

      return questions;
    } on FirebaseException catch (e) {
      throw FirebaseQuizException('Firebase error getting questions by subject: ${e.message}');
    } catch (e) {
      throw FirebaseQuizException('Failed to get questions by subject: $e');
    }
  }

  @override
  Future<List<Question>> getQuestionsByDifficulty(DifficultyLevel difficulty) async {
    try {
      // Check cache first
      final cacheKey = 'difficulty_${difficulty.name}';
      if (_isCacheValid() && _cache.containsKey(cacheKey)) {
        return _cache[cacheKey]!;
      }

      await Future.delayed(simulatedDelay);

      final querySnapshot = await _firestore
          .collection('questions')
          .where('difficulty', isEqualTo: difficulty.name)
          .orderBy('id')
          .get();

      final questions = querySnapshot.docs
          .map((doc) => QuestionModel.fromJson(doc.data()).toEntity())
          .toList();

      // Update cache
      _cache[cacheKey] = questions;
      _lastCacheUpdate = DateTime.now();

      return questions;
    } on FirebaseException catch (e) {
      throw FirebaseQuizException('Firebase error getting questions by difficulty: ${e.message}');
    } catch (e) {
      throw FirebaseQuizException('Failed to get questions by difficulty: $e');
    }
  }

  @override
  Future<List<Question>> getRandomQuestions({
    int limit = 10,
    String? subject,
    DifficultyLevel? difficulty,
    List<String>? excludeIds,
  }) async {
    try {
      await Future.delayed(simulatedDelay);

      var query = _firestore.collection('questions') as Query<Map<String, dynamic>>;

      // Apply filters
      if (subject != null) {
        query = query.where('subject', isEqualTo: subject);
      }
      if (difficulty != null) {
        query = query.where('difficulty', isEqualTo: difficulty.name);
      }

      final querySnapshot = await query.get();
      var questions = querySnapshot.docs
          .map((doc) => QuestionModel.fromJson(doc.data()).toEntity())
          .toList();

      // Exclude specified IDs
      if (excludeIds != null && excludeIds.isNotEmpty) {
        questions = questions.where((q) => !excludeIds.contains(q.id)).toList();
      }

      // Shuffle and limit
      questions.shuffle(Random());
      return questions.take(limit).toList();
    } on FirebaseException catch (e) {
      throw FirebaseQuizException('Firebase error getting random questions: ${e.message}');
    } catch (e) {
      throw FirebaseQuizException('Failed to get random questions: $e');
    }
  }

  @override
  Future<Question?> getQuestionById(String id) async {
    try {
      await Future.delayed(simulatedDelay);

      final docSnapshot = await _firestore
          .collection('questions')
          .doc(id)
          .get();

      if (!docSnapshot.exists) {
        return null;
      }

      return QuestionModel.fromJson(docSnapshot.data()!).toEntity();
    } on FirebaseException catch (e) {
      throw FirebaseQuizException('Firebase error getting question by ID: ${e.message}');
    } catch (e) {
      throw FirebaseQuizException('Failed to get question by ID: $e');
    }
  }

  @override
  Future<List<String>> getAvailableSubjects() async {
    try {
      // Check cache first
      const cacheKey = 'subjects';
      if (_isCacheValid() && _cache.containsKey(cacheKey)) {
        return _cache[cacheKey]!.map((q) => q.subject).toSet().toList();
      }

      await Future.delayed(simulatedDelay);

      final querySnapshot = await _firestore
          .collection('questions')
          .get();

      final subjects = querySnapshot.docs
          .map((doc) => QuestionModel.fromJson(doc.data()).subject)
          .toSet()
          .toList();

      subjects.sort();
      return subjects;
    } on FirebaseException catch (e) {
      throw FirebaseQuizException('Firebase error getting available subjects: ${e.message}');
    } catch (e) {
      throw FirebaseQuizException('Failed to get available subjects: $e');
    }
  }

  @override
  Future<List<Question>> getAllQuestions() async {
    try {
      // Check cache first
      const cacheKey = 'all_questions';
      if (_isCacheValid() && _cache.containsKey(cacheKey)) {
        return _cache[cacheKey]!;
      }

      await Future.delayed(simulatedDelay);

      final querySnapshot = await _firestore
          .collection('questions')
          .orderBy('subject')
          .orderBy('difficulty')
          .orderBy('id')
          .get();

      final questions = querySnapshot.docs
          .map((doc) => QuestionModel.fromJson(doc.data()).toEntity())
          .toList();

      // Update cache
      _cache[cacheKey] = questions;
      _lastCacheUpdate = DateTime.now();

      return questions;
    } on FirebaseException catch (e) {
      throw FirebaseQuizException('Firebase error getting all questions: ${e.message}');
    } catch (e) {
      throw FirebaseQuizException('Failed to get all questions: $e');
    }
  }

  /// Clear the cache manually
  void clearCache() {
    _cache.clear();
    _lastCacheUpdate = null;
  }

  /// Check if cache is still valid
  bool _isCacheValid() {
    if (_lastCacheUpdate == null) return false;
    return DateTime.now().difference(_lastCacheUpdate!) < _cacheExpiry;
  }

  /// Dispose resources
  void dispose() {
    _cache.clear();
  }
}

/// Custom exception for Firebase quiz operations
class FirebaseQuizException implements Exception {
  final String message;
  final String? code;
  final Exception? cause;

  const FirebaseQuizException(
    this.message, {
    this.code,
    this.cause,
  });

  @override
  String toString() {
    final buffer = StringBuffer('FirebaseQuizException: $message');
    if (code != null) {
      buffer.write(' (Code: $code)');
    }
    if (cause != null) {
      buffer.write(' Caused by: $cause');
    }
    return buffer.toString();
  }
}
