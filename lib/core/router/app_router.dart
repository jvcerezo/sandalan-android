import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/guest_mode_service.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/guide/screens/guide_screen.dart';
import '../../features/guide/screens/stage_detail_screen.dart';
import '../../features/guide/screens/article_screen.dart';
import '../../features/guide/screens/checklist_detail_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/transactions/screens/transactions_screen.dart';
import '../../features/accounts/screens/accounts_screen.dart';
import '../../features/budgets/screens/budgets_screen.dart';
import '../../features/goals/screens/goals_screen.dart';
import '../../features/tools/screens/tools_hub_screen.dart';
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
import '../../shared/widgets/safe_back_wrapper.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Cached landing page, loaded synchronously from SharedPreferences at startup.
String _cachedLandingPage = '/home';

/// Call before creating the router to load the default landing page.
Future<void> loadDefaultLandingPage() async {
  final prefs = await SharedPreferences.getInstance();
  _cachedLandingPage = prefs.getString('default_landing_page') ?? '/home';
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

    // Active session on signup route -> redirect to home
    // (but NOT on /login — let them see the quick-login card)
    if (isLoggedIn && state.uri.path == '/signup') {
      return '/home';
    }

    // Logged in but not onboarded -> redirect to onboarding
    // (onboarding check is handled inside onboarding screen itself)

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
        GoRoute(
          path: '/dashboard',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DashboardScreen(),
          ),
        ),
        GoRoute(
          path: '/transactions',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: TransactionsScreen(),
          ),
        ),
        GoRoute(
          path: '/accounts',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AccountsScreen(),
          ),
        ),
        GoRoute(
          path: '/budgets',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: BudgetsScreen(),
          ),
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
        // ─── Finance & Tool sub-pages (inside shell for consistent header) ─
        GoRoute(path: '/investments', pageBuilder: (_, s) => const MaterialPage(child: InvestmentsScreen())),
        GoRoute(path: '/salary-allocation', pageBuilder: (_, s) => const MaterialPage(child: SalaryAllocationScreen())),
        GoRoute(path: '/tools/contributions', pageBuilder: (_, s) => MaterialPage(child: ContributionsScreen())),
        GoRoute(path: '/tools/13th-month', pageBuilder: (_, s) => MaterialPage(child: ThirteenthMonthScreen())),
        GoRoute(path: '/tools/retirement', pageBuilder: (_, s) => MaterialPage(child: RetirementScreen())),
        GoRoute(path: '/tools/rent-vs-buy', pageBuilder: (_, s) => MaterialPage(child: RentVsBuyScreen())),
        GoRoute(path: '/tools/panganay', pageBuilder: (_, s) => MaterialPage(child: PanganayModeScreen())),
        GoRoute(path: '/tools/calculators', pageBuilder: (_, s) => MaterialPage(child: CalculatorsScreen())),
        GoRoute(path: '/tools/insurance', pageBuilder: (_, s) => MaterialPage(child: InsuranceScreen())),
        GoRoute(path: '/tools/bills', pageBuilder: (_, s) => MaterialPage(child: BillsScreen())),
        GoRoute(path: '/tools/debts', pageBuilder: (_, s) => MaterialPage(child: DebtManagerScreen())),
        GoRoute(path: '/tools/taxes', pageBuilder: (_, s) => MaterialPage(child: TaxTrackerScreen())),
        GoRoute(path: '/tools/currency', pageBuilder: (_, s) => const MaterialPage(child: CurrencyConverterScreen())),
        GoRoute(
          path: '/split-bills',
          pageBuilder: (context, state) => const MaterialPage(
            child: SplitsScreen(),
          ),
        ),
        GoRoute(
          path: '/achievements',
          pageBuilder: (context, state) => const MaterialPage(
            child: AchievementsScreen(),
          ),
        ),
        GoRoute(
          path: '/reports',
          pageBuilder: (context, state) => const MaterialPage(
            child: ReportsListScreen(),
          ),
        ),
        GoRoute(
          path: '/reports/:year/:month',
          pageBuilder: (context, state) => MaterialPage(
            child: MonthlyReportScreen(
              year: int.parse(state.pathParameters['year']!),
              month: int.parse(state.pathParameters['month']!),
            ),
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
          pageBuilder: (context, state) => const MaterialPage(
            child: ChatScreen(),
          ),
        ),
      ],
    ),
  ],
);
