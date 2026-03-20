/// Context-aware floating action button matching the web app's FAB.
/// Shows different actions depending on the current page.
/// Hidden on Settings, Guide, Tools pages.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ContextFAB extends StatefulWidget {
  final String currentPath;

  const ContextFAB({super.key, required this.currentPath});

  @override
  State<ContextFAB> createState() => _ContextFABState();
}

class _ContextFABState extends State<ContextFAB> with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late final AnimationController _animController;
  late final Animation<double> _rotationAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _rotationAnim = Tween<double>(begin: 0, end: 0.125).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  bool get _shouldShow {
    final p = widget.currentPath;
    if (p.startsWith('/settings')) return false;
    if (p.startsWith('/guide')) return false;
    if (p.startsWith('/tools')) return false;
    return true;
  }

  List<_FabAction> get _actions {
    final p = widget.currentPath;
    if (p.startsWith('/goals')) {
      return [_FabAction(icon: LucideIcons.target, label: 'Add Goal', onTap: () {})];
    }
    if (p.startsWith('/budgets')) {
      return [_FabAction(icon: LucideIcons.pieChart, label: 'Add Budget', onTap: () {})];
    }
    if (p.startsWith('/accounts')) {
      return [_FabAction(icon: LucideIcons.landmark, label: 'Add Account', onTap: () {})];
    }
    // Dashboard, transactions, home
    return [
      _FabAction(icon: LucideIcons.arrowDownLeft, label: 'Add Income', onTap: () {}),
      _FabAction(icon: LucideIcons.arrowUpRight, label: 'Add Expense', onTap: () {}),
    ];
  }

  void _toggle() {
    HapticFeedback.lightImpact();
    setState(() => _isOpen = !_isOpen);
    if (_isOpen) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldShow) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final actions = _actions;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Expanded actions
        if (_isOpen)
          ...actions.map((action) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(action.label,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface)),
                    ),
                    const SizedBox(width: 8),
                    FloatingActionButton.small(
                      heroTag: action.label,
                      onPressed: () {
                        _toggle();
                        action.onTap();
                      },
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      child: Icon(action.icon, size: 18),
                    ),
                  ],
                ),
              )),

        // Main FAB
        FloatingActionButton(
          onPressed: actions.length == 1
              ? () {
                  HapticFeedback.lightImpact();
                  actions.first.onTap();
                }
              : _toggle,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          child: RotationTransition(
            turns: _rotationAnim,
            child: const Icon(LucideIcons.plus, size: 24),
          ),
        ),
      ],
    );
  }
}

class _FabAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _FabAction({required this.icon, required this.label, required this.onTap});
}
