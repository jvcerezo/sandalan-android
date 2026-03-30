import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sandalan/core/services/premium_service.dart';
import 'package:sandalan/core/router/premium_route_guard.dart';

/// Integration test: signup activates trial → trial unlocks premium routes.
/// Tests the full chain from trial activation to route access.
void main() {
  late PremiumService service;

  setUp(() {
    PremiumService.instance.resetForTesting();
    service = PremiumService.instance;
  });

  group('Signup → Trial → Route Access', () {
    test('fresh user is blocked from all premium routes', () async {
      SharedPreferences.setMockInitialValues({});
      await service.init();

      for (final route in premiumRoutes.keys) {
        final blocked = blockedByPremium(route, service);
        expect(blocked, isNotNull, reason: '$route should be blocked before signup');
      }
    });

    test('after signup trial activation, all premium routes are accessible', () async {
      SharedPreferences.setMockInitialValues({});
      await service.init();

      final granted = await service.activateSignupTrial();
      expect(granted, true);

      for (final route in premiumRoutes.keys) {
        final blocked = blockedByPremium(route, service);
        expect(blocked, isNull, reason: '$route should be allowed during trial');
      }
    });

    test('trial grants exactly 30 days', () async {
      SharedPreferences.setMockInitialValues({});
      await service.init();
      await service.activateSignupTrial();

      final daysLeft = service.signupTrialDaysLeft;
      expect(daysLeft, inInclusiveRange(29, 30));
    });

    test('second signup attempt does not reset trial', () async {
      final tenDaysFromNow = DateTime.now().add(const Duration(days: 10));
      SharedPreferences.setMockInitialValues({
        'signup_trial_expiry': tenDaysFromNow.toIso8601String(),
      });
      await service.init();

      final granted = await service.activateSignupTrial();
      expect(granted, false);

      expect(service.signupTrialDaysLeft, lessThanOrEqualTo(11));
    });

    test('expired trial blocks premium routes', () async {
      final expired = DateTime.now().subtract(const Duration(days: 5));
      SharedPreferences.setMockInitialValues({
        'signup_trial_expiry': expired.toIso8601String(),
      });
      await service.init();

      expect(service.hasActiveSignupTrial, false);

      final blocked = blockedByPremium('/chat', service);
      expect(blocked, isNotNull, reason: 'Expired trial should not grant access');
    });

    test('purchasing premium after trial expiry grants access', () async {
      final expired = DateTime.now().subtract(const Duration(days: 5));
      SharedPreferences.setMockInitialValues({
        'signup_trial_expiry': expired.toIso8601String(),
      });
      await service.init();

      await service.setPremium(true);
      expect(service.isPremium, true);

      for (final route in premiumRoutes.keys) {
        final blocked = blockedByPremium(route, service);
        expect(blocked, isNull, reason: '$route should be allowed after purchase');
      }
    });
  });

  group('Streak Reward → Route Access', () {
    test('active streak reward unlocks all premium routes', () async {
      final thirtyDaysFromNow = DateTime.now().add(const Duration(days: 30));
      SharedPreferences.setMockInitialValues({
        'streak_reward_expiry': thirtyDaysFromNow.toIso8601String(),
      });
      await service.init();

      expect(service.hasActiveStreakReward, true);

      for (final route in premiumRoutes.keys) {
        final blocked = blockedByPremium(route, service);
        expect(blocked, isNull, reason: '$route should be allowed during streak reward');
      }
    });

    test('expired streak reward blocks premium routes', () async {
      final expired = DateTime.now().subtract(const Duration(days: 1));
      SharedPreferences.setMockInitialValues({
        'streak_reward_expiry': expired.toIso8601String(),
      });
      await service.init();

      expect(service.hasActiveStreakReward, false);

      final blocked = blockedByPremium('/investments', service);
      expect(blocked, isNotNull);
    });
  });
}
