import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/local/app_database.dart';
import '../../../data/repositories/local_budget_repository.dart';
import '../../../data/repositories/budget_repository.dart';
import '../../../data/models/budget.dart';
import '../../auth/providers/auth_provider.dart';

final budgetRepositoryProvider = Provider<LocalBudgetRepository>((ref) {
  return LocalBudgetRepository(
    AppDatabase.instance,
    ref.watch(supabaseClientProvider),
  );
});

/// Keep the Supabase repository available for sync service usage.
final remoteBudgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository(ref.watch(supabaseClientProvider));
});

final budgetPeriodProvider = StateProvider<String>((ref) => 'monthly');

final budgetMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
});

final budgetsProvider = FutureProvider<List<Budget>>((ref) async {
  final month = ref.watch(budgetMonthProvider);
  final period = ref.watch(budgetPeriodProvider);
  return ref.read(budgetRepositoryProvider).getBudgets(month, period);
});
