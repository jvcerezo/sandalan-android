import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/math/debt_math.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/automation_service.dart';
import '../../../data/models/debt.dart';
import '../../../data/models/transaction.dart';
import '../providers/tool_providers.dart';
import '../widgets/add_debt_dialog.dart';
import '../widgets/confirm_payment_dialog.dart';
import '../widgets/record_debt_payment_dialog.dart';

class DebtManagerScreen extends ConsumerStatefulWidget {
  const DebtManagerScreen({super.key});

  @override
  ConsumerState<DebtManagerScreen> createState() => _DebtManagerScreenState();
}

class _DebtManagerScreenState extends ConsumerState<DebtManagerScreen> {
  final _extraPaymentController = TextEditingController(text: '0');
  bool _remindersEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadPref();
  }

  Future<void> _loadPref() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _remindersEnabled = prefs.getBool('debt_reminders_enabled') ?? true;
      });
    }
  }

  Future<void> _toggleReminders() async {
    final newValue = !_remindersEnabled;
    setState(() => _remindersEnabled = newValue);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('debt_reminders_enabled', newValue);

    if (newValue) {
      await NotificationService.instance.requestPermission();
      await AutomationService.runOnAppStart();
    } else {
      await NotificationService.instance.cancelAll();
      await AutomationService.runOnAppStart();
    }
  }

  @override
  void dispose() {
    _extraPaymentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final debts = ref.watch(debtsProvider);
    final summary = ref.watch(debtSummaryProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      children: [
        // ← Tools
        GestureDetector(
          onTap: () => context.go('/tools'),
          child: Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(LucideIcons.arrowLeft, size: 14, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text('Tools', style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
            ]),
          ),
        ),

        // Header
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.toolRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(LucideIcons.creditCard, size: 20, color: AppColors.toolRed),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Debt Manager', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text('Track balances · Avalanche & Snowball payoff',
                style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
          ])),
        ]),
        const SizedBox(height: 16),

        // Summary cards
        summary.when(
          data: (s) => Row(children: [
            _SummaryCard(label: 'Total Debt', value: formatCurrency(s.totalDebt)),
            const SizedBox(width: 8),
            _SummaryCard(label: 'Min. Monthly', value: formatCurrency(s.totalMinMonthly)),
            const SizedBox(width: 8),
            _SummaryCard(label: 'Highest Rate', value: '${(s.highestRate * 100).toStringAsFixed(1)}%',
                valueColor: AppColors.toolRed, highlight: true),
          ]),
          loading: () => const SizedBox(height: 60),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 16),

        // Payment Reminders card
        _Card(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppColors.income.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(LucideIcons.zap, size: 18, color: AppColors.income),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Payment Reminders', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Get notified before your debt payments are due.',
                style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            ...[
              'Debts with a due day appear in Upcoming Payments on your Home page',
              'Push notifications sent 3 days before due date',
              'Record a payment to create a transaction and reduce your balance',
              'Set a due day on each debt to enable reminders',
            ].map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('•  ', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                Expanded(child: Text(t, style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant))),
              ]),
            )),
          ])),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _toggleReminders,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _remindersEnabled
                    ? AppColors.warning.withValues(alpha: 0.15)
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (_remindersEnabled) const Icon(LucideIcons.bell, size: 12, color: AppColors.warning),
                if (_remindersEnabled) const SizedBox(width: 4),
                Text(_remindersEnabled ? 'On' : 'Off',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                        color: _remindersEnabled ? AppColors.warning : colorScheme.onSurfaceVariant)),
              ]),
            ),
          ),
        ])),
        const SizedBox(height: 16),

        // Add Debt button
        OutlinedButton.icon(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (_) => const AddDebtDialog(),
            ).then((result) {
              if (result == true) {
                ref.invalidate(debtsProvider);
                ref.invalidate(debtSummaryProvider);
              }
            });
          },
          icon: const Icon(LucideIcons.plus, size: 16),
          label: const Text('Add Debt'),
          style: OutlinedButton.styleFrom(
            foregroundColor: colorScheme.primary,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 16),

        // Pending debt payments
        _PendingDebtsList(ref: ref),
        const SizedBox(height: 16),

        // Active Debts
        debts.when(
          data: (list) {
            final active = list.where((d) => !d.isPaidOff).toList();
            if (active.isEmpty) {
              return _Card(child: Center(child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text('No active debts', style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
              )));
            }
            return _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Active Debts (${active.length})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              ...active.map((d) => _DebtRow(debt: d, ref: ref)),
            ]));
          },
          loading: () => const SizedBox(height: 80),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 16),

        // Payoff Strategies
        debts.when(
          data: (list) {
            final active = list.where((d) => !d.isPaidOff).toList();
            if (active.isEmpty) return const SizedBox.shrink();

            final inputs = active.map((d) => DebtInput(
              id: d.id, name: d.name, balance: d.currentBalance,
              annualRate: d.interestRate, minimumPayment: d.minimumPayment,
            )).toList();

            final extra = double.tryParse(_extraPaymentController.text.replaceAll(',', '')) ?? 0;
            final totalMin = active.fold(0.0, (s, d) => s + d.minimumPayment);
            final budget = totalMin + extra;

            final avalanche = calculateAvalanche(inputs, budget);
            final snowball = calculateSnowball(inputs, budget);

            return _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Payoff Strategies', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 14),

              Text('Extra Monthly Payment on top of minimums (₱)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Row(children: [
                SizedBox(width: 100, child: TextField(
                  controller: _extraPaymentController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(isDense: true),
                )),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  'Total budget: ${formatCurrency(budget)}/mo (min: ${formatCurrency(totalMin)})',
                  style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                )),
              ]),
              const SizedBox(height: 16),

              // Avalanche
              _StrategyCard(
                icon: LucideIcons.trendingDown,
                title: 'Avalanche',
                subtitle: 'Highest interest first — saves the most money',
                recommended: true,
                result: avalanche,
              ),
              const SizedBox(height: 12),

              // Snowball
              _StrategyCard(
                icon: LucideIcons.zap,
                title: 'Snowball',
                subtitle: 'Smallest balance first — quick wins for motivation',
                recommended: false,
                result: snowball,
              ),
              const SizedBox(height: 12),

              // Tip
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(LucideIcons.info, size: 12, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(child: Text(
                  'Both strategies yield similar results with your current debts. Adding extra money each month dramatically reduces total interest paid.',
                  style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                )),
              ]),
            ]));
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// ─── Widgets ───────────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).colorScheme.surfaceContainerHighest),
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  final bool highlight;
  const _SummaryCard({required this.label, required this.value, this.valueColor, this.highlight = false});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlight ? AppColors.toolRed.withValues(alpha: 0.06) : cs.surface,
        border: Border.all(color: cs.surfaceContainerHighest),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: valueColor)),
      ]),
    ));
  }
}

class _DebtRow extends StatelessWidget {
  final Debt debt;
  final WidgetRef ref;
  const _DebtRow({required this.debt, required this.ref});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final paidPct = debt.originalAmount > 0
        ? ((debt.originalAmount - debt.currentBalance) / debt.originalAmount).clamp(0.0, 1.0) : 0.0;
    final paidAmt = debt.originalAmount - debt.currentBalance;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: AppColors.toolRed.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: const Icon(LucideIcons.creditCard, size: 14, color: AppColors.toolRed),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(debt.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(width: 6),
              _TypeChip(debt.type),
              if (debt.lender != null) ...[
                const SizedBox(width: 4),
                _TypeChip(debt.lender!),
              ],
            ]),
            Text(
              '${(debt.interestRate * 100).toStringAsFixed(2)}% annual · Min: ${formatCurrency(debt.minimumPayment)}/mo${debt.dueDay != null ? ' · Due day ${debt.dueDay}' : ''}',
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            ),
          ])),
          Text(formatCurrency(debt.currentBalance),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          Icon(LucideIcons.trash2, size: 14, color: AppColors.toolRed.withValues(alpha: 0.5)),
        ]),
        const SizedBox(height: 8),
        // Progress
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Paid ${(paidPct * 100).toStringAsFixed(0)}%',
              style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
          Text('${formatCurrency(paidAmt)} of ${formatCurrency(debt.originalAmount)}',
              style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
        ]),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(value: paidPct, minHeight: 4,
              backgroundColor: cs.surfaceContainerHighest, color: AppColors.income),
        ),
        const SizedBox(height: 8),
        // Record Payment button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (_) => RecordDebtPaymentDialog(debt: debt),
              ).then((result) {
                if (result == true) {
                  ref.invalidate(debtsProvider);
                  ref.invalidate(debtSummaryProvider);
                }
              });
            },
            icon: const Icon(LucideIcons.circleDollarSign, size: 14),
            label: const Text('Record Payment'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
              textStyle: const TextStyle(fontSize: 12),
            ),
          ),
        ),
      ]),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  const _TypeChip(this.label);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(fontSize: 9, color: Theme.of(context).colorScheme.onSurfaceVariant)),
    );
  }
}

class _StrategyCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final bool recommended;
  final PayoffResult result;
  const _StrategyCard({required this.icon, required this.title, required this.subtitle,
      required this.recommended, required this.result});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final years = result.months ~/ 12;
    final months = result.months % 12;
    final timeStr = '${years}y ${months}m';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: recommended ? cs.primary.withValues(alpha: 0.04) : null,
        border: Border.all(color: recommended ? cs.primary.withValues(alpha: 0.2) : cs.surfaceContainerHighest),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 16, color: recommended ? cs.primary : AppColors.warning),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const Spacer(),
          if (recommended)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(8)),
              child: Text('Recommended', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: cs.onPrimary)),
            ),
        ]),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
        const SizedBox(height: 10),
        const Divider(height: 1),
        const SizedBox(height: 10),
        _StrategyRow('Payoff time', timeStr),
        _StrategyRow('Total interest', formatCurrency(result.totalInterestPaid), valueColor: AppColors.toolRed),
        _StrategyRow('Total paid', formatCurrency(result.totalPaid)),
        const SizedBox(height: 6),
        Text('Payoff order:', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
        ...result.payoffOrder.asMap().entries.map((e) =>
            Text('${e.key + 1}. ${e.value}', style: const TextStyle(fontSize: 12))),
      ]),
    );
  }
}

class _StrategyRow extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  const _StrategyRow(this.label, this.value, {this.valueColor});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: valueColor)),
      ]),
    );
  }
}

class _PendingDebtsList extends StatelessWidget {
  final WidgetRef ref;
  const _PendingDebtsList({required this.ref});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pending = ref.watch(pendingDebtTransactionsProvider);

    return pending.when(
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.04),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(LucideIcons.clock, size: 16, color: AppColors.warning),
              const SizedBox(width: 8),
              Text('Pending Payments (${list.length})',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.warning)),
            ]),
            const SizedBox(height: 4),
            Text('Auto-generated — review amounts and confirm to pay',
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
            const SizedBox(height: 12),
            ...list.map((t) => _PendingDebtRow(transaction: t, ref: ref)),
          ]),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _PendingDebtRow extends StatelessWidget {
  final Transaction transaction;
  final WidgetRef ref;
  const _PendingDebtRow({required this.transaction, required this.ref});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text('Pending', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.warning)),
        ),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(transaction.description, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          Text(formatCurrency(transaction.amount.abs()),
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
        ])),
        SizedBox(
          height: 30,
          child: FilledButton.icon(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (_) => ConfirmPaymentDialog(pendingTransaction: transaction),
              ).then((result) {
                if (result == true) {
                  ref.invalidate(pendingDebtTransactionsProvider);
                  ref.invalidate(debtsProvider);
                  ref.invalidate(debtSummaryProvider);
                }
              });
            },
            icon: const Icon(LucideIcons.checkCircle2, size: 12),
            label: const Text('Confirm & Pay'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              textStyle: const TextStyle(fontSize: 11),
            ),
          ),
        ),
      ]),
    );
  }
}
