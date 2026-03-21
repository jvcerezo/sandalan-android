import 'package:shared_preferences/shared_preferences.dart';
import '../../data/tips/daily_tips.dart';

/// Service to manage daily tip selection and dismissal.
class TipService {
  TipService._();
  static final TipService instance = TipService._();

  static const _keyLastTipDate = 'last_tip_date';
  static const _keySeenTipIndexes = 'seen_tip_indexes';
  static const _keyCurrentTipIndex = 'current_tip_index';
  static const _keyTipDismissedDate = 'tip_dismissed_date';

  /// Get today's tip. Picks a new one if it's a new day.
  /// [context] map can contain: hasBudgets, hasContributions, hasDebts
  Future<DailyTip> getTodaysTip({
    bool hasBudgets = true,
    bool hasContributions = true,
    bool hasDebts = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayStr();
    final lastDate = prefs.getString(_keyLastTipDate);

    if (lastDate == today) {
      // Return same tip
      final idx = prefs.getInt(_keyCurrentTipIndex) ?? 0;
      return dailyTips[idx % dailyTips.length];
    }

    // New day — pick a new tip
    final seenList = prefs.getStringList(_keySeenTipIndexes) ?? [];
    final seen = seenList.map(int.parse).toSet();

    // If all seen, reset
    if (seen.length >= dailyTips.length) {
      seen.clear();
      await prefs.setStringList(_keySeenTipIndexes, []);
    }

    // Determine priority category
    String? priorityCategory;
    if (!hasBudgets) {
      priorityCategory = 'budgeting';
    } else if (!hasContributions) {
      priorityCategory = 'government';
    } else if (hasDebts) {
      priorityCategory = 'debt';
    }

    int? selectedIdx;

    // Try to find an unseen tip from priority category
    if (priorityCategory != null) {
      for (int i = 0; i < dailyTips.length; i++) {
        if (!seen.contains(i) && dailyTips[i].category == priorityCategory) {
          selectedIdx = i;
          break;
        }
      }
    }

    // Fallback: round-robin through categories
    if (selectedIdx == null) {
      for (int i = 0; i < dailyTips.length; i++) {
        if (!seen.contains(i)) {
          selectedIdx = i;
          break;
        }
      }
    }

    selectedIdx ??= 0;

    seen.add(selectedIdx);
    await prefs.setStringList(
        _keySeenTipIndexes, seen.map((e) => e.toString()).toList());
    await prefs.setInt(_keyCurrentTipIndex, selectedIdx);
    await prefs.setString(_keyLastTipDate, today);

    return dailyTips[selectedIdx];
  }

  /// Whether today's tip has been dismissed.
  Future<bool> isDismissedToday() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyTipDismissedDate) == _todayStr();
  }

  /// Dismiss today's tip.
  Future<void> dismissTip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTipDismissedDate, _todayStr());
  }

  String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
