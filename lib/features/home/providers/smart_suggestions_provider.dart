import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter/material.dart';
import '../../../core/services/anomaly_service.dart';
import '../../../data/local/app_database.dart';
import '../../../data/repositories/local_bill_repository.dart';
import '../../../data/repositories/local_goal_repository.dart';
import '../../../data/repositories/local_transaction_repository.dart';
import '../../../data/repositories/transaction_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SmartSuggestion {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String? route;

  const SmartSuggestion({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.route,
  });
}

final smartSuggestionsProvider = FutureProvider<List<SmartSuggestion>>((ref) async {
  final suggestions = <SmartSuggestion>[];

  try {
    final db = AppDatabase.instance;
    final client = Supabase.instance.client;

    // 1. Bills due in next 3 days
    try {
      final billRepo = LocalBillRepository(db, client);
      final bills = await billRepo.getBills();
      final now = DateTime.now();
      for (final bill in bills) {
        if (!bill.isActive || bill.dueDay == null) continue;
        final lastDay = DateTime(now.year, now.month + 1, 0).day;
        final dueDay = bill.dueDay!.clamp(1, lastDay);
        var dueDate = DateTime(now.year, now.month, dueDay);
        if (dueDate.isBefore(now)) {
          dueDate = DateTime(now.year, now.month + 1, dueDay.clamp(1, DateTime(now.year, now.month + 2, 0).day));
        }
        final daysUntilDue = dueDate.difference(now).inDays;
        if (daysUntilDue >= 0 && daysUntilDue <= 3) {
          suggestions.add(SmartSuggestion(
            title: daysUntilDue == 0 ? '${bill.name} is due today' : '${bill.name} due in $daysUntilDue day${daysUntilDue == 1 ? '' : 's'}',
            subtitle: 'Tap to view your bills',
            icon: LucideIcons.alertCircle,
            color: const Color(0xFFEF4444),
            route: '/tools/bills',
          ));
        }
      }
    } catch (_) {}

    // 2. Goals close to completion (80%+)
    try {
      final goalRepo = LocalGoalRepository(db, client);
      final goals = await goalRepo.getGoals();
      for (final goal in goals) {
        if (goal.isCompleted || goal.targetAmount <= 0) continue;
        final progress = goal.currentAmount / goal.targetAmount;
        if (progress >= 0.8 && progress < 1.0) {
          final remaining = goal.targetAmount - goal.currentAmount;
          suggestions.add(SmartSuggestion(
            title: '${goal.name} is almost there!',
            subtitle: 'Just P${remaining.toStringAsFixed(0)} more to reach your goal',
            icon: LucideIcons.target,
            color: const Color(0xFF10B981),
            route: '/goals',
          ));
        }
      }
    } catch (_) {}

    // 3. Spending anomalies
    try {
      final anomalies = await AnomalyService.detect();
      for (final a in anomalies.take(1)) { // Only show top anomaly
        suggestions.add(SmartSuggestion(
          title: a.message,
          subtitle: 'Tap to review your spending',
          icon: LucideIcons.trendingUp,
          color: const Color(0xFFF59E0B),
          route: '/dashboard',
        ));
      }
    } catch (_) {}

    // 4. No transactions today
    try {
      final txnRepo = LocalTransactionRepository(db, client);
      final today = DateTime.now();
      final todayTxns = await txnRepo.getTransactions(TransactionFilters(
        startDate: DateTime(today.year, today.month, today.day),
        endDate: today,
      ));
      if (todayTxns.isEmpty && today.hour >= 12) {
        suggestions.add(const SmartSuggestion(
          title: 'No transactions logged today',
          subtitle: 'Don\'t forget to track your spending!',
          icon: LucideIcons.clipboardList,
          color: Color(0xFF6366F1),
        ));
      }
    } catch (_) {}
  } catch (_) {}

  return suggestions.take(3).toList(); // Max 3 suggestions
});
