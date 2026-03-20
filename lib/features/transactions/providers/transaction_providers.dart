import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../data/models/transaction.dart';
import '../../auth/providers/auth_provider.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(ref.watch(supabaseClientProvider));
});

final recentTransactionsProvider = FutureProvider<List<Transaction>>((ref) async {
  return ref.read(transactionRepositoryProvider).getRecentTransactions();
});

final transactionFiltersProvider = StateProvider<TransactionFilters>((ref) {
  return const TransactionFilters();
});

final transactionsProvider = FutureProvider<List<Transaction>>((ref) async {
  final filters = ref.watch(transactionFiltersProvider);
  return ref.read(transactionRepositoryProvider).getTransactions(filters);
});

final transactionsCountProvider = FutureProvider<int>((ref) async {
  final filters = ref.watch(transactionFiltersProvider);
  return ref.read(transactionRepositoryProvider).getTransactionsCount(filters);
});

final transactionsSummaryProvider = FutureProvider<TransactionsSummary>((ref) async {
  return ref.read(transactionRepositoryProvider).getTransactionsSummary();
});
