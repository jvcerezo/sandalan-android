import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../app.dart';
import '../../../core/services/premium_service.dart';
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
import '../../goals/providers/goal_providers.dart';
import '../providers/smart_suggestions_provider.dart';
import '../../tools/providers/tool_providers.dart';
import '../providers/upcoming_payments_provider.dart';
import '../widgets/streak_detail_sheet.dart';
import '../widgets/tip_of_day_card.dart';
import '../widgets/weekly_recap_card.dart';
import '../../../core/services/salary_allocation_service.dart';
import '../../../data/repositories/transaction_repository.dart';
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Invalidate providers to force refresh when returning from other screens
    ref.invalidate(transactionsSummaryProvider);
    ref.invalidate(recentTransactionsProvider);
    ref.invalidate(upcomingPaymentsProvider);
    ref.invalidate(billsSummaryProvider);
    ref.invalidate(debtSummaryProvider);
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
    ref.invalidate(recentTransactionsProvider);
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
                    child: _PulseWidget(
                      enabled: _streak >= 3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _flameColor(_streak).withOpacity(0.12),
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
                      colorScheme.primary.withOpacity(0.1),
                      colorScheme.primary.withOpacity(0.05),
                    ]),
                    border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
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
                        onPressed: () => context.go('/salary-allocation'),
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

          // ─── Financial Summary ───────────────────────────────────
          StaggeredFadeIn(
            index: 2,
            child: summary.when(
              data: (s) => s.income == 0 && s.expenses == 0 && s.balance == 0
                  // First-time user CTA
                  ? Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.06),
                        border: Border.all(color: colorScheme.primary.withOpacity(0.15)),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(children: [
                        Icon(LucideIcons.sparkles, size: 24, color: colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Ready to start tracking?',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text('Tap the + button below to add your first expense or income.',
                              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                        ])),
                      ]),
                    )
                  : Row(
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

          // ─── Smart Suggestions ────────────────────────────────────
          StaggeredFadeIn(
            index: 3,
            child: _SmartSuggestionsSection(ref: ref),
          ),

          // ─── Spending Insight ─────────────────────────────────────
          StaggeredFadeIn(
            index: 4,
            child: const HomeInsightCard(),
          ),

          // ─── Tier 2: Contextual Card (Recap or Tip) ───────────────
          StaggeredFadeIn(
            index: 3,
            child: _buildContextualCard(),
          ),

          // ─── Goal Progress ──────────────────────────────────────
          StaggeredFadeIn(
            index: 4,
            child: _GoalProgressSection(ref: ref, hideBalances: hideBalances),
          ),

          // ─── Recent Transactions ─────────────────────────────────
          StaggeredFadeIn(
            index: 5,
            child: _RecentTransactionsSection(ref: ref, hideBalances: hideBalances),
          ),

          // ─── Upcoming Payments ───────────────────────────────────
          StaggeredFadeIn(
            index: 6,
            child: _UpcomingPaymentsSection(ref: ref, hideBalances: hideBalances),
          ),

          // ─── Quick Links ──────────────────────────────────────────
          StaggeredFadeIn(
            index: 7,
            child: _QuickLinksSection(),
          ),

        ],
      ),
    );
  }
}


// ─── Pulse Animation (for streak badge) ──────────────────────────────────────

class _PulseWidget extends StatefulWidget {
  final Widget child;
  final bool enabled;
  const _PulseWidget({required this.child, this.enabled = true});

  @override
  State<_PulseWidget> createState() => _PulseWidgetState();
}

class _PulseWidgetState extends State<_PulseWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.enabled) _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = 1.0 + (_controller.value * 0.06);
        return Transform.scale(scale: scale, child: child);
      },
      child: widget.child,
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

// ─── Recent Transactions ──────────────────────────────────────────────────────

class _RecentTransactionsSection extends StatelessWidget {
  final WidgetRef ref;
  final bool hideBalances;
  const _RecentTransactionsSection({required this.ref, this.hideBalances = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final recent = ref.watch(recentTransactionsProvider);

    return recent.when(
      data: (txns) {
        if (txns.isEmpty) return const SizedBox.shrink();

        final visible = txns.take(5).toList();

        return Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('RECENT TRANSACTIONS',
                      style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600,
                        letterSpacing: 0.8, color: colorScheme.onSurfaceVariant,
                      )),
                  GestureDetector(
                    onTap: () => GoRouter.of(context).go('/transactions'),
                    child: Text('See all',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                            color: colorScheme.primary)),
                  ),
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
                  final t = entry.value;
                  final isLast = entry.key == visible.length - 1;
                  final isExpense = t.amount < 0;
                  final amountColor = isExpense
                      ? colorScheme.onSurface
                      : AppColors.income;
                  final sign = isExpense ? '-' : '+';
                  final displayAmt = hideBalances
                      ? '••••'
                      : '$sign${formatCurrency(t.amount.abs())}';

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(
                                color: (isExpense
                                    ? colorScheme.onSurfaceVariant
                                    : AppColors.income).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                isExpense ? LucideIcons.arrowUpRight : LucideIcons.arrowDownLeft,
                                size: 16,
                                color: isExpense ? colorScheme.onSurfaceVariant : AppColors.income,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(t.description.isNotEmpty ? t.description : t.category,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                      maxLines: 1, overflow: TextOverflow.ellipsis),
                                  Text(t.category,
                                      style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                                ],
                              ),
                            ),
                            Text(displayAmt,
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                                    color: amountColor)),
                          ],
                        ),
                      ),
                      if (!isLast)
                        Divider(height: 1, indent: 56, color: colorScheme.outline.withOpacity(0.08)),
                    ],
                  );
                }).toList(),
              ),
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
                    iconBg: config.color.withOpacity(0.1),
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
                    color: colorScheme.onSurfaceVariant.withOpacity(0.25)),
              ],
            ),
          ),
          if (showDivider)
            Divider(height: 1, indent: 56, color: colorScheme.outline.withOpacity(0.08)),
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
            color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
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

// ─── Smart Suggestions Section ───────────────────────────────────────────────────

class _SmartSuggestionsSection extends StatelessWidget {
  final WidgetRef ref;
  const _SmartSuggestionsSection({required this.ref});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final suggestions = ref.watch(smartSuggestionsProvider);

    return suggestions.when(
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            children: items.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: s.route != null ? () => GoRouter.of(context).go(s.route!) : null,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: s.color.withOpacity(0.06),
                    border: Border.all(color: s.color.withOpacity(0.15)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: s.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(s.icon, size: 16, color: s.color),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        Text(s.subtitle, style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                      ],
                    )),
                    if (s.route != null)
                      Icon(LucideIcons.chevronRight, size: 16, color: colorScheme.onSurfaceVariant.withOpacity(0.4)),
                  ]),
                ),
              ),
            )).toList(),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ─── Goal Progress Section ──────────────────────────────────────────────────────

class _GoalProgressSection extends StatelessWidget {
  final WidgetRef ref;
  final bool hideBalances;
  const _GoalProgressSection({required this.ref, this.hideBalances = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final goals = ref.watch(goalsProvider);

    return goals.when(
      data: (goalList) {
        final active = goalList.where((g) => !g.isCompleted).take(2).toList();
        if (active.isEmpty) return const SizedBox.shrink();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('GOAL PROGRESS',
                      style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600,
                        letterSpacing: 0.8, color: colorScheme.onSurfaceVariant,
                      )),
                  GestureDetector(
                    onTap: () => GoRouter.of(context).go('/goals'),
                    child: Text('See all',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                            color: colorScheme.primary)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ...active.map((goal) {
              final progress = goal.targetAmount > 0
                  ? (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0)
                  : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => GoRouter.of(context).go('/goals'),
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
                        Row(children: [
                          Icon(LucideIcons.target, size: 14, color: colorScheme.primary),
                          const SizedBox(width: 6),
                          Expanded(child: Text(goal.name,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              maxLines: 1, overflow: TextOverflow.ellipsis)),
                          Text(hideBalances
                              ? '••••'
                              : '${(progress * 100).toStringAsFixed(0)}%',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                                  color: colorScheme.primary)),
                        ]),
                        const SizedBox(height: 8),
                        AnimatedProgressBar(
                          value: progress,
                          minHeight: 6,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(height: 4),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text(hideBalances ? '••••' : formatCurrency(goal.currentAmount),
                              style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                          Text(hideBalances ? '••••' : formatCurrency(goal.targetAmount),
                              style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                        ]),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 10),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ─── Quick Links Section ────────────────────────────────────────────────────────

class _QuickLinksSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text('QUICK LINKS',
              style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600,
                letterSpacing: 0.8, color: colorScheme.onSurfaceVariant,
              )),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _QuickLink(
              icon: LucideIcons.bookOpen,
              label: 'Guide',
              color: const Color(0xFF10B981),
              onTap: () => GoRouter.of(context).go('/guide'),
            ),
            const SizedBox(width: 8),
            _QuickLink(
              icon: LucideIcons.messageCircle,
              label: 'AI Chat',
              color: const Color(0xFF8B5CF6),
              onTap: () {
                if (PremiumService.instance.hasAccess(PremiumFeature.aiChat)) {
                  GoRouter.of(context).go('/chat');
                } else {
                  showPremiumGateWithPaywall(context, PremiumFeature.aiChat);
                }
              },
            ),
            const SizedBox(width: 8),
            _QuickLink(
              icon: LucideIcons.pieChart,
              label: 'Reports',
              color: const Color(0xFF3B82F6),
              onTap: () {
                if (PremiumService.instance.hasAccess(PremiumFeature.advancedReports)) {
                  GoRouter.of(context).go('/reports');
                } else {
                  showPremiumGateWithPaywall(context, PremiumFeature.advancedReports);
                }
              },
            ),
            const SizedBox(width: 8),
            _QuickLink(
              icon: LucideIcons.settings,
              label: 'Settings',
              color: const Color(0xFF64748B),
              onTap: () => GoRouter.of(context).go('/settings'),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _QuickLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickLink({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500,
                  color: colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}
