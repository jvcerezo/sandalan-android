import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/transactions/widgets/add_transaction_dialog.dart';
import '../../features/transactions/screens/receipt_scanner_screen.dart';
import '../../features/accounts/widgets/add_account_dialog.dart';
import '../../features/budgets/widgets/add_budget_dialog.dart';
import '../../features/goals/widgets/add_goal_dialog.dart';

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
  String _aiName = 'Sandalan AI';

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _rotationAnim = Tween<double>(begin: 0, end: 0.125).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _loadAiName();
  }

  Future<void> _loadAiName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('ai_assistant_name');
    if (name != null && name.isNotEmpty && mounted) {
      setState(() => _aiName = name);
    }
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

  void _openSheet(BuildContext context, Widget sheet) {
    _close();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => sheet,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldShow) return const SizedBox.shrink();

    // Hide FAB when keyboard is open (e.g. during modal bottom sheet input)
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    if (keyboardVisible) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final p = widget.currentPath;

    // ─── Single-action FABs (Accounts, Budgets, Goals) ─────────
    if (p.startsWith('/accounts')) {
      return FloatingActionButton(
        onPressed: () => _openSheet(context, const AddAccountDialog()),
        backgroundColor: cs.primary, foregroundColor: cs.onPrimary,
        child: const Icon(LucideIcons.plus, size: 24),
      );
    }

    if (p.startsWith('/budgets')) {
      return FloatingActionButton(
        onPressed: () => _openSheet(context, const AddBudgetDialog()),
        backgroundColor: cs.primary, foregroundColor: cs.onPrimary,
        child: const Icon(LucideIcons.plus, size: 24),
      );
    }

    if (p.startsWith('/goals')) {
      return FloatingActionButton(
        onPressed: () => _openSheet(context, const AddGoalDialog()),
        backgroundColor: cs.primary, foregroundColor: cs.onPrimary,
        child: const Icon(LucideIcons.plus, size: 24),
      );
    }

    // ─── Multi-action FAB (Home, Dashboard, Transactions) ──────
    if (_isTransactionPage) {
      final fab = Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
        if (_isOpen) ...[
          _FabMenuItem(
            label: _aiName,
            icon: LucideIcons.messageCircle,
            onTap: () { _close(); context.push('/chat'); },
          ),
          const SizedBox(height: 8),
          _FabMenuItem(
            label: 'Scan Receipt',
            icon: LucideIcons.scanLine,
            onTap: () => _openSheet(context, const ReceiptScannerScreen()),
          ),
          const SizedBox(height: 8),
          _FabMenuItem(
            label: 'Add Expense',
            icon: LucideIcons.trendingDown,
            onTap: () => _openSheet(context, const AddTransactionDialog(isIncome: false)),
          ),
          const SizedBox(height: 8),
          _FabMenuItem(
            label: 'Add Income',
            icon: LucideIcons.trendingUp,
            onTap: () => _openSheet(context, const AddTransactionDialog(isIncome: true)),
          ),
          const SizedBox(height: 8),
        ],
        FloatingActionButton(
          onPressed: _toggle,
          backgroundColor: cs.primary, foregroundColor: cs.onPrimary,
          child: RotationTransition(
            turns: _rotationAnim,
            child: Icon(_isOpen ? LucideIcons.x : LucideIcons.plus, size: 24),
          ),
        ),
      ]);

      if (!_isOpen) return fab;

      // When open, add a full-screen tap barrier that closes the menu
      return SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: _close,
                behavior: HitTestBehavior.opaque,
                child: const SizedBox.expand(),
              ),
            ),
            Positioned(right: 0, bottom: 0, child: fab),
          ],
        ),
      );
    }

    // Default: hidden
    return const SizedBox.shrink();
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
            color: cs.surfaceContainerHigh,
            border: Border.all(color: cs.outline.withValues(alpha: 0.3), width: 1),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4))],
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
