import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Full-screen celebration dialog shown when a user gets their 30-day free trial.
/// Call after signup/Google sign-in when activateSignupTrial() returns true.
Future<void> showTrialWelcomeDialog(BuildContext context) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black87,
    builder: (ctx) => const _TrialWelcomeDialog(),
  );
}

class _TrialWelcomeDialog extends StatefulWidget {
  const _TrialWelcomeDialog();

  @override
  State<_TrialWelcomeDialog> createState() => _TrialWelcomeDialogState();
}

class _TrialWelcomeDialogState extends State<_TrialWelcomeDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Crown icon with glow
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.2),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(LucideIcons.crown, size: 40, color: Color(0xFF6366F1)),
                ),
                const SizedBox(height: 20),

                // Title
                const Text(
                  'Welcome to Premium!',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  'You\'ve unlocked 30 days of free Premium access. '
                  'All features are yours — explore everything Sandalan has to offer.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Feature highlights
                ...[
                  ('Bills, debts & insurance tracking', LucideIcons.receipt),
                  ('Advanced dashboard & reports', LucideIcons.barChart3),
                  ('AI chat, receipt scanner & more', LucideIcons.sparkles),
                ].map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(item.$2, size: 14, color: const Color(0xFF10B981)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(item.$1,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                  ]),
                )),
                const SizedBox(height: 16),

                // Timer reminder
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAB308).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEAB308).withOpacity(0.2)),
                  ),
                  child: Row(children: [
                    const Icon(LucideIcons.clock, size: 16, color: Color(0xFFEAB308)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your trial ends in 30 days. You can subscribe anytime to keep Premium.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 20),

                // CTA
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: const Color(0xFF6366F1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Let\'s Go!', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
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
