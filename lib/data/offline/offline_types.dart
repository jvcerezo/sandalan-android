/// Offline mutation types — port of offline/types.ts

enum OfflineMutationType {
  addAccount,
  updateAccount,
  deleteAccount,
  addTransaction,
  updateTransaction,
  deleteTransaction,
  importTransactions,
  addGoal,
  updateGoal,
  deleteGoal,
  addFundsToGoal,
  addBudget,
  updateBudget,
  deleteBudget,
  createTransfer,
  uploadAttachment,
}

enum OfflineMutationStatus {
  pending,
  syncing,
  failed,
  conflict,
}

class OfflineMutationRecord {
  final String id;
  final OfflineMutationType type;
  final Map<String, dynamic> payload;
  final OfflineMutationStatus status;
  final String createdAt;
  final String updatedAt;
  final String? error;

  const OfflineMutationRecord({
    required this.id,
    required this.type,
    required this.payload,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.error,
  });
}

class OfflineSyncMeta {
  final String status; // idle | offline | syncing | synced | error
  final int queuedCount;
  final int failedCount;
  final String? lastSyncedAt;
  final String? lastError;
  final int totalSyncRuns;
  final int totalSyncedMutations;
  final int totalFailedMutations;

  const OfflineSyncMeta({
    required this.status,
    required this.queuedCount,
    required this.failedCount,
    this.lastSyncedAt,
    this.lastError,
    required this.totalSyncRuns,
    required this.totalSyncedMutations,
    required this.totalFailedMutations,
  });
}

/// Generate a local offline ID with prefix.
String createOfflineId(String prefix) =>
    'local-$prefix-${DateTime.now().millisecondsSinceEpoch}';

/// Check if a value is an offline-generated ID.
bool isOfflineId(String? value) => value != null && value.startsWith('local-');
