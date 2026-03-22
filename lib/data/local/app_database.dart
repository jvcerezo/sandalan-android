import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Offline-first local SQLite database using Drift's raw SQL approach.
/// No code generation needed — all queries use customSelect / customInsert.
class AppDatabase {
  final DatabaseConnection _connection;
  late final GeneratedDatabase _db;

  AppDatabase._(this._connection) {
    _db = _RawDatabase(_connection);
  }

  static AppDatabase? _instance;

  static AppDatabase get instance {
    if (_instance == null) {
      throw StateError('AppDatabase not initialized. Call AppDatabase.init() first.');
    }
    return _instance!;
  }

  static Future<void> init() async {
    if (_instance != null) return;
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'sandalan.sqlite'));
    final connection = DatabaseConnection(NativeDatabase.createInBackground(file));
    _instance = AppDatabase._(connection);
    await _instance!._createTables();
  }

  /// For testing with an in-memory database.
  static void initWith(DatabaseConnection connection) {
    _instance = AppDatabase._(connection);
  }

  DatabaseConnection get connection => _connection;

  Future<void> _createTables() async {
    await _db.customStatement('''
      CREATE TABLE IF NOT EXISTS local_transactions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        description TEXT NOT NULL,
        date TEXT NOT NULL,
        currency TEXT NOT NULL DEFAULT 'PHP',
        attachment_path TEXT,
        account_id TEXT,
        transfer_id TEXT,
        split_group_id TEXT,
        tags TEXT,
        status TEXT NOT NULL DEFAULT 'confirmed',
        sync_status TEXT NOT NULL DEFAULT 'synced',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL DEFAULT ''
      )
    ''');
    await _db.customStatement('''
      CREATE TABLE IF NOT EXISTS local_accounts (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        currency TEXT NOT NULL DEFAULT 'PHP',
        balance REAL NOT NULL DEFAULT 0,
        is_archived INTEGER NOT NULL DEFAULT 0,
        sync_status TEXT NOT NULL DEFAULT 'synced',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL DEFAULT ''
      )
    ''');
    await _db.customStatement('''
      CREATE TABLE IF NOT EXISTS local_budgets (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        month TEXT NOT NULL,
        period TEXT NOT NULL DEFAULT 'monthly',
        rollover INTEGER NOT NULL DEFAULT 0,
        sync_status TEXT NOT NULL DEFAULT 'synced',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL DEFAULT ''
      )
    ''');
    await _db.customStatement('''
      CREATE TABLE IF NOT EXISTS local_goals (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        target_amount REAL NOT NULL,
        current_amount REAL NOT NULL DEFAULT 0,
        deadline TEXT,
        category TEXT NOT NULL DEFAULT 'Savings',
        account_id TEXT,
        is_completed INTEGER NOT NULL DEFAULT 0,
        sync_status TEXT NOT NULL DEFAULT 'synced',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL DEFAULT ''
      )
    ''');
    // Migration: add new columns if missing
    try { await _db.customStatement('ALTER TABLE local_goals ADD COLUMN account_id TEXT'); } catch (_) {}
    try { await _db.customStatement("ALTER TABLE local_transactions ADD COLUMN status TEXT NOT NULL DEFAULT 'confirmed'"); } catch (_) {}
    await _db.customStatement('''
      CREATE TABLE IF NOT EXISTS local_contributions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        type TEXT NOT NULL,
        period TEXT NOT NULL,
        monthly_salary REAL NOT NULL,
        employee_share REAL NOT NULL,
        employer_share REAL,
        total_contribution REAL NOT NULL,
        is_paid INTEGER NOT NULL DEFAULT 0,
        employment_type TEXT NOT NULL DEFAULT 'employed',
        notes TEXT,
        sync_status TEXT NOT NULL DEFAULT 'synced',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL DEFAULT ''
      )
    ''');
    await _db.customStatement('''
      CREATE TABLE IF NOT EXISTS local_bills (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        billing_cycle TEXT NOT NULL DEFAULT 'monthly',
        due_day INTEGER,
        provider TEXT,
        last_paid_date TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        notes TEXT,
        account_id TEXT,
        sync_status TEXT NOT NULL DEFAULT 'synced',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL DEFAULT ''
      )
    ''');
    await _db.customStatement('''
      CREATE TABLE IF NOT EXISTS local_debts (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        lender TEXT,
        current_balance REAL NOT NULL,
        original_amount REAL NOT NULL,
        interest_rate REAL NOT NULL,
        minimum_payment REAL NOT NULL,
        due_day INTEGER,
        is_paid_off INTEGER NOT NULL DEFAULT 0,
        notes TEXT,
        account_id TEXT,
        sync_status TEXT NOT NULL DEFAULT 'synced',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL DEFAULT ''
      )
    ''');
    await _db.customStatement('''
      CREATE TABLE IF NOT EXISTS local_insurance (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        provider TEXT,
        policy_number TEXT,
        premium_amount REAL NOT NULL,
        premium_frequency TEXT NOT NULL DEFAULT 'monthly',
        coverage_amount REAL,
        renewal_date TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        notes TEXT,
        account_id TEXT,
        sync_status TEXT NOT NULL DEFAULT 'synced',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL DEFAULT ''
      )
    ''');

    // ─── Net Worth Snapshots ────────────────────────────────────────────────
    await _db.customStatement('''
      CREATE TABLE IF NOT EXISTS net_worth_snapshots (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        date TEXT NOT NULL,
        total REAL NOT NULL,
        breakdown TEXT,
        created_at TEXT NOT NULL DEFAULT '',
        UNIQUE(user_id, date)
      )
    ''');

    // ─── Chat AI tables ───────────────────────────────────────────────────
    await _db.customStatement('''
      CREATE TABLE IF NOT EXISTS learned_keywords (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL DEFAULT '',
        keyword TEXT NOT NULL,
        category TEXT NOT NULL,
        source TEXT NOT NULL DEFAULT 'user_pick',
        correction_count INTEGER NOT NULL DEFAULT 0,
        usage_count INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL DEFAULT '',
        updated_at TEXT NOT NULL DEFAULT '',
        UNIQUE(user_id, keyword)
      )
    ''');
    await _db.customStatement('''
      CREATE TABLE IF NOT EXISTS chat_report_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL DEFAULT '',
        user_input TEXT NOT NULL,
        parsed_intent TEXT NOT NULL,
        parsed_amount REAL,
        parsed_category TEXT,
        parsed_description TEXT,
        parsed_account TEXT,
        parsed_type TEXT,
        category_source TEXT,
        tflite_confidence REAL,
        error_type TEXT NOT NULL,
        corrected_category TEXT,
        corrected_amount REAL,
        corrected_account TEXT,
        corrected_type TEXT,
        corrected_description TEXT,
        user_comment TEXT,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        created_at TEXT NOT NULL DEFAULT ''
      )
    ''');

    // Create indexes for common queries
    await _db.customStatement('CREATE INDEX IF NOT EXISTS idx_transactions_user ON local_transactions(user_id)');
    await _db.customStatement('CREATE INDEX IF NOT EXISTS idx_transactions_sync ON local_transactions(sync_status)');
    await _db.customStatement('CREATE INDEX IF NOT EXISTS idx_tx_date ON local_transactions(user_id, date DESC)');
    await _db.customStatement('CREATE INDEX IF NOT EXISTS idx_tx_status ON local_transactions(user_id, status)');
    await _db.customStatement('CREATE INDEX IF NOT EXISTS idx_tx_category ON local_transactions(user_id, category)');
    await _db.customStatement('CREATE INDEX IF NOT EXISTS idx_tx_account ON local_transactions(user_id, account_id)');
    await _db.customStatement('CREATE INDEX IF NOT EXISTS idx_accounts_user ON local_accounts(user_id)');
    await _db.customStatement('CREATE INDEX IF NOT EXISTS idx_budgets_user ON local_budgets(user_id)');
    await _db.customStatement('CREATE INDEX IF NOT EXISTS idx_goals_user ON local_goals(user_id)');
    await _db.customStatement('CREATE INDEX IF NOT EXISTS idx_contributions_user ON local_contributions(user_id)');
    await _db.customStatement('CREATE INDEX IF NOT EXISTS idx_bills_user ON local_bills(user_id)');
    await _db.customStatement('CREATE INDEX IF NOT EXISTS idx_debts_user ON local_debts(user_id)');
    await _db.customStatement('CREATE INDEX IF NOT EXISTS idx_insurance_user ON local_insurance(user_id)');
    await _db.customStatement('CREATE INDEX IF NOT EXISTS idx_net_worth_user_date ON net_worth_snapshots(user_id, date DESC)');
    await _db.customStatement('CREATE INDEX IF NOT EXISTS idx_learned_keyword ON learned_keywords(user_id, keyword)');
    await _db.customStatement('CREATE INDEX IF NOT EXISTS idx_chat_report_sync ON chat_report_queue(user_id, sync_status)');

    // ─── Migrations for existing installs ─────────────────────────────
    await _migrateSchema();
  }

  /// Add columns that didn't exist in earlier schema versions.
  /// Each ALTER is wrapped in try/catch so it's safe to re-run.
  Future<void> _migrateSchema() async {
    // v9: add user_id to learned_keywords and chat_report_queue
    for (final table in ['learned_keywords', 'chat_report_queue']) {
      try {
        await _db.customStatement("ALTER TABLE $table ADD COLUMN user_id TEXT NOT NULL DEFAULT ''");
      } catch (_) {
        // Column already exists — safe to ignore
      }
    }

    // v10: net_worth_snapshots table (handled by CREATE TABLE IF NOT EXISTS above,
    // but ensure the table exists for older installs that skip _createTables partially)
    try {
      await _db.customStatement('''
        CREATE TABLE IF NOT EXISTS net_worth_snapshots (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          date TEXT NOT NULL,
          total REAL NOT NULL,
          breakdown TEXT,
          created_at TEXT NOT NULL DEFAULT '',
          UNIQUE(user_id, date)
        )
      ''');
    } catch (_) {}
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  static String now() => DateTime.now().toUtc().toIso8601String();

  static String? encodeTags(List<String>? tags) {
    if (tags == null || tags.isEmpty) return null;
    return jsonEncode(tags);
  }

  static List<String>? decodeTags(String? encoded) {
    if (encoded == null || encoded.isEmpty) return null;
    return (jsonDecode(encoded) as List<dynamic>).cast<String>();
  }

  // ─── Generic upsert ─────────────────────────────────────────────────────

  Future<void> _upsert(String table, Map<String, dynamic> values) async {
    final columns = values.keys.join(', ');
    final placeholders = values.keys.map((_) => '?').join(', ');
    final updateClauses = values.keys
        .where((k) => k != 'id')
        .map((k) => '$k = excluded.$k')
        .join(', ');

    await _db.customStatement(
      'INSERT INTO $table ($columns) VALUES ($placeholders) '
      'ON CONFLICT(id) DO UPDATE SET $updateClauses',
      values.values.toList(),
    );
  }

  // ─── Transactions ────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getTransactions(String userId) async {
    final results = await _db.customSelect(
      'SELECT * FROM local_transactions WHERE user_id = ? ORDER BY date DESC, created_at DESC',
      variables: [Variable.withString(userId)],
    ).get();
    return results.map((r) => r.data).toList();
  }

  Future<List<Map<String, dynamic>>> getRecentTransactions(String userId, {int limit = 10}) async {
    final results = await _db.customSelect(
      'SELECT * FROM local_transactions WHERE user_id = ? ORDER BY date DESC, created_at DESC LIMIT ?',
      variables: [Variable.withString(userId), Variable.withInt(limit)],
    ).get();
    return results.map((r) => r.data).toList();
  }

  Future<List<Map<String, dynamic>>> getFilteredTransactions(
    String userId, {
    String? category,
    String? type,
    String? search,
    String? startDate,
    String? endDate,
    String? accountId,
    int page = 1,
    int pageSize = 20,
  }) async {
    var where = 'WHERE user_id = ?';
    final vars = <Variable>[Variable.withString(userId)];

    if (category != null) {
      where += ' AND category = ?';
      vars.add(Variable.withString(category));
    }
    if (accountId != null) {
      where += ' AND account_id = ?';
      vars.add(Variable.withString(accountId));
    }
    if (startDate != null) {
      where += ' AND date >= ?';
      vars.add(Variable.withString(startDate));
    }
    if (endDate != null) {
      where += ' AND date <= ?';
      vars.add(Variable.withString(endDate));
    }
    if (type == 'income') where += ' AND amount > 0';
    if (type == 'expense') where += ' AND amount < 0';
    if (search != null && search.isNotEmpty) {
      where += ' AND description LIKE ?';
      vars.add(Variable.withString('%$search%'));
    }

    final offset = (page - 1) * pageSize;
    final results = await _db.customSelect(
      'SELECT * FROM local_transactions $where ORDER BY date DESC, created_at DESC LIMIT $pageSize OFFSET $offset',
      variables: vars,
    ).get();
    return results.map((r) => r.data).toList();
  }

  Future<int> getFilteredTransactionsCount(
    String userId, {
    String? category,
    String? type,
    String? startDate,
    String? endDate,
    String? accountId,
  }) async {
    var where = "WHERE user_id = ? AND category != 'Transfer'";
    final vars = <Variable>[Variable.withString(userId)];

    if (category != null) {
      where += ' AND category = ?';
      vars.add(Variable.withString(category));
    }
    if (accountId != null) {
      where += ' AND account_id = ?';
      vars.add(Variable.withString(accountId));
    }
    if (startDate != null) {
      where += ' AND date >= ?';
      vars.add(Variable.withString(startDate));
    }
    if (endDate != null) {
      where += ' AND date <= ?';
      vars.add(Variable.withString(endDate));
    }
    if (type == 'income') where += ' AND amount > 0';
    if (type == 'expense') where += ' AND amount < 0';

    final results = await _db.customSelect(
      'SELECT COUNT(*) as cnt FROM local_transactions $where',
      variables: vars,
    ).get();
    return results.first.data['cnt'] as int;
  }

  Future<void> upsertTransaction(Map<String, dynamic> values) => _upsert('local_transactions', values);

  /// Get income/expense totals using SQL aggregation (avoids loading all rows into Dart).
  Future<Map<String, double>> getTransactionsSummaryAggregate(
    String userId, {
    required String startDate,
    required String endDate,
  }) async {
    final results = await _db.customSelect(
      '''SELECT
        COALESCE(SUM(CASE WHEN amount > 0 AND LOWER(category) NOT IN ('transfer', 'goal funding') AND status = 'confirmed' THEN amount ELSE 0 END), 0) as income,
        COALESCE(SUM(CASE WHEN amount < 0 AND LOWER(category) NOT IN ('transfer', 'goal funding') AND status = 'confirmed' THEN ABS(amount) ELSE 0 END), 0) as expenses
      FROM local_transactions
      WHERE user_id = ? AND date >= ? AND date <= ?''',
      variables: [
        Variable.withString(userId),
        Variable.withString(startDate),
        Variable.withString(endDate),
      ],
    ).get();

    final row = results.first.data;
    return {
      'income': (row['income'] as num).toDouble(),
      'expenses': (row['expenses'] as num).toDouble(),
    };
  }

  /// Get total balance across all accounts using SQL aggregation.
  Future<double> getTotalAccountBalance(String userId) async {
    final results = await _db.customSelect(
      'SELECT COALESCE(SUM(balance), 0) as total FROM local_accounts WHERE user_id = ?',
      variables: [Variable.withString(userId)],
    ).get();
    return (results.first.data['total'] as num).toDouble();
  }

  Future<List<Map<String, dynamic>>> getPendingTransactions(String userId) async {
    final results = await _db.customSelect(
      "SELECT * FROM local_transactions WHERE user_id = ? AND status = 'pending' ORDER BY date DESC, created_at DESC",
      variables: [Variable.withString(userId)],
    ).get();
    return results.map((r) => r.data).toList();
  }

  Future<void> deleteTransaction(String id) async {
    await _db.customStatement('DELETE FROM local_transactions WHERE id = ?', [id]);
  }

  Future<void> deleteTransactionsByAccountId(String accountId) async {
    await _db.customStatement('DELETE FROM local_transactions WHERE account_id = ?', [accountId]);
  }

  Future<int> countTransactionsByAccountId(String accountId) async {
    final results = await _db.customSelect(
      'SELECT COUNT(*) as cnt FROM local_transactions WHERE account_id = ?',
      variables: [Variable.withString(accountId)],
    ).get();
    return results.first.data['cnt'] as int;
  }

  // ─── Accounts ────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getAccounts(String userId, {bool archived = false}) async {
    final results = await _db.customSelect(
      'SELECT * FROM local_accounts WHERE user_id = ? AND is_archived = ? ORDER BY name ASC',
      variables: [Variable.withString(userId), Variable.withInt(archived ? 1 : 0)],
    ).get();
    return results.map((r) => r.data).toList();
  }

  Future<List<Map<String, dynamic>>> getAllAccounts(String userId) async {
    final results = await _db.customSelect(
      'SELECT * FROM local_accounts WHERE user_id = ?',
      variables: [Variable.withString(userId)],
    ).get();
    return results.map((r) => r.data).toList();
  }

  Future<void> upsertAccount(Map<String, dynamic> values) => _upsert('local_accounts', values);

  Future<void> deleteAccount(String id) async {
    await _db.customStatement('DELETE FROM local_accounts WHERE id = ?', [id]);
  }

  // ─── Budgets ─────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getBudgets(String userId, String month, String period) async {
    final results = await _db.customSelect(
      'SELECT * FROM local_budgets WHERE user_id = ? AND month = ? AND period = ? ORDER BY category ASC',
      variables: [Variable.withString(userId), Variable.withString(month), Variable.withString(period)],
    ).get();
    return results.map((r) => r.data).toList();
  }

  Future<List<Map<String, dynamic>>> getAllBudgets(String userId) async {
    final results = await _db.customSelect(
      'SELECT * FROM local_budgets WHERE user_id = ?',
      variables: [Variable.withString(userId)],
    ).get();
    return results.map((r) => r.data).toList();
  }

  Future<void> upsertBudget(Map<String, dynamic> values) => _upsert('local_budgets', values);

  Future<void> deleteBudget(String id) async {
    await _db.customStatement('DELETE FROM local_budgets WHERE id = ?', [id]);
  }

  // ─── Goals ───────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getGoals(String userId) async {
    final results = await _db.customSelect(
      'SELECT * FROM local_goals WHERE user_id = ? ORDER BY is_completed ASC, created_at DESC',
      variables: [Variable.withString(userId)],
    ).get();
    return results.map((r) => r.data).toList();
  }

  Future<void> upsertGoal(Map<String, dynamic> values) => _upsert('local_goals', values);

  Future<void> deleteGoal(String id) async {
    await _db.customStatement('DELETE FROM local_goals WHERE id = ?', [id]);
  }

  // ─── Contributions ──────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getContributions(String userId, {String? period}) async {
    var sql = 'SELECT * FROM local_contributions WHERE user_id = ?';
    final vars = <Variable>[Variable.withString(userId)];
    if (period != null) {
      sql += ' AND period = ?';
      vars.add(Variable.withString(period));
    }
    sql += ' ORDER BY period DESC';
    final results = await _db.customSelect(sql, variables: vars).get();
    return results.map((r) => r.data).toList();
  }

  Future<void> upsertContribution(Map<String, dynamic> values) => _upsert('local_contributions', values);

  Future<void> deleteContribution(String id) async {
    await _db.customStatement('DELETE FROM local_contributions WHERE id = ?', [id]);
  }

  // ─── Bills ───────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getBills(String userId) async {
    final results = await _db.customSelect(
      'SELECT * FROM local_bills WHERE user_id = ? ORDER BY is_active DESC, category ASC',
      variables: [Variable.withString(userId)],
    ).get();
    return results.map((r) => r.data).toList();
  }

  Future<void> upsertBill(Map<String, dynamic> values) => _upsert('local_bills', values);

  Future<void> deleteBill(String id) async {
    await _db.customStatement('DELETE FROM local_bills WHERE id = ?', [id]);
  }

  // ─── Debts ───────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getDebts(String userId) async {
    final results = await _db.customSelect(
      'SELECT * FROM local_debts WHERE user_id = ? ORDER BY is_paid_off ASC, current_balance DESC',
      variables: [Variable.withString(userId)],
    ).get();
    return results.map((r) => r.data).toList();
  }

  Future<void> upsertDebt(Map<String, dynamic> values) => _upsert('local_debts', values);

  Future<void> deleteDebt(String id) async {
    await _db.customStatement('DELETE FROM local_debts WHERE id = ?', [id]);
  }

  // ─── Insurance ───────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getInsurancePolicies(String userId) async {
    final results = await _db.customSelect(
      'SELECT * FROM local_insurance WHERE user_id = ? ORDER BY is_active DESC, type ASC',
      variables: [Variable.withString(userId)],
    ).get();
    return results.map((r) => r.data).toList();
  }

  Future<void> upsertInsurance(Map<String, dynamic> values) => _upsert('local_insurance', values);

  Future<void> deleteInsurance(String id) async {
    await _db.customStatement('DELETE FROM local_insurance WHERE id = ?', [id]);
  }

  // ─── Net Worth Snapshots ─────────────────────────────────────────────────

  Future<void> upsertNetWorthSnapshot(Map<String, dynamic> row) async {
    final columns = row.keys.join(', ');
    final placeholders = row.keys.map((_) => '?').join(', ');
    final updateClauses = row.keys
        .where((k) => k != 'id' && k != 'user_id' && k != 'date')
        .map((k) => '$k = excluded.$k')
        .join(', ');

    await _db.customStatement(
      'INSERT INTO net_worth_snapshots ($columns) VALUES ($placeholders) '
      'ON CONFLICT(user_id, date) DO UPDATE SET $updateClauses',
      row.values.toList(),
    );
  }

  Future<List<Map<String, dynamic>>> getNetWorthSnapshots(String userId, {int months = 6}) async {
    final cutoff = DateTime.now().subtract(Duration(days: months * 31));
    final cutoffStr = '${cutoff.year}-${cutoff.month.toString().padLeft(2, '0')}-${cutoff.day.toString().padLeft(2, '0')}';
    final results = await _db.customSelect(
      'SELECT * FROM net_worth_snapshots WHERE user_id = ? AND date >= ? ORDER BY date DESC',
      variables: [Variable.withString(userId), Variable.withString(cutoffStr)],
    ).get();
    return results.map((r) => r.data).toList();
  }

  // ─── Learned Keywords ────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getLearnedKeyword(String keyword, {required String userId}) async {
    final results = await _db.customSelect(
      'SELECT * FROM learned_keywords WHERE user_id = ? AND keyword = ? LIMIT 1',
      variables: [Variable.withString(userId), Variable.withString(keyword.toLowerCase())],
    ).get();
    if (results.isEmpty) return null;
    return results.first.data;
  }

  Future<List<Map<String, dynamic>>> getAllLearnedKeywords({required String userId}) async {
    final results = await _db.customSelect(
      'SELECT * FROM learned_keywords WHERE user_id = ? ORDER BY usage_count DESC',
      variables: [Variable.withString(userId)],
    ).get();
    return results.map((r) => r.data).toList();
  }

  Future<void> upsertLearnedKeyword({
    required String keyword,
    required String category,
    required String source,
    required String userId,
  }) async {
    final now = AppDatabase.now();
    final existing = await getLearnedKeyword(keyword, userId: userId);
    if (existing != null) {
      await _db.customStatement(
        '''UPDATE learned_keywords
           SET category = ?, source = ?,
               correction_count = correction_count + CASE WHEN ? = 'correction' THEN 1 ELSE 0 END,
               usage_count = usage_count + 1,
               updated_at = ?
           WHERE user_id = ? AND keyword = ?''',
        [category, source, source, now, userId, keyword.toLowerCase()],
      );
    } else {
      await _db.customStatement(
        '''INSERT INTO learned_keywords (user_id, keyword, category, source, correction_count, usage_count, created_at, updated_at)
           VALUES (?, ?, ?, ?, ?, 1, ?, ?)''',
        [userId, keyword.toLowerCase(), category, source, source == 'correction' ? 1 : 0, now, now],
      );
    }
  }

  // ─── Chat Report Queue ─────────────────────────────────────────────────

  Future<void> insertChatReport(Map<String, dynamic> values) async {
    final cols = values.keys.join(', ');
    final placeholders = values.keys.map((_) => '?').join(', ');
    await _db.customStatement(
      'INSERT INTO chat_report_queue ($cols) VALUES ($placeholders)',
      values.values.toList(),
    );
  }

  Future<List<Map<String, dynamic>>> getPendingChatReports({required String userId}) async {
    final results = await _db.customSelect(
      "SELECT * FROM chat_report_queue WHERE user_id = ? AND sync_status = 'pending'",
      variables: [Variable.withString(userId)],
    ).get();
    return results.map((r) => r.data).toList();
  }

  Future<void> markChatReportSynced(int id) async {
    await _db.customStatement(
      "UPDATE chat_report_queue SET sync_status = 'synced' WHERE id = ?",
      [id],
    );
  }

  // ─── Row lookup ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getRowById(String table, String id) async {
    final results = await _db.customSelect(
      'SELECT * FROM $table WHERE id = ? LIMIT 1',
      variables: [Variable.withString(id)],
    ).get();
    if (results.isEmpty) return null;
    return results.first.data;
  }

  // ─── Pending sync queries ────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getPendingRows(String table) async {
    final results = await _db.customSelect(
      "SELECT * FROM $table WHERE sync_status IN ('pending', 'failed')",
    ).get();
    return results.map((r) => r.data).toList();
  }

  Future<void> markSynced(String table, String id) async {
    await _db.customStatement(
      "UPDATE $table SET sync_status = 'synced' WHERE id = ?",
      [id],
    );
  }

  Future<void> markFailed(String table, String id) async {
    await _db.customStatement(
      "UPDATE $table SET sync_status = 'failed' WHERE id = ?",
      [id],
    );
  }

  /// Get IDs of all synced rows for a user in a table (for remote deletion detection).
  Future<List<String>> getSyncedRowIds(String table, String userId) async {
    final results = await _db.customSelect(
      "SELECT id FROM $table WHERE user_id = ? AND sync_status = 'synced'",
      variables: [Variable.withString(userId)],
    ).get();
    return results.map((r) => r.data['id'] as String).toList();
  }

  /// Delete a single row by ID from a table.
  Future<void> deleteRow(String table, String id) async {
    await _db.customStatement('DELETE FROM $table WHERE id = ?', [id]);
  }

  // ─── Sync status counts ─────────────────────────────────────────────────

  static const _syncTables = [
    'local_transactions',
    'local_accounts',
    'local_budgets',
    'local_goals',
    'local_contributions',
    'local_bills',
    'local_debts',
    'local_insurance',
  ];

  /// Returns aggregate sync_status counts across all sync-enabled tables.
  /// Keys: 'pending', 'failed', 'synced' (defaults to 0).
  Future<Map<String, int>> getSyncStatusCounts(String userId) async {
    final counts = <String, int>{'pending': 0, 'failed': 0, 'synced': 0};
    for (final table in _syncTables) {
      final results = await _db.customSelect(
        'SELECT sync_status, COUNT(*) as cnt FROM $table WHERE user_id = ? GROUP BY sync_status',
        variables: [Variable.withString(userId)],
      ).get();
      for (final row in results) {
        final status = row.data['sync_status'] as String;
        final cnt = row.data['cnt'] as int;
        counts[status] = (counts[status] ?? 0) + cnt;
      }
    }
    return counts;
  }

  /// Delete all rows with sync_status='failed' across sync-enabled tables.
  Future<void> clearFailedRows(String userId) async {
    for (final table in _syncTables) {
      await _db.customStatement(
        "DELETE FROM $table WHERE user_id = ? AND sync_status = 'failed'",
        [userId],
      );
    }
  }

  // ─── Clear all data ──────────────────────────────────────────────────────

  Future<void> clearAllData(String userId) async {
    for (final table in [
      'local_transactions',
      'local_accounts',
      'local_budgets',
      'local_goals',
      'local_contributions',
      'local_bills',
      'local_debts',
      'local_insurance',
      'net_worth_snapshots',
      'learned_keywords',
      'chat_report_queue',
    ]) {
      await _db.customStatement('DELETE FROM $table WHERE user_id = ?', [userId]);
    }
  }

  /// Update user_id for all rows in [table] from [oldUserId] to [newUserId]
  /// and mark them as pending for sync.
  Future<void> updateUserId(String table, String oldUserId, String newUserId) async {
    await _db.customStatement(
      "UPDATE $table SET user_id = ?, sync_status = 'pending' WHERE user_id = ?",
      [newUserId, oldUserId],
    );
  }

  /// Close the database.
  Future<void> close() async {
    await _db.close();
    _instance = null;
  }
}

/// Minimal GeneratedDatabase subclass to expose customSelect/customStatement
/// without code generation.
class _RawDatabase extends GeneratedDatabase {
  _RawDatabase(DatabaseConnection connection) : super(connection);

  @override
  int get schemaVersion => 1;

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];

  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => const [];
}
