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

  // Finance tracking
  static const bills = 'feature_visible_bills';
  static const debts = 'feature_visible_debts';
  static const insurance = 'feature_visible_insurance';
  static const contributions = 'feature_visible_contributions';

  // Dashboard sections
  static const budgets = 'feature_visible_budgets';
  static const goals = 'feature_visible_goals';
  static const healthScore = 'feature_visible_health_score';
  static const spendingChart = 'feature_visible_spending_chart';

  static const allKeys = [
    taxTracker, thirteenthMonth, retirement, rentVsBuy, panganay, calculators,
    bills, debts, insurance, contributions,
    budgets, goals, healthScore, spendingChart,
  ];
}

final featureVisibilityProvider =
    StateNotifierProvider<FeatureVisibilityNotifier, Map<String, bool>>((ref) {
  return FeatureVisibilityNotifier();
});

class FeatureVisibilityNotifier extends StateNotifier<Map<String, bool>> {
  FeatureVisibilityNotifier() : super({}) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final map = <String, bool>{};
    for (final key in FeatureKeys.allKeys) {
      map[key] = prefs.getBool(key) ?? true; // default visible
    }
    state = map;
  }

  bool isVisible(String key) => state[key] ?? true;

  Future<void> toggle(String key) async {
    final current = state[key] ?? true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, !current);
    state = {...state, key: !current};
  }
}
