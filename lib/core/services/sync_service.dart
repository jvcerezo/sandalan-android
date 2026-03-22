import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/local/app_database.dart';
import '../../data/repositories/chat_report_repository.dart';
import 'sync_status_notifier.dart';

/// Background sync service: pulls from Supabase into local DB, pushes pending
/// local changes back to Supabase. Uses last-write-wins conflict resolution
/// based on updated_at timestamps.
///
/// Syncs once daily (end of day), when app goes to background, and on manual trigger.
class SyncService with WidgetsBindingObserver {
  final SupabaseClient _client;
  final AppDatabase _db;
  final SyncStatusNotifier? _syncStatus;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _isSyncing = false;
  DateTime? _lastSyncAttempt;
  static const _lastSyncKey = 'last_sync_date';
  static const _minSyncInterval = Duration(seconds: 60);

  SyncService(this._client, this._db, {SyncStatusNotifier? syncStatus})
      : _syncStatus = syncStatus;

  String? get _userId => _client.auth.currentUser?.id;

  // ─── Public API ──────────────────────────────────────────────────────────

  /// Start daily sync: listen for app lifecycle changes and connectivity.
  /// Replaces the old 5-minute periodic timer.
  void startDailySync() {
    // Listen for app lifecycle (sync when app goes to background).
    WidgetsBinding.instance.addObserver(this);

    // Sync when connectivity is restored.
    _connectivitySub?.cancel();
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (isOnline) {
        _syncIfDailyDue();
      }
    });
  }

  /// Stop sync listener and lifecycle observer.
  void stopSync() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySub?.cancel();
    _connectivitySub = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // Sync when app goes to background.
      fullSync();
    }
  }

  /// Check if we should sync today (once per day).
  Future<void> _syncIfDailyDue() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSync = prefs.getString(_lastSyncKey);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (lastSync != today) {
      await fullSync();
      await prefs.setString(_lastSyncKey, today);
    }
  }

  /// Full sync: pull from remote, then push local pending changes.
  /// Rate-limited to at most once per 60 seconds.
  Future<void> fullSync() async {
    if (_isSyncing || _userId == null) return;
    if (!await _isOnline()) return;

    // Rate limit: don't sync more than once per minute
    if (_lastSyncAttempt != null &&
        DateTime.now().difference(_lastSyncAttempt!) < _minSyncInterval) {
      return;
    }
    _lastSyncAttempt = DateTime.now();

    _isSyncing = true;
    _syncStatus?.markSyncing();
    try {
      await pullFromSupabase();
      await pushToSupabase();
      // Sync chat error reports
      try {
        await ChatReportRepository(_db, _client).syncPendingReports();
      } catch (e) {
        if (kDebugMode) debugPrint('SyncService: chat report sync failed: $e');
      }
      _syncStatus?.markSynced();
    } catch (e) {
      if (kDebugMode) debugPrint('SyncService: fullSync failed: $e');
      _syncStatus?.markFailed(e.toString());
    } finally {
      _isSyncing = false;
    }
  }

  // ─── Pull ────────────────────────────────────────────────────────────────

  /// Fetch all tables from Supabase and upsert into local DB.
  /// Only overwrites rows that are 'synced' locally (preserves pending changes).
  Future<void> pullFromSupabase() async {
    final userId = _userId;
    if (userId == null) return;

    await Future.wait([
      _pullTable('transactions', 'local_transactions', userId),
      _pullTable('accounts', 'local_accounts', userId),
      _pullTable('budgets', 'local_budgets', userId),
      _pullTable('goals', 'local_goals', userId),
      _pullTable('contributions', 'local_contributions', userId),
      _pullTable('bills', 'local_bills', userId),
      _pullTable('debts', 'local_debts', userId),
      _pullTable('insurance_policies', 'local_insurance', userId),
    ]);
  }

  Future<void> _pullTable(String remoteTable, String localTable, String userId) async {
    try {
      final data = await _client.from(remoteTable).select().eq('user_id', userId);

      // Batch: collect all pending IDs upfront (1 query instead of N)
      final pendingIds = (await _db.getPendingRows(localTable))
          .map((r) => r['id'] as String)
          .toSet();

      final remoteIds = <String>{};
      for (final row in data) {
        final id = row['id'] as String;
        remoteIds.add(id);
        // Skip if local has pending changes for this row
        if (pendingIds.contains(id)) continue;

        // Timestamp-based conflict resolution: keep the newer version
        final existing = await _db.getRowById(localTable, id);
        if (existing != null) {
          final localUpdated = existing['updated_at'] as String? ?? '';
          final remoteUpdated = row['updated_at'] as String? ?? row['created_at'] as String? ?? '';
          if (localUpdated.compareTo(remoteUpdated) > 0) {
            continue; // local is newer, skip remote
          }
        }

        final localRow = _remoteToLocal(row, remoteTable);
        await _upsertToLocal(localTable, localRow);
      }

      // Guard: only remove deleted rows if remote returned actual data.
      // An empty response could mean API error, not "user deleted everything."
      if (data.isNotEmpty) {
        await _removeDeletedRows(localTable, userId, remoteIds);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('SyncService: pull $remoteTable failed: $e');
    }
  }

  /// Delete local rows that were synced but no longer exist on remote.
  Future<void> _removeDeletedRows(String localTable, String userId, Set<String> remoteIds) async {
    try {
      final localRows = await _db.getSyncedRowIds(localTable, userId);
      for (final localId in localRows) {
        if (!remoteIds.contains(localId)) {
          await _db.deleteRow(localTable, localId);
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('SyncService: removeDeletedRows $localTable failed: $e');
    }
  }

  /// Dispatch upsert to the correct AppDatabase method based on table name.
  Future<void> _upsertToLocal(String localTable, Map<String, dynamic> row) async {
    switch (localTable) {
      case 'local_transactions':
        await _db.upsertTransaction(row);
        break;
      case 'local_accounts':
        await _db.upsertAccount(row);
        break;
      case 'local_budgets':
        await _db.upsertBudget(row);
        break;
      case 'local_goals':
        await _db.upsertGoal(row);
        break;
      case 'local_contributions':
        await _db.upsertContribution(row);
        break;
      case 'local_bills':
        await _db.upsertBill(row);
        break;
      case 'local_debts':
        await _db.upsertDebt(row);
        break;
      case 'local_insurance':
        await _db.upsertInsurance(row);
        break;
    }
  }

  /// Map remote column names to local column names.
  Map<String, dynamic> _remoteToLocal(Map<String, dynamic> row, String remoteTable) {
    final local = Map<String, dynamic>.from(row);
    local['sync_status'] = 'synced';
    if (!local.containsKey('updated_at')) {
      local['updated_at'] = local['created_at'] ?? AppDatabase.now();
    }
    // Encode tags as JSON string for transactions
    if (remoteTable == 'transactions' && local['tags'] is List) {
      local['tags'] = AppDatabase.encodeTags((local['tags'] as List).cast<String>());
    }
    // Convert booleans to integers for SQLite
    for (final key in local.keys.toList()) {
      if (local[key] is bool) {
        local[key] = (local[key] as bool) ? 1 : 0;
      }
    }
    return local;
  }

  // ─── Push ────────────────────────────────────────────────────────────────

  /// Find all pending rows and push to Supabase.
  Future<void> pushToSupabase() async {
    await Future.wait([
      _pushTable('local_transactions', 'transactions'),
      _pushTable('local_accounts', 'accounts'),
      _pushTable('local_budgets', 'budgets'),
      _pushTable('local_goals', 'goals'),
      _pushTable('local_contributions', 'contributions'),
      _pushTable('local_bills', 'bills'),
      _pushTable('local_debts', 'debts'),
      _pushTable('local_insurance', 'insurance_policies'),
    ]);
  }

  Future<void> _pushTable(String localTable, String remoteTable) async {
    try {
      final pending = await _db.getPendingRows(localTable);
      for (final row in pending) {
        try {
          final remoteRow = _localToRemote(row, localTable);
          await _client.from(remoteTable).upsert(remoteRow);
          await _db.markSynced(localTable, row['id'] as String);
        } catch (e) {
          final errorMsg = e.toString();
          debugPrint('SyncService: push $remoteTable row ${row['id']} failed: $errorMsg');

          // Distinguish validation errors (non-retryable) from network errors.
          // Postgres constraint violations (23xxx) and 400 errors won't fix on retry.
          final isValidationError = errorMsg.contains('violates check constraint') ||
              errorMsg.contains('23') || // Postgres integrity constraint class
              errorMsg.contains('400') ||
              errorMsg.contains('not-null') ||
              errorMsg.contains('invalid input');

          await _db.markFailed(
            localTable,
            row['id'] as String,
            reason: isValidationError
                ? 'Validation error: $errorMsg'
                : 'Network error: $errorMsg',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('SyncService: push $remoteTable failed: $e');
    }
  }

  /// Map local column names back to remote, removing local-only fields.
  Map<String, dynamic> _localToRemote(Map<String, dynamic> row, String localTable) {
    final remote = Map<String, dynamic>.from(row);
    remote.remove('sync_status');
    remote.remove('updated_at');

    // Decode tags from JSON string for transactions
    if (localTable == 'local_transactions' && remote['tags'] is String) {
      remote['tags'] = AppDatabase.decodeTags(remote['tags'] as String);
    }
    // Convert SQLite integers back to booleans for known boolean columns
    _convertIntToBool(remote, 'is_archived');
    _convertIntToBool(remote, 'is_completed');
    _convertIntToBool(remote, 'is_paid');
    _convertIntToBool(remote, 'is_paid_off');
    _convertIntToBool(remote, 'is_active');
    _convertIntToBool(remote, 'rollover');

    return remote;
  }

  void _convertIntToBool(Map<String, dynamic> map, String key) {
    if (map.containsKey(key) && map[key] is int) {
      map[key] = (map[key] as int) == 1;
    }
  }

  // ─── Connectivity ───────────────────────────────────────────────────────

  Future<bool> _isOnline() async {
    final results = await Connectivity().checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }
}
