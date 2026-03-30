import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sandalan/core/router/premium_route_guard.dart';
import 'package:sandalan/core/services/premium_service.dart';

void main() {
  late PremiumService service;

  setUp(() async {
    // Reset singleton + fresh SharedPreferences for each test
    PremiumService.instance.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    service = PremiumService.instance;
    await service.init();
  });

  group('Free user is blocked from all premium routes', () {
    final routes = [
      '/tools/bills',
      '/tools/debts',
      '/tools/insurance',
      '/tools/contributions',
      '/tools/taxes',
      '/tools/13th-month',
      '/tools/retirement',
      '/tools/rent-vs-buy',
      '/tools/panganay',
      '/tools/calculators',
      '/tools/currency',
      '/tools',
      '/investments',
      '/split-bills',
      '/salary-allocation',
      '/vault',
      '/chat',
      '/reports',
    ];

    for (final route in routes) {
      test('blocks $route', () {
        final blocked = blockedByPremium(route, service);
        expect(blocked, isNotNull, reason: '$route should be blocked for free user');
      });
    }

    test('blocks nested route /reports/2026/3', () {
      final blocked = blockedByPremium('/reports/2026/3', service);
      expect(blocked, isNotNull);
    });

    test('blocks nested route /tools/bills/123', () {
      final blocked = blockedByPremium('/tools/bills/123', service);
      expect(blocked, isNotNull);
    });
  });

  group('Free routes are never blocked', () {
    final freeRoutes = [
      '/home',
      '/guide',
      '/guide/unang-hakbang',
      '/dashboard',
      '/transactions',
      '/accounts',
      '/budgets',
      '/goals',
      '/more',
      '/settings',
      '/achievements',
      '/onboarding',
      '/login',
      '/signup',
    ];

    for (final route in freeRoutes) {
      test('allows $route', () {
        final blocked = blockedByPremium(route, service);
        expect(blocked, isNull, reason: '$route should not be blocked');
      });
    }
  });

  group('Premium user passes all routes', () {
    test('all premium routes return null when isPremium', () async {
      // Make user premium
      await service.setPremium(true);

      for (final route in premiumRoutes.keys) {
        final blocked = blockedByPremium(route, service);
        expect(blocked, isNull, reason: '$route should be allowed for premium user');
      }
    });
  });

  group('Trial user passes all routes', () {
    test('all premium routes return null during active trial', () async {
      await service.activateSignupTrial();

      for (final route in premiumRoutes.keys) {
        final blocked = blockedByPremium(route, service);
        expect(blocked, isNull, reason: '$route should be allowed during trial');
      }
    });
  });

  group('Correct PremiumFeature returned', () {
    test('/tools/bills returns billsTracker', () {
      expect(blockedByPremium('/tools/bills', service), PremiumFeature.billsTracker);
    });

    test('/chat returns aiChat', () {
      expect(blockedByPremium('/chat', service), PremiumFeature.aiChat);
    });

    test('/investments returns investments', () {
      expect(blockedByPremium('/investments', service), PremiumFeature.investments);
    });
  });
}
