import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sandalan/core/services/streak_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('First visit', () {
    test('sets streak to 1', () async {
      SharedPreferences.setMockInitialValues({});
      await StreakService.instance.recordVisit();
      expect(await StreakService.instance.getStreak(), 1);
    });

    test('sets best streak to 1', () async {
      SharedPreferences.setMockInitialValues({});
      await StreakService.instance.recordVisit();
      expect(await StreakService.instance.getBestStreak(), 1);
    });
  });

  group('Same day visit', () {
    test('is a no-op — streak stays the same', () async {
      final today = _dateStr(DateTime.now());
      SharedPreferences.setMockInitialValues({
        'streak_count': 5,
        'streak_best': 5,
        'last_active_date': today,
      });
      await StreakService.instance.recordVisit();
      expect(await StreakService.instance.getStreak(), 5);
    });
  });

  group('Consecutive day visit', () {
    test('increments streak', () async {
      final yesterday = _dateStr(DateTime.now().subtract(const Duration(days: 1)));
      SharedPreferences.setMockInitialValues({
        'streak_count': 5,
        'streak_best': 5,
        'last_active_date': yesterday,
        'streak_last_server_verify': DateTime.now().toIso8601String(),
      });
      await StreakService.instance.recordVisit();
      expect(await StreakService.instance.getStreak(), 6);
    });
  });

  group('Gap of 2+ days', () {
    test('resets streak to 1', () async {
      final threeDaysAgo = _dateStr(DateTime.now().subtract(const Duration(days: 3)));
      SharedPreferences.setMockInitialValues({
        'streak_count': 10,
        'streak_best': 10,
        'last_active_date': threeDaysAgo,
        'streak_last_server_verify': DateTime.now().toIso8601String(),
      });
      await StreakService.instance.recordVisit();
      expect(await StreakService.instance.getStreak(), 1);
    });
  });

  group('Pahinha tokens (streak freeze)', () {
    test('2-day gap with pahinha token continues streak', () async {
      final twoDaysAgo = _dateStr(DateTime.now().subtract(const Duration(days: 2)));
      SharedPreferences.setMockInitialValues({
        'streak_count': 15,
        'streak_best': 15,
        'last_active_date': twoDaysAgo,
        'pahinha_tokens': 2,
        'streak_last_server_verify': DateTime.now().toIso8601String(),
      });
      await StreakService.instance.recordVisit();
      expect(await StreakService.instance.getStreak(), 16);
      expect(StreakService.instance.lastVisitUsedPahinha, true);
      // Token should be consumed
      expect(await StreakService.instance.getPahinhaTokens(), 1);
    });

    test('2-day gap with 0 tokens resets streak', () async {
      final twoDaysAgo = _dateStr(DateTime.now().subtract(const Duration(days: 2)));
      SharedPreferences.setMockInitialValues({
        'streak_count': 15,
        'streak_best': 15,
        'last_active_date': twoDaysAgo,
        'pahinha_tokens': 0,
        'streak_last_server_verify': DateTime.now().toIso8601String(),
      });
      await StreakService.instance.recordVisit();
      expect(await StreakService.instance.getStreak(), 1);
    });

    test('earns pahinha token at 7-day multiple', () async {
      final yesterday = _dateStr(DateTime.now().subtract(const Duration(days: 1)));
      SharedPreferences.setMockInitialValues({
        'streak_count': 6, // Will become 7 after this visit
        'streak_best': 6,
        'last_active_date': yesterday,
        'pahinha_tokens': 0,
        'streak_last_server_verify': DateTime.now().toIso8601String(),
      });
      await StreakService.instance.recordVisit();
      expect(await StreakService.instance.getStreak(), 7);
      expect(await StreakService.instance.getPahinhaTokens(), 1);
    });

    test('pahinha tokens cap at 3', () async {
      final yesterday = _dateStr(DateTime.now().subtract(const Duration(days: 1)));
      SharedPreferences.setMockInitialValues({
        'streak_count': 13, // Will become 14 (7*2)
        'streak_best': 13,
        'last_active_date': yesterday,
        'pahinha_tokens': 3,
        'streak_last_server_verify': DateTime.now().toIso8601String(),
      });
      await StreakService.instance.recordVisit();
      expect(await StreakService.instance.getPahinhaTokens(), 3); // Stays at 3
    });
  });

  group('90-day streak reward', () {
    test('streak reaching 90 sets justUnlockedStreakReward', () async {
      final yesterday = _dateStr(DateTime.now().subtract(const Duration(days: 1)));
      SharedPreferences.setMockInitialValues({
        'streak_count': 89, // Will become 90
        'streak_best': 89,
        'last_active_date': yesterday,
        'streak_last_server_verify': DateTime.now().toIso8601String(),
      });
      await StreakService.instance.recordVisit();
      expect(await StreakService.instance.getStreak(), 90);
      expect(StreakService.instance.justUnlockedStreakReward, true);
    });
  });

  group('Best streak tracking', () {
    test('best updates when current exceeds it', () async {
      final yesterday = _dateStr(DateTime.now().subtract(const Duration(days: 1)));
      SharedPreferences.setMockInitialValues({
        'streak_count': 20,
        'streak_best': 20,
        'last_active_date': yesterday,
        'streak_last_server_verify': DateTime.now().toIso8601String(),
      });
      await StreakService.instance.recordVisit();
      expect(await StreakService.instance.getBestStreak(), 21);
    });

    test('best preserved when streak resets', () async {
      final threeDaysAgo = _dateStr(DateTime.now().subtract(const Duration(days: 3)));
      SharedPreferences.setMockInitialValues({
        'streak_count': 10,
        'streak_best': 50,
        'last_active_date': threeDaysAgo,
        'streak_last_server_verify': DateTime.now().toIso8601String(),
      });
      await StreakService.instance.recordVisit();
      expect(await StreakService.instance.getStreak(), 1);
      expect(await StreakService.instance.getBestStreak(), 50);
    });
  });

  group('Week history', () {
    test('returns 7 booleans', () async {
      SharedPreferences.setMockInitialValues({});
      final history = await StreakService.instance.getWeekHistory();
      expect(history.length, 7);
    });
  });
}

String _dateStr(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
