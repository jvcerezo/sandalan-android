import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sandalan/core/services/premium_service.dart';

void main() {
  late PremiumService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PremiumService.instance.resetForTesting();
    service = PremiumService.instance;
  });

  group('hasAccess', () {
    test('returns false for free user with no trial or streak', () async {
      await service.init();
      expect(service.isBetaPeriod, false);
      expect(service.hasAccess(PremiumFeature.aiChat), false);
    });
  });

  group('Signup Trial', () {
    test('activateSignupTrial grants 30 days', () async {
      await service.init();
      final granted = await service.activateSignupTrial();
      expect(granted, true);

      final prefs = await SharedPreferences.getInstance();
      final expiryStr = prefs.getString('signup_trial_expiry');
      expect(expiryStr, isNotNull);

      final expiry = DateTime.parse(expiryStr!);
      expect(expiry.difference(DateTime.now()).inDays, closeTo(30, 1));
    });

    test('activateSignupTrial second call returns false (one-time)', () async {
      SharedPreferences.setMockInitialValues({
        'signup_trial_expiry': DateTime.now().add(const Duration(days: 25)).toIso8601String(),
      });
      await service.init();
      final granted = await service.activateSignupTrial();
      expect(granted, false);
    });

    test('hasActiveSignupTrial true when expiry in future', () async {
      SharedPreferences.setMockInitialValues({
        'signup_trial_expiry': DateTime.now().add(const Duration(days: 10)).toIso8601String(),
      });
      await service.init();
      expect(service.hasActiveSignupTrial, true);
    });

    test('signupTrialDaysLeft returns correct count', () async {
      SharedPreferences.setMockInitialValues({
        'signup_trial_expiry': DateTime.now().add(const Duration(days: 15)).toIso8601String(),
      });
      await service.init();
      expect(service.signupTrialDaysLeft, inInclusiveRange(14, 15));
    });
  });

  group('setPremium', () {
    test('persists to SharedPreferences', () async {
      await service.init();
      await service.setPremium(true);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('is_premium_user'), true);
      expect(prefs.getString('premium_purchase_date'), isNotNull);
    });

    test('isPremium returns true after setPremium(true)', () async {
      await service.init();
      await service.setPremium(true);
      expect(service.isPremium, true);
    });
  });

  group('Streak Reward', () {
    test('hasActiveStreakReward true when expiry in future', () async {
      SharedPreferences.setMockInitialValues({
        'streak_reward_expiry': DateTime.now().add(const Duration(days: 15)).toIso8601String(),
      });
      await service.init();
      expect(service.hasActiveStreakReward, true);
      expect(service.streakRewardDaysLeft, inInclusiveRange(14, 15));
    });

    test('claimStreakReward fails below threshold', () async {
      await service.init();
      final claimed = await service.claimStreakReward(50);
      expect(claimed, false);
    });
  });

  group('Beta Period', () {
    test('isBetaPeriod is false (production mode)', () {
      expect(service.isBetaPeriod, false);
    });
  });
}
