import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'milestone_service.dart';
import 'premium_service.dart';

/// Tracks daily app usage streaks using SharedPreferences.
class StreakService {
  StreakService._();
  static final StreakService instance = StreakService._();

  static const _keyStreakCount = 'streak_count';
  static const _keyStreakBest = 'streak_best';
  static const _keyLastActiveDate = 'last_active_date';
  static const _keyStreakHistory = 'streak_history';
  static const _keyPahinhaTokens = 'pahinha_tokens';
  static const _keyPahinhaUsedDates = 'pahinha_used_dates';
  static const maxPahinhaTokens = 3;

  /// Whether a pahinha token was consumed on this visit.
  bool lastVisitUsedPahinha = false;

  /// Whether this visit unlocked the 90-day streak reward.
  bool justUnlockedStreakReward = false;

  static const _keyLastServerVerify = 'streak_last_server_verify';

  /// Record a visit. Call on home screen load.
  /// - Same day: no-op
  /// - Yesterday: increment streak
  /// - >1 day gap: reset to 1
  ///
  /// Anti-tamper: periodically verifies device time against server.
  /// If device clock is >48h ahead of server, streak is reset.
  Future<void> recordVisit() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayStr = _dateStr(now);
    final lastStr = prefs.getString(_keyLastActiveDate);

    if (lastStr == todayStr) return; // Same day, no-op

    // Anti-tamper: verify device time every 3 days
    final lastVerifyStr = prefs.getString(_keyLastServerVerify);
    final lastVerify = lastVerifyStr != null ? DateTime.tryParse(lastVerifyStr) : null;
    final shouldVerify = lastVerify == null ||
        now.difference(lastVerify).inDays >= 3;

    if (shouldVerify) {
      final serverTime = await PremiumService.getServerTime();
      if (serverTime != null) {
        final drift = now.difference(serverTime).inHours;
        if (drift > 48) {
          // Device clock is way ahead — reset streak to prevent gaming
          await prefs.setInt(_keyStreakCount, 0);
          await prefs.setString(_keyLastActiveDate, todayStr);
          return;
        }
        await prefs.setString(_keyLastServerVerify, serverTime.toIso8601String());
      }
    }

    int streak = prefs.getInt(_keyStreakCount) ?? 0;
    int best = prefs.getInt(_keyStreakBest) ?? 0;

    lastVisitUsedPahinha = false;
    int pahinhaTokens = prefs.getInt(_keyPahinhaTokens) ?? 0;

    if (lastStr != null) {
      final lastDate = DateTime.tryParse(lastStr);
      if (lastDate != null) {
        final diff = _daysDifference(lastDate, now);
        if (diff == 1) {
          // Yesterday — normal streak increment
          streak += 1;
        } else if (diff == 2 && pahinhaTokens > 0) {
          // Missed exactly 1 day — use pahinha token to save streak
          pahinhaTokens -= 1;
          streak += 1; // Continue the streak
          lastVisitUsedPahinha = true;
          // Record the pahinha date
          final usedJson = prefs.getString(_keyPahinhaUsedDates);
          List<String> used = [];
          if (usedJson != null) {
            used = (jsonDecode(usedJson) as List).cast<String>();
          }
          used.add(_dateStr(now.subtract(const Duration(days: 1))));
          await prefs.setString(_keyPahinhaUsedDates, jsonEncode(used));
        } else {
          streak = 1; // Too big a gap, reset
        }
      } else {
        streak = 1;
      }
    } else {
      streak = 1;
    }

    // Check if earned a new pahinha token (every 7-day milestone)
    if (streak > 0 && streak % 7 == 0 && pahinhaTokens < maxPahinhaTokens) {
      pahinhaTokens += 1;
    }

    if (streak > best) best = streak;

    // Check if user just hit the 90-day streak reward threshold
    justUnlockedStreakReward = false;
    if (streak == PremiumService.streakRewardThreshold &&
        !PremiumService.instance.hasActiveStreakReward) {
      justUnlockedStreakReward = true;
      MilestoneService.checkAndTrigger('streak_reward_earned');
    }

    await prefs.setInt(_keyPahinhaTokens, pahinhaTokens);

    await prefs.setInt(_keyStreakCount, streak);
    await prefs.setInt(_keyStreakBest, best);
    await prefs.setString(_keyLastActiveDate, todayStr);

    // Push streak to Supabase for cross-device sync (fire-and-forget)
    _pushStreakToCloud(streak, best, todayStr, pahinhaTokens);

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

  /// Get current pahinha (streak freeze) token count.
  Future<int> getPahinhaTokens() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyPahinhaTokens) ?? 0;
  }

  /// Get dates where pahinha tokens were used.
  Future<List<String>> getPahinhaUsedDates() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_keyPahinhaUsedDates);
    if (json == null) return [];
    return (jsonDecode(json) as List).cast<String>();
  }

  int _daysDifference(DateTime a, DateTime b) {
    final dateA = DateTime(a.year, a.month, a.day);
    final dateB = DateTime(b.year, b.month, b.day);
    return dateB.difference(dateA).inDays;
  }

  // ─── Cross-device sync ─────────────────────────────────────────────────────

  /// Push streak data to Supabase profiles table. Fire-and-forget.
  Future<void> _pushStreakToCloud(int streak, int best, String lastDate, int tokens) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      await Supabase.instance.client.from('profiles').update({
        'streak_count': streak,
        'streak_best': best,
        'last_active_date': lastDate,
        'pahinha_tokens': tokens,
      }).eq('id', user.id);
    } catch (e) {
      if (kDebugMode) debugPrint('StreakService: push to cloud failed: $e');
    }
  }

  /// Pull streak data from Supabase and restore to SharedPreferences.
  /// Call this on login to restore streak on a new device.
  /// Uses max(local, remote) to never lose progress.
  Future<void> pullFromCloud() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final data = await Supabase.instance.client
          .from('profiles')
          .select('streak_count, streak_best, last_active_date, pahinha_tokens')
          .eq('id', user.id)
          .maybeSingle();

      if (data == null) return;

      final prefs = await SharedPreferences.getInstance();
      final localStreak = prefs.getInt(_keyStreakCount) ?? 0;
      final localBest = prefs.getInt(_keyStreakBest) ?? 0;
      final localTokens = prefs.getInt(_keyPahinhaTokens) ?? 0;

      final cloudStreak = data['streak_count'] as int? ?? 0;
      final cloudBest = data['streak_best'] as int? ?? 0;
      final cloudDate = data['last_active_date'] as String?;
      final cloudTokens = data['pahinha_tokens'] as int? ?? 0;

      // Use whichever is higher (never lose progress)
      if (cloudStreak > localStreak) {
        await prefs.setInt(_keyStreakCount, cloudStreak);
      }
      if (cloudBest > localBest) {
        await prefs.setInt(_keyStreakBest, cloudBest);
      }
      if (cloudTokens > localTokens) {
        await prefs.setInt(_keyPahinhaTokens, cloudTokens);
      }
      if (cloudDate != null) {
        final localDate = prefs.getString(_keyLastActiveDate);
        if (localDate == null || cloudDate.compareTo(localDate) > 0) {
          await prefs.setString(_keyLastActiveDate, cloudDate);
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('StreakService: pull from cloud failed: $e');
    }
  }
}
