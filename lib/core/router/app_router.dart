import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/widgets/app_scaffold.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/guide/screens/guide_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/transactions/screens/transactions_screen.dart';
import '../../features/accounts/screens/accounts_screen.dart';
import '../../features/budgets/screens/budgets_screen.dart';
import '../../features/goals/screens/goals_screen.dart';
import '../../features/tools/screens/tools_hub_screen.dart';
import '../../features/tools/screens/contributions_screen.dart';
import '../../features/tools/screens/tax_tracker_screen.dart';
import '../../features/tools/screens/thirteenth_month_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/home',
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final isLoggedIn = session != null;
    final isAuthRoute = state.uri.path == '/login' || state.uri.path == '/signup';
    final isOnboarding = state.uri.path == '/onboarding';

    // Not logged in -> redirect to login (unless already on auth route)
    if (!isLoggedIn && !isAuthRoute) {
      return '/login';
    }

    // Logged in on auth route -> redirect to home
    if (isLoggedIn && isAuthRoute) {
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

    // ─── App routes (with bottom nav shell) ───────────────────────────
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
        GoRoute(
          path: '/tools/contributions',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ContributionsScreen(),
          ),
        ),
        GoRoute(
          path: '/tools/13th-month',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ThirteenthMonthScreen(),
          ),
        ),
        GoRoute(
          path: '/tools/taxes',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: TaxTrackerScreen(),
          ),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SettingsScreen(),
          ),
        ),
      ],
    ),
  ],
);
