import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../database/repositories/mab_repository.dart';

/// Service for syncing MAB state with server using delta sync strategy
class SyncService {
  final MabRepository _mabRepository = MabRepository();

  static const String _lastSyncTimeKey = 'mab_last_sync_time';

  /// Get last sync time from SharedPreferences
  Future<int> _getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lastSyncTimeKey) ?? 0;
  }

  /// Save last sync time to SharedPreferences
  Future<void> _setLastSyncTime(int time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastSyncTimeKey, time);
  }

  /// Get auth token from SharedPreferences
  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Sync MAB state with server (two-way delta sync)
  Future<SyncResult> syncMabState(String userId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return SyncResult(
          success: false,
          error: 'Not authenticated',
        );
      }

      final lastSyncTime = await _getLastSyncTime();

      // Get records that need sync (updated after lastSyncTime)
      final recordsToSync = await _mabRepository.getRecordsToSync(userId, lastSyncTime);

      // Prepare request body
      final requestBody = {
        'last_sync_time': lastSyncTime,
        'question_arms': recordsToSync['questionArms']?.map((arm) => {
          'question_id': arm['question_id'],
          'attempts': arm['attempts'],
          'successes': arm['successes'],
          'failures': arm['failures'],
          'total_response_time_ms': arm['total_response_time'],
          'alpha': arm['alpha'],
          'beta': arm['beta'],
          'user_confidence': arm['user_confidence'],
          'last_attempted': arm['last_attempted'],
          'created_at': arm['created_at'],
          'updated_at': arm['updated_at'],
        }).toList() ?? [],
        'topic_arms': recordsToSync['topicArms']?.map((arm) => {
          'topic_key': arm['topic_key'],
          'topic': arm['topic'],
          'knowledge_type': arm['knowledge_type'],
          'course': arm['course'],
          'attempts': arm['attempts'],
          'successes': arm['successes'],
          'failures': arm['failures'],
          'total_response_time_ms': arm['total_response_time'],
          'alpha': arm['alpha'],
          'beta': arm['beta'],
          'created_at': arm['created_at'],
          'updated_at': arm['updated_at'],
        }).toList() ?? [],
      };

      // Send sync request
      final response = await http.post(
        Uri.parse(ApiConfig.syncMab),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Update last sync time
        final serverTime = responseData['server_time'] as int;
        await _setLastSyncTime(serverTime);

        // Process server updates
        final serverQuestionArms = responseData['question_arms'] as List? ?? [];
        final serverTopicArms = responseData['topic_arms'] as List? ?? [];

        // Apply server changes to local DB
        await _applyServerChanges(userId, serverQuestionArms, serverTopicArms);

        return SyncResult(
          success: true,
          uploadedQuestionArms: recordsToSync['questionArms']?.length ?? 0,
          uploadedTopicArms: recordsToSync['topicArms']?.length ?? 0,
          downloadedQuestionArms: serverQuestionArms.length,
          downloadedTopicArms: serverTopicArms.length,
          conflictsResolved: responseData['conflicts_resolved'] ?? 0,
        );
      } else {
        return SyncResult(
          success: false,
          error: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      return SyncResult(
        success: false,
        error: 'Sync failed: $e',
      );
    }
  }

  /// Apply server changes to local database
  Future<void> _applyServerChanges(
    String userId,
    List<dynamic> serverQuestionArms,
    List<dynamic> serverTopicArms,
  ) async {
    // Apply question arm updates
    for (final arm in serverQuestionArms) {
      final existing = await _mabRepository.getQuestionArm(
        userId,
        arm['question_id'] as String,
      );

      // Server data is newer - update local
      if (existing == null || _shouldUpdateLocal(existing.updatedAt, arm['updated_at'])) {
        await _mabRepository.updateQuestionArmStats(
          userId: userId,
          questionId: arm['question_id'] as String,
          isCorrect: false, // Not used when passing explicit values
          responseTimeMs: 0, // Not used when passing explicit values
          userConfidence: (arm['user_confidence'] as num?)?.toDouble() ?? 0.5,
          alpha: (arm['alpha'] as num?)?.toDouble() ?? 1.0,
          beta: (arm['beta'] as num?)?.toDouble() ?? 1.0,
          attempts: arm['attempts'] as int? ?? 0,
          successes: arm['successes'] as int? ?? 0,
          failures: arm['failures'] as int? ?? 0,
          totalResponseTime: arm['total_response_time_ms'] as int? ?? 0,
        );
      }
    }

    // Apply topic arm updates
    for (final arm in serverTopicArms) {
      final existing = await _mabRepository.getTopicArm(
        userId,
        arm['topic_key'] as String,
      );

      // Server data is newer - update local
      if (existing == null || _shouldUpdateLocal(existing.updatedAt, arm['updated_at'])) {
        await _mabRepository.updateTopicArmStats(
          userId: userId,
          topicKey: arm['topic_key'] as String,
          topic: arm['topic'] as String,
          knowledgeType: arm['knowledge_type'] as String,
          course: arm['course'] as String,
          isCorrect: false, // Not used when passing explicit values
          responseTimeMs: 0, // Not used when passing explicit values
          alpha: (arm['alpha'] as num?)?.toDouble() ?? 1.0,
          beta: (arm['beta'] as num?)?.toDouble() ?? 1.0,
          attempts: arm['attempts'] as int? ?? 0,
          successes: arm['successes'] as int? ?? 0,
          failures: arm['failures'] as int? ?? 0,
          totalResponseTime: arm['total_response_time_ms'] as int? ?? 0,
        );
      }
    }
  }

  /// Check if local record should be updated with server data
  bool _shouldUpdateLocal(int localUpdatedAt, dynamic serverUpdatedAt) {
    if (serverUpdatedAt == null) return false;

    // Server might return ISO string or epoch ms
    int serverTime;
    if (serverUpdatedAt is String) {
      serverTime = DateTime.parse(serverUpdatedAt).millisecondsSinceEpoch;
    } else {
      serverTime = serverUpdatedAt as int;
    }

    return serverTime > localUpdatedAt;
  }

  /// Get sync status from server
  Future<Map<String, dynamic>?> getSyncStatus() async {
    try {
      final token = await _getAuthToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse(ApiConfig.syncStatus),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get pending sync count (local records that need to be synced)
  Future<Map<String, int>> getPendingSyncCount(String userId) async {
    final lastSyncTime = await _getLastSyncTime();
    return await _mabRepository.getPendingSyncCount(userId, lastSyncTime);
  }

  /// Force full sync (reset lastSyncTime to 0)
  Future<SyncResult> forceFullSync(String userId) async {
    await _setLastSyncTime(0);
    return await syncMabState(userId);
  }
}

/// Result of a sync operation
class SyncResult {
  final bool success;
  final String? error;
  final int uploadedQuestionArms;
  final int uploadedTopicArms;
  final int downloadedQuestionArms;
  final int downloadedTopicArms;
  final int conflictsResolved;

  SyncResult({
    required this.success,
    this.error,
    this.uploadedQuestionArms = 0,
    this.uploadedTopicArms = 0,
    this.downloadedQuestionArms = 0,
    this.downloadedTopicArms = 0,
    this.conflictsResolved = 0,
  });

  @override
  String toString() {
    if (!success) {
      return 'SyncResult(failed: $error)';
    }
    return 'SyncResult(success: uploaded $uploadedQuestionArms questions + $uploadedTopicArms topics, '
           'downloaded $downloadedQuestionArms questions + $downloadedTopicArms topics, '
           'conflicts: $conflictsResolved)';
  }
}
