/// Full-screen tour overlay that walks users through the app.
/// Adapted from the web app's tour-overlay.tsx / use-tour.ts.
///
/// Usage:
///   - Wrap inside a Stack on top of main content (in AppScaffold).
///   - Call TourController.of(context).start() to begin the tour.
///   - Auto-starts after onboarding via SharedPreferences flag.

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Tour Step Data ─────────────────────────────────────────────────────────

enum TourTarget { none, bottomCenter, topRight }

enum TourPreview { logo, menuGrid, quickActions, journeyMap, dashboard, smartFeatures, streak, none }

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
        'Your Filipino adulting companion. Let\u2019s take a quick 30-second tour.',
    icon: LucideIcons.map,
    preview: TourPreview.logo,
  ),
  // Step 2: Menu FAB
  TourStep(
    title: 'This is your Menu',
    description:
        'Tap it anytime to navigate anywhere \u2014 finances, guides, tools, settings. Everything in one place.',
    icon: LucideIcons.layoutGrid,
    iconColor: Color(0xFF3B82F6),
    target: TourTarget.bottomCenter,
    preview: TourPreview.menuGrid,
  ),
  // Step 3: Quick Actions
  TourStep(
    title: 'Quick Actions',
    description:
        'Add expenses, income, or scan receipts right from the Menu. Your most common actions, one tap away.',
    icon: LucideIcons.zap,
    iconColor: Color(0xFFF59E0B),
    target: TourTarget.bottomCenter,
    preview: TourPreview.quickActions,
  ),
  // Step 4: Adulting Guide
  TourStep(
    title: 'Your Adulting Journey',
    description:
        'Step-by-step guides for every life stage \u2014 from getting your first ID to retirement planning. All in Filipino context.',
    icon: LucideIcons.bookOpen,
    iconColor: Color(0xFF10B981),
    preview: TourPreview.journeyMap,
  ),
  // Step 5: Financial Dashboard
  TourStep(
    title: 'Track Your Money',
    description:
        'See your net worth, spending patterns, budgets, and goals all in one dashboard.',
    icon: LucideIcons.layoutDashboard,
    iconColor: Color(0xFF3B82F6),
    preview: TourPreview.dashboard,
  ),
  // Step 6: Smart Features
  TourStep(
    title: 'AI Assistant + Receipt Scanner',
    description:
        'Ask your personal AI about finances in Taglish, or scan receipts to auto-log expenses. Parang magic!',
    icon: LucideIcons.sparkles,
    iconColor: Color(0xFF8B5CF6),
    preview: TourPreview.smartFeatures,
  ),
  // Step 7: Streak & Achievements
  TourStep(
    title: 'Stay Consistent',
    description:
        'Build a daily streak, earn Pahinga Days for rest, and unlock 75+ achievements. Tuloy-tuloy lang!',
    icon: LucideIcons.flame,
    iconColor: Color(0xFFF97316),
    target: TourTarget.topRight,
    preview: TourPreview.streak,
  ),
  // Step 8: All Set
  TourStep(
    title: 'Tara, simulan na natin!',
    description:
        'Tap the Menu to explore, or start by adding your first expense. Salamat sa pagtitiwala! \uD83E\uDEF6',
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
    final size = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Dark backdrop with optional spotlight cutout
          GestureDetector(
            onTap: () {}, // absorb taps
            child: CustomPaint(
              size: size,
              painter: _SpotlightPainter(
                target: step.target,
                screenSize: size,
                bottomPadding: bottomPadding,
              ),
            ),
          ),

          // Card positioned based on target
          _buildPositionedCard(context, colorScheme, step, isFirst, isLast, size, bottomPadding),
        ],
      ),
    );
  }

  Widget _buildPositionedCard(BuildContext context, ColorScheme colorScheme,
      TourStep step, bool isFirst, bool isLast, Size size, double bottomPadding) {
    // For bottom-center targets, position card above the spotlight
    if (step.target == TourTarget.bottomCenter) {
      return Positioned(
        left: 24,
        right: 24,
        bottom: 100 + bottomPadding,
        child: _buildAnimatedCard(colorScheme, step, isFirst, isLast),
      );
    }

    // For top-right targets, position card below the spotlight
    if (step.target == TourTarget.topRight) {
      return Positioned(
        left: 24,
        right: 24,
        top: 100,
        child: _buildAnimatedCard(colorScheme, step, isFirst, isLast),
      );
    }

    // Default: centered
    return Center(
      child: _buildAnimatedCard(colorScheme, step, isFirst, isLast),
    );
  }

  Widget _buildAnimatedCard(ColorScheme colorScheme, TourStep step,
      bool isFirst, bool isLast) {
    return FadeTransition(
      opacity: _fadeIn,
      child: SlideTransition(
        position: _slideIn,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 0),
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
              // Illustration area
              _StepIllustration(
                step: step,
                colorScheme: colorScheme,
              ),

              // Content area
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
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

                    // Description
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
                                Text(step.buttonLabel ?? (isLast ? 'Done' : 'Next')),
                                if (!isLast && step.buttonLabel == null) ...[
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

    // Create a path that covers the whole screen then cuts out the spotlight
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    if (target == TourTarget.bottomCenter) {
      // Spotlight on the Menu FAB pill at bottom center
      final center = Offset(size.width / 2, size.height - 32 - bottomPadding);
      path.addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: 100, height: 48),
        const Radius.circular(24),
      ));
    } else if (target == TourTarget.topRight) {
      // Spotlight on streak badge area at top right
      final center = Offset(size.width - 48, 52);
      path.addOval(Rect.fromCircle(center: center, radius: 28));
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
      case TourPreview.menuGrid:
        return _MiniMenuGridPreview(colorScheme: colorScheme);
      case TourPreview.quickActions:
        return _MiniQuickActionsPreview(colorScheme: colorScheme);
      case TourPreview.journeyMap:
        return _MiniJourneyMapPreview(colorScheme: colorScheme);
      case TourPreview.dashboard:
        return _MiniDashboardPreview(colorScheme: colorScheme);
      case TourPreview.smartFeatures:
        return _MiniSmartFeaturesPreview(colorScheme: colorScheme);
      case TourPreview.streak:
        return _MiniStreakPreview(colorScheme: colorScheme);
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
          // Sandalan logo representation
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
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                  color: colorScheme.onSurface)),
          const SizedBox(height: 2),
          Text('Your adulting companion',
              style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─── Mini Preview: Menu Grid ────────────────────────────────────────────────

class _MiniMenuGridPreview extends StatelessWidget {
  final ColorScheme colorScheme;
  const _MiniMenuGridPreview({required this.colorScheme});

  static const _items = [
    (icon: LucideIcons.home, label: 'Home', color: Color(0xFF6366F1)),
    (icon: LucideIcons.bookOpen, label: 'Guide', color: Color(0xFF10B981)),
    (icon: LucideIcons.layoutDashboard, label: 'Dashboard', color: Color(0xFF3B82F6)),
    (icon: LucideIcons.arrowLeftRight, label: 'Transactions', color: Color(0xFFF59E0B)),
    (icon: LucideIcons.wrench, label: 'Tools', color: Color(0xFFEF4444)),
    (icon: LucideIcons.settings, label: 'Settings', color: Color(0xFF8B5CF6)),
  ];

  @override
  Widget build(BuildContext context) {
    return _PreviewFrame(
      colorScheme: colorScheme,
      child: Column(
        children: [
          Text('Menu',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface)),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.0,
            children: _items.map((item) => Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.icon, size: 16, color: item.color),
                ),
                const SizedBox(height: 4),
                Text(item.label,
                    style: TextStyle(fontSize: 7, color: colorScheme.onSurfaceVariant),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            )).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Mini Preview: Quick Actions ────────────────────────────────────────────

class _MiniQuickActionsPreview extends StatelessWidget {
  final ColorScheme colorScheme;
  const _MiniQuickActionsPreview({required this.colorScheme});

  static const _actions = [
    (icon: LucideIcons.trendingDown, label: 'Expense', color: Color(0xFFEF4444)),
    (icon: LucideIcons.trendingUp, label: 'Income', color: Color(0xFF22C55E)),
    (icon: LucideIcons.camera, label: 'Scan', color: Color(0xFF6366F1)),
    (icon: LucideIcons.arrowLeftRight, label: 'Transfer', color: Color(0xFF3B82F6)),
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
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: a.color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(a.icon, size: 18, color: a.color),
                ),
                const SizedBox(height: 6),
                Text(a.label,
                    style: TextStyle(fontSize: 7, color: colorScheme.onSurfaceVariant)),
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

          // Stage nodes
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
          // Net worth card
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
              ),
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
                      Text('Net Worth',
                          style: TextStyle(fontSize: 7, color: Colors.white70)),
                      Text('P42,800',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
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
                  height: 32,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _MiniBar(height: 16, color: const Color(0xFF22C55E), colorScheme: colorScheme),
                      _MiniBar(height: 24, color: const Color(0xFFEF4444), colorScheme: colorScheme),
                      _MiniBar(height: 12, color: const Color(0xFF22C55E), colorScheme: colorScheme),
                      _MiniBar(height: 28, color: const Color(0xFFEF4444), colorScheme: colorScheme),
                      _MiniBar(height: 20, color: const Color(0xFF22C55E), colorScheme: colorScheme),
                      _MiniBar(height: 32, color: const Color(0xFFEF4444), colorScheme: colorScheme),
                      _MiniBar(height: 14, color: const Color(0xFF22C55E), colorScheme: colorScheme),
                    ],
                  ),
                ),
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
          // Chat bubble side
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
                // User message
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
                // AI response
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
          // Camera / scan side
          Column(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.camera, size: 24, color: Color(0xFF6366F1)),
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

// ─── Mini Preview: Streak ───────────────────────────────────────────────────

class _MiniStreakPreview extends StatelessWidget {
  final ColorScheme colorScheme;
  const _MiniStreakPreview({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return _PreviewFrame(
      colorScheme: colorScheme,
      child: Column(
        children: [
          // Streak flame
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.flame, size: 28, color: Color(0xFFF97316)),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('7-day streak!',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface)),
                  Text('Keep it going!',
                      style: TextStyle(fontSize: 8, color: colorScheme.onSurfaceVariant)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Achievement badges
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _AchievementBadge(icon: LucideIcons.trophy, color: const Color(0xFFF59E0B), colorScheme: colorScheme),
              const SizedBox(width: 8),
              _AchievementBadge(icon: LucideIcons.target, color: const Color(0xFF10B981), colorScheme: colorScheme),
              const SizedBox(width: 8),
              _AchievementBadge(icon: LucideIcons.star, color: const Color(0xFF8B5CF6), colorScheme: colorScheme),
              const SizedBox(width: 8),
              _AchievementBadge(icon: LucideIcons.medal, color: const Color(0xFF3B82F6), colorScheme: colorScheme),
              const SizedBox(width: 8),
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('+71',
                      style: TextStyle(fontSize: 7, fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final ColorScheme colorScheme;
  const _AchievementBadge({required this.icon, required this.color, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 14, color: color),
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
