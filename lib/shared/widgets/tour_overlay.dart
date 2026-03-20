/// Full-screen tour overlay that walks users through the app.
/// Adapted from the web app's tour-overlay.tsx / use-tour.ts.
///
/// Usage:
///   - Wrap inside a Stack on top of main content (in AppScaffold).
///   - Call TourController.of(context).start() to begin the tour.
///   - Auto-starts after onboarding via SharedPreferences flag.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Tour Step Data ─────────────────────────────────────────────────────────

enum TourPreview { home, guide, dashboard, transactions, tools, settings, fab, search }

class TourStep {
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final TourPreview? preview;

  const TourStep({
    required this.title,
    required this.description,
    required this.icon,
    this.iconColor = const Color(0xFF6366F1),
    this.preview,
  });
}

const _tourSteps = [
  TourStep(
    title: 'Welcome to Sandalan!',
    description:
        'Your companion for every stage of Filipino adult life. This quick tour walks you through everything you need to get started.',
    icon: LucideIcons.map,
    preview: TourPreview.home,
  ),
  TourStep(
    title: 'Your Adulting Journey',
    description:
        'The Journey Map is your roadmap through Filipino adulting \u2014 from getting your first IDs to retirement. Each stage has step-by-step guides and checklists you can mark as done or skip.',
    icon: LucideIcons.bookOpen,
    iconColor: Color(0xFF3B82F6),
    preview: TourPreview.guide,
  ),
  TourStep(
    title: 'Financial Dashboard',
    description:
        'See your net worth, financial health score, spending trends, and budget alerts \u2014 all in one place. This is your financial overview.',
    icon: LucideIcons.layoutDashboard,
    iconColor: Color(0xFF10B981),
    preview: TourPreview.dashboard,
  ),
  TourStep(
    title: 'Track Transactions',
    description:
        'Log every peso \u2014 income, expenses, and transfers between accounts. Your balances and insights update automatically.',
    icon: LucideIcons.arrowLeftRight,
    iconColor: Color(0xFFF59E0B),
    preview: TourPreview.transactions,
  ),
  TourStep(
    title: 'Adulting Tools',
    description:
        'Track SSS, PhilHealth, and Pag-IBIG contributions. Compute your BIR taxes. Manage debts, bills, and insurance \u2014 built for Filipino needs.',
    icon: LucideIcons.wrench,
    iconColor: Color(0xFFEF4444),
    preview: TourPreview.tools,
  ),
  TourStep(
    title: 'Settings & Preferences',
    description:
        'Customize your experience \u2014 change themes, manage your profile, set your currency, and configure notifications. Replay this tour anytime from here.',
    icon: LucideIcons.settings,
    iconColor: Color(0xFF8B5CF6),
    preview: TourPreview.settings,
  ),
  TourStep(
    title: 'Quick Add',
    description:
        'Tap the + button anytime to instantly log an expense or income. It\'s the fastest way to keep your records up to date.',
    icon: LucideIcons.plusCircle,
    iconColor: Color(0xFF6366F1),
    preview: TourPreview.fab,
  ),
  TourStep(
    title: 'Search Everything',
    description:
        'Find any transaction, account, guide, or tool instantly. Tap the search icon in the header to search across your entire app.',
    icon: LucideIcons.search,
    iconColor: Color(0xFF3B82F6),
    preview: TourPreview.search,
  ),
  TourStep(
    title: "You're all set!",
    description:
        'Start by exploring your Journey Map, then try Quick Add to log your first transaction. You can replay this tour anytime from Settings.',
    icon: LucideIcons.checkCircle2,
    iconColor: Color(0xFF10B981),
  ),
];

// ─── SharedPreferences Keys ─────────────────────────────────────────────────

const _kTourCompleted = 'sandalan_tour_completed';
const _kTourPending = 'sandalan_tour_pending';

/// Schedule the tour to auto-start on next app load (call after onboarding).
Future<void> scheduleTour() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kTourPending, true);
}

/// Check if tour should auto-start (pending flag set, not yet completed).
Future<bool> shouldAutoStartTour() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kTourPending) ?? false;
}

/// Mark tour as completed and clear the pending flag.
Future<void> _markTourCompleted() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kTourCompleted, true);
  await prefs.remove(_kTourPending);
}

/// Clear the pending flag without marking completed (skip).
Future<void> _clearTourPending() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_kTourPending);
}

// ─── Tour Controller (InheritedWidget) ──────────────────────────────────────

class TourController extends InheritedWidget {
  final VoidCallback start;

  const TourController({
    super.key,
    required this.start,
    required super.child,
  });

  static TourController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<TourController>();
  }

  static TourController of(BuildContext context) {
    final controller = maybeOf(context);
    assert(controller != null, 'No TourController found in context');
    return controller!;
  }

  @override
  bool updateShouldNotify(TourController oldWidget) => start != oldWidget.start;
}

// ─── Tour Host (wraps child + shows overlay) ────────────────────────────────

class TourHost extends StatefulWidget {
  final Widget child;

  const TourHost({super.key, required this.child});

  @override
  State<TourHost> createState() => _TourHostState();
}

class _TourHostState extends State<TourHost> {
  bool _active = false;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _checkAutoStart();
  }

  Future<void> _checkAutoStart() async {
    final shouldStart = await shouldAutoStartTour();
    if (shouldStart && mounted) {
      // Small delay to let the home screen render first.
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        setState(() {
          _active = true;
          _currentStep = 0;
        });
      }
    }
  }

  void _start() {
    setState(() {
      _active = true;
      _currentStep = 0;
    });
  }

  void _next() {
    if (_currentStep >= _tourSteps.length - 1) {
      // Last step -> finish
      setState(() => _active = false);
      _markTourCompleted();
      return;
    }
    setState(() => _currentStep++);
  }

  void _prev() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _skip() {
    setState(() => _active = false);
    _clearTourPending();
    _markTourCompleted();
  }

  @override
  Widget build(BuildContext context) {
    return TourController(
      start: _start,
      child: Stack(
        children: [
          widget.child,
          if (_active) _TourOverlayWidget(
            step: _tourSteps[_currentStep],
            currentStep: _currentStep,
            totalSteps: _tourSteps.length,
            onNext: _next,
            onPrev: _prev,
            onSkip: _skip,
          ),
        ],
      ),
    );
  }
}

// ─── Tour Overlay Widget ────────────────────────────────────────────────────

class _TourOverlayWidget extends StatefulWidget {
  final TourStep step;
  final int currentStep;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback onPrev;
  final VoidCallback onSkip;

  const _TourOverlayWidget({
    required this.step,
    required this.currentStep,
    required this.totalSteps,
    required this.onNext,
    required this.onPrev,
    required this.onSkip,
  });

  @override
  State<_TourOverlayWidget> createState() => _TourOverlayWidgetState();
}

class _TourOverlayWidgetState extends State<_TourOverlayWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideIn = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant _TourOverlayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentStep != widget.currentStep) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final step = widget.step;
    final isLast = widget.currentStep == widget.totalSteps - 1;
    final isFirst = widget.currentStep == 0;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Dark backdrop
          GestureDetector(
            onTap: () {}, // absorb taps
            child: Container(color: Colors.black.withValues(alpha: 0.6)),
          ),

          // Centered card
          Center(
            child: FadeTransition(
              opacity: _fadeIn,
              child: SlideTransition(
                position: _slideIn,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  constraints: const BoxConstraints(maxWidth: 400),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ─── Illustration area ────────────────────────
                      _StepIllustration(
                        step: step,
                        colorScheme: colorScheme,
                      ),

                      // ─── Content area ─────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Title
                            Text(
                              step.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.3,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),

                            // Description
                            Text(
                              step.description,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),

                            // Step dots
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(widget.totalSteps, (i) {
                                final isCurrent = i == widget.currentStep;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  width: isCurrent ? 20 : 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: isCurrent
                                        ? colorScheme.primary
                                        : colorScheme.onSurfaceVariant
                                            .withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 20),

                            // Navigation row
                            Row(
                              children: [
                                // Skip
                                GestureDetector(
                                  onTap: widget.onSkip,
                                  child: Text(
                                    'Skip tour',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                const Spacer(),

                                // Back button
                                if (!isFirst)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: SizedBox(
                                      height: 40,
                                      width: 40,
                                      child: OutlinedButton(
                                        onPressed: widget.onPrev,
                                        style: OutlinedButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          side: BorderSide(
                                            color: colorScheme.outline
                                                .withValues(alpha: 0.2),
                                          ),
                                        ),
                                        child: Icon(
                                          LucideIcons.arrowLeft,
                                          size: 16,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                  ),

                                // Next / Done button
                                SizedBox(
                                  height: 40,
                                  child: FilledButton(
                                    onPressed: widget.onNext,
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(isLast ? 'Done' : 'Next'),
                                        if (!isLast) ...[
                                          const SizedBox(width: 6),
                                          const Icon(LucideIcons.arrowRight,
                                              size: 14),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // Step counter
                            const SizedBox(height: 12),
                            Text(
                              '${widget.currentStep + 1} / ${widget.totalSteps}',
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Step Illustration ──────────────────────────────────────────────────────

class _StepIllustration extends StatelessWidget {
  final TourStep step;
  final ColorScheme colorScheme;

  const _StepIllustration({required this.step, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: step.preview != null
          ? _buildPreview(step.preview!)
          : _buildIconFallback(),
    );
  }

  Widget _buildIconFallback() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: step.iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(step.icon, size: 32, color: step.iconColor),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(TourPreview preview) {
    switch (preview) {
      case TourPreview.home:
        return _MiniHomePreview(colorScheme: colorScheme);
      case TourPreview.guide:
        return _MiniGuidePreview(colorScheme: colorScheme);
      case TourPreview.dashboard:
        return _MiniDashboardPreview(colorScheme: colorScheme);
      case TourPreview.transactions:
        return _MiniTransactionsPreview(colorScheme: colorScheme);
      case TourPreview.tools:
        return _MiniToolsPreview(colorScheme: colorScheme);
      case TourPreview.settings:
        return _MiniSettingsPreview(colorScheme: colorScheme);
      case TourPreview.fab:
        return _MiniFabPreview(colorScheme: colorScheme);
      case TourPreview.search:
        return _MiniSearchPreview(colorScheme: colorScheme);
    }
  }
}

// ─── Mini Preview: Home ─────────────────────────────────────────────────────

class _MiniHomePreview extends StatelessWidget {
  final ColorScheme colorScheme;
  const _MiniHomePreview({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return _PreviewFrame(
      colorScheme: colorScheme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting
          Text('Good morning, Juan',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface)),
          const SizedBox(height: 1),
          Text("Here's your snapshot for today.",
              style: TextStyle(fontSize: 8, color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),

          // Stage card
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(LucideIcons.graduationCap,
                      size: 12, color: Colors.white),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Unang Hakbang',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600,
                              color: Colors.white)),
                      Text('First Steps',
                          style: TextStyle(fontSize: 7, color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Financial summary row
          Row(
            children: [
              Expanded(child: _MiniStatCard(
                icon: LucideIcons.wallet, label: 'Balance',
                value: 'P25,000', colorScheme: colorScheme,
              )),
              const SizedBox(width: 6),
              Expanded(child: _MiniStatCard(
                icon: LucideIcons.trendingUp, label: 'Income',
                value: 'P18,500', colorScheme: colorScheme,
                valueColor: const Color(0xFF22C55E),
              )),
              const SizedBox(width: 6),
              Expanded(child: _MiniStatCard(
                icon: LucideIcons.trendingDown, label: 'Expenses',
                value: 'P12,300', colorScheme: colorScheme,
                valueColor: const Color(0xFFEF4444),
              )),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Mini Preview: Guide (Journey Map) ──────────────────────────────────────

class _MiniGuidePreview extends StatelessWidget {
  final ColorScheme colorScheme;
  const _MiniGuidePreview({required this.colorScheme});

  static const _stages = [
    (icon: LucideIcons.graduationCap, label: 'Unang Hakbang', color: Color(0xFF3B82F6)),
    (icon: LucideIcons.toyBrick, label: 'Pundasyon', color: Color(0xFF10B981)),
    (icon: LucideIcons.home, label: 'Tahanan', color: Color(0xFF8B5CF6)),
    (icon: LucideIcons.mountain, label: 'Tugatog', color: Color(0xFFF59E0B)),
    (icon: LucideIcons.clock, label: 'Paghahanda', color: Color(0xFFF43F5E)),
    (icon: LucideIcons.gem, label: 'Gintong Taon', color: Color(0xFFEAB308)),
  ];

  @override
  Widget build(BuildContext context) {
    return _PreviewFrame(
      colorScheme: colorScheme,
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Text('Your Adulting Journey',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('0% complete',
                    style: TextStyle(fontSize: 7, color: Color(0xFF3B82F6))),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Stage nodes with connecting line
          SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(_stages.length, (i) {
                final s = _stages[i];
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: s.color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: i == 0
                            ? Border.all(color: s.color, width: 1.5)
                            : null,
                      ),
                      child: Icon(s.icon, size: 12, color: s.color),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 44,
                      child: Text(s.label,
                          style: TextStyle(fontSize: 6,
                              color: colorScheme.onSurfaceVariant),
                          textAlign: TextAlign.center,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                );
              }),
            ),
          ),

          // Connecting dots
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: List.generate(23, (i) => Expanded(
                child: Container(
                  height: 1,
                  color: i % 2 == 0
                      ? colorScheme.outline.withValues(alpha: 0.15)
                      : Colors.transparent,
                ),
              )),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Mini Preview: Dashboard ────────────────────────────────────────────────

class _MiniDashboardPreview extends StatelessWidget {
  final ColorScheme colorScheme;
  const _MiniDashboardPreview({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return _PreviewFrame(
      colorScheme: colorScheme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overview cards
          Row(
            children: [
              Expanded(child: _MiniStatCard(
                icon: LucideIcons.landmark, label: 'Total Balance',
                value: 'P25,000', colorScheme: colorScheme,
              )),
              const SizedBox(width: 6),
              Expanded(child: _MiniStatCard(
                icon: LucideIcons.trendingUp, label: 'Net Worth',
                value: 'P42,800', colorScheme: colorScheme,
                valueColor: const Color(0xFF22C55E),
              )),
            ],
          ),
          const SizedBox(height: 8),

          // Mini bar chart
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SPENDING TRENDS',
                    style: TextStyle(fontSize: 7, fontWeight: FontWeight.w600,
                        letterSpacing: 0.5, color: colorScheme.onSurfaceVariant)),
                const SizedBox(height: 6),
                SizedBox(
                  height: 40,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _MiniBar(height: 20, color: const Color(0xFF22C55E), colorScheme: colorScheme),
                      _MiniBar(height: 30, color: const Color(0xFFEF4444), colorScheme: colorScheme),
                      _MiniBar(height: 15, color: const Color(0xFF22C55E), colorScheme: colorScheme),
                      _MiniBar(height: 35, color: const Color(0xFFEF4444), colorScheme: colorScheme),
                      _MiniBar(height: 25, color: const Color(0xFF22C55E), colorScheme: colorScheme),
                      _MiniBar(height: 40, color: const Color(0xFFEF4444), colorScheme: colorScheme),
                      _MiniBar(height: 18, color: const Color(0xFF22C55E), colorScheme: colorScheme),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                      .map((d) => Expanded(
                        child: Text(d, textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 5,
                                color: colorScheme.onSurfaceVariant)),
                      ))
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Mini Preview: Transactions ─────────────────────────────────────────────

class _MiniTransactionsPreview extends StatelessWidget {
  final ColorScheme colorScheme;
  const _MiniTransactionsPreview({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return _PreviewFrame(
      colorScheme: colorScheme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tab bar
          Row(
            children: [
              _MiniChip(label: 'All', active: true, colorScheme: colorScheme),
              const SizedBox(width: 4),
              _MiniChip(label: 'Income', active: false, colorScheme: colorScheme),
              const SizedBox(width: 4),
              _MiniChip(label: 'Expenses', active: false, colorScheme: colorScheme),
            ],
          ),
          const SizedBox(height: 8),

          // Transaction rows
          _MiniTransactionRow(
            icon: LucideIcons.briefcase, iconColor: const Color(0xFF22C55E),
            title: 'Salary', subtitle: 'Income',
            amount: '+P18,500', amountColor: const Color(0xFF22C55E),
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 4),
          _MiniTransactionRow(
            icon: LucideIcons.shoppingCart, iconColor: const Color(0xFFEF4444),
            title: 'Grocery', subtitle: 'Food & Drink',
            amount: '-P2,350', amountColor: const Color(0xFFEF4444),
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 4),
          _MiniTransactionRow(
            icon: LucideIcons.zap, iconColor: const Color(0xFFEF4444),
            title: 'Electric Bill', subtitle: 'Utilities',
            amount: '-P3,200', amountColor: const Color(0xFFEF4444),
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 4),
          _MiniTransactionRow(
            icon: LucideIcons.arrowLeftRight, iconColor: const Color(0xFF6366F1),
            title: 'Savings Transfer', subtitle: 'Transfer',
            amount: 'P5,000', amountColor: const Color(0xFF6366F1),
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }
}

// ─── Mini Preview: Tools ────────────────────────────────────────────────────

class _MiniToolsPreview extends StatelessWidget {
  final ColorScheme colorScheme;
  const _MiniToolsPreview({required this.colorScheme});

  static const _tools = [
    (icon: LucideIcons.landmark, color: Color(0xFF3B82F6), label: "Gov't"),
    (icon: LucideIcons.receipt, color: Color(0xFFF97316), label: 'BIR Tax'),
    (icon: LucideIcons.creditCard, color: Color(0xFFEF4444), label: 'Debts'),
    (icon: LucideIcons.receipt, color: Color(0xFF6366F1), label: 'Bills'),
    (icon: LucideIcons.shield, color: Color(0xFF14B8A6), label: 'Insurance'),
    (icon: LucideIcons.piggyBank, color: Color(0xFFF59E0B), label: 'Retire'),
    (icon: LucideIcons.gift, color: Color(0xFF22C55E), label: '13th Mo.'),
    (icon: LucideIcons.home, color: Color(0xFFEC4899), label: 'Rent/Buy'),
  ];

  @override
  Widget build(BuildContext context) {
    return _PreviewFrame(
      colorScheme: colorScheme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tools',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface)),
          const SizedBox(height: 6),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 0.85,
            children: _tools.map((t) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: t.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(t.icon, size: 13, color: t.color),
                ),
                const SizedBox(height: 3),
                Text(t.label,
                    style: TextStyle(fontSize: 6, color: colorScheme.onSurfaceVariant),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            )).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Mini Preview: Settings ─────────────────────────────────────────────────

class _MiniSettingsPreview extends StatelessWidget {
  final ColorScheme colorScheme;
  const _MiniSettingsPreview({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return _PreviewFrame(
      colorScheme: colorScheme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Settings',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface)),
          const SizedBox(height: 6),
          _MiniSettingsRow(icon: LucideIcons.user, label: 'Profile',
              colorScheme: colorScheme),
          _MiniSettingsRow(icon: LucideIcons.palette, label: 'Appearance',
              trailing: 'System', colorScheme: colorScheme),
          _MiniSettingsRow(icon: LucideIcons.coins, label: 'Currency',
              trailing: 'PHP', colorScheme: colorScheme),
          _MiniSettingsRow(icon: LucideIcons.bell, label: 'Notifications',
              colorScheme: colorScheme),
          _MiniSettingsRow(icon: LucideIcons.map, label: 'Replay Tour',
              colorScheme: colorScheme),
          _MiniSettingsRow(icon: LucideIcons.logOut, label: 'Sign Out',
              iconColor: const Color(0xFFEF4444), colorScheme: colorScheme),
        ],
      ),
    );
  }
}

// ─── Mini Preview: FAB ──────────────────────────────────────────────────────

class _MiniFabPreview extends StatelessWidget {
  final ColorScheme colorScheme;
  const _MiniFabPreview({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Mock bottom nav
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  top: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Icon(LucideIcons.home, size: 14,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                  Icon(LucideIcons.bookOpen, size: 14,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                  const SizedBox(width: 28), // space for FAB
                  Icon(LucideIcons.layoutDashboard, size: 14,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                  Icon(LucideIcons.arrowLeftRight, size: 14,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                ],
              ),
            ),
          ),

          // Expanded action buttons
          Positioned(
            bottom: 44,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MiniFabAction(
                  icon: LucideIcons.trendingDown,
                  label: 'Expense',
                  color: const Color(0xFFEF4444),
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 4),
                _MiniFabAction(
                  icon: LucideIcons.trendingUp,
                  label: 'Income',
                  color: const Color(0xFF22C55E),
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 4),
                _MiniFabAction(
                  icon: LucideIcons.arrowLeftRight,
                  label: 'Transfer',
                  color: const Color(0xFF6366F1),
                  colorScheme: colorScheme,
                ),
              ],
            ),
          ),

          // Main FAB
          Positioned(
            bottom: 20,
            child: Transform.rotate(
              angle: math.pi / 4,
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 8, offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Transform.rotate(
                  angle: -math.pi / 4,
                  child: const Icon(LucideIcons.x, size: 16, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Mini Preview: Search ───────────────────────────────────────────────────

class _MiniSearchPreview extends StatelessWidget {
  final ColorScheme colorScheme;
  const _MiniSearchPreview({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return _PreviewFrame(
      colorScheme: colorScheme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.search, size: 12,
                    color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text('Search everything...',
                    style: TextStyle(fontSize: 8,
                        color: colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Sample results
          _MiniSearchResult(
            icon: LucideIcons.arrowLeftRight,
            iconColor: const Color(0xFFF59E0B),
            title: 'Salary - March 2026',
            subtitle: 'Transaction',
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 4),
          _MiniSearchResult(
            icon: LucideIcons.bookOpen,
            iconColor: const Color(0xFF3B82F6),
            title: 'How to Get a TIN',
            subtitle: 'Guide',
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 4),
          _MiniSearchResult(
            icon: LucideIcons.landmark,
            iconColor: const Color(0xFF3B82F6),
            title: "Gov't Contributions",
            subtitle: 'Tool',
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }
}

// ─── Shared Mini Components ─────────────────────────────────────────────────

/// Wrapper that looks like a mini phone screen.
class _PreviewFrame extends StatelessWidget {
  final ColorScheme colorScheme;
  final Widget child;
  const _PreviewFrame({required this.colorScheme, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.12)),
      ),
      child: child,
    );
  }
}

/// Small stat card (used in Home + Dashboard previews).
class _MiniStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme colorScheme;
  final Color? valueColor;

  const _MiniStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.colorScheme,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 8, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 3),
              Text(label, style: TextStyle(fontSize: 6,
                  color: colorScheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 3),
          Text(value, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold,
              color: valueColor ?? colorScheme.onSurface)),
        ],
      ),
    );
  }
}

/// Mini chart bar.
class _MiniBar extends StatelessWidget {
  final double height;
  final Color color;
  final ColorScheme colorScheme;
  const _MiniBar({required this.height, required this.color, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

/// Mini filter chip.
class _MiniChip extends StatelessWidget {
  final String label;
  final bool active;
  final ColorScheme colorScheme;
  const _MiniChip({required this.label, required this.active, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: active ? colorScheme.primary : Colors.transparent,
        border: Border.all(
          color: active
              ? colorScheme.primary
              : colorScheme.outline.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 7, fontWeight: FontWeight.w500,
              color: active ? colorScheme.onPrimary : colorScheme.onSurfaceVariant)),
    );
  }
}

/// Mini transaction row.
class _MiniTransactionRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String amount;
  final Color amountColor;
  final ColorScheme colorScheme;

  const _MiniTransactionRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.amountColor,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Container(
            width: 20, height: 20,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Icon(icon, size: 10, color: iconColor),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 8,
                    fontWeight: FontWeight.w500, color: colorScheme.onSurface)),
                Text(subtitle, style: TextStyle(fontSize: 6,
                    color: colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          Text(amount, style: TextStyle(fontSize: 8,
              fontWeight: FontWeight.w600, color: amountColor)),
        ],
      ),
    );
  }
}

/// Mini settings row.
class _MiniSettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final Color? iconColor;
  final ColorScheme colorScheme;

  const _MiniSettingsRow({
    required this.icon,
    required this.label,
    this.trailing,
    this.iconColor,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 11, color: iconColor ?? colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 8, color: colorScheme.onSurface)),
          const Spacer(),
          if (trailing != null)
            Text(trailing!, style: TextStyle(fontSize: 7,
                color: colorScheme.onSurfaceVariant)),
          Icon(LucideIcons.chevronRight, size: 8,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
        ],
      ),
    );
  }
}

/// Mini FAB action button.
class _MiniFabAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final ColorScheme colorScheme;

  const _MiniFabAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 4,
              ),
            ],
          ),
          child: Text(label,
              style: TextStyle(fontSize: 8, fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface)),
        ),
        const SizedBox(width: 6),
        Container(
          width: 24, height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 4,
              ),
            ],
          ),
          child: Icon(icon, size: 12, color: Colors.white),
        ),
      ],
    );
  }
}

/// Mini search result row.
class _MiniSearchResult extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final ColorScheme colorScheme;

  const _MiniSearchResult({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 20, height: 20,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Icon(icon, size: 10, color: iconColor),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 8,
                fontWeight: FontWeight.w500, color: colorScheme.onSurface)),
            Text(subtitle, style: TextStyle(fontSize: 6,
                color: colorScheme.onSurfaceVariant)),
          ],
        ),
      ],
    );
  }
}
