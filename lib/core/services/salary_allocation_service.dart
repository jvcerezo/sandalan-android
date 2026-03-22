import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AllocationRule {
  final String type; // 'budget', 'goal', 'bills', 'debts', 'savings'
  final String label;
  final double amount;
  final bool auto;
  final String? categoryOrGoal;

  const AllocationRule({
    required this.type, required this.label, required this.amount,
    this.auto = false, this.categoryOrGoal,
  });

  factory AllocationRule.fromJson(Map<String, dynamic> j) => AllocationRule(
    type: j['type'] as String, label: j['label'] as String,
    amount: (j['amount'] as num).toDouble(),
    auto: j['auto'] as bool? ?? false,
    categoryOrGoal: j['category_or_goal'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'type': type, 'label': label, 'amount': amount,
    'auto': auto, 'category_or_goal': categoryOrGoal,
  };
}

class SalaryAllocationConfig {
  final double salary;
  final String frequency; // 'monthly', 'twice_monthly', 'biweekly', 'weekly'
  final List<int> payDates;
  final List<AllocationRule> rules;

  const SalaryAllocationConfig({
    required this.salary, required this.frequency,
    this.payDates = const [15, 30], this.rules = const [],
  });

  double get totalAllocated => rules.fold(0.0, (s, r) => s + r.amount);
  double get freeAmount => salary - totalAllocated;
  double get allocatedPercent => salary > 0 ? (totalAllocated / salary) * 100 : 0;

  factory SalaryAllocationConfig.fromJson(Map<String, dynamic> j) =>
      SalaryAllocationConfig(
        salary: (j['salary'] as num).toDouble(),
        frequency: j['frequency'] as String,
        payDates: (j['pay_dates'] as List?)?.cast<int>() ?? [15, 30],
        rules: (j['rules'] as List?)
            ?.map((r) => AllocationRule.fromJson(r as Map<String, dynamic>))
            .toList() ?? [],
      );

  Map<String, dynamic> toJson() => {
    'salary': salary, 'frequency': frequency,
    'pay_dates': payDates,
    'rules': rules.map((r) => r.toJson()).toList(),
  };
}

class SalaryAllocationService {
  static const _key = 'salary_allocation_config';
  static const _lastAllocatedKey = 'last_salary_allocated_date';

  static Future<SalaryAllocationConfig?> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json == null) return null;
    return SalaryAllocationConfig.fromJson(
        jsonDecode(json) as Map<String, dynamic>);
  }

  static Future<void> saveConfig(SalaryAllocationConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(config.toJson()));
  }

  static Future<bool> hasAllocatedThisPeriod() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString(_lastAllocatedKey);
    if (lastDate == null) return false;
    final last = DateTime.tryParse(lastDate);
    if (last == null) return false;
    final now = DateTime.now();
    return last.year == now.year && last.month == now.month &&
        (now.day - last.day).abs() < 3;
  }

  static Future<void> markAllocated() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastAllocatedKey, DateTime.now().toIso8601String());
  }

  static Future<bool> isConfigured() async {
    final config = await loadConfig();
    return config != null && config.rules.isNotEmpty;
  }
}
