import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sync lifecycle states shown to the user.
enum SyncState { idle, syncing, synced, failed }

/// Immutable snapshot of current sync status.
class SyncStatusState {
  final SyncState state;
  final DateTime? lastSyncTime;
  final String? lastError;
  final int permanentFailureCount;

  const SyncStatusState({
    this.state = SyncState.idle,
    this.lastSyncTime,
    this.lastError,
    this.permanentFailureCount = 0,
  });

  SyncStatusState copyWith({
    SyncState? state,
    DateTime? lastSyncTime,
    String? lastError,
    int? permanentFailureCount,
  }) {
    return SyncStatusState(
      state: state ?? this.state,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      lastError: lastError ?? this.lastError,
      permanentFailureCount: permanentFailureCount ?? this.permanentFailureCount,
    );
  }
}

/// Notifier that tracks sync progress — updated by [SyncService].
class SyncStatusNotifier extends StateNotifier<SyncStatusState> {
  SyncStatusNotifier() : super(const SyncStatusState());

  void markSyncing() {
    state = state.copyWith(state: SyncState.syncing, lastError: null);
  }

  void markSynced() {
    state = SyncStatusState(
      state: SyncState.synced,
      lastSyncTime: DateTime.now(),
    );
  }

  void markFailed(String error) {
    state = state.copyWith(state: SyncState.failed, lastError: error);
  }

  void markIdle() {
    state = state.copyWith(state: SyncState.idle);
  }

  void updatePermanentFailureCount(int count) {
    state = state.copyWith(permanentFailureCount: count);
  }
}

/// Global provider — created once, passed to SyncService.
final syncStatusProvider =
    StateNotifierProvider<SyncStatusNotifier, SyncStatusState>((ref) {
  return SyncStatusNotifier();
});
