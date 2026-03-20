import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transaction.dart';

class TransactionFilters {
  final String? category;
  final String? type; // 'income', 'expense'
  final String? search;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? accountId;
  final String? tag;
  final int page;
  final int pageSize;

  const TransactionFilters({
    this.category,
    this.type,
    this.search,
    this.startDate,
    this.endDate,
    this.accountId,
    this.tag,
    this.page = 1,
    this.pageSize = 20,
  });
}

class TransactionsSummary {
  final double balance;
  final double income;
  final double expenses;

  const TransactionsSummary({
    required this.balance,
    required this.income,
    required this.expenses,
  });
}

class TransactionRepository {
  final SupabaseClient _client;

  TransactionRepository(this._client);

  String get _userId => _client.auth.currentUser!.id;

  /// Get recent transactions (last 10).
  Future<List<Transaction>> getRecentTransactions() async {
    final data = await _client
        .from('transactions')
        .select()
        .eq('user_id', _userId)
        .order('date', ascending: false)
        .order('created_at', ascending: false)
        .limit(10);
    return data.map((e) => Transaction.fromJson(e)).toList();
  }

  /// Get transactions with filters and pagination.
  Future<List<Transaction>> getTransactions([TransactionFilters? filters]) async {
    final f = filters ?? const TransactionFilters();
    var query = _client.from('transactions').select().eq('user_id', _userId);

    if (f.category != null) query = query.eq('category', f.category!);
    if (f.accountId != null) query = query.eq('account_id', f.accountId!);
    if (f.startDate != null) {
      query = query.gte('date', f.startDate!.toIso8601String().substring(0, 10));
    }
    if (f.endDate != null) {
      query = query.lte('date', f.endDate!.toIso8601String().substring(0, 10));
    }
    if (f.type == 'income') query = query.gt('amount', 0);
    if (f.type == 'expense') query = query.lt('amount', 0);
    if (f.search != null && f.search!.isNotEmpty) {
      query = query.ilike('description', '%${f.search}%');
    }

    final offset = (f.page - 1) * f.pageSize;
    final data = await query
        .order('date', ascending: false)
        .order('created_at', ascending: false)
        .range(offset, offset + f.pageSize - 1);

    return data.map((e) => Transaction.fromJson(e)).toList();
  }

  /// Get count of matching transactions.
  Future<int> getTransactionsCount([TransactionFilters? filters]) async {
    final f = filters ?? const TransactionFilters();
    var query = _client
        .from('transactions')
        .select('id')
        .eq('user_id', _userId)
        .neq('category', 'Transfer');

    if (f.category != null) query = query.eq('category', f.category!);
    if (f.accountId != null) query = query.eq('account_id', f.accountId!);
    if (f.startDate != null) {
      query = query.gte('date', f.startDate!.toIso8601String().substring(0, 10));
    }
    if (f.endDate != null) {
      query = query.lte('date', f.endDate!.toIso8601String().substring(0, 10));
    }
    if (f.type == 'income') query = query.gt('amount', 0);
    if (f.type == 'expense') query = query.lt('amount', 0);

    final data = await query;
    return data.length;
  }

  /// Get transaction summary (balance, income, expenses).
  Future<TransactionsSummary> getTransactionsSummary() async {
    final data = await _client
        .from('transactions')
        .select('amount')
        .eq('user_id', _userId);

    double income = 0;
    double expenses = 0;
    for (final row in data) {
      final amount = (row['amount'] as num).toDouble();
      if (amount > 0) {
        income += amount;
      } else {
        expenses += amount.abs();
      }
    }

    return TransactionsSummary(
      balance: income - expenses,
      income: income,
      expenses: expenses,
    );
  }

  /// Create a transaction via RPC (atomic balance update).
  Future<Transaction> createTransaction({
    required double amount,
    required String category,
    required String description,
    required DateTime date,
    String currency = 'PHP',
    String? accountId,
    List<String>? tags,
  }) async {
    final result = await _client.rpc('create_user_transaction', params: {
      'p_amount': amount,
      'p_category': category,
      'p_description': description,
      'p_date': date.toIso8601String().substring(0, 10),
      'p_currency': currency,
      'p_account_id': accountId,
      'p_tags': tags,
    });

    // RPC returns the created transaction ID
    final data = await _client
        .from('transactions')
        .select()
        .eq('id', result)
        .single();
    return Transaction.fromJson(data);
  }

  /// Update a transaction via RPC.
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
    // Fetch existing for partial update
    final existing = await _client
        .from('transactions')
        .select()
        .eq('id', id)
        .single();

    await _client.rpc('update_user_transaction', params: {
      'p_transaction_id': id,
      'p_amount': amount ?? existing['amount'],
      'p_category': category ?? existing['category'],
      'p_description': description ?? existing['description'],
      'p_date': date?.toIso8601String().substring(0, 10) ?? existing['date'],
      'p_currency': currency ?? existing['currency'],
      'p_account_id': accountId ?? existing['account_id'],
      'p_tags': tags ?? existing['tags'],
    });
  }

  /// Delete a transaction via RPC (reverses balance).
  Future<void> deleteTransaction(String id) async {
    await _client.rpc('delete_user_transaction', params: {
      'p_transaction_id': id,
    });
  }

  /// Import transactions in bulk via RPC.
  Future<void> importTransactions(List<Map<String, dynamic>> transactions) async {
    await _client.rpc('import_transactions_with_balance', params: {
      'p_transactions': transactions,
    });
  }

  /// Create a transfer between accounts via RPC.
  Future<void> createTransfer({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    required DateTime date,
    String? description,
  }) async {
    await _client.rpc('create_account_transfer', params: {
      'from_account_id': fromAccountId,
      'to_account_id': toAccountId,
      'transfer_amount': amount,
      'transfer_date': date.toIso8601String().substring(0, 10),
      'transfer_description': description ?? 'Transfer',
    });
  }
}
