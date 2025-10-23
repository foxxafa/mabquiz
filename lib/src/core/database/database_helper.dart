import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// SQLite Database Helper for MAB Quiz System
///
/// Manages all database operations including:
/// - Questions storage
/// - User responses tracking
/// - MAB algorithm state persistence
/// - Quiz sessions management
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  /// Database version for migration management
  static const int _databaseVersion = 2;
  static const String _databaseName = 'mabquiz.db';

  /// Get database instance (lazy initialization)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database and create tables
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create all tables on first database creation
  Future<void> _onCreate(Database db, int version) async {
    await _createQuestionsTable(db);
    await _createUserResponsesTable(db);
    await _createMabQuestionArmsTable(db);
    await _createMabTopicArmsTable(db);
    await _createQuizSessionsTable(db);
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migration from version 1 to 2: Add last_attempted column
    if (oldVersion < 2) {
      await db.execute('''
        ALTER TABLE mab_question_arms
        ADD COLUMN last_attempted INTEGER
      ''');
    }
  }

  /// Create questions table
  Future<void> _createQuestionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE questions (
        id TEXT PRIMARY KEY,
        text TEXT NOT NULL,
        course TEXT NOT NULL,
        topic TEXT NOT NULL,
        knowledge_type TEXT NOT NULL,
        difficulty TEXT NOT NULL,
        option_a TEXT NOT NULL,
        option_b TEXT NOT NULL,
        option_c TEXT NOT NULL,
        option_d TEXT NOT NULL,
        option_e TEXT,
        correct_answer TEXT NOT NULL,
        explanation TEXT,
        tags TEXT,
        initial_confidence REAL DEFAULT 0.5,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        synced_at INTEGER,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    // Create indexes for better query performance
    await db.execute(
        'CREATE INDEX idx_questions_course ON questions(course)');
    await db.execute(
        'CREATE INDEX idx_questions_topic ON questions(topic)');
    await db.execute(
        'CREATE INDEX idx_questions_difficulty ON questions(difficulty)');
    await db.execute(
        'CREATE INDEX idx_questions_synced ON questions(is_synced)');
  }

  /// Create user responses table
  Future<void> _createUserResponsesTable(Database db) async {
    await db.execute('''
      CREATE TABLE user_responses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        question_id TEXT NOT NULL,
        session_id TEXT NOT NULL,
        selected_answer TEXT NOT NULL,
        is_correct INTEGER NOT NULL,
        response_time_ms INTEGER NOT NULL,
        confidence_level REAL,
        timestamp INTEGER NOT NULL,
        synced_at INTEGER,
        is_synced INTEGER DEFAULT 0,
        FOREIGN KEY (question_id) REFERENCES questions(id),
        FOREIGN KEY (session_id) REFERENCES quiz_sessions(id)
      )
    ''');

    await db.execute(
        'CREATE INDEX idx_responses_user ON user_responses(user_id)');
    await db.execute(
        'CREATE INDEX idx_responses_question ON user_responses(question_id)');
    await db.execute(
        'CREATE INDEX idx_responses_session ON user_responses(session_id)');
    await db.execute(
        'CREATE INDEX idx_responses_synced ON user_responses(is_synced)');
  }

  /// Create MAB question arms table
  Future<void> _createMabQuestionArmsTable(Database db) async {
    await db.execute('''
      CREATE TABLE mab_question_arms (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        question_id TEXT NOT NULL,
        difficulty TEXT NOT NULL,
        attempts INTEGER DEFAULT 0,
        successes INTEGER DEFAULT 0,
        failures INTEGER DEFAULT 0,
        total_response_time INTEGER DEFAULT 0,
        user_confidence REAL DEFAULT 0.5,
        alpha REAL DEFAULT 1.0,
        beta REAL DEFAULT 1.0,
        last_attempted INTEGER,
        last_updated INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        synced_at INTEGER,
        is_synced INTEGER DEFAULT 0,
        UNIQUE(user_id, question_id),
        FOREIGN KEY (question_id) REFERENCES questions(id)
      )
    ''');

    await db.execute(
        'CREATE INDEX idx_mab_question_user ON mab_question_arms(user_id)');
    await db.execute(
        'CREATE INDEX idx_mab_question_qid ON mab_question_arms(question_id)');
    await db.execute(
        'CREATE INDEX idx_mab_question_synced ON mab_question_arms(is_synced)');
  }

  /// Create MAB topic arms table
  Future<void> _createMabTopicArmsTable(Database db) async {
    await db.execute('''
      CREATE TABLE mab_topic_arms (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        topic_key TEXT NOT NULL,
        topic TEXT NOT NULL,
        knowledge_type TEXT NOT NULL,
        course TEXT NOT NULL,
        attempts INTEGER DEFAULT 0,
        successes INTEGER DEFAULT 0,
        failures INTEGER DEFAULT 0,
        total_response_time INTEGER DEFAULT 0,
        alpha REAL DEFAULT 1.0,
        beta REAL DEFAULT 1.0,
        last_updated INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        synced_at INTEGER,
        is_synced INTEGER DEFAULT 0,
        UNIQUE(user_id, topic_key)
      )
    ''');

    await db.execute(
        'CREATE INDEX idx_mab_topic_user ON mab_topic_arms(user_id)');
    await db.execute(
        'CREATE INDEX idx_mab_topic_key ON mab_topic_arms(topic_key)');
    await db.execute(
        'CREATE INDEX idx_mab_topic_synced ON mab_topic_arms(is_synced)');
  }

  /// Create quiz sessions table
  Future<void> _createQuizSessionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE quiz_sessions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        course TEXT NOT NULL,
        topic TEXT,
        difficulty TEXT,
        total_questions INTEGER NOT NULL,
        correct_answers INTEGER DEFAULT 0,
        total_time_ms INTEGER DEFAULT 0,
        started_at INTEGER NOT NULL,
        completed_at INTEGER,
        is_completed INTEGER DEFAULT 0,
        synced_at INTEGER,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    await db.execute(
        'CREATE INDEX idx_sessions_user ON quiz_sessions(user_id)');
    await db.execute(
        'CREATE INDEX idx_sessions_course ON quiz_sessions(course)');
    await db.execute(
        'CREATE INDEX idx_sessions_completed ON quiz_sessions(is_completed)');
    await db.execute(
        'CREATE INDEX idx_sessions_synced ON quiz_sessions(is_synced)');
  }

  /// Close database connection
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// Clear all data (useful for logout or reset)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('user_responses');
    await db.delete('mab_question_arms');
    await db.delete('mab_topic_arms');
    await db.delete('quiz_sessions');
    // Optionally keep questions table as it contains course data
  }

  /// Clear user-specific data only
  Future<void> clearUserData(String userId) async {
    final db = await database;
    await db.delete('user_responses', where: 'user_id = ?', whereArgs: [userId]);
    await db.delete('mab_question_arms', where: 'user_id = ?', whereArgs: [userId]);
    await db.delete('mab_topic_arms', where: 'user_id = ?', whereArgs: [userId]);
    await db.delete('quiz_sessions', where: 'user_id = ?', whereArgs: [userId]);
  }

  /// Get unsynced records count (for offline sync)
  Future<Map<String, int>> getUnsyncedCounts() async {
    final db = await database;

    final responses = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM user_responses WHERE is_synced = 0')
    ) ?? 0;

    final questionArms = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM mab_question_arms WHERE is_synced = 0')
    ) ?? 0;

    final topicArms = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM mab_topic_arms WHERE is_synced = 0')
    ) ?? 0;

    final sessions = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM quiz_sessions WHERE is_synced = 0')
    ) ?? 0;

    return {
      'responses': responses,
      'questionArms': questionArms,
      'topicArms': topicArms,
      'sessions': sessions,
      'total': responses + questionArms + topicArms + sessions,
    };
  }

  /// Mark records as synced
  Future<void> markAsSynced(String table, List<int> ids) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final id in ids) {
      await db.update(
        table,
        {'is_synced': 1, 'synced_at': now},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  /// Get database statistics
  Future<Map<String, dynamic>> getDatabaseStats() async {
    final db = await database;

    final questionsCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM questions')
    ) ?? 0;

    final responsesCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM user_responses')
    ) ?? 0;

    final sessionsCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM quiz_sessions')
    ) ?? 0;

    final mabQuestionArmsCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM mab_question_arms')
    ) ?? 0;

    final mabTopicArmsCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM mab_topic_arms')
    ) ?? 0;

    return {
      'questions': questionsCount,
      'responses': responsesCount,
      'sessions': sessionsCount,
      'mabQuestionArms': mabQuestionArmsCount,
      'mabTopicArms': mabTopicArmsCount,
      'databaseVersion': _databaseVersion,
      'databasePath': await getDatabasesPath(),
    };
  }

  /// Delete database (use with caution!)
  Future<void> deleteDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);
    await close();
    await databaseFactory.deleteDatabase(path);
  }
}