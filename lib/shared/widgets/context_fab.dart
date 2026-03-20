import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../features/transactions/widgets/add_transaction_dialog.dart';

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
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _rotationAnim = Tween<double>(begin: 0, end: 0.125).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOut));
  }

  @override
  void dispose() { _animController.dispose(); super.dispose(); }

  bool get _shouldShow {
    final p = widget.currentPath;
    if (p.startsWith('/settings')) return false;
    if (p.startsWith('/guide')) return false;
    if (p.startsWith('/tools')) return false;
    return true;
  }

  bool get _isTransactionPage {
    final p = widget.currentPath;
    return p.startsWith('/home') || p.startsWith('/dashboard') || p.startsWith('/transactions');
  }

  void _toggle() {
    HapticFeedback.lightImpact();
    setState(() => _isOpen = !_isOpen);
    _isOpen ? _animController.forward() : _animController.reverse();
  }

  void _close() {
    if (_isOpen) {
      setState(() => _isOpen = false);
      _animController.reverse();
    }
  }

  void _openAddTransaction(BuildContext context, {required bool isIncome}) {
    _close();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTransactionDialog(isIncome: isIncome),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldShow) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;

    // For transaction pages: show Add Expense / Add Income
    if (_isTransactionPage) {
      return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
        if (_isOpen) ...[
          _FabMenuItem(
            label: 'Add Expense',
            icon: LucideIcons.trendingDown,
            onTap: () => _openAddTransaction(context, isIncome: false),
          ),
          const SizedBox(height: 8),
          _FabMenuItem(
            label: 'Add Income',
            icon: LucideIcons.trendingUp,
            onTap: () => _openAddTransaction(context, isIncome: true),
          ),
          const SizedBox(height: 8),
        ],
        FloatingActionButton(
          onPressed: _toggle,
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          child: RotationTransition(
            turns: _rotationAnim,
            child: Icon(_isOpen ? LucideIcons.x : LucideIcons.plus, size: 24),
          ),
        ),
      ]);
    }

    // For other pages: single action FAB
    return FloatingActionButton(
      onPressed: () {
        HapticFeedback.lightImpact();
        // Goals, budgets, accounts get their own add dialogs
      },
      backgroundColor: cs.primary,
      foregroundColor: cs.onPrimary,
      child: const Icon(LucideIcons.plus, size: 24),
    );
  }
}

class _FabMenuItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _FabMenuItem({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 16, color: cs.onSurface),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: cs.onSurface)),
          ]),
        ),
      ]),
    );
  }
}
