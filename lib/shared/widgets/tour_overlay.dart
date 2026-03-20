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

class TourStep {
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;

  const TourStep({
    required this.title,
    required this.description,
    required this.icon,
    this.iconColor = const Color(0xFF6366F1),
  });
}

const _tourSteps = [
  TourStep(
    title: 'Welcome to Sandalan!',
    description:
        'Your companion for every stage of Filipino adult life. This quick tour walks you through everything you need to get started.',
    icon: LucideIcons.map,
  ),
  TourStep(
    title: 'Your Adulting Journey',
    description:
        'The Journey Map is your roadmap through Filipino adulting \u2014 from getting your first IDs to retirement. Each stage has step-by-step guides and checklists you can mark as done or skip.',
    icon: LucideIcons.bookOpen,
    iconColor: Color(0xFF3B82F6),
  ),
  TourStep(
    title: 'Financial Dashboard',
    description:
        'See your net worth, financial health score, spending trends, and budget alerts \u2014 all in one place. This is your financial overview.',
    icon: LucideIcons.layoutDashboard,
    iconColor: Color(0xFF10B981),
  ),
  TourStep(
    title: 'Track Transactions',
    description:
        'Log every peso \u2014 income, expenses, and transfers between accounts. Your balances and insights update automatically.',
    icon: LucideIcons.arrowLeftRight,
    iconColor: Color(0xFFF59E0B),
  ),
  TourStep(
    title: 'Goals & Budgets',
    description:
        'Set savings targets and monthly spending limits. Track your progress with visual bars and get alerts when you\'re near a limit.',
    icon: LucideIcons.target,
    iconColor: Color(0xFF8B5CF6),
  ),
  TourStep(
    title: 'Adulting Tools',
    description:
        'Track SSS, PhilHealth, and Pag-IBIG contributions. Compute your BIR taxes. Manage debts, bills, and insurance \u2014 built for Filipino needs.',
    icon: LucideIcons.wrench,
    iconColor: Color(0xFFEF4444),
  ),
  TourStep(
    title: 'Quick Add',
    description:
        'Tap the + button anytime to instantly log an expense or income. It\'s the fastest way to keep your records up to date.',
    icon: LucideIcons.plusCircle,
    iconColor: Color(0xFF6366F1),
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
                      _StepIllustration(step: step, colorScheme: colorScheme),

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
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
