import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/guest_mode_service.dart';
import '../services/premium_service.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/guide/screens/guide_screen.dart';
import '../../features/guide/screens/stage_detail_screen.dart';
import '../../features/guide/screens/article_screen.dart';
import '../../features/guide/screens/checklist_detail_screen.dart';
import '../../features/money/screens/money_screen.dart';
import '../../features/goals/screens/goals_screen.dart';
import '../../features/tools/screens/tools_hub_screen.dart';
import '../../features/vault/screens/vault_screen.dart';
import '../../features/tools/screens/contributions_screen.dart';
import '../../features/tools/screens/tax_tracker_screen.dart';
import '../../features/tools/screens/thirteenth_month_screen.dart';
import '../../features/tools/screens/debt_manager_screen.dart';
import '../../features/tools/screens/bills_screen.dart';
import '../../features/tools/screens/insurance_screen.dart';
import '../../features/tools/screens/retirement_screen.dart';
import '../../features/tools/screens/rent_vs_buy_screen.dart';
import '../../features/tools/screens/panganay_mode_screen.dart';
import '../../features/tools/screens/calculators_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/investments/screens/investments_screen.dart';
import '../../features/settings/widgets/salary_allocation_screen.dart';
import '../../features/achievements/screens/achievements_screen.dart';
import '../../features/reports/screens/reports_list_screen.dart';
import '../../features/reports/screens/monthly_report_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/splits/screens/splits_screen.dart';
import '../../features/tools/screens/currency_converter_screen.dart';
import '../../features/more/screens/more_screen.dart';
import '../../shared/widgets/safe_back_wrapper.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Pending money tab — set by router redirects before navigation.
/// MoneyScreen reads this in initState to set the initial tab.
int _pendingMoneyTab = 0;
int get pendingMoneyTab => _pendingMoneyTab;
void _setMoneyTab(int tab) => _pendingMoneyTab = tab;

/// Cached landing page, loaded synchronously from SharedPreferences at startup.
String _cachedLandingPage = '/home';

/// Call before creating the router to load the default landing page.
Future<void> loadDefaultLandingPage() async {
  final prefs = await SharedPreferences.getInstance();
  _cachedLandingPage = prefs.getString('default_landing_page') ?? '/home';
}

/// Routes that require premium access. Maps route prefix -> PremiumFeature.
/// The router redirect checks this before allowing navigation.
const _premiumRoutes = <String, PremiumFeature>{
  '/tools/bills': PremiumFeature.billsTracker,
  '/tools/debts': PremiumFeature.debtManager,
  '/tools/insurance': PremiumFeature.insuranceTracker,
  '/tools/contributions': PremiumFeature.contributionTracker,
  '/tools/taxes': PremiumFeature.taxTracker,
  '/tools/13th-month': PremiumFeature.advancedCalculators,
  '/tools/retirement': PremiumFeature.advancedCalculators,
  '/tools/rent-vs-buy': PremiumFeature.advancedCalculators,
  '/tools/panganay': PremiumFeature.panganayMode,
  '/tools/calculators': PremiumFeature.advancedCalculators,
  '/tools/currency': PremiumFeature.exchangeRates,
  '/tools': PremiumFeature.advancedCalculators,
  '/investments': PremiumFeature.investments,
  '/split-bills': PremiumFeature.splitBills,
  '/salary-allocation': PremiumFeature.salaryAllocation,
  '/vault': PremiumFeature.documentVault,
  '/chat': PremiumFeature.aiChat,
  '/reports': PremiumFeature.advancedReports,
};

/// Check if a path requires premium and the user doesn't have access.
/// Returns the PremiumFeature that's blocking, or null if allowed.
PremiumFeature? _blockedByPremium(String path) {
  final premium = PremiumService.instance;
  for (final entry in _premiumRoutes.entries) {
    if (path == entry.key || path.startsWith('${entry.key}/')) {
      if (!premium.hasAccess(entry.value)) return entry.value;
      break;
    }
  }
  return null;
}

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: _cachedLandingPage,
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final isLoggedIn = session != null;
    final isGuest = GuestModeService.isGuestSync();
    final isAuthRoute = state.uri.path == '/login' || state.uri.path == '/signup';

    // Not logged in and not guest -> must go to login
    if (!isLoggedIn && !isGuest && !isAuthRoute) {
      return '/login';
    }

    // Guest trying to access login -> block, send to signup instead
    if (isGuest && state.uri.path == '/login') {
      return '/signup';
    }

    // Active session on signup route -> redirect to home
    if (isLoggedIn && state.uri.path == '/signup') {
      return '/home';
    }

    // Premium route guard — redirect to /more if user lacks access.
    // The UI-level gates (showPremiumGateWithPaywall) handle showing
    // the paywall; this redirect is a safety net for deep links,
    // search results, guide links, and any other bypass.
    final blocked = _blockedByPremium(state.uri.path);
    if (blocked != null) {
      return '/more';
    }

    return null;
  },
  routes: [
    // ─── Auth routes (no bottom nav) ──────────────────────────────────
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    // Chat moved into ShellRoute below for consistent header + menu FAB

    // ─── Guide sub-pages (full-screen push, no shell) ───────────────
    GoRoute(
      path: '/guide/:stageSlug',
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (context, state) {
        final slug = state.pathParameters['stageSlug']!;
        return MaterialPage(child: SafeBackWrapper(
          fallbackRoute: '/guide',
          child: StageDetailScreen(stageSlug: slug),
        ));
      },
    ),
    GoRoute(
      path: '/guide/:stageSlug/checklist/:itemId',
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (context, state) {
        final slug = state.pathParameters['stageSlug']!;
        return MaterialPage(child: SafeBackWrapper(
          fallbackRoute: '/guide/$slug',
          child: ChecklistDetailScreen(stageSlug: slug, itemId: state.pathParameters['itemId']!),
        ));
      },
    ),
    GoRoute(
      path: '/guide/:stageSlug/:guideSlug',
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (context, state) {
        final slug = state.pathParameters['stageSlug']!;
        return MaterialPage(child: SafeBackWrapper(
          fallbackRoute: '/guide/$slug',
          child: ArticleScreen(stageSlug: slug, guideSlug: state.pathParameters['guideSlug']!),
        ));
      },
    ),

    // Tool/finance sub-pages moved into ShellRoute below for consistent header

    // ─── App routes (with shell) ─────────────────────────────────────
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => AppScaffold(child: child),
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HomeScreen(),
          ),
        ),
        GoRoute(
          path: '/guide',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: GuideScreen(),
          ),
        ),
        // Money: single route, tab switching via moneyTabProvider
        GoRoute(
          path: '/dashboard',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: MoneyScreen(),
          ),
        ),
        GoRoute(
          path: '/transactions',
          redirect: (context, state) {
            // Set tab to Transactions before redirecting
            _setMoneyTab(1);
            return '/dashboard';
          },
        ),
        GoRoute(
          path: '/accounts',
          redirect: (context, state) {
            _setMoneyTab(2);
            return '/dashboard';
          },
        ),
        GoRoute(
          path: '/budgets',
          redirect: (context, state) {
            _setMoneyTab(3);
            return '/dashboard';
          },
        ),
        GoRoute(
          path: '/goals',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: GoalsScreen(),
          ),
        ),
        GoRoute(
          path: '/tools',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ToolsHubScreen(),
          ),
        ),
        // ─── Finance & Tool sub-pages (inside shell — no transition) ────
        GoRoute(path: '/investments', pageBuilder: (_, s) => const NoTransitionPage(child: InvestmentsScreen())),
        GoRoute(path: '/salary-allocation', pageBuilder: (_, s) => const NoTransitionPage(child: SalaryAllocationScreen())),
        GoRoute(path: '/tools/contributions', pageBuilder: (_, s) => NoTransitionPage(child: ContributionsScreen())),
        GoRoute(path: '/tools/13th-month', pageBuilder: (_, s) => NoTransitionPage(child: ThirteenthMonthScreen())),
        GoRoute(path: '/tools/retirement', pageBuilder: (_, s) => NoTransitionPage(child: RetirementScreen())),
        GoRoute(path: '/tools/rent-vs-buy', pageBuilder: (_, s) => NoTransitionPage(child: RentVsBuyScreen())),
        GoRoute(path: '/tools/panganay', pageBuilder: (_, s) => NoTransitionPage(child: PanganayModeScreen())),
        GoRoute(path: '/tools/calculators', pageBuilder: (_, s) => NoTransitionPage(child: CalculatorsScreen())),
        GoRoute(path: '/tools/insurance', pageBuilder: (_, s) => NoTransitionPage(child: InsuranceScreen())),
        GoRoute(path: '/tools/bills', pageBuilder: (_, s) => NoTransitionPage(child: BillsScreen())),
        GoRoute(path: '/tools/debts', pageBuilder: (_, s) => NoTransitionPage(child: DebtManagerScreen())),
        GoRoute(path: '/tools/taxes', pageBuilder: (_, s) => NoTransitionPage(child: TaxTrackerScreen())),
        GoRoute(path: '/tools/currency', pageBuilder: (_, s) => const NoTransitionPage(child: CurrencyConverterScreen())),
        GoRoute(
          path: '/split-bills',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SplitsScreen(),
          ),
        ),
        GoRoute(path: '/vault', pageBuilder: (_, s) => const NoTransitionPage(child: VaultScreen())),
        GoRoute(
          path: '/achievements',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AchievementsScreen(),
          ),
        ),
        GoRoute(
          path: '/reports',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ReportsListScreen(),
          ),
        ),
        GoRoute(
          path: '/reports/:year/:month',
          pageBuilder: (context, state) => NoTransitionPage(
            child: MonthlyReportScreen(
              year: int.parse(state.pathParameters['year']!),
              month: int.parse(state.pathParameters['month']!),
            ),
          ),
        ),
        GoRoute(
          path: '/more',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: MoreScreen(),
          ),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SettingsScreen(),
          ),
        ),
        GoRoute(
          path: '/chat',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ChatScreen(),
          ),
        ),
      ],
    ),
  ],
);
