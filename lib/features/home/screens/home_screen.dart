import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app.dart';
import '../../../core/services/streak_service.dart';
import '../../../core/services/tip_service.dart';
import '../../../core/services/weekly_recap_service.dart';
import '../../../core/services/widget_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../data/tips/daily_tips.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../shared/widgets/staggered_fade_in.dart';
import '../../../shared/widgets/animated_counter.dart';
import '../../auth/providers/auth_provider.dart';
import '../../transactions/providers/transaction_providers.dart';
import '../../tools/providers/tool_providers.dart';
import '../providers/upcoming_payments_provider.dart';
import '../widgets/streak_detail_sheet.dart';
import '../widgets/tip_of_day_card.dart';
import '../widgets/weekly_recap_card.dart';
import '../../../core/services/salary_allocation_service.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../tools/widgets/bill_calendar.dart';
import '../../transactions/widgets/quick_add_strip.dart';
import '../widgets/insight_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Streak state
  int _streak = 0;
  int _bestStreak = 0;
  List<bool> _weekHistory = List.filled(7, false);

  // Tip state
  DailyTip? _todaysTip;
  bool _tipDismissed = false;

  // Recap state
  WeeklyRecap? _weeklyRecap;
  bool _recapVisible = false;

  // Payday state
  bool _paydayDetected = false;
  bool _paydayDismissed = false;
  double _salaryAmount = 0;

  @override
  void initState() {
    super.initState();
    _initRetentionFeatures();
    _updateHomeWidget();
  }

  /// Push latest data to the Android home screen widget.
  Future<void> _updateHomeWidget() async {
    final streak = await StreakService.instance.getStreak();
    // Summary will be updated via ref.listen in build; send streak now.
    WidgetService.updateWidget(
      todaySpending: '\u20B10.00',
      streakCount: streak,
    );
  }

  Future<void> _initRetentionFeatures() async {
    // Record streak visit
    await StreakService.instance.recordVisit();

    final streak = await StreakService.instance.getStreak();
    final best = await StreakService.instance.getBestStreak();
    final history = await StreakService.instance.getWeekHistory();

    // Load tip
    final tip = await TipService.instance.getTodaysTip();
    final tipDismissed = await TipService.instance.isDismissedToday();

    // Load recap
    final recapVisible = await WeeklyRecapService.instance.isRecapVisible();
    WeeklyRecap? recap;
    if (recapVisible) {
      recap = await WeeklyRecapService.instance.getWeeklyRecap();
    }

    // Payday detection
    bool paydayDetected = false;
    double salaryAmount = 0;
    try {
      final configured = await SalaryAllocationService.isConfigured();
      if (configured) {
        final allocated = await SalaryAllocationService.hasAllocatedThisPeriod();
        if (!allocated) {
          // Check today's transactions for salary
          final txRepo = ref.read(transactionRepositoryProvider);
          final today = DateTime.now();
          final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
          final transactions = await txRepo.getTransactions(TransactionFilters(
            startDate: today,
            endDate: today,
          ));
          for (final t in transactions) {
            if (t.category.toLowerCase() == 'salary' && t.amount > 0) {
              paydayDetected = true;
              salaryAmount = t.amount;
              break;
            }
          }
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _streak = streak;
        _bestStreak = best;
        _weekHistory = history;
        _todaysTip = tip;
        _tipDismissed = tipDismissed;
        _weeklyRecap = recap;
        _recapVisible = recapVisible && recap != null;
        _paydayDetected = paydayDetected;
        _salaryAmount = salaryAmount;
      });
    }
  }

  Future<void> _onRefresh(WidgetRef ref) async {
    HapticFeedback.mediumImpact();
    ref.invalidate(transactionsSummaryProvider);
    ref.invalidate(profileProvider);
    ref.invalidate(billsSummaryProvider);
    ref.invalidate(debtSummaryProvider);
    await ref.read(transactionsSummaryProvider.future);
    await _initRetentionFeatures();
  }

  void _showStreakDetail() {
    StreakDetailSheet.show(
      context,
      streak: _streak,
      bestStreak: _bestStreak,
      weekHistory: _weekHistory,
    );
  }

  Future<void> _dismissTip() async {
    await TipService.instance.dismissTip();
    if (mounted) setState(() => _tipDismissed = true);
  }

  Future<void> _dismissRecap() async {
    await WeeklyRecapService.instance.dismissRecap();
    if (mounted) setState(() => _recapVisible = false);
  }

  Color _flameColor(int s) {
    if (s >= 100) return const Color(0xFFEF4444); // blazing red
    if (s >= 30) return const Color(0xFFF97316);   // strong orange
    if (s >= 7) return const Color(0xFFF59E0B);    // warm amber
    if (s >= 1) return const Color(0xFFD97706);    // earthy amber (active, not gray)
    return const Color(0xFF9CA3AF);                 // gray (only when 0)
  }

  /// Tier 2 contextual card slot logic:
  /// 1. Sun-Tue AND recap not dismissed -> WeeklyRecapCard
  /// 2. Else if tip not dismissed today (Wed-Sat) -> TipOfDayCard
  /// 3. Else -> nothing
  Widget _buildContextualCard() {
    final weekday = DateTime.now().weekday; // 1=Mon, 7=Sun

    // Weekly recap takes priority on Sun-Tue
    if ((weekday == 7 || weekday == 1 || weekday == 2) && _recapVisible && _weeklyRecap != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: WeeklyRecapCard(
          recap: _weeklyRecap!,
          onDismiss: _dismissRecap,
        ),
      );
    }

    // Tip of the day on Wed-Sat (or when recap is dismissed)
    if (!_tipDismissed && _todaysTip != null) {
      // Only show Wed-Sat when recap isn't showing
      final showTip = weekday >= 3 && weekday <= 6 ||
          // Also show on Sun-Tue if recap was dismissed
          ((weekday == 7 || weekday == 1 || weekday == 2) && !_recapVisible);
      if (showTip) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: TipOfDayCard(
            tip: _todaysTip!,
            onDismiss: _dismissTip,
          ),
        );
      }
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final profile = ref.watch(profileProvider);
    final firstName = profile.valueOrNull?.firstName ?? 'there';
    final summary = ref.watch(transactionsSummaryProvider);
    // Update home screen widget whenever the summary refreshes.
    ref.listen(transactionsSummaryProvider, (_, next) {
      next.whenData((s) {
        WidgetService.updateWidget(
          todaySpending: formatCurrency(s.expenses),
          streakCount: _streak,
        );
      });
    });
    final greetingStyle = ref.watch(greetingStyleProvider);
    final hideBalances = ref.watch(hideBalancesProvider);
    final compactNumbers = ref.watch(compactNumbersProvider);

    // Build greeting based on style
    String greeting;
    switch (greetingStyle) {
      case GreetingStyle.english:
        greeting = '${getTimeGreeting()}, $firstName';
      case GreetingStyle.filipino:
        greeting = '${getTimeGreetingFilipino()}, $firstName';
      case GreetingStyle.casual:
        greeting = 'Hey, $firstName!';
      case GreetingStyle.minimal:
        greeting = firstName;
    }

    return RefreshIndicator(
      onRefresh: () => _onRefresh(ref),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          // ─── Greeting + Streak Badge ──────────────────────────────
          StaggeredFadeIn(
            index: 0,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    greeting,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.3),
                  ),
                ),
                // Hide balances eye toggle
                GestureDetector(
                  onTap: () => ref.read(hideBalancesProvider.notifier).toggle(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      hideBalances ? LucideIcons.eyeOff : LucideIcons.eye,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (_streak > 0)
                  GestureDetector(
                    onTap: _showStreakDetail,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _flameColor(_streak).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.flame, size: 16, color: _flameColor(_streak)),
                          const SizedBox(width: 4),
                          Text(
                            '$_streak',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: _flameColor(_streak),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          StaggeredFadeIn(
            index: 0,
            child: Text(
              "Here's your snapshot for today.",
              style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 16),

          // ─── Payday Card ──────────────────────────────────────────
          if (_paydayDetected && !_paydayDismissed)
            StaggeredFadeIn(
              index: 1,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(colors: [
                      colorScheme.primary.withValues(alpha: 0.1),
                      colorScheme.primary.withValues(alpha: 0.05),
                    ]),
                    border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('\ud83d\udcb8 Salary received!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('${formatCurrency(_salaryAmount)} deposited. Ready to allocate to your budgets and goals?',
                          style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
                    ])),
                    const SizedBox(width: 12),
                    Column(children: [
                      FilledButton(
                        onPressed: () => context.go('/settings/salary-allocation'),
                        child: const Text('Allocate', style: TextStyle(fontSize: 12)),
                      ),
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: () => setState(() => _paydayDismissed = true),
                        child: const Text('Skip', style: TextStyle(fontSize: 12)),
                      ),
                    ]),
                  ]),
                ),
              ),
            ),

          // ─── Current Stage Card ──────────────────────────────────
          StaggeredFadeIn(
            index: 1,
            child: _CurrentStageCard(onTap: () => context.go('/guide')),
          ),
          const SizedBox(height: 14),

          // ─── Financial Summary ───────────────────────────────────
          StaggeredFadeIn(
            index: 2,
            child: summary.when(
              data: (s) => Row(
                children: [
                  _FinStat(
                    icon: LucideIcons.wallet,
                    label: 'Balance',
                    value: s.balance,
                    iconColor: colorScheme.onSurfaceVariant,
                    valueColor: colorScheme.onSurface,
                    hidden: hideBalances,
                    compact: compactNumbers,
                    onTap: () => context.go('/dashboard'),
                  ),
                  const SizedBox(width: 8),
                  _FinStat(
                    icon: LucideIcons.trendingUp,
                    label: 'Income',
                    value: s.income,
                    iconColor: AppColors.income,
                    valueColor: AppColors.income,
                    hidden: hideBalances,
                    compact: compactNumbers,
                    onTap: () => context.go('/dashboard'),
                  ),
                  const SizedBox(width: 8),
                  _FinStat(
                    icon: LucideIcons.trendingDown,
                    label: 'Expenses',
                    value: s.expenses,
                    iconColor: colorScheme.onSurfaceVariant,
                    valueColor: colorScheme.onSurface,
                    hidden: hideBalances,
                    compact: compactNumbers,
                    onTap: () => context.go('/dashboard'),
                  ),
                ],
              ),
              loading: () => const ShimmerStatRow(count: 3),
              error: (_, __) => _ErrorRetry(onRetry: () => ref.invalidate(transactionsSummaryProvider)),
            ),
          ),
          const SizedBox(height: 14),

          // ─── Quick Add Templates ──────────────────────────────────
          StaggeredFadeIn(
            index: 3,
            child: const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: QuickAddStrip(),
            ),
          ),

          // ─── Spending Insight ─────────────────────────────────────
          StaggeredFadeIn(
            index: 3,
            child: const HomeInsightCard(),
          ),

          // ─── Tier 2: Contextual Card (Recap or Tip) ───────────────
          StaggeredFadeIn(
            index: 3,
            child: _buildContextualCard(),
          ),

          // ─── Due This Week Strip ────────────────────────────────
          StaggeredFadeIn(
            index: 4,
            child: const DueThisWeekStrip(),
          ),

          // ─── Upcoming Payments ───────────────────────────────────
          StaggeredFadeIn(
            index: 5,
            child: _UpcomingPaymentsSection(ref: ref, hideBalances: hideBalances),
          ),

          // ─── Next Steps Carousel ─────────────────────────────────
          StaggeredFadeIn(
            index: 6,
            child: _NextStepsSection(),
          ),

          // ─── Quick Navigation ────────────────────────────────────
          const SizedBox(height: 6),
          StaggeredFadeIn(
            index: 7,
            child: _NavRow(
              icon: LucideIcons.bookOpen,
              iconBg: colorScheme.primary.withValues(alpha: 0.1),
              iconColor: colorScheme.primary,
              title: 'Adulting Guide',
              subtitle: '0% complete · 58 steps remaining',
              onTap: () => context.go('/guide'),
            ),
          ),
          const SizedBox(height: 8),
          StaggeredFadeIn(
            index: 8,
            child: _NavRow(
              icon: LucideIcons.wrench,
              iconBg: AppColors.warning.withValues(alpha: 0.1),
              iconColor: AppColors.warning,
              title: 'Tools',
              subtitle: 'Contributions, bills, debts, insurance & more',
              onTap: () => context.go('/tools'),
            ),
          ),
          const SizedBox(height: 8),
          StaggeredFadeIn(
            index: 9,
            child: _NavRow(
              icon: LucideIcons.wallet,
              iconBg: AppColors.toolEmerald.withValues(alpha: 0.1),
              iconColor: AppColors.toolEmerald,
              title: 'Financial Dashboard',
              subtitle: 'Budgets, trends, spending insights',
              onTap: () => context.go('/dashboard'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stage data lookup for home card ──────────────────────────────────────────

class _StageInfo {
  final String title;
  final IconData icon;
  final Color color;
  const _StageInfo(this.title, this.icon, this.color);
}

const _stageMap = <String, _StageInfo>{
  'unang-hakbang': _StageInfo('Unang Hakbang', LucideIcons.graduationCap, StageColors.blue),
  'pundasyon': _StageInfo('Pundasyon', LucideIcons.toyBrick, StageColors.emerald),
  'tahanan': _StageInfo('Tahanan', LucideIcons.home, StageColors.violet),
  'tugatog': _StageInfo('Tugatog', LucideIcons.mountain, StageColors.amber),
  'paghahanda': _StageInfo('Paghahanda', LucideIcons.clock, StageColors.rose),
  'gintong-taon': _StageInfo('Gintong Taon', LucideIcons.gem, StageColors.yellow),
};

// ─── Current Stage Card ────────────────────────────────────────────────────────

class _CurrentStageCard extends ConsumerWidget {
  final VoidCallback onTap;
  const _CurrentStageCard({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final profile = ref.watch(profileProvider).valueOrNull;
    final stageId = profile?.lifeStage ?? 'unang-hakbang';
    final stage = _stageMap[stageId] ??
        const _StageInfo('Unang Hakbang', LucideIcons.graduationCap, StageColors.blue);

    return Semantics(
      label: 'Current stage: ${stage.title}',
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border.all(color: colorScheme.surfaceContainerHighest),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: stage.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(stage.icon, size: 20, color: stage.color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CURRENT STAGE',
                        style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600,
                          letterSpacing: 0.8, color: colorScheme.onSurfaceVariant,
                        )),
                    const SizedBox(height: 3),
                    Text(stage.title,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 140),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: 0,
                                minHeight: 6,
                                backgroundColor: colorScheme.surfaceContainerHighest,
                                color: stage.color,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('0/58',
                            style: TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w500,
                              color: colorScheme.onSurfaceVariant,
                            )),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronRight, size: 16,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.35)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Financial Stat Card ───────────────────────────────────────────────────────

class _FinStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final Color iconColor;
  final Color valueColor;
  final bool hidden;
  final bool compact;
  final VoidCallback onTap;

  const _FinStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    required this.valueColor,
    this.hidden = false,
    this.compact = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Semantics(
        label: '$label: ${hidden ? 'hidden' : formatCurrency(value)}',
        button: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border.all(color: colorScheme.surfaceContainerHighest),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 12, color: iconColor),
                    const SizedBox(width: 4),
                    Text(label,
                        style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant)),
                  ],
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: hidden
                      ? Text(displayAmount(value, hidden: true),
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: valueColor))
                      : compact
                          ? Text(displayAmount(value, compact: true),
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: valueColor))
                          : AnimatedCurrency(
                              value: value,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: valueColor),
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Upcoming Payments ─────────────────────────────────────────────────────────

const _typeConfig = <PaymentType, ({IconData icon, Color color})>{
  PaymentType.bill: (icon: LucideIcons.receipt, color: Color(0xFF3B82F6)),
  PaymentType.debt: (icon: LucideIcons.creditCard, color: Color(0xFF8B5CF6)),
  PaymentType.insurance: (icon: LucideIcons.shield, color: Color(0xFF10B981)),
  PaymentType.contribution: (icon: LucideIcons.landmark, color: Color(0xFFF59E0B)),
};

class _UpcomingPaymentsSection extends StatelessWidget {
  final WidgetRef ref;
  final bool hideBalances;
  const _UpcomingPaymentsSection({required this.ref, this.hideBalances = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final upcoming = ref.watch(upcomingPaymentsProvider);

    return upcoming.when(
      data: (data) {
        if (data.items.isEmpty) return const SizedBox.shrink();

        final visible = data.items.take(5).toList();
        final remaining = data.items.length - visible.length;

        return Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Text('UPCOMING PAYMENTS',
                        style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600,
                          letterSpacing: 0.8, color: colorScheme.onSurfaceVariant,
                        )),
                    if (data.overdueCount > 0) ...[
                      const SizedBox(width: 8),
                      Row(children: [
                        const Icon(LucideIcons.alertCircle, size: 12, color: AppColors.expense),
                        const SizedBox(width: 3),
                        Text('${data.overdueCount} overdue',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                                color: AppColors.expense)),
                      ]),
                    ],
                  ]),
                  Text(displayAmount(data.totalDue, hidden: hideBalances),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Items
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.surfaceContainerHighest),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: visible.asMap().entries.map((entry) {
                  final item = entry.value;
                  final isLast = entry.key == visible.length - 1;
                  final config = _typeConfig[item.type]!;
                  final urgencyLabel = item.daysUntilDue < 0
                      ? 'Overdue'
                      : item.daysUntilDue == 0
                          ? 'Due today'
                          : '${item.daysUntilDue}d';
                  final urgencyColor = item.daysUntilDue < 0
                      ? AppColors.expense
                      : item.daysUntilDue <= 3
                          ? AppColors.warning
                          : colorScheme.onSurfaceVariant;

                  return _PaymentItem(
                    icon: config.icon,
                    iconColor: config.color,
                    iconBg: config.color.withValues(alpha: 0.1),
                    title: item.title,
                    subtitle: item.subtitle,
                    amount: item.amount,
                    urgency: urgencyLabel,
                    urgencyColor: urgencyColor,
                    showDivider: !isLast,
                    hideAmount: hideBalances,
                    onTap: () {
                      switch (item.type) {
                        case PaymentType.bill:
                          context.go('/tools/bills');
                        case PaymentType.debt:
                          context.go('/tools/debts');
                        case PaymentType.insurance:
                          context.go('/tools/insurance');
                        case PaymentType.contribution:
                          context.go('/tools/contributions');
                      }
                    },
                  );
                }).toList(),
              ),
            ),

            if (remaining > 0)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('+$remaining more upcoming',
                    style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center),
              ),

            const SizedBox(height: 18),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _PaymentItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final double amount;
  final String urgency;
  final Color? urgencyColor;
  final bool showDivider;
  final bool hideAmount;
  final VoidCallback? onTap;

  const _PaymentItem({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.urgency,
    this.urgencyColor,
    this.showDivider = true,
    this.hideAmount = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      label: '$title, $subtitle, ${hideAmount ? 'hidden' : formatCurrency(amount)}${urgency.isNotEmpty ? ', $urgency' : ''}',
      button: onTap != null,
      child: InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: iconColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(subtitle,
                          style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(displayAmount(amount, hidden: hideAmount),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    if (urgency.isNotEmpty)
                      Text(urgency,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500,
                              color: urgencyColor ?? colorScheme.onSurfaceVariant)),
                  ],
                ),
                const SizedBox(width: 4),
                Icon(LucideIcons.chevronRight, size: 14,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.25)),
              ],
            ),
          ),
          if (showDivider)
            Divider(height: 1, indent: 56, color: colorScheme.outline.withValues(alpha: 0.08)),
        ],
      ),
      ),
    );
  }
}

// ─── Next Steps Carousel ───────────────────────────────────────────────────────

class _NextStepsSection extends StatefulWidget {
  @override
  State<_NextStepsSection> createState() => _NextStepsSectionState();
}

class _NextStepsSectionState extends State<_NextStepsSection> {
  static const _prefsKey = 'dismissed_next_steps';
  Set<String> _dismissed = {};
  bool _loaded = false;

  // Static next steps based on guide data
  static const _allSteps = [
    _NextStep(
      id: 'tin',
      type: 'checklist',
      title: 'Get your TIN from BIR',
      description: 'Your Tax Identification Number is required for employment, banking, business registration,...',
      actionLabel: 'View Guide',
    ),
    _NextStep(
      id: 'sss',
      type: 'checklist',
      title: 'Register with SSS',
      description: 'The Social Security System provides retirement pension, disability benefits,...',
      actionLabel: 'View Guide',
    ),
    _NextStep(
      id: 'philhealth',
      type: 'checklist',
      title: 'Register with PhilHealth',
      description: 'Philippine Health Insurance Corporation provides healthcare coverage...',
      actionLabel: 'View Guide',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadDismissed();
  }

  Future<void> _loadDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefsKey) ?? [];
    setState(() {
      _dismissed = list.toSet();
      _loaded = true;
    });
  }

  Future<void> _dismiss(String stepId) async {
    final prefs = await SharedPreferences.getInstance();
    _dismissed.add(stepId);
    await prefs.setStringList(_prefsKey, _dismissed.toList());
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final steps = _allSteps.where((s) => !_dismissed.contains(s.id)).toList();

    if (steps.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text('NEXT STEPS',
              style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600,
                letterSpacing: 0.8, color: colorScheme.onSurfaceVariant,
              )),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 170,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            itemCount: steps.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) => _NextStepCard(
              step: steps[i],
              onDismiss: () => _dismiss(steps[i].id),
            ),
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }
}

class _NextStep {
  final String id;
  final String type;
  final String title;
  final String description;
  final String actionLabel;
  const _NextStep({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.actionLabel,
  });
}

class _NextStepCard extends StatelessWidget {
  final _NextStep step;
  final VoidCallback onDismiss;
  const _NextStepCard({required this.step, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isChecklist = step.type == 'checklist';
    final accentColor = isChecklist ? AppColors.warning : colorScheme.primary;

    return GestureDetector(
      onTap: () => context.go('/guide/unang-hakbang'),
      child: Container(
      width: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.surfaceContainerHighest),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isChecklist ? LucideIcons.alertCircle : LucideIcons.bookOpen,
                  size: 14, color: accentColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isChecklist ? 'NEXT STEP' : 'READ',
                  style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    letterSpacing: 0.8, color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Semantics(
                label: 'Dismiss next step',
                button: true,
                child: InkWell(
                  onTap: onDismiss,
                  borderRadius: BorderRadius.circular(24),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                      child: Icon(LucideIcons.x, size: 14,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Title
          Text(step.title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          // Description
          Expanded(
            child: Text(step.description,
                style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant, height: 1.3),
                maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
          // Action
          Row(
            children: [
              Text(step.actionLabel,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.primary)),
              const SizedBox(width: 4),
              Icon(LucideIcons.arrowRight, size: 12, color: colorScheme.primary),
            ],
          ),
        ],
      ),
    ),
    );
  }
}

// ─── Error Retry Widget ─────────────────────────────────────────────────────────

class _ErrorRetry extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorRetry({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.surfaceContainerHighest),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(LucideIcons.alertCircle, size: 24,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
        const SizedBox(height: 6),
        Text('Something went wrong',
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onRetry,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text('Tap to retry',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.primary)),
          ),
        ),
      ]),
    );
  }
}

// ─── Navigation Row ────────────────────────────────────────────────────────────

class _NavRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NavRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      label: '$title: $subtitle',
      button: true,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border.all(color: colorScheme.surfaceContainerHighest),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    Text(subtitle,
                        style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            Icon(LucideIcons.chevronRight, size: 16,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.25)),
          ],
        ),
      ),
      ),
    );
  }
}
