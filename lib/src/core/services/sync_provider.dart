import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'sync_service.dart';

/// Provider for SyncService singleton
final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService();
});

/// State for sync operation
class SyncState {
  final bool isSyncing;
  final SyncResult? lastResult;
  final DateTime? lastSyncTime;

  const SyncState({
    this.isSyncing = false,
    this.lastResult,
    this.lastSyncTime,
  });

  SyncState copyWith({
    bool? isSyncing,
    SyncResult? lastResult,
    DateTime? lastSyncTime,
  }) {
    return SyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      lastResult: lastResult ?? this.lastResult,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }
}

/// StateNotifier for managing sync operations
class SyncNotifier extends StateNotifier<SyncState> {
  final SyncService _syncService;

  SyncNotifier(this._syncService) : super(const SyncState());

  /// Sync MAB state with server
  Future<SyncResult> sync(String userId) async {
    if (state.isSyncing) {
      return SyncResult(success: false, error: 'Sync already in progress');
    }

    state = state.copyWith(isSyncing: true);

    try {
      final result = await _syncService.syncMabState(userId);
      state = state.copyWith(
        isSyncing: false,
        lastResult: result,
        lastSyncTime: DateTime.now(),
      );

      if (result.success) {
        // ignore: avoid_print
        print('🔄 Sync completed: ${result.toString()}');
      } else {
        // ignore: avoid_print
        print('❌ Sync failed: ${result.error}');
      }

      return result;
    } catch (e) {
      final result = SyncResult(success: false, error: e.toString());
      state = state.copyWith(
        isSyncing: false,
        lastResult: result,
      );
      // ignore: avoid_print
      print('❌ Sync error: $e');
      return result;
    }
  }

  /// Force full sync (reset lastSyncTime)
  Future<SyncResult> forceFullSync(String userId) async {
    if (state.isSyncing) {
      return SyncResult(success: false, error: 'Sync already in progress');
    }

    state = state.copyWith(isSyncing: true);

    try {
      final result = await _syncService.forceFullSync(userId);
      state = state.copyWith(
        isSyncing: false,
        lastResult: result,
        lastSyncTime: DateTime.now(),
      );
      return result;
    } catch (e) {
      final result = SyncResult(success: false, error: e.toString());
      state = state.copyWith(
        isSyncing: false,
        lastResult: result,
      );
      return result;
    }
  }
}

/// Provider for SyncNotifier
final syncNotifierProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return SyncNotifier(syncService);
});
