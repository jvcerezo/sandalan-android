import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/automation_service.dart';
import '../../../core/constants/ph_rates.dart';
import '../../../core/math/ph_math.dart';
import '../../../data/models/contribution.dart';
import '../../../data/models/account.dart';
import '../../../shared/widgets/shimmer_loading.dart' show ShimmerLoading;
import '../../accounts/providers/account_providers.dart';
import '../providers/tool_providers.dart';

class ContributionsScreen extends ConsumerStatefulWidget {
  const ContributionsScreen({super.key});

  @override
  ConsumerState<ContributionsScreen> createState() => _ContributionsScreenState();
}

class _ContributionsScreenState extends ConsumerState<ContributionsScreen> {
  final _salaryController = TextEditingController();
  String _employmentType = 'employed';
  bool _autoGenerate = true;

  double get _salary => double.tryParse(_salaryController.text.replaceAll(',', '')) ?? 0;

  @override
  void initState() {
    super.initState();
    _loadPref();
  }

  Future<void> _loadPref() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _autoGenerate = prefs.getBool('auto_generate_contributions') ?? false;
        _employmentType = prefs.getString('contribution_employment_type') ?? 'employed';
        final savedSalary = prefs.getDouble('contribution_salary');
        if (savedSalary != null && savedSalary > 0) {
          _salaryController.text = savedSalary.toStringAsFixed(0);
        }
      });
    }
  }

  Future<void> _toggleAutoGenerate() async {
    final newValue = !_autoGenerate;
    setState(() => _autoGenerate = newValue);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_generate_contributions', newValue);

    if (newValue) {
      // Re-run automation to auto-generate contributions
      await AutomationService.runOnAppStart();
    }
  }

  @override
  void dispose() {
    _salaryController.dispose();
    super.dispose();
  }

  void _showImportPastDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ImportPastContributionsDialog(
        onImported: () {
          ref.invalidate(contributionsProvider);
          ref.invalidate(contributionSummaryProvider);
        },
      ),
    );
  }

  void _showPayDialog(Contribution contrib) {
    final accounts = ref.read(accountsProvider).valueOrNull ?? [];
    if (accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add an account first to mark contributions as paid')),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        const typeLabels = {'sss': 'SSS', 'philhealth': 'PhilHealth', 'pagibig': 'Pag-IBIG'};
        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Pay ${typeLabels[contrib.type] ?? contrib.type} — ${contrib.period}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Employee share: ${formatCurrency(contrib.employeeShare)}',
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
            const SizedBox(height: 16),
            const Text('Which account did you pay from?',
                style: TextStyle(fontSize: 13)),
            const SizedBox(height: 12),
            ...accounts.map((a) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SizedBox(width: double.infinity, child: OutlinedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await ref.read(contributionRepositoryProvider).markPaidWithAccount(contrib.id, a.id);
                  ref.invalidate(contributionsProvider);
                  ref.invalidate(contributionSummaryProvider);
                  ref.invalidate(accountsProvider);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${typeLabels[contrib.type] ?? contrib.type} marked as paid from ${a.name}')),
                    );
                  }
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text('${a.name} — ${formatCurrency(a.balance)}'),
              )),
            )),
            SizedBox(height: MediaQuery.of(ctx).padding.bottom),
          ]),
        );
      },
    );
  }

  void _confirmDeleteContribution(Contribution contrib) {
    const typeLabels = {'sss': 'SSS', 'philhealth': 'PhilHealth', 'pagibig': 'Pag-IBIG'};
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Contribution'),
        content: Text('Delete ${typeLabels[contrib.type] ?? contrib.type} for ${contrib.period}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(contributionRepositoryProvider).deleteContribution(contrib.id);
              ref.invalidate(contributionsProvider);
              ref.invalidate(contributionSummaryProvider);
            },
            child: Text('Delete', style: TextStyle(color: AppColors.expense)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final contributions = ref.watch(contributionsProvider);
    final salary = _salary;

    // Calculate breakdowns
    final sss = calculateSSS(salary);
    final phil = calculatePhilHealth(salary);
    final pag = calculatePagIbig(salary);
    final sssEmployee = sss.employee;
    final sssEmployer = sss.employer;
    final philEmployee = phil.employee;
    final philEmployer = phil.employer;
    final pagEmployee = pag.employee;
    final pagEmployer = pag.employer;
    final totalYou = sssEmployee + philEmployee + pagEmployee;
    final totalEmployer = sssEmployer + philEmployer + pagEmployer;
    final totalAll = totalYou + totalEmployer;
    final netTakeHome = salary - totalYou;

    final msc = sss.msc;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      children: [
        // Header
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("Gov't Contributions",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(_salary > 0
                ? 'SSS · PhilHealth · Pag-IBIG · ${formatCurrency(_salary)}/mo salary'
                : 'SSS · PhilHealth · Pag-IBIG deductions',
                style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
          ])),
        ]),
        const SizedBox(height: 16),

        // Rate cards
        Row(children: [
          _RateCard(label: 'SSS', rate: '13%', detail: 'MSC ₱3k–₱30k', color: AppColors.info),
          const SizedBox(width: 8),
          _RateCard(label: 'PhilHealth', rate: '5%', detail: '₱10k–₱100k', color: AppColors.income),
          const SizedBox(width: 8),
          _RateCard(label: 'Pag-IBIG', rate: '2%', detail: 'Max ₱100', color: AppColors.warning),
        ]),
        const SizedBox(height: 16),

        // Auto-generate card
        _Card(
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
              const Text('Auto-Generate Monthly Entries',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              if (!_autoGenerate) ...[
                const SizedBox(height: 4),
                Text('Automatically create SSS, PhilHealth, and Pag-IBIG entries each month based on your last salary.',
                    style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                const SizedBox(height: 8),
                ...[
                  'New entries created on the 1st of each month as unpaid',
                  'Uses your most recent salary and employment type',
                  'You still mark each as paid when you actually pay',
                  'Reminder notifications sent 3 days before month-end',
                ].map((text) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('•  ', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                    Expanded(child: Text(text, style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant))),
                  ]),
                )),
              ],
            ])),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _toggleAutoGenerate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _autoGenerate ? AppColors.warning.withValues(alpha: 0.15) : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (_autoGenerate) const Icon(LucideIcons.bell, size: 12, color: AppColors.warning),
                  if (_autoGenerate) const SizedBox(width: 4),
                  Text(_autoGenerate ? 'On' : 'Off',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                          color: _autoGenerate ? AppColors.warning : colorScheme.onSurfaceVariant)),
                ]),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 16),

        // Monthly Salary form
        _Card(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Monthly Salary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 14),
            const Text('Basic Monthly Salary (₱)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            TextField(
              controller: _salaryController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(isDense: true),
            ),
            const SizedBox(height: 12),
            const Text('Employment Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _employmentType,
              isDense: true,
              items: const [
                DropdownMenuItem(value: 'employed', child: Text('Employed')),
                DropdownMenuItem(value: 'self_employed', child: Text('Self-Employed')),
                DropdownMenuItem(value: 'voluntary', child: Text('Voluntary')),
                DropdownMenuItem(value: 'ofw', child: Text('OFW')),
              ],
              onChanged: (v) => setState(() => _employmentType = v ?? 'employed'),
            ),
            const SizedBox(height: 12),
            const Text('Period (YYYY-MM)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: now,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(now.year + 1, 12),
                );
                if (picked != null && mounted) {
                  // Period is informational — the Update button uses DateTime.now()
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Selected: ${picked.year}-${picked.month.toString().padLeft(2, '0')}')),
                  );
                }
              },
              child: AbsorbPointer(
                child: TextField(
                  readOnly: true,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}',
                    suffixIcon: Icon(LucideIcons.calendar, size: 16, color: colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 16),

        // Monthly Breakdown table
        _Card(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Monthly Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('2024 rates', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
              ),
            ]),
            const SizedBox(height: 12),

            // Header
            _TableRow(isHeader: true, fund: 'FUND', you: 'YOU', employer: 'EMPLOYER', total: 'TOTAL'),
            const Divider(height: 1),

            // SSS
            _TableRow(fund: 'SSS', you: formatCurrency(sssEmployee),
                employer: formatCurrency(sssEmployer), total: formatCurrency(sssEmployee + sssEmployer),
                fundColor: AppColors.info, detail: 'MSC: ${formatCurrency(msc)}'),
            const Divider(height: 1),

            // PhilHealth
            _TableRow(fund: 'PhilHealth', you: formatCurrency(philEmployee),
                employer: formatCurrency(philEmployer), total: formatCurrency(philEmployee + philEmployer),
                fundColor: AppColors.income, detail: 'Based on salary ≤ ₱100k'),
            const Divider(height: 1),

            // Pag-IBIG
            _TableRow(fund: 'Pag-IBIG', you: formatCurrency(pagEmployee),
                employer: formatCurrency(pagEmployer), total: formatCurrency(pagEmployee + pagEmployer),
                fundColor: AppColors.warning, detail: 'Max ₱100 each'),
            const Divider(height: 1),

            // Total
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(children: [
                const Expanded(flex: 2, child: Text('Total', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
                Expanded(flex: 2, child: Text(formatCurrency(totalYou),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700), textAlign: TextAlign.right)),
                Expanded(flex: 2, child: Text(formatCurrency(totalEmployer),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700), textAlign: TextAlign.right)),
                Expanded(flex: 2, child: Text(formatCurrency(totalAll),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700), textAlign: TextAlign.right)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 12),

        // Summary cards
        Row(children: [
          _SummaryCard(label: 'Gross Monthly', value: formatCurrency(salary)),
          const SizedBox(width: 8),
          _SummaryCard(label: 'Deductions', value: formatCurrency(totalYou)),
          const SizedBox(width: 8),
          _SummaryCard(label: 'Net Take-Home', value: formatCurrency(netTakeHome),
              valueColor: AppColors.income, highlight: true),
        ]),
        const SizedBox(height: 12),

        // Update button
        FilledButton.icon(
          onPressed: () async {
            HapticFeedback.mediumImpact();
            // Save salary and employment type for auto-generation
            final prefs = await SharedPreferences.getInstance();
            await prefs.setDouble(AutomationKeys.contribSalary, salary);
            await prefs.setString(AutomationKeys.contribEmploymentType, _employmentType);

            final now = DateTime.now();
            final period = '${now.year}-${now.month.toString().padLeft(2, '0')}';
            final repo = ref.read(contributionRepositoryProvider);
            for (final type in ['sss', 'philhealth', 'pagibig']) {
              final emp = type == 'sss' ? sssEmployee : type == 'philhealth' ? philEmployee : pagEmployee;
              final empr = type == 'sss' ? sssEmployer : type == 'philhealth' ? philEmployer : pagEmployer;
              await repo.createContribution(
                type: type, period: period, monthlySalary: salary,
                employeeShare: emp, employerShare: empr,
                totalContribution: emp + empr, employmentType: _employmentType,
              );
            }
            ref.invalidate(contributionsProvider);
            ref.invalidate(contributionSummaryProvider);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Contributions updated')),
              );
            }
          },
          icon: const Icon(LucideIcons.save, size: 16),
          label: Text('Update ${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Rates based on SSS 2024 schedule (13% total, MSC ₱3k–₱30k), PhilHealth 5% premium (₱10k–₱100k salary), and Pag-IBIG 2% (max ₱100 each). Consult your HR or the respective agency for exact figures.',
          style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant, height: 1.4),
        ),
        const SizedBox(height: 20),

        // Contribution History
        _Card(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Contribution History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              OutlinedButton.icon(
                onPressed: () => _showImportPastDialog(context),
                icon: const Icon(LucideIcons.plus, size: 14),
                label: const Text('Log Past'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            contributions.when(
              data: (list) {
                if (list.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: Text('No contributions recorded yet',
                        style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant))),
                  );
                }
                // Group by period
                final grouped = <String, List<Contribution>>{};
                for (final c in list) {
                  grouped.putIfAbsent(c.period, () => []).add(c);
                }
                return Column(children: grouped.entries.map((entry) {
                  final period = entry.key;
                  final items = entry.value;
                  final totalYourShare = items.fold(0.0, (s, c) => s + c.employeeShare);
                  final allPaid = items.every((c) => c.isPaid);
                  // Parse period for display
                  final parts = period.split('-');
                  const monthNames = ['', 'January', 'February', 'March', 'April', 'May', 'June',
                      'July', 'August', 'September', 'October', 'November', 'December'];
                  final displayPeriod = '${monthNames[int.parse(parts[1])]} ${parts[0]}';

                  return _HistoryMonth(
                    period: displayPeriod,
                    count: items.length,
                    yourShare: totalYourShare,
                    isPaid: allPaid,
                    items: items,
                    onPayItem: _showPayDialog,
                    onDeleteItem: _confirmDeleteContribution,
                  );
                }).toList());
              },
              loading: () => const ShimmerLoading(height: 60),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ]),
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
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).colorScheme.surfaceContainerHighest),
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}

class _RateCard extends StatelessWidget {
  final String label, rate, detail;
  final Color color;
  const _RateCard({required this.label, required this.rate, required this.detail, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
          Text(rate, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(detail, style: TextStyle(fontSize: 9, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ]),
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  final String fund, you, employer, total;
  final Color? fundColor;
  final String? detail;
  final bool isHeader;
  const _TableRow({required this.fund, required this.you, required this.employer,
      required this.total, this.fundColor, this.detail, this.isHeader = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final style = isHeader
        ? TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: colorScheme.onSurfaceVariant)
        : const TextStyle(fontSize: 12, fontWeight: FontWeight.w500);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(flex: 2, child: Text(fund, style: isHeader ? style : TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fundColor))),
          Expanded(flex: 2, child: Text(you, style: style, textAlign: TextAlign.right)),
          Expanded(flex: 2, child: Text(employer, style: style, textAlign: TextAlign.right)),
          Expanded(flex: 2, child: Text(total, style: isHeader ? style : const TextStyle(fontSize: 12, fontWeight: FontWeight.w700), textAlign: TextAlign.right)),
        ]),
        if (detail != null) ...[
          const SizedBox(height: 2),
          Row(children: [
            Icon(LucideIcons.info, size: 10, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(detail!, style: TextStyle(fontSize: 9, color: colorScheme.onSurfaceVariant)),
          ]),
        ],
      ]),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: highlight ? AppColors.income.withValues(alpha: 0.08) : colorScheme.surface,
          border: Border.all(color: colorScheme.surfaceContainerHighest),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: valueColor)),
        ]),
      ),
    );
  }
}

class _HistoryMonth extends StatefulWidget {
  final String period;
  final int count;
  final double yourShare;
  final bool isPaid;
  final List<Contribution> items;
  final void Function(Contribution) onPayItem;
  final void Function(Contribution) onDeleteItem;
  const _HistoryMonth({required this.period, required this.count,
      required this.yourShare, required this.isPaid, required this.items,
      required this.onPayItem, required this.onDeleteItem});

  @override
  State<_HistoryMonth> createState() => _HistoryMonthState();
}

class _HistoryMonthState extends State<_HistoryMonth> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const typeColors = {'sss': AppColors.info, 'philhealth': AppColors.income, 'pagibig': AppColors.warning};
    const typeLabels = {'sss': 'SSS', 'philhealth': 'PhilHealth', 'pagibig': 'Pag-IBIG'};

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.surfaceContainerHighest),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: [
        // Month header
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Icon(LucideIcons.checkCircle2, size: 18,
                  color: widget.isPaid ? AppColors.income : colorScheme.onSurfaceVariant),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.period, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                Text('${widget.count} contributions · your share: ${formatCurrency(widget.yourShare)}',
                    style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: widget.isPaid ? AppColors.income : AppColors.warning,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(widget.isPaid ? 'Paid' : 'Unpaid',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
              const SizedBox(width: 6),
              Icon(_expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown, size: 16,
                  color: colorScheme.onSurfaceVariant),
            ]),
          ),
        ),

        // Expanded items
        if (_expanded)
          ...widget.items.map((c) {
            final color = typeColors[c.type] ?? AppColors.info;
            final label = typeLabels[c.type] ?? c.type;
            return InkWell(
              onTap: c.isPaid ? null : () => widget.onPayItem(c),
              child: Container(
                padding: const EdgeInsets.fromLTRB(44, 8, 12, 8),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: colorScheme.outline.withValues(alpha: 0.08))),
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Your share: ${formatCurrency(c.employeeShare)}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    Text('Employer: ${formatCurrency(c.employerShare ?? 0)}',
                        style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                  ])),
                  GestureDetector(
                    onTap: c.isPaid ? null : () => widget.onPayItem(c),
                    child: Icon(c.isPaid ? LucideIcons.checkCircle2 : LucideIcons.circle, size: 16,
                        color: c.isPaid ? AppColors.income : colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => widget.onDeleteItem(c),
                    child: Icon(LucideIcons.trash2, size: 14, color: AppColors.expense.withValues(alpha: 0.5)),
                  ),
                ]),
              ),
            );
          }),
      ]),
    );
  }
}

// ─── Import Past Contributions Dialog ────────────────────────────────────────

class _ImportPastContributionsDialog extends ConsumerStatefulWidget {
  final VoidCallback onImported;
  const _ImportPastContributionsDialog({required this.onImported});

  @override
  ConsumerState<_ImportPastContributionsDialog> createState() => _ImportPastDialogState();
}

class _ImportPastDialogState extends ConsumerState<_ImportPastContributionsDialog> {
  bool _fromSalary = true;
  DateTime? _fromDate;
  DateTime _toDate = DateTime.now();
  final _salaryController = TextEditingController();
  final _sssController = TextEditingController();
  final _philhealthController = TextEditingController();
  final _pagibigController = TextEditingController();
  bool _importing = false;

  @override
  void dispose() {
    _salaryController.dispose();
    _sssController.dispose();
    _philhealthController.dispose();
    _pagibigController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isFrom) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? (_fromDate ?? DateTime(now.year - 1, now.month)) : _toDate,
      firstDate: DateTime(2018),
      lastDate: DateTime(now.year + 1, 12),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isFrom) {
          _fromDate = DateTime(picked.year, picked.month);
        } else {
          _toDate = DateTime(picked.year, picked.month);
        }
      });
    }
  }

  String _formatMonthYear(DateTime? d) {
    if (d == null) return '---------- ----';
    const months = ['', 'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'];
    return '${months[d.month]} ${d.year}';
  }

  Future<void> _import() async {
    if (_fromDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a start date')),
      );
      return;
    }

    setState(() => _importing = true);

    try {
      final repo = ref.read(contributionRepositoryProvider);
      var current = DateTime(_fromDate!.year, _fromDate!.month);
      final end = DateTime(_toDate.year, _toDate.month);

      while (!current.isAfter(end)) {
        final period = '${current.year}-${current.month.toString().padLeft(2, '0')}';

        if (_fromSalary) {
          final salary = double.tryParse(_salaryController.text.replaceAll(',', '')) ?? 0;
          if (salary <= 0) break;
          final sss = calculateSSS(salary);
          final phil = calculatePhilHealth(salary);
          final pag = calculatePagIbig(salary);

          for (final entry in [
            ('sss', sss.employee, sss.employer),
            ('philhealth', phil.employee, phil.employer),
            ('pagibig', pag.employee, pag.employer),
          ]) {
            await repo.createContribution(
              type: entry.$1, period: period, monthlySalary: salary,
              employeeShare: entry.$2, employerShare: entry.$3,
              totalContribution: entry.$2 + entry.$3,
            );
          }
        } else {
          final sss = double.tryParse(_sssController.text.replaceAll(',', ''));
          final phil = double.tryParse(_philhealthController.text.replaceAll(',', ''));
          final pag = double.tryParse(_pagibigController.text.replaceAll(',', ''));

          if (sss != null && sss > 0) {
            await repo.createContribution(
              type: 'sss', period: period, monthlySalary: 0,
              employeeShare: sss, employerShare: 0, totalContribution: sss,
            );
          }
          if (phil != null && phil > 0) {
            await repo.createContribution(
              type: 'philhealth', period: period, monthlySalary: 0,
              employeeShare: phil, employerShare: 0, totalContribution: phil,
            );
          }
          if (pag != null && pag > 0) {
            await repo.createContribution(
              type: 'pagibig', period: period, monthlySalary: 0,
              employeeShare: pag, employerShare: 0, totalContribution: pag,
            );
          }
        }

        // Mark all as paid for this period
        final all = await repo.getContributions(period: period);
        for (final c in all) {
          if (!c.isPaid) await repo.markPaid(c.id);
        }

        current = DateTime(current.year, current.month + 1);
      }

      widget.onImported();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Past contributions imported and marked as paid')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Import Past Contributions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(LucideIcons.x, size: 20, color: cs.onSurfaceVariant),
          ),
        ]),
        const SizedBox(height: 16),

        // Date range
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('From', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => _pickDate(true),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Flexible(child: Text(_formatMonthYear(_fromDate),
                      style: TextStyle(fontSize: 13, color: _fromDate == null ? cs.onSurfaceVariant : null),
                      overflow: TextOverflow.ellipsis)),
                  Icon(LucideIcons.calendar, size: 14, color: cs.onSurfaceVariant),
                ]),
              ),
            ),
          ])),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('To', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => _pickDate(false),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Flexible(child: Text(_formatMonthYear(_toDate), style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis)),
                  Icon(LucideIcons.calendar, size: 14, color: cs.onSurfaceVariant),
                ]),
              ),
            ),
          ])),
        ]),
        const SizedBox(height: 16),

        // Toggle: From Salary / Enter Manually
        Row(children: [
          Expanded(child: GestureDetector(
            onTap: () => setState(() => _fromSalary = true),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: _fromSalary ? AppColors.income : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _fromSalary ? AppColors.income : cs.outline.withValues(alpha: 0.2)),
              ),
              child: Center(child: Text('From Salary',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      color: _fromSalary ? Colors.white : cs.onSurface))),
            ),
          )),
          const SizedBox(width: 8),
          Expanded(child: GestureDetector(
            onTap: () => setState(() => _fromSalary = false),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: !_fromSalary ? AppColors.income : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: !_fromSalary ? AppColors.income : cs.outline.withValues(alpha: 0.2)),
              ),
              child: Center(child: Text('Enter Manually',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      color: !_fromSalary ? Colors.white : cs.onSurface))),
            ),
          )),
        ]),
        const SizedBox(height: 16),

        if (_fromSalary) ...[
          const Text('Monthly Salary (₱)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          TextField(
            controller: _salaryController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
            decoration: const InputDecoration(isDense: true, hintText: 'e.g. 25000'),
          ),
        ] else ...[
          Text("Enter the amount you paid each month. Leave blank to skip that fund.",
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          const SizedBox(height: 12),
          Text('SSS — Employee Share (₱)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.info)),
          const SizedBox(height: 4),
          TextField(controller: _sssController, keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
            decoration: const InputDecoration(isDense: true, hintText: 'e.g. 900')),
          const SizedBox(height: 10),
          Text('PhilHealth — Employee Share (₱)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.income)),
          const SizedBox(height: 4),
          TextField(controller: _philhealthController, keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
            decoration: const InputDecoration(isDense: true, hintText: 'e.g. 625')),
          const SizedBox(height: 10),
          Text('Pag-IBIG — Employee Share (₱)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.warning)),
          const SizedBox(height: 4),
          TextField(controller: _pagibigController, keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
            decoration: const InputDecoration(isDense: true, hintText: 'e.g. 100')),
        ],
        const SizedBox(height: 12),

        RichText(text: TextSpan(style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant), children: [
          const TextSpan(text: 'All imported months will be marked as '),
          TextSpan(text: 'Paid', style: TextStyle(fontWeight: FontWeight.bold, color: cs.onSurface)),
          const TextSpan(text: '. Existing records for the same month will be updated.'),
        ])),
        const SizedBox(height: 16),

        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: _importing ? null : _import,
            child: _importing
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Import'),
          ),
        ]),

        SizedBox(height: MediaQuery.of(context).padding.bottom),
      ]),
    );
  }
}

