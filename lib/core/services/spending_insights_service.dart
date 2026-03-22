import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/local/app_database.dart';

/// A single spending insight with metadata for display.
class SpendingInsight {
  final String text;
  final String category; // 'pattern', 'trend', 'projection', 'anomaly', 'positive'
  final String severity; // 'info', 'warning', 'positive'
  final IconData icon;
  final String? actionRoute;

  const SpendingInsight({
    required this.text,
    required this.category,
    required this.severity,
    required this.icon,
    this.actionRoute,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'category': category,
    'severity': severity,
  };

  factory SpendingInsight.fromJson(Map<String, dynamic> json) {
    final cat = json['category'] as String;
    final sev = json['severity'] as String;
    return SpendingInsight(
      text: json['text'] as String,
      category: cat,
      severity: sev,
      icon: _iconForCategory(cat),
    );
  }

  static IconData _iconForCategory(String cat) {
    switch (cat) {
      case 'pattern': return LucideIcons.calendar;
      case 'trend': return LucideIcons.trendingUp;
      case 'projection': return LucideIcons.coffee;
      case 'anomaly': return LucideIcons.alertTriangle;
      case 'positive': return LucideIcons.piggyBank;
      default: return LucideIcons.lightbulb;
    }
  }
}

/// Analyzes transactions and returns actionable insights.
/// Caches results daily via SharedPreferences.
class SpendingInsightsService {
  static Future<List<SpendingInsight>> getInsights(AppDatabase db, String userId) async {
    // Check cache first
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'insights_${DateTime.now().toIso8601String().substring(0, 10)}';
    final cached = prefs.getString(cacheKey);
    if (cached != null) {
      try {
        final list = (jsonDecode(cached) as List).cast<Map<String, dynamic>>();
        return list.map((e) => SpendingInsight.fromJson(e)).toList();
      } catch (_) {}
    }

    final insights = <SpendingInsight>[];
    final now = DateTime.now();

    // Get this month's transactions
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final thisMonthEnd = DateTime(now.year, now.month + 1, 0);
    final thisMonthRows = await db.getFilteredTransactions(
      userId,
      startDate: thisMonthStart.toIso8601String().substring(0, 10),
      endDate: thisMonthEnd.toIso8601String().substring(0, 10),
      pageSize: 9999,
    );

    // Get last month's transactions
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final lastMonthEnd = DateTime(now.year, now.month, 0);
    final lastMonthRows = await db.getFilteredTransactions(
      userId,
      startDate: lastMonthStart.toIso8601String().substring(0, 10),
      endDate: lastMonthEnd.toIso8601String().substring(0, 10),
      pageSize: 9999,
    );

    final thisExpenses = thisMonthRows.where((r) => (r['amount'] as num).toDouble() < 0).toList();
    final lastExpenses = lastMonthRows.where((r) => (r['amount'] as num).toDouble() < 0).toList();

    // ── 1. Day-of-week patterns ─────────────────────────────────
    _dayOfWeekPatterns(thisExpenses, insights);

    // ── 2. Category trend vs last month ─────────────────────────
    _categoryTrends(thisExpenses, lastExpenses, insights);

    // ── 3. Annualized small purchases ───────────────────────────
    _annualizedSmallPurchases(thisExpenses, insights);

    // ── 4. Post-payday velocity ─────────────────────────────────
    _postPaydayVelocity(thisExpenses, insights);

    // ── 5. Budget anomalies ─────────────────────────────────────
    try {
      final budgets = await db.getAllBudgets(userId);
      _budgetAnomalies(thisExpenses, budgets, now, insights);
    } catch (_) {}

    // ── 6. Positive reinforcements ──────────────────────────────
    _positiveReinforcements(thisMonthRows, insights, userId);

    // Cache results
    try {
      final jsonList = insights.map((i) => i.toJson()).toList();
      await prefs.setString(cacheKey, jsonEncode(jsonList));
    } catch (_) {}

    return insights;
  }

  static void _dayOfWeekPatterns(
    List<Map<String, dynamic>> expenses,
    List<SpendingInsight> insights,
  ) {
    if (expenses.length < 7) return;

    // Group expenses by weekday
    final weekdayTotals = <int, double>{};
    final weekdayCounts = <int, int>{};
    for (final row in expenses) {
      final date = DateTime.tryParse(row['date'] as String? ?? '');
      if (date == null) continue;
      final wd = date.weekday; // 1=Mon, 7=Sun
      weekdayTotals[wd] = (weekdayTotals[wd] ?? 0) + (row['amount'] as num).toDouble().abs();
      weekdayCounts[wd] = (weekdayCounts[wd] ?? 0) + 1;
    }

    if (weekdayTotals.isEmpty) return;
    final overallAvg = weekdayTotals.values.fold(0.0, (a, b) => a + b) / weekdayTotals.length;

    // Find which day has highest average
    double highestAvg = 0;
    int highestDay = 1;
    for (final entry in weekdayTotals.entries) {
      final avg = entry.value / (weekdayCounts[entry.key] ?? 1);
      if (avg > highestAvg) {
        highestAvg = avg;
        highestDay = entry.key;
      }
    }

    final overallDayAvg = overallAvg / (weekdayCounts.values.fold(0, (a, b) => a + b) / weekdayTotals.length);
    if (overallDayAvg > 0 && highestAvg > overallDayAvg * 1.3) {
      final pct = ((highestAvg / overallDayAvg - 1) * 100).round();
      final dayName = _weekdayName(highestDay);
      insights.add(SpendingInsight(
        text: 'You spend $pct% more on ${dayName}s vs other days',
        category: 'pattern',
        severity: 'info',
        icon: LucideIcons.calendar,
        actionRoute: '/dashboard',
      ));
    }
  }

  static void _categoryTrends(
    List<Map<String, dynamic>> thisExpenses,
    List<Map<String, dynamic>> lastExpenses,
    List<SpendingInsight> insights,
  ) {
    if (lastExpenses.isEmpty) return;

    // Group by category
    final thisCatTotals = <String, double>{};
    for (final row in thisExpenses) {
      final cat = row['category'] as String? ?? 'Other';
      if (cat == 'Transfer') continue;
      thisCatTotals[cat] = (thisCatTotals[cat] ?? 0) + (row['amount'] as num).toDouble().abs();
    }

    final lastCatTotals = <String, double>{};
    for (final row in lastExpenses) {
      final cat = row['category'] as String? ?? 'Other';
      if (cat == 'Transfer') continue;
      lastCatTotals[cat] = (lastCatTotals[cat] ?? 0) + (row['amount'] as num).toDouble().abs();
    }

    for (final cat in thisCatTotals.keys) {
      final thisTotal = thisCatTotals[cat] ?? 0;
      final lastTotal = lastCatTotals[cat] ?? 0;
      if (lastTotal == 0) continue;

      final changeRatio = (thisTotal - lastTotal) / lastTotal;
      if (changeRatio > 0.2) {
        final pct = (changeRatio * 100).round();
        insights.add(SpendingInsight(
          text: 'Your $cat spending is up $pct% from last month',
          category: 'trend',
          severity: 'warning',
          icon: LucideIcons.trendingUp,
          actionRoute: '/dashboard',
        ));
      } else if (changeRatio < -0.2) {
        final pct = (changeRatio.abs() * 100).round();
        insights.add(SpendingInsight(
          text: 'Great job! You spent $pct% less on $cat this month',
          category: 'positive',
          severity: 'positive',
          icon: LucideIcons.trendingDown,
        ));
      }
    }
  }

  static void _annualizedSmallPurchases(
    List<Map<String, dynamic>> expenses,
    List<SpendingInsight> insights,
  ) {
    // Find recurring small expenses (same description, 3+ times this month)
    final descCounts = <String, ({int count, double total})>{};
    for (final row in expenses) {
      final desc = (row['description'] as String? ?? '').toLowerCase().trim();
      if (desc.isEmpty) continue;
      final amt = (row['amount'] as num).toDouble().abs();
      if (amt > 500) continue; // only small purchases
      final existing = descCounts[desc];
      descCounts[desc] = (
        count: (existing?.count ?? 0) + 1,
        total: (existing?.total ?? 0) + amt,
      );
    }

    for (final entry in descCounts.entries) {
      if (entry.value.count >= 3) {
        final avg = entry.value.total / entry.value.count;
        final yearly = avg * entry.value.count * 12;
        final desc = entry.key.length > 20 ? '${entry.key.substring(0, 20)}...' : entry.key;
        insights.add(SpendingInsight(
          text: 'You\'ve spent \u20b1${entry.value.total.toStringAsFixed(0)} on "$desc" this month — that\'s \u20b1${yearly.toStringAsFixed(0)}/year',
          category: 'projection',
          severity: 'info',
          icon: LucideIcons.coffee,
        ));
      }
    }
  }

  static void _postPaydayVelocity(
    List<Map<String, dynamic>> expenses,
    List<SpendingInsight> insights,
  ) {
    if (expenses.length < 10) return;

    // Check spending in first 3 days after 15th/30th vs rest
    double paydaySpending = 0;
    int paydayDays = 0;
    double otherSpending = 0;
    int otherDays = 0;

    final dayTotals = <int, double>{};
    for (final row in expenses) {
      final date = DateTime.tryParse(row['date'] as String? ?? '');
      if (date == null) continue;
      dayTotals[date.day] = (dayTotals[date.day] ?? 0) + (row['amount'] as num).toDouble().abs();
    }

    for (final entry in dayTotals.entries) {
      final day = entry.key;
      // First 3 days after paydays (1-3, 16-18)
      if ((day >= 1 && day <= 3) || (day >= 16 && day <= 18)) {
        paydaySpending += entry.value;
        paydayDays++;
      } else {
        otherSpending += entry.value;
        otherDays++;
      }
    }

    if (paydayDays == 0 || otherDays == 0) return;
    final paydayAvg = paydaySpending / paydayDays;
    final otherAvg = otherSpending / otherDays;

    if (otherAvg > 0 && paydayAvg > otherAvg * 1.4) {
      final pct = ((paydayAvg / otherAvg - 1) * 100).round();
      insights.add(SpendingInsight(
        text: 'You spend $pct% more in the first 3 days after payday',
        category: 'pattern',
        severity: 'warning',
        icon: LucideIcons.clock,
      ));
    }
  }

  static void _budgetAnomalies(
    List<Map<String, dynamic>> expenses,
    List<Map<String, dynamic>> budgets,
    DateTime now,
    List<SpendingInsight> insights,
  ) {
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final monthProgress = now.day / daysInMonth;

    if (monthProgress > 0.5) return; // Only alert early in the month

    // Group expenses by category
    final catTotals = <String, double>{};
    for (final row in expenses) {
      final cat = row['category'] as String? ?? 'Other';
      catTotals[cat] = (catTotals[cat] ?? 0) + (row['amount'] as num).toDouble().abs();
    }

    for (final budget in budgets) {
      final cat = budget['category'] as String? ?? '';
      final budgetAmount = (budget['amount'] as num?)?.toDouble() ?? 0;
      if (budgetAmount <= 0) continue;

      final spent = catTotals[cat] ?? 0;
      final usedPct = spent / budgetAmount;
      if (usedPct >= 0.8) {
        final usedPctRound = (usedPct * 100).round();
        final monthPctRound = (monthProgress * 100).round();
        insights.add(SpendingInsight(
          text: 'Your $cat budget is $usedPctRound% used but the month is only $monthPctRound% through',
          category: 'anomaly',
          severity: 'warning',
          icon: LucideIcons.alertTriangle,
          actionRoute: '/budgets',
        ));
      }
    }
  }

  static void _positiveReinforcements(
    List<Map<String, dynamic>> allTxns,
    List<SpendingInsight> insights,
    String userId,
  ) {
    double income = 0;
    double expenses = 0;
    for (final row in allTxns) {
      final amount = (row['amount'] as num).toDouble();
      final cat = row['category'] as String? ?? '';
      if (cat == 'Transfer') continue;
      if (amount > 0) {
        income += amount;
      } else {
        expenses += amount.abs();
      }
    }

    if (income > 0) {
      final savingsRate = (income - expenses) / income;
      if (savingsRate > 0.3) {
        final pct = (savingsRate * 100).round();
        insights.add(SpendingInsight(
          text: 'Your savings rate is $pct% — above the Filipino average of 15%!',
          category: 'positive',
          severity: 'positive',
          icon: LucideIcons.piggyBank,
        ));
      }
    }

    // Check streak from SharedPreferences
    SharedPreferences.getInstance().then((prefs) {
      final streak = prefs.getInt('streak_current') ?? 0;
      if (streak > 14) {
        insights.add(SpendingInsight(
          text: 'You\'ve been logging consistently for $streak days!',
          category: 'positive',
          severity: 'positive',
          icon: LucideIcons.flame,
        ));
      }
    });
  }

  static String _weekdayName(int weekday) {
    const names = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return names[(weekday - 1).clamp(0, 6)];
  }
}
