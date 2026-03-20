import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/guest_mode_service.dart';
import '../../core/services/notification_service.dart';
import '../local/app_database.dart';
import '../models/transaction.dart';
import 'transaction_repository.dart';

/// Local-first transaction repository. All reads come from SQLite.
/// All writes go to SQLite first (marked 'pending'), then sync in background.
class LocalTransactionRepository {
  final AppDatabase _db;
  final SupabaseClient _client;

  LocalTransactionRepository(this._db, this._client);

  String get _userId {
    final user = _client.auth.currentUser;
    if (user != null) return user.id;
    return GuestModeService.getGuestIdSync() ?? 'guest';
  }

  // ─── Reads (from local DB) ──────────────────────────────────────────────

  Future<List<Transaction>> getRecentTransactions() async {
    final rows = await _db.getRecentTransactions(_userId);
    return rows.map(_rowToTransaction).toList();
  }

  Future<List<Transaction>> getTransactions([TransactionFilters? filters]) async {
    final f = filters ?? const TransactionFilters();
    final rows = await _db.getFilteredTransactions(
      _userId,
      category: f.category,
      type: f.type,
      search: f.search,
      startDate: f.startDate?.toIso8601String().substring(0, 10),
      endDate: f.endDate?.toIso8601String().substring(0, 10),
      accountId: f.accountId,
      page: f.page,
      pageSize: f.pageSize,
    );
    return rows.map(_rowToTransaction).toList();
  }

  Future<int> getTransactionsCount([TransactionFilters? filters]) async {
    final f = filters ?? const TransactionFilters();
    return _db.getFilteredTransactionsCount(
      _userId,
      category: f.category,
      type: f.type,
      startDate: f.startDate?.toIso8601String().substring(0, 10),
      endDate: f.endDate?.toIso8601String().substring(0, 10),
      accountId: f.accountId,
    );
  }

  /// Transaction summary computed from local data.
  /// Only counts confirmed transactions (excludes pending bills/insurance).
  Future<TransactionsSummary> getTransactionsSummary() async {
    final transactions = await _db.getTransactions(_userId);
    final accounts = await _db.getAllAccounts(_userId);
    final goals = await _db.getGoals(_userId);
    final contributions = await _db.getContributions(_userId);

    final nonTransfer = transactions
        .where((t) {
          final cat = (t['category'] as String).toLowerCase();
          final status = t['status'] as String? ?? 'confirmed';
          return cat != 'transfer' && cat != 'goal funding' && status == 'confirmed';
        })
        .toList();

    final income = nonTransfer
        .where((t) => (t['amount'] as num) > 0)
        .fold<double>(0, (sum, t) => sum + (t['amount'] as num).toDouble());

    final paidContribs = contributions.where((c) {
      final isPaid = c['is_paid'];
      return isPaid == 1 || isPaid == true;
    });
    final contribExpenses = paidContribs
        .fold<double>(0, (s, c) => s + (c['employee_share'] as num).toDouble());

    final expenses = nonTransfer
        .where((t) => (t['amount'] as num) < 0)
        .fold<double>(0, (sum, t) => sum + (t['amount'] as num).toDouble().abs()) +
        contribExpenses;

    final accountsTotal = accounts
        .fold<double>(0, (sum, a) => sum + (a['balance'] as num).toDouble());
    final unlinkedBalance = transactions
        .where((t) => t['account_id'] == null)
        .fold<double>(0, (sum, t) => sum + (t['amount'] as num).toDouble());
    final goalsSaved = goals
        .fold<double>(0, (sum, g) => sum + (g['current_amount'] as num).toDouble());

    final balance = ((accountsTotal + goalsSaved + unlinkedBalance) * 100).roundToDouble() / 100;

    return TransactionsSummary(
      balance: balance,
      income: (income * 100).roundToDouble() / 100,
      expenses: (expenses * 100).roundToDouble() / 100,
    );
  }

  // ─── Writes (to local DB, marked pending) ───────────────────────────────

  Future<Transaction> createTransaction({
    required double amount,
    required String category,
    required String description,
    required DateTime date,
    String currency = 'PHP',
    String? accountId,
    List<String>? tags,
    String status = 'confirmed',
  }) async {
    final id = _generateId();
    final now = AppDatabase.now();
    final dateStr = date.toIso8601String().substring(0, 10);

    final row = <String, dynamic>{
      'id': id,
      'user_id': _userId,
      'amount': amount,
      'category': category,
      'description': description,
      'date': dateStr,
      'currency': currency,
      'attachment_path': null,
      'account_id': accountId,
      'transfer_id': null,
      'split_group_id': null,
      'tags': AppDatabase.encodeTags(tags),
      'status': status,
      'sync_status': 'pending',
      'created_at': now,
      'updated_at': now,
    };

    await _db.upsertTransaction(row);

    // Update account balance locally if linked and transaction is confirmed
    if (accountId != null && status == 'confirmed') {
      await _updateAccountBalance(accountId, amount);
    }

    // Check budget thresholds for expense transactions
    if (amount < 0 && status == 'confirmed' && category.toLowerCase() != 'transfer' && category.toLowerCase() != 'goal funding') {
      await _checkBudgetThresholds(category);
    }

    return _rowToTransaction(row);
  }

  /// Confirm a pending transaction (mark as paid, deduct from account).
  Future<void> confirmTransaction(String id, String accountId) async {
    final existing = await _db.getRowById('local_transactions', id);
    if (existing == null) return;

    final updated = Map<String, dynamic>.from(existing);
    updated['status'] = 'confirmed';
    updated['account_id'] = accountId;
    updated['sync_status'] = 'pending';
    updated['updated_at'] = AppDatabase.now();
    await _db.upsertTransaction(updated);

    // Deduct from account
    final amount = (existing['amount'] as num).toDouble();
    await _updateAccountBalance(accountId, amount);
  }

  Future<void> updateTransaction({
    required String id,
    double? amount,
    String? category,
    String? description,
    DateTime? date,
    String? currency,
    String? accountId,
    List<String>? tags,
  }) async {
    final existing = await _db.getRowById('local_transactions', id);
    if (existing == null) return;

    final now = AppDatabase.now();
    final updated = Map<String, dynamic>.from(existing);

    // Reverse old balance if account changed or amount changed
    final oldAccountId = existing['account_id'] as String?;
    final oldAmount = (existing['amount'] as num).toDouble();
    final newAmount = amount ?? oldAmount;
    final newAccountId = accountId ?? oldAccountId;
    final status = existing['status'] as String? ?? 'confirmed';

    if (status == 'confirmed') {
      if (oldAccountId != null) {
        await _updateAccountBalance(oldAccountId, -oldAmount);
      }
      if (newAccountId != null) {
        await _updateAccountBalance(newAccountId, newAmount);
      }
    }

    if (amount != null) updated['amount'] = amount;
    if (category != null) updated['category'] = category;
    if (description != null) updated['description'] = description;
    if (date != null) updated['date'] = date.toIso8601String().substring(0, 10);
    if (currency != null) updated['currency'] = currency;
    if (accountId != null) updated['account_id'] = accountId;
    if (tags != null) updated['tags'] = AppDatabase.encodeTags(tags);
    updated['sync_status'] = 'pending';
    updated['updated_at'] = now;

    await _db.upsertTransaction(updated);
  }

  Future<void> deleteTransaction(String id) async {
    final existing = await _db.getRowById('local_transactions', id);
    if (existing != null) {
      final status = existing['status'] as String? ?? 'confirmed';
      // Reverse balance only for confirmed transactions
      if (status == 'confirmed') {
        final accountId = existing['account_id'] as String?;
        if (accountId != null) {
          final amount = (existing['amount'] as num).toDouble();
          await _updateAccountBalance(accountId, -amount);
        }
      }
    }
    await _db.deleteTransaction(id);
  }

  Future<void> importTransactions(List<Map<String, dynamic>> transactions) async {
    final now = AppDatabase.now();
    for (final t in transactions) {
      final id = _generateId();
      t['id'] = id;
      t['user_id'] = _userId;
      t['status'] = t['status'] ?? 'confirmed';
      t['sync_status'] = 'pending';
      t['created_at'] = now;
      t['updated_at'] = now;
      if (t['tags'] is List) {
        t['tags'] = AppDatabase.encodeTags((t['tags'] as List).cast<String>());
      }
      await _db.upsertTransaction(t);
    }
  }

  Future<void> createTransfer({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    required DateTime date,
    String? description,
  }) async {
    final now = AppDatabase.now();
    final dateStr = date.toIso8601String().substring(0, 10);
    final transferId = _generateId();

    // Debit from source
    await _db.upsertTransaction({
      'id': _generateId(),
      'user_id': _userId,
      'amount': -amount,
      'category': 'Transfer',
      'description': description ?? 'Transfer',
      'date': dateStr,
      'currency': 'PHP',
      'account_id': fromAccountId,
      'transfer_id': transferId,
      'status': 'confirmed',
      'sync_status': 'pending',
      'created_at': now,
      'updated_at': now,
    });

    // Credit to destination
    await _db.upsertTransaction({
      'id': _generateId(),
      'user_id': _userId,
      'amount': amount,
      'category': 'Transfer',
      'description': description ?? 'Transfer',
      'date': dateStr,
      'currency': 'PHP',
      'account_id': toAccountId,
      'transfer_id': transferId,
      'status': 'confirmed',
      'sync_status': 'pending',
      'created_at': now,
      'updated_at': now,
    });

    // Update balances
    await _updateAccountBalance(fromAccountId, -amount);
    await _updateAccountBalance(toAccountId, amount);
  }

  // ─── Budget threshold checks ───────────────────────────────────────────

  Future<void> _checkBudgetThresholds(String category) async {
    try {
      final now = DateTime.now();
      final monthStr = DateTime(now.year, now.month, 1).toIso8601String().substring(0, 10);
      final budgets = await _db.getBudgets(_userId, monthStr, 'monthly');

      for (final budget in budgets) {
        final budgetCat = budget['category'] as String;
        if (budgetCat.toLowerCase() != category.toLowerCase()) continue;

        final budgetAmount = (budget['amount'] as num).toDouble();
        if (budgetAmount <= 0) continue;

        // Calculate spent this month for this category
        final startDate = monthStr;
        final endDate = DateTime(now.year, now.month + 1, 0).toIso8601String().substring(0, 10);
        final transactions = await _db.getFilteredTransactions(
          _userId,
          category: budgetCat,
          startDate: startDate,
          endDate: endDate,
        );

        final spent = transactions
            .where((t) {
              final status = t['status'] as String? ?? 'confirmed';
              return (t['amount'] as num) < 0 && status == 'confirmed';
            })
            .fold<double>(0, (sum, t) => sum + (t['amount'] as num).toDouble().abs());

        final pct = spent / budgetAmount;
        final notifId = 'budget-$budgetCat-${now.month}'.hashCode;

        if (pct >= 1.0) {
          final over = spent - budgetAmount;
          await NotificationService.instance.showNotification(
            id: notifId,
            title: 'Budget Exceeded: $budgetCat',
            body: 'You\'ve gone over your $budgetCat budget by PHP ${over.toStringAsFixed(2)}',
          );
        } else if (pct >= 0.9) {
          await NotificationService.instance.showNotification(
            id: notifId,
            title: 'Budget Alert: $budgetCat',
            body: 'You\'ve spent 90% of your $budgetCat budget (PHP ${spent.toStringAsFixed(2)} of PHP ${budgetAmount.toStringAsFixed(2)})',
          );
        } else if (pct >= 0.8) {
          await NotificationService.instance.showNotification(
            id: notifId,
            title: 'Budget Warning: $budgetCat',
            body: 'You\'ve spent 80% of your $budgetCat budget (PHP ${spent.toStringAsFixed(2)} of PHP ${budgetAmount.toStringAsFixed(2)})',
          );
        }
      }
    } catch (_) {
      // Don't let budget checks break transaction creation
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  Transaction _rowToTransaction(Map<String, dynamic> row) {
    return Transaction(
      id: row['id'] as String,
      createdAt: row['created_at'] as String,
      userId: row['user_id'] as String,
      amount: (row['amount'] as num).toDouble(),
      category: row['category'] as String,
      description: row['description'] as String,
      date: row['date'] as String,
      currency: row['currency'] as String? ?? 'PHP',
      attachmentPath: row['attachment_path'] as String?,
      accountId: row['account_id'] as String?,
      transferId: row['transfer_id'] as String?,
      splitGroupId: row['split_group_id'] as String?,
      tags: AppDatabase.decodeTags(row['tags'] as String?),
      status: row['status'] as String? ?? 'confirmed',
    );
  }

  Future<void> _updateAccountBalance(String accountId, double delta) async {
    final account = await _db.getRowById('local_accounts', accountId);
    if (account == null) return;

    final updated = Map<String, dynamic>.from(account);
    updated['balance'] = (account['balance'] as num).toDouble() + delta;
    updated['sync_status'] = 'pending';
    updated['updated_at'] = AppDatabase.now();
    await _db.upsertAccount(updated);
  }

  String _generateId() =>
      'local-txn-${DateTime.now().millisecondsSinceEpoch}-${_counter++}';
  static int _counter = 0;
}
