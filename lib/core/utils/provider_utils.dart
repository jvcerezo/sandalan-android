import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/transactions/providers/transaction_providers.dart';
import '../../features/accounts/providers/account_providers.dart';
import '../../features/goals/providers/goal_providers.dart';
import '../../features/budgets/providers/budget_providers.dart';
import '../../features/tools/providers/tool_providers.dart';

/// Invalidate all financial providers after any mutation (transaction, account,
/// goal, budget, bill, debt, insurance). Call this after any write operation
/// to ensure the entire UI reflects the latest data.
void invalidateFinancialProviders(dynamic ref) {
  // ref can be WidgetRef or Ref — both support invalidate
  void inv(ProviderOrFamily provider) {
    try {
      if (ref is WidgetRef) {
        ref.invalidate(provider);
      } else if (ref is Ref) {
        ref.invalidate(provider);
      }
    } catch (_) {} // Ignore if provider not yet initialized
  }

  // Transactions
  inv(recentTransactionsProvider);
  inv(transactionsProvider);
  inv(transactionsCountProvider);
  inv(transactionsSummaryProvider);

  // Accounts
  inv(accountsProvider);

  // Goals
  inv(goalsProvider);
  inv(goalsSummaryProvider);

  // Budgets
  inv(budgetsProvider);

  // Tools
  inv(billsProvider);
  inv(billsSummaryProvider);
  inv(debtsProvider);
  inv(debtSummaryProvider);
  inv(insurancePoliciesProvider);
  inv(insuranceSummaryProvider);
}

/// Invalidate all transaction-related providers + accounts.
/// This is the go-to function after any transaction write (add/edit/delete).
/// Covers: list views, summary cards, dashboard charts, home screen.
void invalidateTransactionProviders(dynamic ref) {
  void inv(ProviderOrFamily provider) {
    try {
      if (ref is WidgetRef) {
        ref.invalidate(provider);
      } else if (ref is Ref) {
        ref.invalidate(provider);
      }
    } catch (_) {}
  }

  // Transaction lists
  inv(recentTransactionsProvider);
  inv(transactionsProvider);
  inv(transactionsCountProvider);

  // Summary (home + dashboard)
  inv(transactionsSummaryProvider);

  // Dashboard charts
  inv(currentMonthTransactionsProvider);
  inv(last6MonthsTransactionsProvider);
  inv(categoryTotalsProvider);
  inv(monthlyTotalsProvider);
  inv(monthlyNetTotalsProvider);

  // Accounts (balance changes)
  inv(accountsProvider);
}
