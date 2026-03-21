/// Monthly financial report card model.

class CategoryBreakdown {
  final String category;
  final double amount;
  final double percentage;

  const CategoryBreakdown({
    required this.category,
    required this.amount,
    required this.percentage,
  });

  factory CategoryBreakdown.fromJson(Map<String, dynamic> json) {
    return CategoryBreakdown(
      category: json['category'] as String,
      amount: (json['amount'] as num).toDouble(),
      percentage: (json['percentage'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'category': category,
        'amount': amount,
        'percentage': percentage,
      };
}

class MonthlyReport {
  final String grade; // A+, A, B+, B, C+, C, D
  final int year;
  final int month;
  final double totalIncome;
  final double totalExpenses;
  final double netSaved;
  final double savingsRate;
  final List<CategoryBreakdown> topCategories; // top 5
  final int daysActive;
  final int bestStreak;
  final double healthScore;
  final double healthScoreDelta;
  final int goalsContributed;
  final int stageStepsCompleted;

  const MonthlyReport({
    required this.grade,
    required this.year,
    required this.month,
    required this.totalIncome,
    required this.totalExpenses,
    required this.netSaved,
    required this.savingsRate,
    required this.topCategories,
    required this.daysActive,
    required this.bestStreak,
    required this.healthScore,
    required this.healthScoreDelta,
    required this.goalsContributed,
    required this.stageStepsCompleted,
  });

  factory MonthlyReport.fromJson(Map<String, dynamic> json) {
    return MonthlyReport(
      grade: json['grade'] as String,
      year: json['year'] as int,
      month: json['month'] as int,
      totalIncome: (json['total_income'] as num).toDouble(),
      totalExpenses: (json['total_expenses'] as num).toDouble(),
      netSaved: (json['net_saved'] as num).toDouble(),
      savingsRate: (json['savings_rate'] as num).toDouble(),
      topCategories: (json['top_categories'] as List<dynamic>)
          .map((e) => CategoryBreakdown.fromJson(e as Map<String, dynamic>))
          .toList(),
      daysActive: json['days_active'] as int,
      bestStreak: json['best_streak'] as int,
      healthScore: (json['health_score'] as num).toDouble(),
      healthScoreDelta: (json['health_score_delta'] as num).toDouble(),
      goalsContributed: json['goals_contributed'] as int,
      stageStepsCompleted: json['stage_steps_completed'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'grade': grade,
        'year': year,
        'month': month,
        'total_income': totalIncome,
        'total_expenses': totalExpenses,
        'net_saved': netSaved,
        'savings_rate': savingsRate,
        'top_categories': topCategories.map((c) => c.toJson()).toList(),
        'days_active': daysActive,
        'best_streak': bestStreak,
        'health_score': healthScore,
        'health_score_delta': healthScoreDelta,
        'goals_contributed': goalsContributed,
        'stage_steps_completed': stageStepsCompleted,
      };
}
