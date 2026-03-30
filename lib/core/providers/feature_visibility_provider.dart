import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keys for each hideable feature.
class FeatureKeys {
  // Calculators & Tools
  static const taxTracker = 'feature_visible_tax';
  static const thirteenthMonth = 'feature_visible_13th_month';
  static const retirement = 'feature_visible_retirement';
  static const rentVsBuy = 'feature_visible_rent_vs_buy';
  static const panganay = 'feature_visible_panganay';
  static const calculators = 'feature_visible_calculators';
  static const currency = 'feature_visible_currency';

  // Finance tracking
  static const bills = 'feature_visible_bills';
  static const debts = 'feature_visible_debts';
  static const insurance = 'feature_visible_insurance';
  static const contributions = 'feature_visible_contributions';
  static const investments = 'feature_visible_investments';
  static const splitBills = 'feature_visible_split_bills';
  static const salaryAllocation = 'feature_visible_salary_allocation';

  // Dashboard sections
  static const budgets = 'feature_visible_budgets';
  static const goals = 'feature_visible_goals';
  static const healthScore = 'feature_visible_health_score';
  static const spendingChart = 'feature_visible_spending_chart';

  // App features
  static const achievements = 'feature_visible_achievements';
  static const reports = 'feature_visible_reports';

  static const allKeys = [
    taxTracker, thirteenthMonth, retirement, rentVsBuy, panganay, calculators, currency,
    bills, debts, insurance, contributions, investments, splitBills, salaryAllocation,
    budgets, goals, healthScore, spendingChart,
    achievements, reports,
  ];

  /// Features shown by default for new users.
  /// Everything else starts hidden until the user enables it.
  static const _defaultVisible = {
    bills, debts, contributions, goals,
    budgets, healthScore, spendingChart,
    achievements, investments, insurance,
    splitBills, salaryAllocation,
  };

  /// Returns the default visibility for a given key.
  static bool defaultFor(String key) => _defaultVisible.contains(key);
}

final featureVisibilityProvider =
    StateNotifierProvider<FeatureVisibilityNotifier, Map<String, bool>>((ref) {
  return FeatureVisibilityNotifier();
});

class FeatureVisibilityNotifier extends StateNotifier<Map<String, bool>> {
  FeatureVisibilityNotifier() : super({}) {
    _load();
  }

  Future<void> reload() async => _load();

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final map = <String, bool>{};
    for (final key in FeatureKeys.allKeys) {
      // If the user has explicitly set a value, use it.
      // Otherwise fall back to the beginner-friendly default.
      map[key] = prefs.getBool(key) ?? FeatureKeys.defaultFor(key);
    }
    state = map;
  }

  bool isVisible(String key) => state[key] ?? FeatureKeys.defaultFor(key);

  Future<void> toggle(String key) async {
    final current = state[key] ?? FeatureKeys.defaultFor(key);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, !current);
    state = {...state, key: !current};
  }
}
