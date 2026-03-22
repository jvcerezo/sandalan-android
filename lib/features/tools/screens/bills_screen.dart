import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/automation_service.dart';
import '../../../data/models/bill.dart';
import '../../../data/models/transaction.dart';
import '../providers/tool_providers.dart';
import '../widgets/add_bill_dialog.dart';
import '../widgets/bill_calendar.dart';
import '../widgets/confirm_payment_dialog.dart';

class BillsScreen extends ConsumerStatefulWidget {
  const BillsScreen({super.key});

  @override
  ConsumerState<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends ConsumerState<BillsScreen> {
  bool _remindersEnabled = true;
  bool _calendarView = false;

  @override
  void initState() {
    super.initState();
    _loadPref();
  }

  Future<void> _loadPref() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _remindersEnabled = prefs.getBool('bills_reminders_enabled') ?? true;
      });
    }
  }

  Future<void> _toggleReminders() async {
    final newValue = !_remindersEnabled;
    setState(() => _remindersEnabled = newValue);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('bills_reminders_enabled', newValue);

    if (newValue) {
      // Re-schedule bill notifications
      await NotificationService.instance.requestPermission();
      await AutomationService.runOnAppStart();
    } else {
      // Cancel bill notifications and re-run to keep other categories
      await NotificationService.instance.cancelAll();
      await AutomationService.runOnAppStart();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bills = ref.watch(billsProvider);
    final summary = ref.watch(billsSummaryProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      children: [
        // ← Tools
        GestureDetector(
          onTap: () { if (context.canPop()) context.pop(); else context.go('/tools'); },
          child: Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(LucideIcons.arrowLeft, size: 14, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text('My Finances', style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
            ]),
          ),
        ),

        // Header
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.toolIndigo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(LucideIcons.receipt, size: 20, color: AppColors.toolIndigo),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Bills & Subscriptions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text('Track recurring expenses and due dates',
                style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
          ])),
        ]),
        const SizedBox(height: 12),

        // View toggle: List / Calendar
        Row(children: [
          GestureDetector(
            onTap: () => setState(() => _calendarView = false),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: !_calendarView ? colorScheme.primary : Colors.transparent,
                border: Border.all(color: !_calendarView ? colorScheme.primary : colorScheme.outline.withValues(alpha: 0.2)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text('List View', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                  color: !_calendarView ? colorScheme.onPrimary : colorScheme.onSurfaceVariant)),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _calendarView = true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _calendarView ? colorScheme.primary : Colors.transparent,
                border: Border.all(color: _calendarView ? colorScheme.primary : colorScheme.outline.withValues(alpha: 0.2)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text('Calendar View', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                  color: _calendarView ? colorScheme.onPrimary : colorScheme.onSurfaceVariant)),
            ),
          ),
        ]),
        const SizedBox(height: 12),

        // Calendar view
        if (_calendarView) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border.all(color: colorScheme.surfaceContainerHighest),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const BillDueCalendar(),
          ),
          const SizedBox(height: 16),
        ],

        // Summary cards
        summary.when(
          data: (s) => Row(children: [
            _SummaryCard(label: 'Monthly Total', value: formatCurrency(s.monthlyTotal),
                highlight: true, highlightColor: AppColors.toolIndigo),
            const SizedBox(width: 8),
            _SummaryCard(label: 'Annual Cost', value: formatCurrency(s.annualTotal)),
            const SizedBox(width: 8),
            _SummaryCard(label: 'Due This Week', value: '${s.dueSoonCount}',
                highlight: s.dueSoonCount > 0, highlightColor: AppColors.warning,
                valueColor: s.dueSoonCount > 0 ? AppColors.warning : null),
          ]),
          loading: () => const SizedBox(height: 60),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 14),

        // Due soon alert (hidden when reminders are off)
        if (_remindersEnabled) summary.when(
          data: (s) {
            if (s.dueSoonCount == 0) return const SizedBox.shrink();
            return bills.when(
              data: (list) {
                final now = DateTime.now();
                final dueSoon = list.where((b) =>
                    b.isActive && b.dueDay != null &&
                    (b.dueDay! - now.day).abs() <= 7).toList();
                if (dueSoon.isEmpty) return const SizedBox.shrink();

                return Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.06),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Icon(LucideIcons.alertCircle, size: 14, color: AppColors.warning),
                      const SizedBox(width: 6),
                      Text('Due within 7 days',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.warning)),
                    ]),
                    const SizedBox(height: 6),
                    ...dueSoon.map((b) => Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text('${b.name} — Day ${b.dueDay} · ${formatCurrency(b.amount)}',
                          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    )),
                  ]),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),

        // Category breakdown
        summary.when(
          data: (s) {
            if (s.monthlyTotal <= 0) return const SizedBox.shrink();
            return bills.when(
              data: (list) {
                final byCategory = <String, double>{};
                for (final b in list.where((b) => b.isActive)) {
                  double monthly = b.amount;
                  if (b.billingCycle == 'quarterly') monthly /= 3;
                  if (b.billingCycle == 'semi_annual') monthly /= 6;
                  if (b.billingCycle == 'annual') monthly /= 12;
                  byCategory[b.category] = (byCategory[b.category] ?? 0) + monthly;
                }
                if (byCategory.isEmpty) return const SizedBox.shrink();
                final sorted = byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Wrap(spacing: 8, runSpacing: 8, children: sorted.map((e) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: colorScheme.surfaceContainerHighest),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(e.key, style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant)),
                      Text('${formatCurrency(e.value)}/mo', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    ]),
                  )).toList()),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),

        // Bill Reminders card
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
            const Text('Bill Reminders', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            if (!_remindersEnabled) ...[
              const SizedBox(height: 4),
              Text('Get notified before your bills are due so you never miss a payment.',
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
              const SizedBox(height: 8),
              ...[
                'Bills with a due day appear in Upcoming Payments on your Home page',
                'Push notifications sent 3 days before due date',
                'Mark as paid to record a transaction from your linked account',
                'Set a due day on each bill to enable reminders',
              ].map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('•  ', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                  Expanded(child: Text(t, style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant))),
                ]),
              )),
            ],
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

        // Add Bill button
        OutlinedButton.icon(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (_) => const AddBillDialog(),
            ).then((result) {
              if (result == true) {
                ref.invalidate(billsProvider);
                ref.invalidate(billsSummaryProvider);
              }
            });
          },
          icon: const Icon(LucideIcons.plus, size: 16),
          label: const Text('Add Bill'),
          style: OutlinedButton.styleFrom(
            foregroundColor: colorScheme.primary,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 16),

        // Pending bill payments
        _PendingBillsList(ref: ref),
        const SizedBox(height: 16),

        // Bills list
        bills.when(
          data: (list) {
            final active = list.where((b) => b.isActive).toList();
            return _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Bills & Subscriptions (${active.length} active)',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              if (active.isEmpty)
                Center(child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text('No bills yet', style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
                ))
              else
                ...active.map((b) => _BillRow(bill: b, ref: ref)),
            ]));
          },
          loading: () => const SizedBox(height: 80),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity, padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      border: Border.all(color: Theme.of(context).colorScheme.surfaceContainerHighest),
      borderRadius: BorderRadius.circular(14),
    ),
    child: child,
  );
}

class _SummaryCard extends StatelessWidget {
  final String label, value;
  final Color? valueColor, highlightColor;
  final bool highlight;
  const _SummaryCard({required this.label, required this.value,
      this.valueColor, this.highlightColor, this.highlight = false});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlight ? (highlightColor ?? cs.primary).withValues(alpha: 0.06) : cs.surface,
        border: Border.all(color: cs.surfaceContainerHighest),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: valueColor)),
        ),
      ]),
    ));
  }
}

class _BillRow extends StatelessWidget {
  final Bill bill;
  final WidgetRef ref;
  const _BillRow({required this.bill, required this.ref});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDueSoon = bill.dueDay != null && (bill.dueDay! - DateTime.now().day).abs() <= 7;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(LucideIcons.zap, size: 16, color: AppColors.warning),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(bill.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            if (bill.dueDay != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDueSoon ? AppColors.expense.withValues(alpha: 0.1) : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (isDueSoon) ...[
                    Icon(LucideIcons.alertCircle, size: 10, color: AppColors.expense),
                    const SizedBox(width: 3),
                  ],
                  Text('Due day ${bill.dueDay}',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600,
                          color: isDueSoon ? AppColors.expense : cs.onSurfaceVariant)),
                ]),
              ),
            ],
          ]),
          Text('${bill.provider ?? bill.category} · ${formatCurrency(bill.amount)}/${_cycleShort(bill.billingCycle)}',
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
          if (bill.accountId != null)
            Row(children: [
              Icon(LucideIcons.landmark, size: 10, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text('Linked account', style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
            ]),
        ])),
        // Mark paid
        IconButton(
          onPressed: () async {
            await ref.read(billRepositoryProvider).markPaid(bill.id);
            ref.invalidate(billsProvider);
            ref.invalidate(billsSummaryProvider);
          },
          icon: Icon(LucideIcons.checkCircle2, size: 18, color: cs.onSurfaceVariant),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
        // Delete
        IconButton(
          onPressed: () async {
            await ref.read(billRepositoryProvider).deleteBill(bill.id);
            ref.invalidate(billsProvider);
            ref.invalidate(billsSummaryProvider);
          },
          icon: Icon(LucideIcons.trash2, size: 16, color: AppColors.expense.withValues(alpha: 0.5)),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ]),
    );
  }

  String _cycleShort(String cycle) {
    switch (cycle) {
      case 'monthly': return 'mo';
      case 'quarterly': return 'qtr';
      case 'semi_annual': return '6mo';
      case 'annual': return 'yr';
      default: return 'mo';
    }
  }
}

class _PendingBillsList extends StatelessWidget {
  final WidgetRef ref;
  const _PendingBillsList({required this.ref});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pending = ref.watch(pendingBillTransactionsProvider);

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
            ...list.map((t) => _PendingRow(transaction: t, ref: ref)),
          ]),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _PendingRow extends StatelessWidget {
  final Transaction transaction;
  final WidgetRef ref;
  const _PendingRow({required this.transaction, required this.ref});

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
                  ref.invalidate(pendingBillTransactionsProvider);
                  ref.invalidate(billsProvider);
                  ref.invalidate(billsSummaryProvider);
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
