import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../../core/config/app_config.dart';
import '../data_sources/firebase_quiz_datasource.dart';
import '../../domain/entities/question.dart';
import '../models/question.dart';

/// Service for configuring and initializing Firebase quiz features
///
/// This service handles Firebase initialization, data seeding,
/// and configuration for the quiz module following Clean Architecture principles
class FirebaseQuizConfigService {
  static FirebaseQuizConfigService? _instance;
  static FirebaseQuizConfigService get instance => _instance ??= FirebaseQuizConfigService._();

  FirebaseQuizConfigService._();

  FirebaseFirestore? _firestore;
  bool _isInitialized = false;

  /// Initialize Firebase quiz features with proper configuration
  ///
  /// This method should be called during app startup, preferably in main()
  /// after Firebase.initializeApp() has been called
  Future<void> initialize(AppConfig config) async {
    if (_isInitialized) return;

    try {
      // Ensure Firebase is initialized
      await Firebase.initializeApp();

      _firestore = FirebaseFirestore.instance;

      // Configure Firestore settings based on environment
      await _configureFirestore(config);

      // Initialize sample data if needed
      await _initializeSampleData(config);

      _isInitialized = true;
    } catch (e) {
      throw FirebaseQuizConfigException(
        'Failed to initialize Firebase quiz service: $e',
        cause: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Configure Firestore settings based on app configuration
  Future<void> _configureFirestore(AppConfig config) async {
    if (_firestore == null) return;

    try {
      // Enable offline persistence for better performance
      if (config.firebase.enabled) {
        await _firestore!.enablePersistence(const PersistenceSettings(
          synchronizeTabs: true,
        ));
      }

      // Configure cache settings
      _firestore!.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    } catch (e) {
      // Persistence might already be enabled, ignore this error
      print('Firestore persistence configuration: $e');
    }
  }

  /// Initialize sample data in Firebase if collections are empty
  Future<void> _initializeSampleData(AppConfig config) async {
    if (_firestore == null) return;

    try {
      // Check if we should initialize sample data
      final shouldInitialize = config.environment == AppEnvironment.development ||
          await _shouldInitializeSampleData();

      if (shouldInitialize) {
        final dataSource = FirebaseQuizDataSourceImpl(
          firestore: _firestore,
          simulatedDelay: Duration(milliseconds: config.auth.mockAuthDelay),
        );

        await dataSource.initializeQuestions();
        print('Sample quiz data initialized in Firebase');
      }
    } catch (e) {
      print('Warning: Failed to initialize sample data: $e');
      // Don't throw here - app should continue even if sample data fails
    }
  }

  /// Check if sample data should be initialized
  Future<bool> _shouldInitializeSampleData() async {
    if (_firestore == null) return false;

    try {
      final snapshot = await _firestore!
          .collection('questions')
          .limit(1)
          .get();

      return snapshot.docs.isEmpty;
    } catch (e) {
      return true; // If we can't check, assume we need to initialize
    }
  }

  /// Create Firestore indexes programmatically
  ///
  /// Note: In production, indexes should be created via Firebase Console
  /// or Firebase CLI. This is mainly for development/testing.
  Future<void> createIndexes() async {
    // Firestore automatically creates single-field indexes
    // Composite indexes need to be created via console or CLI
    print('Firestore indexes should be created via Firebase Console or CLI');
    print('Required composite indexes:');
    print('- Collection: questions, Fields: subject (Ascending), difficulty (Ascending)');
    print('- Collection: questions, Fields: difficulty (Ascending), subject (Ascending)');
    print('- Collection: questions, Fields: tags (Array), subject (Ascending)');
  }

  /// Upload questions in batches for better performance
  Future<void> uploadQuestionsInBatches(List<Question> questions, {
    int batchSize = 50,
  }) async {
    if (_firestore == null) {
      throw FirebaseQuizConfigException('Firestore not initialized');
    }

    try {
      for (int i = 0; i < questions.length; i += batchSize) {
        final batch = _firestore!.batch();
        final end = (i + batchSize < questions.length) ? i + batchSize : questions.length;
        final batchQuestions = questions.sublist(i, end);

        for (final question in batchQuestions) {
          final docRef = _firestore!.collection('questions').doc(question.id);
          final questionModel = QuestionModel.fromEntity(question);
          batch.set(docRef, questionModel.toJson());
        }

        await batch.commit();
        print('Uploaded batch ${(i ~/ batchSize) + 1}/${((questions.length - 1) ~/ batchSize) + 1}');
      }
    } catch (e) {
      throw FirebaseQuizConfigException(
        'Failed to upload questions in batches: $e',
        cause: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Clear all questions (for testing/reset purposes)
  Future<void> clearAllQuestions() async {
    if (_firestore == null) {
      throw FirebaseQuizConfigException('Firestore not initialized');
    }

    try {
      final snapshot = await _firestore!.collection('questions').get();
      final batch = _firestore!.batch();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('All questions cleared from Firebase');
    } catch (e) {
      throw FirebaseQuizConfigException(
        'Failed to clear questions: $e',
        cause: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Get collection statistics
  Future<Map<String, dynamic>> getCollectionStats() async {
    if (_firestore == null) {
      throw FirebaseQuizConfigException('Firestore not initialized');
    }

    try {
      final questionsSnapshot = await _firestore!.collection('questions').get();
      final sessionsSnapshot = await _firestore!.collection('quiz_sessions').get();

      // Calculate subject distribution
      final subjectCounts = <String, int>{};
      final difficultyCounts = <String, int>{};

      for (final doc in questionsSnapshot.docs) {
        final data = doc.data();
        final subject = data['subject'] as String? ?? 'Unknown';
        final difficulty = data['difficulty'] as String? ?? 'Unknown';

        subjectCounts[subject] = (subjectCounts[subject] ?? 0) + 1;
        difficultyCounts[difficulty] = (difficultyCounts[difficulty] ?? 0) + 1;
      }

      return {
        'questions': {
          'total': questionsSnapshot.docs.length,
          'by_subject': subjectCounts,
          'by_difficulty': difficultyCounts,
        },
        'quiz_sessions': {
          'total': sessionsSnapshot.docs.length,
        },
        'last_updated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw FirebaseQuizConfigException(
        'Failed to get collection stats: $e',
        cause: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Validate Firebase connection and permissions
  Future<bool> validateConnection() async {
    if (_firestore == null) return false;

    try {
      // Try to read from a collection
      await _firestore!.collection('questions').limit(1).get();
      return true;
    } catch (e) {
      print('Firebase connection validation failed: $e');
      return false;
    }
  }

  /// Get Firestore instance
  FirebaseFirestore? get firestore => _firestore;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Dispose resources
  void dispose() {
    _firestore = null;
    _isInitialized = false;
  }
}

/// Exception thrown when Firebase quiz configuration fails
class FirebaseQuizConfigException implements Exception {
  final String message;
  final String? code;
  final Exception? cause;

  const FirebaseQuizConfigException(
    this.message, {
    this.code,
    this.cause,
  });

  @override
  String toString() {
    final buffer = StringBuffer('FirebaseQuizConfigException: $message');
    if (code != null) {
      buffer.write(' (Code: $code)');
    }
    if (cause != null) {
      buffer.write(' Caused by: $cause');
    }
    return buffer.toString();
  }
}
