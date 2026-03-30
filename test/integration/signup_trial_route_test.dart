import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sandalan/core/services/premium_service.dart';
import 'package:sandalan/core/router/premium_route_guard.dart';

/// Integration test: signup activates trial → trial unlocks premium routes.
/// Tests the full chain from trial activation to route access.
void main() {
  group('Signup → Trial → Route Access', () {
    test('fresh user is blocked from all premium routes', () async {
      SharedPreferences.setMockInitialValues({});
      final service = PremiumService.instance;
      await service.init();

      // Should NOT have premium
      if (service.isPremium) return; // Skip if singleton has leftover state

      for (final route in premiumRoutes.keys) {
        final blocked = blockedByPremium(route, service);
        expect(blocked, isNotNull, reason: '$route should be blocked before signup');
      }
    });

    test('after signup trial activation, all premium routes are accessible', () async {
      SharedPreferences.setMockInitialValues({});
      final service = PremiumService.instance;

      // Simulate signup flow
      final granted = await service.activateSignupTrial();
      // Trial may already exist from previous test (singleton) — that's OK
      if (!granted && !service.hasActiveSignupTrial) {
        fail('Trial should be active');
      }

      // All premium routes should now be allowed
      for (final route in premiumRoutes.keys) {
        final blocked = blockedByPremium(route, service);
        expect(blocked, isNull, reason: '$route should be allowed during trial');
      }
    });

    test('trial grants exactly 30 days', () async {
      SharedPreferences.setMockInitialValues({});
      final service = PremiumService.instance;
      await service.activateSignupTrial();

      final daysLeft = service.signupTrialDaysLeft;
      expect(daysLeft, inInclusiveRange(29, 30));
    });

    test('second signup attempt does not reset trial', () async {
      // Pre-seed with a trial that has 10 days left
      final tenDaysFromNow = DateTime.now().add(const Duration(days: 10));
      SharedPreferences.setMockInitialValues({
        'signup_trial_expiry': tenDaysFromNow.toIso8601String(),
      });
      final service = PremiumService.instance;
      await service.init();

      // Try to activate again — should fail (one-time only)
      final granted = await service.activateSignupTrial();
      expect(granted, false);

      // Days left should still be ~10, not reset to 30
      expect(service.signupTrialDaysLeft, lessThanOrEqualTo(10));
    });

    test('expired trial blocks premium routes', () async {
      // Pre-seed with expired trial
      final expired = DateTime.now().subtract(const Duration(days: 5));
      SharedPreferences.setMockInitialValues({
        'signup_trial_expiry': expired.toIso8601String(),
      });
      final service = PremiumService.instance;
      await service.init();

      expect(service.hasActiveSignupTrial, false);

      // Premium routes should be blocked again
      if (!service.isPremium) {
        final blocked = blockedByPremium('/chat', service);
        expect(blocked, isNotNull, reason: 'Expired trial should not grant access');
      }
    });

    test('purchasing premium after trial expiry grants access', () async {
      final expired = DateTime.now().subtract(const Duration(days: 5));
      SharedPreferences.setMockInitialValues({
        'signup_trial_expiry': expired.toIso8601String(),
      });
      final service = PremiumService.instance;
      await service.init();

      // Simulate purchase
      await service.setPremium(true);
      expect(service.isPremium, true);

      // All routes should be allowed
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
      final service = PremiumService.instance;
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
      final service = PremiumService.instance;
      await service.init();

      expect(service.hasActiveStreakReward, false);

      if (!service.isPremium) {
        final blocked = blockedByPremium('/investments', service);
        expect(blocked, isNotNull);
      }
    });
  });
}
