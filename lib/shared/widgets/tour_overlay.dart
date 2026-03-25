/// Full-screen tour overlay that walks users through the app.
///
/// Usage:
///   - Wrap inside a Stack on top of main content (in AppScaffold).
///   - Call TourController.of(context).start() to begin the tour.
///   - Auto-starts after onboarding via SharedPreferences flag.

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Tour Step Data ─────────────────────────────────────────────────────────

enum TourTarget {
  none,
  bottomNavGuide,   // Guide tab (2nd from left)
  bottomNavCenter,  // + button (center)
  bottomNavMoney,   // Money tab (4th from left)
}

enum TourPreview { logo, journeyMap, dashboard, quickActions, smartFeatures, none }

class TourStep {
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final TourTarget target;
  final TourPreview preview;
  final String? buttonLabel;

  const TourStep({
    required this.title,
    required this.description,
    required this.icon,
    this.iconColor = const Color(0xFF6366F1),
    this.target = TourTarget.none,
    this.preview = TourPreview.none,
    this.buttonLabel,
  });
}

const _tourSteps = [
  // Step 1: Welcome
  TourStep(
    title: 'Welcome to Sandalan!',
    description:
        'Your Filipino adulting companion. Let\u2019s take a quick tour.',
    icon: LucideIcons.map,
    preview: TourPreview.logo,
  ),
  // Step 2: Guide tab
  TourStep(
    title: 'Your Adulting Journey',
    description:
        'Step-by-step guides for every life stage \u2014 from getting your first ID to retirement planning. Tap the Guide tab anytime.',
    icon: LucideIcons.bookOpen,
    iconColor: Color(0xFF10B981),
    target: TourTarget.bottomNavGuide,
    preview: TourPreview.journeyMap,
  ),
  // Step 3: Money tab
  TourStep(
    title: 'Track Your Money',
    description:
        'Tap Money to see your dashboard, transactions, accounts, and budgets \u2014 all in one place.',
    icon: LucideIcons.wallet,
    iconColor: Color(0xFF3B82F6),
    target: TourTarget.bottomNavMoney,
    preview: TourPreview.dashboard,
  ),
  // Step 4: + button
  TourStep(
    title: 'Add Transactions Fast',
    description:
        'Tap + to log expenses, income, or scan a receipt. Your most common action, always one tap away.',
    icon: LucideIcons.zap,
    iconColor: Color(0xFFF59E0B),
    target: TourTarget.bottomNavCenter,
    preview: TourPreview.quickActions,
  ),
  // Step 5: Smart Features
  TourStep(
    title: 'AI + Receipt Scanner',
    description:
        'Ask your personal AI about finances in Taglish, or scan receipts to auto-log expenses. Parang magic!',
    icon: LucideIcons.sparkles,
    iconColor: Color(0xFF8B5CF6),
    preview: TourPreview.smartFeatures,
  ),
  // Step 6: All Set
  TourStep(
    title: 'Tara, simulan na natin!',
    description:
        'Explore the Guide tab, or tap + to add your first expense. Salamat sa pagtitiwala! \uD83E\uDEF6',
    icon: LucideIcons.checkCircle2,
    iconColor: Color(0xFF10B981),
    buttonLabel: "Let's Go!",
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

class _TourOverlayWidgetState extends State<_TourOverlayWidget> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final step = widget.step;
    final isLast = widget.currentStep == widget.totalSteps - 1;
    final isFirst = widget.currentStep == 0;
    final size = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Dark backdrop with animated spotlight
          GestureDetector(
            onTap: () {},
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: CustomPaint(
                key: ValueKey(step.target),
                size: size,
                painter: _SpotlightPainter(
                  target: step.target,
                  screenSize: size,
                  bottomPadding: bottomPadding,
                ),
              ),
            ),
          ),

          // Card with crossfade
          _buildPositionedCard(context, colorScheme, step, isFirst, isLast, size, bottomPadding),
        ],
      ),
    );
  }

  Widget _buildPositionedCard(BuildContext context, ColorScheme colorScheme,
      TourStep step, bool isFirst, bool isLast, Size size, double bottomPadding) {
    // For bottom nav targets, position card above the bottom bar
    if (step.target != TourTarget.none) {
      return Positioned(
        left: 24,
        right: 24,
        bottom: 100 + bottomPadding,
        child: _buildCard(colorScheme, step, isFirst, isLast),
      );
    }

    // Default: centered
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: _buildCard(colorScheme, step, isFirst, isLast),
      ),
    );
  }

  Widget _buildCard(ColorScheme colorScheme, TourStep step,
      bool isFirst, bool isLast) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: Container(
        key: ValueKey(widget.currentStep),
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
              // Illustration
              _StepIllustration(step: step, colorScheme: colorScheme),

              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      step.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      step.description,
                      style: TextStyle(
                        fontSize: 13,
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
                                : colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),

                    // Navigation
                    Row(
                      children: [
                        GestureDetector(
                          onTap: widget.onSkip,
                          child: Text(
                            'Skip tour',
                            style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                          ),
                        ),
                        const Spacer(),
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
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
                                ),
                                child: Icon(LucideIcons.arrowLeft, size: 16, color: colorScheme.onSurface),
                              ),
                            ),
                          ),
                        SizedBox(
                          height: 40,
                          child: FilledButton(
                            onPressed: widget.onNext,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(step.buttonLabel ?? (isLast ? 'Done' : 'Next')),
                                if (!isLast && step.buttonLabel == null) ...[
                                  const SizedBox(width: 6),
                                  const Icon(LucideIcons.arrowRight, size: 14),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    Text(
                      '${widget.currentStep + 1} / ${widget.totalSteps}',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Spotlight Painter ──────────────────────────────────────────────────────

class _SpotlightPainter extends CustomPainter {
  final TourTarget target;
  final Size screenSize;
  final double bottomPadding;

  _SpotlightPainter({
    required this.target,
    required this.screenSize,
    required this.bottomPadding,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.6);

    if (target == TourTarget.none) {
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
      return;
    }

    final path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Bottom nav is 64px high + safe area. Tab items are evenly spaced in 5 columns.
    final navTop = size.height - 64 - bottomPadding;
    final tabWidth = size.width / 5;

    Offset center;
    switch (target) {
      case TourTarget.bottomNavGuide:
        // 2nd tab (index 1)
        center = Offset(tabWidth * 1.5, navTop + 32);
      case TourTarget.bottomNavCenter:
        // Center + button (index 2)
        center = Offset(tabWidth * 2.5, navTop + 32);
      case TourTarget.bottomNavMoney:
        // 4th tab (index 3)
        center = Offset(tabWidth * 3.5, navTop + 32);
      case TourTarget.none:
        return;
    }

    if (target == TourTarget.bottomNavCenter) {
      // Larger spotlight for the + button
      path.addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: 60, height: 60),
        const Radius.circular(18),
      ));
    } else {
      // Pill spotlight for tab items
      path.addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: 64, height: 52),
        const Radius.circular(16),
      ));
    }

    path.fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) =>
      target != oldDelegate.target;
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
      child: _buildPreview(step.preview),
    );
  }

  Widget _buildPreview(TourPreview preview) {
    switch (preview) {
      case TourPreview.logo:
        return _MiniLogoPreview(colorScheme: colorScheme);
      case TourPreview.journeyMap:
        return _MiniJourneyMapPreview(colorScheme: colorScheme);
      case TourPreview.dashboard:
        return _MiniDashboardPreview(colorScheme: colorScheme);
      case TourPreview.quickActions:
        return _MiniQuickActionsPreview(colorScheme: colorScheme);
      case TourPreview.smartFeatures:
        return _MiniSmartFeaturesPreview(colorScheme: colorScheme);
      case TourPreview.none:
        return _buildIconFallback();
    }
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
}

// ─── Mini Preview: Logo (Welcome) ───────────────────────────────────────────

class _MiniLogoPreview extends StatelessWidget {
  final ColorScheme colorScheme;
  const _MiniLogoPreview({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return _PreviewFrame(
      colorScheme: colorScheme,
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6366F1), Color(0xFF3B82F6)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(LucideIcons.footprints, size: 36, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text('Sandalan',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold,
                  letterSpacing: -0.3, color: colorScheme.onSurface)),
          const SizedBox(height: 2),
          Text('Your adulting companion',
              style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─── Mini Preview: Quick Actions (Expense / Income / Scan) ──────────────────

class _MiniQuickActionsPreview extends StatelessWidget {
  final ColorScheme colorScheme;
  const _MiniQuickActionsPreview({required this.colorScheme});

  static const _actions = [
    (icon: LucideIcons.arrowUpRight, label: 'Expense', color: Color(0xFF64748B)),
    (icon: LucideIcons.arrowDownLeft, label: 'Income', color: Color(0xFF22C55E)),
    (icon: LucideIcons.scanLine, label: 'Scan', color: Color(0xFF6366F1)),
  ];

  @override
  Widget build(BuildContext context) {
    return _PreviewFrame(
      colorScheme: colorScheme,
      child: Column(
        children: [
          Text('Quick Actions',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _actions.map((a) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: a.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(a.icon, size: 20, color: a.color),
                ),
                const SizedBox(height: 6),
                Text(a.label,
                    style: TextStyle(fontSize: 8, color: colorScheme.onSurfaceVariant)),
              ],
            )).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Mini Preview: Journey Map ──────────────────────────────────────────────

class _MiniJourneyMapPreview extends StatelessWidget {
  final ColorScheme colorScheme;
  const _MiniJourneyMapPreview({required this.colorScheme});

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
                child: const Text('6 stages',
                    style: TextStyle(fontSize: 7, color: Color(0xFF3B82F6))),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
                        border: i == 0 ? Border.all(color: s.color, width: 1.5) : null,
                      ),
                      child: Icon(s.icon, size: 12, color: s.color),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 44,
                      child: Text(s.label,
                          style: TextStyle(fontSize: 6, color: colorScheme.onSurfaceVariant),
                          textAlign: TextAlign.center,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                );
              }),
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
          // Tabs preview
          Row(
            children: ['Overview', 'Transactions', 'Accounts', 'Budgets'].map((t) =>
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: t == 'Overview'
                        ? colorScheme.surface
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: t == 'Overview' ? [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4),
                    ] : null,
                  ),
                  child: Text(t,
                      style: TextStyle(fontSize: 7,
                          fontWeight: t == 'Overview' ? FontWeight.w600 : FontWeight.normal,
                          color: t == 'Overview' ? colorScheme.onSurface : colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center),
                ),
              ),
            ).toList(),
          ),
          const SizedBox(height: 8),

          // Net worth card
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF6366F1)]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(LucideIcons.landmark, size: 14, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Net Worth', style: TextStyle(fontSize: 7, color: Colors.white70)),
                      Text('P42,800', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Mini chart
          SizedBox(
            height: 24,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _MiniBar(height: 12, color: const Color(0xFF22C55E), colorScheme: colorScheme),
                _MiniBar(height: 20, color: const Color(0xFFEF4444), colorScheme: colorScheme),
                _MiniBar(height: 8, color: const Color(0xFF22C55E), colorScheme: colorScheme),
                _MiniBar(height: 24, color: const Color(0xFFEF4444), colorScheme: colorScheme),
                _MiniBar(height: 16, color: const Color(0xFF22C55E), colorScheme: colorScheme),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Mini Preview: Smart Features ───────────────────────────────────────────

class _MiniSmartFeaturesPreview extends StatelessWidget {
  final ColorScheme colorScheme;
  const _MiniSmartFeaturesPreview({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return _PreviewFrame(
      colorScheme: colorScheme,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.messageCircle, size: 12, color: const Color(0xFF8B5CF6)),
                    const SizedBox(width: 4),
                    Text('AI Chat',
                        style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface)),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('"Magkano ginastos ko this week?"',
                      style: TextStyle(fontSize: 7, color: colorScheme.onSurface)),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('P3,450 ang total mo this week.',
                      style: TextStyle(fontSize: 7, color: colorScheme.onSurface)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.scanLine, size: 24, color: Color(0xFF6366F1)),
              ),
              const SizedBox(height: 4),
              Text('Scan',
                  style: TextStyle(fontSize: 7, color: colorScheme.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Shared Mini Components ─────────────────────────────────────────────────

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
