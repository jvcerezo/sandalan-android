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
///
/// Pull strategy:
/// - **Incremental** (default): only fetches rows with updated_at > last pull
///   timestamp, skipping delete detection. This cuts bandwidth ~90% after the
///   first sync.
/// - **Full**: fetches everything and removes locally-synced rows that no
///   longer exist on remote. Runs on first-ever sync and once per week to
///   catch server-side deletes.
class SyncService with WidgetsBindingObserver {
  final SupabaseClient _client;
  final AppDatabase _db;
  final SyncStatusNotifier? _syncStatus;

  /// Global instance set in main.dart so auth operations can flush/stop sync.
  static SyncService? instance;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _isSyncing = false;
  static const _lastFullSyncKey = 'last_full_sync_date';
  static const _fullSyncInterval = Duration(days: 7);

  SyncService(this._client, this._db, {SyncStatusNotifier? syncStatus})
      : _syncStatus = syncStatus;

  String? get _userId => _client.auth.currentUser?.id;

  // ─── Public API ──────────────────────────────────────────────────────────

  /// Start listening for app lifecycle to push on background and pull on resume.
  void startDailySync() {
    WidgetsBinding.instance.addObserver(this);
  }

  /// Stop lifecycle observer.
  void stopSync() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySub?.cancel();
    _connectivitySub = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // Push any remaining pending changes when app goes to background.
      pushAfterWrite();
    } else if (state == AppLifecycleState.resumed) {
      // Pull fresh data when app comes back (another device may have synced).
      fullSync();
    }
  }

  /// Push pending local changes to Supabase immediately.
  /// Called after every write (create/update/delete) in repositories.
  /// Capped at 1 push per 2 seconds to prevent accidental infinite loops.
  DateTime? _lastPushAt;

  Future<void> pushAfterWrite() async {
    if (_isSyncing || _userId == null) return;
    if (_lastPushAt != null && DateTime.now().difference(_lastPushAt!) < const Duration(seconds: 2)) return;
    if (!await _isOnline()) return;
    _lastPushAt = DateTime.now();

    try {
      await pushToSupabase();
    } catch (e) {
      debugPrint('[SyncService] pushAfterWrite failed: $e');
    }
  }

  /// Sync: pull from remote, then push local pending changes.
  ///
  /// Uses incremental pull by default (only rows changed since last pull).
  /// Pass [forceFullPull] = true to fetch everything and detect deletes.
  /// A full pull also runs automatically once per week and on first-ever sync.
  Future<void> fullSync({bool forceFullPull = false}) async {
    if (_isSyncing) return;

    // Wait briefly for auth session to propagate (can be null right after login)
    var userId = _userId;
    if (userId == null) {
      await Future.delayed(const Duration(milliseconds: 500));
      userId = _userId;
      if (userId == null) {
        debugPrint('[SyncService] fullSync aborted — no userId');
        return;
      }
    }

    if (!await _isOnline()) {
      debugPrint('[SyncService] fullSync aborted — offline');
      return;
    }

    _isSyncing = true;
    _syncStatus?.markSyncing();
    debugPrint('[SyncService] fullSync started — userId=$userId, forceFullPull=$forceFullPull');
    try {
      final needsFullPull = forceFullPull || await _isFullPullDue();
      debugPrint('[SyncService] pulling (fullPull=$needsFullPull)...');
      await pullFromSupabase(fullPull: needsFullPull);
      debugPrint('[SyncService] pushing...');
      await pushToSupabase();
      // Sync chat error reports
      try {
        await ChatReportRepository(_db, _client).syncPendingReports();
      } catch (e) {
        if (kDebugMode) debugPrint('SyncService: chat report sync failed: $e');
      }
      if (needsFullPull) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_lastFullSyncKey, DateTime.now().toUtc().toIso8601String());
      }
      _syncStatus?.markSynced();
    } catch (e) {
      if (kDebugMode) debugPrint('SyncService: fullSync failed: $e');
      _syncStatus?.markFailed(e.toString());
    } finally {
      _isSyncing = false;
    }
  }

  /// Returns true if a full pull is needed (first sync or > 7 days since last full pull).
  Future<bool> _isFullPullDue() async {
    final prefs = await SharedPreferences.getInstance();
    final lastFull = prefs.getString(_lastFullSyncKey);
    if (lastFull == null) return true; // first-ever sync
    final lastFullDate = DateTime.tryParse(lastFull);
    if (lastFullDate == null) return true;
    return DateTime.now().toUtc().difference(lastFullDate) >= _fullSyncInterval;
  }

  /// Push all pending local changes to Supabase before logout/deletion.
  /// Ignores rate limiting and sync lock — this is a last-chance flush.
  /// Returns silently on failure (best-effort).
  Future<void> flushPending() async {
    if (_userId == null) return;
    if (!await _isOnline()) return;
    try {
      await pushToSupabase();
    } catch (e) {
      if (kDebugMode) debugPrint('SyncService: flushPending failed: $e');
    }
  }

  /// Clear all per-table pull timestamps and sync date from SharedPreferences.
  /// Must be called on logout to prevent cross-user stale data.
  static Future<void> clearSyncTimestamps() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('last_pull_')).toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
    await prefs.remove(_lastFullSyncKey);
  }

  // ─── Pull ────────────────────────────────────────────────────────────────

  /// Fetch tables from Supabase and upsert into local DB.
  /// Only overwrites rows that are 'synced' locally (preserves pending changes).
  ///
  /// When [fullPull] is false (default), only rows updated since the last
  /// successful pull are fetched. Delete detection is skipped because we can't
  /// distinguish "not updated" from "deleted" with a partial result set.
  /// A full pull runs on first sync and weekly to reconcile deletes.
  Future<void> pullFromSupabase({bool fullPull = false}) async {
    final userId = _userId;
    if (userId == null) return;

    final tables = [
      ('transactions', 'local_transactions'),
      ('accounts', 'local_accounts'),
      ('budgets', 'local_budgets'),
      ('goals', 'local_goals'),
      ('contributions', 'local_contributions'),
      ('bills', 'local_bills'),
      ('debts', 'local_debts'),
      ('insurance_policies', 'local_insurance'),
      ('investments', 'local_investments'),
    ];

    final prefs = await SharedPreferences.getInstance();

    await Future.wait([
      for (final (remote, local) in tables)
        _pullTable(remote, local, userId, prefs, fullPull: fullPull),
    ]);
  }

  /// SharedPreferences key for the last successful pull timestamp of a table.
  static String _lastPullKey(String remoteTable) => 'last_pull_$remoteTable';

  Future<void> _pullTable(
    String remoteTable,
    String localTable,
    String userId,
    SharedPreferences prefs, {
    required bool fullPull,
  }) async {
    try {
      // Decide whether to do an incremental or full pull for this table.
      final lastPullAt = prefs.getString(_lastPullKey(remoteTable));
      final isIncremental = !fullPull && lastPullAt != null;

      // Build query — incremental only fetches rows updated since last pull.
      var query = _client.from(remoteTable).select().eq('user_id', userId);
      if (isIncremental) {
        query = query.gte('updated_at', lastPullAt);
      }

      final data = await query;
      debugPrint('[SyncService] pulled ${data.length} rows from $remoteTable (incremental=$isIncremental)');

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

        final localRow = remoteToLocal(row, remoteTable);
        await _upsertToLocal(localTable, localRow);
      }

      // Only detect deletes on full pulls — incremental results don't include
      // unchanged rows, so missing IDs don't mean "deleted".
      if (!isIncremental && data.isNotEmpty) {
        await _removeDeletedRows(localTable, userId, remoteIds);
      }

      // Persist the pull timestamp ONLY after successful completion.
      // If app is killed mid-pull, we'll re-fetch from the old timestamp.
      await prefs.setString(
        _lastPullKey(remoteTable),
        DateTime.now().toUtc().toIso8601String(),
      );
    } catch (e) {
      // Don't persist timestamp on failure — next sync will retry from last good point
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
      case 'local_investments':
        await _db.upsertInvestment(row);
        break;
    }
  }

  /// Map remote column names to local column names.
  @visibleForTesting
  Map<String, dynamic> remoteToLocal(Map<String, dynamic> row, String remoteTable) {
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
  /// Each table push is wrapped in try-catch so one failing table
  /// doesn't break all sync (e.g. if a Supabase table doesn't exist yet).
  Future<void> pushToSupabase() async {
    final pushes = <(String, String)>[
      ('local_transactions', 'transactions'),
      ('local_accounts', 'accounts'),
      ('local_budgets', 'budgets'),
      ('local_goals', 'goals'),
      ('local_contributions', 'contributions'),
      ('local_bills', 'bills'),
      ('local_debts', 'debts'),
      ('local_insurance', 'insurance_policies'),
      ('local_investments', 'investments'),
      // NOTE: local_bill_splits is local-only, no Supabase table for it
    ];
    for (final (local, remote) in pushes) {
      try {
        await _pushTable(local, remote);
      } catch (e) {
        if (kDebugMode) debugPrint('SyncService: push $remote failed: $e');
      }
    }
  }

  static const _maxRetryCount = 3;

  Future<void> _pushTable(String localTable, String remoteTable) async {
    try {
      final pending = await _db.getPendingRows(localTable);
      if (pending.isNotEmpty) {
        debugPrint('[SyncService] pushing ${pending.length} rows from $localTable');
      }
      for (final row in pending) {
        // Skip rows that have permanently failed
        final syncStatus = row['sync_status'] as String? ?? '';
        if (syncStatus == 'failed_permanent') continue;

        // Track retry count via failure_reason prefix
        final failureReason = row['failure_reason'] as String? ?? '';
        final retryCount = parseRetryCount(failureReason);
        if (retryCount >= _maxRetryCount) {
          // Mark as permanently failed — stop retrying
          await _db.markFailedPermanent(localTable, row['id'] as String,
              reason: 'Max retries ($retryCount) exceeded. Last error: $failureReason');
          continue;
        }

        try {
          final remoteRow = localToRemote(row, localTable);
          await _client.from(remoteTable).upsert(remoteRow);
          await _db.markSynced(localTable, row['id'] as String);
          debugPrint('[SyncService] pushed ${row['id']} to $remoteTable OK');
        } catch (e) {
          final errorMsg = e.toString();
          debugPrint('SyncService: push $remoteTable row ${row['id']} failed (attempt ${retryCount + 1}): $errorMsg');

          // Distinguish validation errors (non-retryable) from network errors.
          final isValidationError = errorMsg.contains('violates check constraint') ||
              errorMsg.contains('23') ||
              errorMsg.contains('400') ||
              errorMsg.contains('not-null') ||
              errorMsg.contains('invalid input');

          if (isValidationError) {
            // Validation errors will never succeed — mark permanent immediately
            await _db.markFailedPermanent(
              localTable,
              row['id'] as String,
              reason: 'Validation error: $errorMsg',
            );
          } else {
            await _db.markFailed(
              localTable,
              row['id'] as String,
              reason: 'retry:${retryCount + 1} Network error: $errorMsg',
            );
          }
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('SyncService: push $remoteTable failed: $e');
    }
  }

  /// Parse the retry count from a failure_reason string that starts with "retry:N ".
  @visibleForTesting
  static int parseRetryCount(String failureReason) {
    final match = RegExp(r'^retry:(\d+)\s').firstMatch(failureReason);
    return match != null ? int.tryParse(match.group(1)!) ?? 0 : 0;
  }

  /// Clear all permanently failed rows by marking them as synced.
  Future<void> clearFailedRows() async {
    final tables = [
      'local_transactions', 'local_accounts', 'local_budgets', 'local_goals',
      'local_contributions', 'local_bills', 'local_debts', 'local_insurance',
      'local_investments',
    ];
    for (final table in tables) {
      await _db.clearPermanentlyFailed(table);
    }
  }

  /// Map local column names back to remote, removing local-only fields.
  @visibleForTesting
  Map<String, dynamic> localToRemote(Map<String, dynamic> row, String localTable) {
    final remote = Map<String, dynamic>.from(row);
    // Remove local-only columns that don't exist on Supabase
    remote.remove('sync_status');
    remote.remove('failure_reason');
    remote.remove('status'); // confirmed/pending is local-only

    // Decode tags from JSON string for transactions
    if (localTable == 'local_transactions' && remote['tags'] is String) {
      remote['tags'] = AppDatabase.decodeTags(remote['tags'] as String);
    }
    // Convert SQLite integers back to booleans for all is_* and known boolean columns.
    // Generic approach: any column starting with is_ or named rollover is boolean.
    for (final key in remote.keys.toList()) {
      if (remote[key] is int && (key.startsWith('is_') || key == 'rollover')) {
        remote[key] = (remote[key] as int) == 1;
      }
    }

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
