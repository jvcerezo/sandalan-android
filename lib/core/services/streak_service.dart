import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks daily app usage streaks using SharedPreferences.
class StreakService {
  StreakService._();
  static final StreakService instance = StreakService._();

  static const _keyStreakCount = 'streak_count';
  static const _keyStreakBest = 'streak_best';
  static const _keyLastActiveDate = 'last_active_date';
  static const _keyStreakHistory = 'streak_history';

  /// Record a visit. Call on home screen load.
  /// - Same day: no-op
  /// - Yesterday: increment streak
  /// - >1 day gap: reset to 1
  Future<void> recordVisit() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayStr = _dateStr(now);
    final lastStr = prefs.getString(_keyLastActiveDate);

    if (lastStr == todayStr) return; // Same day, no-op

    int streak = prefs.getInt(_keyStreakCount) ?? 0;
    int best = prefs.getInt(_keyStreakBest) ?? 0;

    if (lastStr != null) {
      final lastDate = DateTime.tryParse(lastStr);
      if (lastDate != null) {
        final diff = _daysDifference(lastDate, now);
        if (diff == 1) {
          streak += 1;
        } else {
          streak = 1;
        }
      } else {
        streak = 1;
      }
    } else {
      streak = 1;
    }

    if (streak > best) best = streak;

    await prefs.setInt(_keyStreakCount, streak);
    await prefs.setInt(_keyStreakBest, best);
    await prefs.setString(_keyLastActiveDate, todayStr);

    // Update 7-day history
    final historyJson = prefs.getString(_keyStreakHistory);
    List<String> history = [];
    if (historyJson != null) {
      history = (jsonDecode(historyJson) as List).cast<String>();
    }
    if (!history.contains(todayStr)) {
      history.add(todayStr);
    }
    // Keep only last 14 days to allow lookback for any week
    if (history.length > 14) {
      history = history.sublist(history.length - 14);
    }
    await prefs.setString(_keyStreakHistory, jsonEncode(history));
  }

  /// Get current streak count.
  Future<int> getStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyStreakCount) ?? 0;
  }

  /// Get best streak ever.
  Future<int> getBestStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyStreakBest) ?? 0;
  }

  /// Returns a List<bool> of length 7 for Mon-Sun of the current week,
  /// indicating whether the user was active on each day.
  Future<List<bool>> getWeekHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_keyStreakHistory);
    final Set<String> activeDates = {};
    if (historyJson != null) {
      activeDates.addAll((jsonDecode(historyJson) as List).cast<String>());
    }

    final now = DateTime.now();
    // Monday = 1, Sunday = 7
    final monday = now.subtract(Duration(days: now.weekday - 1));

    return List.generate(7, (i) {
      final day = DateTime(monday.year, monday.month, monday.day + i);
      return activeDates.contains(_dateStr(day));
    });
  }

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  int _daysDifference(DateTime a, DateTime b) {
    final dateA = DateTime(a.year, a.month, a.day);
    final dateB = DateTime(b.year, b.month, b.day);
    return dateB.difference(dateA).inDays;
  }
}
