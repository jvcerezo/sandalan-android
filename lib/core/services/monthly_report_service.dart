import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/local/app_database.dart';
import '../../data/models/monthly_report.dart';
import 'guest_mode_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service to generate and cache monthly financial report cards.
class MonthlyReportService {
  final AppDatabase _db;

  MonthlyReportService(this._db);

  String get _userId {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) return user.id;
    return GuestModeService.getGuestIdSync() ?? 'guest';
  }

  /// Generate a report for the given month. Computes all data from local DB.
  Future<MonthlyReport> generateReport(int year, int month, {bool forceRegenerate = false}) async {
    // Return cached report if available (unless forced)
    if (!forceRegenerate) {
      final cached = await _getCachedReport(year, month);
      if (cached != null) return cached;
    }

    final userId = _userId;
    final startDate = '$year-${month.toString().padLeft(2, '0')}-01';
    final lastDay = DateTime(year, month + 1, 0).day;
    final endDate = '$year-${month.toString().padLeft(2, '0')}-$lastDay';

    // Get income/expense summary
    final summary = await _db.getTransactionsSummaryAggregate(
      userId,
      startDate: startDate,
      endDate: endDate,
    );
    final totalIncome = summary['income'] ?? 0.0;
    final totalExpenses = summary['expenses'] ?? 0.0;
    final netSaved = totalIncome - totalExpenses;
    final savingsRate = totalIncome > 0 ? (netSaved / totalIncome * 100) : 0.0;

    // Get all transactions for the month
    final txRows = await _db.getFilteredTransactions(
      userId,
      startDate: startDate,
      endDate: endDate,
      pageSize: 100000,
    );
    final confirmedTx = txRows.where(
      (t) => (t['status'] as String? ?? 'confirmed') == 'confirmed',
    ).toList();

    // Days active and streak
    final activeDays = <String>{};
    for (final t in confirmedTx) {
      activeDays.add((t['date'] as String).substring(0, 10));
    }
    final daysActive = activeDays.length;

    // Best streak in the month
    final sortedDays = activeDays.toList()..sort();
    int bestStreak = 0;
    int currentStreak = 0;
    DateTime? lastDate;
    for (final dayStr in sortedDays) {
      final date = DateTime.parse(dayStr);
      if (lastDate != null && date.difference(lastDate).inDays == 1) {
        currentStreak++;
      } else {
        currentStreak = 1;
      }
      if (currentStreak > bestStreak) bestStreak = currentStreak;
      lastDate = date;
    }

    // Top 5 expense categories
    final categoryTotals = <String, double>{};
    for (final t in confirmedTx) {
      final amount = (t['amount'] as num).toDouble();
      final category = t['category'] as String;
      if (amount < 0 &&
          category.toLowerCase() != 'transfer' &&
          category.toLowerCase() != 'goal funding') {
        categoryTotals[category] =
            (categoryTotals[category] ?? 0) + amount.abs();
      }
    }
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top5 = sortedCategories.take(5).toList();
    final totalCatSpend =
        categoryTotals.values.fold<double>(0, (s, v) => s + v);
    final topCategories = top5
        .map((e) => CategoryBreakdown(
              category: e.key,
              amount: e.value,
              percentage: totalCatSpend > 0 ? (e.value / totalCatSpend * 100) : 0,
            ))
        .toList();

    // Goals contributed (count of goal funding transactions)
    final goalsContributed = confirmedTx
        .where((t) =>
            (t['category'] as String).toLowerCase() == 'goal funding' &&
            (t['amount'] as num).toDouble() < 0)
        .length;

    // Budget adherence
    final budgets = await _db.getBudgets(
      userId,
      '$year-${month.toString().padLeft(2, '0')}',
      'monthly',
    );
    int budgetsExceeded = 0;
    if (budgets.isNotEmpty) {
      for (final b in budgets) {
        final budgetCat = b['category'] as String;
        final budgetAmount = (b['amount'] as num).toDouble();
        final spent = categoryTotals[budgetCat] ?? 0;
        if (spent > budgetAmount) budgetsExceeded++;
      }
    }

    // Debt reduction check
    final debts = await _db.getDebts(userId);
    final hasDebts = debts.isNotEmpty;

    // Health score (simplified version matching health_tab.dart approach)
    final savingsRateScore = totalIncome > 0
        ? (savingsRate / 20 * 100).clamp(0.0, 100.0)
        : 0.0;

    double budgetAdherenceScore = 50.0;
    if (budgets.isNotEmpty) {
      final underLimit = budgets.length - budgetsExceeded;
      budgetAdherenceScore =
          (underLimit / budgets.length * 100).clamp(0.0, 100.0);
    }

    final streakScore = daysActive >= 25
        ? 100.0
        : daysActive >= 20
            ? 80.0
            : daysActive >= 15
                ? 60.0
                : (daysActive / 15 * 60).clamp(0.0, 60.0);

    final goalScore = goalsContributed > 0 ? 100.0 : 50.0;
    final debtScore = hasDebts ? 60.0 : 100.0; // simplified

    final healthScore = (savingsRateScore * 0.30 +
            budgetAdherenceScore * 0.25 +
            streakScore * 0.15 +
            goalScore * 0.15 +
            debtScore * 0.15)
        .clamp(0.0, 100.0);

    // Previous month's health score for delta
    final prevMonth = month == 1 ? 12 : month - 1;
    final prevYear = month == 1 ? year - 1 : year;
    double healthScoreDelta = 0;
    final prevReport = await _getCachedReport(prevYear, prevMonth);
    if (prevReport != null) {
      healthScoreDelta = healthScore - prevReport.healthScore;
    }

    // Compute grade
    final grade = _computeGrade(
      savingsRate: savingsRate,
      budgetsExceeded: budgetsExceeded,
      daysActive: daysActive,
      goalsContributed: goalsContributed,
      hasDebts: hasDebts,
    );

    // ── Sandwich report: positive highlight ──
    String positiveHighlight;
    // Find best under-budget category
    String? underBudgetCat;
    double underBudgetAmt = 0;
    for (final b in budgets) {
      final budgetCat = b['category'] as String;
      final budgetAmount = (b['amount'] as num).toDouble();
      final spent = categoryTotals[budgetCat] ?? 0;
      if (spent < budgetAmount && (budgetAmount - spent) > underBudgetAmt) {
        underBudgetAmt = budgetAmount - spent;
        underBudgetCat = budgetCat;
      }
    }
    if (underBudgetCat != null && underBudgetAmt > 0) {
      positiveHighlight = 'You stayed \u20B1${underBudgetAmt.toStringAsFixed(0)} under your $underBudgetCat budget! \ud83c\udfaf';
    } else if (savingsRate > 20) {
      positiveHighlight = 'Your savings rate was ${savingsRate.toStringAsFixed(1)}% \u2014 above the recommended 20%! \ud83d\udcc8';
    } else if (bestStreak > 20) {
      positiveHighlight = 'You maintained a $bestStreak-day logging streak this month! \ud83d\udd25';
    } else if (goalsContributed > 0) {
      positiveHighlight = 'You made $goalsContributed goal contribution${goalsContributed > 1 ? 's' : ''} this month! \ud83d\udcaa';
    } else {
      final txCount = confirmedTx.length;
      positiveHighlight = 'You logged $txCount transaction${txCount != 1 ? 's' : ''} this month \u2014 awareness is the first step! \u2728';
    }

    // ── Hard truth ──
    String hardTruth;
    String? overBudgetCat;
    double overBudgetAmt = 0;
    for (final b in budgets) {
      final budgetCat = b['category'] as String;
      final budgetAmount = (b['amount'] as num).toDouble();
      final spent = categoryTotals[budgetCat] ?? 0;
      if (spent > budgetAmount && (spent - budgetAmount) > overBudgetAmt) {
        overBudgetAmt = spent - budgetAmount;
        overBudgetCat = budgetCat;
      }
    }
    if (overBudgetCat != null) {
      hardTruth = 'You went \u20B1${overBudgetAmt.toStringAsFixed(0)} over on $overBudgetCat this month.';
    } else if (savingsRate < 10) {
      hardTruth = 'Your savings rate was only ${savingsRate.toStringAsFixed(1)}% \u2014 below the healthy 20% target.';
    } else if (goalsContributed == 0) {
      hardTruth = 'No contributions to your savings goals this month.';
    } else {
      hardTruth = 'No major concerns this month \u2014 keep it up!';
    }

    // ── Encouragement ──
    String encouragement;
    if (overBudgetCat != null) {
      final cat = overBudgetCat.toLowerCase();
      if (cat == 'food') {
        encouragement = 'Try meal prepping on Sundays \u2014 even 2 days of home cooking saves \u20B1500+/week.';
      } else if (cat == 'transportation') {
        encouragement = 'Consider a weekly Grab pass or carpooling to cap transport costs.';
      } else {
        encouragement = 'Review your top 3 categories \u2014 small adjustments there make the biggest impact.';
      }
    } else if (savingsRate < 10) {
      encouragement = 'Try the \u20B120 challenge \u2014 save \u20B120 more each day. By month end that\u2019s \u20B1600+.';
    } else if (goalsContributed == 0) {
      encouragement = 'Even \u20B1100/week to your goal adds up to \u20B15,200 in a year!';
    } else {
      encouragement = 'Stay consistent and keep logging. You\u2019re building great habits! \ud83c\udf1f';
    }

    final report = MonthlyReport(
      grade: grade,
      year: year,
      month: month,
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      netSaved: netSaved,
      savingsRate: savingsRate,
      topCategories: topCategories,
      daysActive: daysActive,
      bestStreak: bestStreak,
      healthScore: healthScore,
      healthScoreDelta: healthScoreDelta,
      goalsContributed: goalsContributed,
      stageStepsCompleted: 0, // Not tracked in local DB
      positiveHighlight: positiveHighlight,
      hardTruth: hardTruth,
      encouragement: encouragement,
    );

    // Cache the report
    await _cacheReport(report);

    return report;
  }

  String _computeGrade({
    required double savingsRate,
    required int budgetsExceeded,
    required int daysActive,
    required int goalsContributed,
    required bool hasDebts,
  }) {
    // Weighted scoring: savings 30%, budget 25%, streak 15%, goal 15%, debt 15%
    double score = 0;

    // Savings rate (30%)
    if (savingsRate >= 20) {
      score += 30;
    } else if (savingsRate >= 10) {
      score += 22.5;
    } else if (savingsRate >= 0) {
      score += 15;
    } else {
      score += 7.5;
    }

    // Budget adherence (25%)
    if (budgetsExceeded == 0) {
      score += 25;
    } else if (budgetsExceeded == 1) {
      score += 18.75;
    } else if (budgetsExceeded <= 3) {
      score += 12.5;
    } else {
      score += 6.25;
    }

    // Streak consistency (15%)
    if (daysActive >= 25) {
      score += 15;
    } else if (daysActive >= 20) {
      score += 11.25;
    } else if (daysActive >= 15) {
      score += 7.5;
    } else {
      score += 3.75;
    }

    // Goal progress (15%)
    if (goalsContributed > 0) {
      score += 15;
    } else {
      score += 7.5;
    }

    // Debt (15%)
    if (!hasDebts) {
      score += 15;
    } else {
      score += 7.5; // simplified: assume minimum paid
    }

    // Convert score to grade
    if (score >= 95) return 'A+';
    if (score >= 85) return 'A';
    if (score >= 78) return 'B+';
    if (score >= 68) return 'B';
    if (score >= 58) return 'C+';
    if (score >= 48) return 'C';
    return 'D';
  }

  /// Get all cached reports, most recent first.
  Future<List<MonthlyReport>> getAllReports() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('report_')).toList();
    keys.sort((a, b) => b.compareTo(a)); // Most recent first

    final reports = <MonthlyReport>[];
    for (final key in keys) {
      final raw = prefs.getString(key);
      if (raw != null) {
        try {
          reports.add(MonthlyReport.fromJson(
            jsonDecode(raw) as Map<String, dynamic>,
          ));
        } catch (_) {}
      }
    }
    return reports;
  }

  Future<MonthlyReport?> _getCachedReport(int year, int month) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'report_${year}_${month.toString().padLeft(2, '0')}';
    final raw = prefs.getString(key);
    if (raw == null) return null;
    try {
      return MonthlyReport.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> _cacheReport(MonthlyReport report) async {
    final prefs = await SharedPreferences.getInstance();
    final key =
        'report_${report.year}_${report.month.toString().padLeft(2, '0')}';
    await prefs.setString(key, jsonEncode(report.toJson()));
  }
}
