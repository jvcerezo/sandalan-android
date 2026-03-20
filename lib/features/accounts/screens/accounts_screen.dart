import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../data/models/account.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../shared/widgets/staggered_fade_in.dart';
import '../../../shared/widgets/animated_counter.dart';
import '../providers/account_providers.dart';
import '../../tools/providers/tool_providers.dart';
import '../widgets/add_account_dialog.dart';
import '../widgets/transfer_dialog.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final accounts = ref.watch(accountsProvider);
    final archived = ref.watch(archivedAccountsProvider);
    final totalBalance = ref.watch(totalBalanceProvider);
    final contribSummary = ref.watch(contributionSummaryProvider);

    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.mediumImpact();
        ref.invalidate(accountsProvider);
        ref.invalidate(archivedAccountsProvider);
        ref.invalidate(contributionSummaryProvider);
        await ref.read(accountsProvider.future);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Accounts', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Row(mainAxisSize: MainAxisSize.min, children: [
            OutlinedButton.icon(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (_) => const TransferDialog(),
                ).then((result) {
                  if (result == true) {
                    ref.invalidate(accountsProvider);
                  }
                });
              },
              icon: const Icon(LucideIcons.arrowLeftRight, size: 14),
              label: const Text('Transfer'),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: () => _showAddAccount(context, ref),
              icon: const Icon(LucideIcons.plus, size: 16),
              label: const Text('Add'),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
            ),
          ]),
        ]),
        const SizedBox(height: 4),
        AnimatedCurrency(
          value: totalBalance,
          style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 20),

        // Active accounts
        accounts.when(
          data: (accs) => accs.isEmpty
              ? EmptyState(
                  icon: LucideIcons.landmark,
                  title: 'No accounts yet',
                  subtitle: 'Add your first bank, e-wallet, or cash account.',
                  action: FilledButton.icon(
                    onPressed: () => _showAddAccount(context, ref),
                    icon: const Icon(LucideIcons.plus, size: 16),
                    label: const Text('Add Account'),
                  ),
                )
              : Column(children: accs.asMap().entries.map((e) =>
                  StaggeredFadeIn(index: e.key, child: _AccountCard(account: e.value))).toList()),
          loading: () => Column(children: List.generate(3, (_) => const ShimmerCard(height: 72))),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
        const SizedBox(height: 20),

        // Government contributions
        contribSummary.when(
          data: (cs) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('GOVERNMENT CONTRIBUTIONS',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8,
                    color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            _ContribDetailCard(label: 'SSS', yourShare: cs.sssPaid,
                employerShare: cs.sssEmployerPaid, color: AppColors.info),
            const SizedBox(height: 8),
            _ContribDetailCard(label: 'PhilHealth', yourShare: cs.philhealthPaid,
                employerShare: cs.philhealthEmployerPaid, color: AppColors.income),
            const SizedBox(height: 8),
            _ContribDetailCard(label: 'Pag-IBIG', yourShare: cs.pagibigPaid,
                employerShare: cs.pagibigEmployerPaid, color: AppColors.warning),
          ]),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 20),

        // Archived
        archived.when(
          data: (arcs) => arcs.isEmpty
              ? const SizedBox.shrink()
              : ExpansionTile(
                  title: Text('Archived (${arcs.length})',
                      style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant)),
                  children: arcs.map((a) => _AccountCard(account: a, isArchived: true)).toList(),
                ),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    ),
    );
  }

  void _showAddAccount(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const AddAccountDialog(),
    ).then((_) {
      ref.invalidate(accountsProvider);
      ref.invalidate(archivedAccountsProvider);
    });
  }
}

class _AccountCard extends StatelessWidget {
  final Account account;
  final bool isArchived;

  const _AccountCard({required this.account, this.isArchived = false});

  IconData get _typeIcon {
    switch (account.type) {
      case 'bank': return LucideIcons.landmark;
      case 'e-wallet': return LucideIcons.smartphone;
      case 'credit-card': return LucideIcons.creditCard;
      default: return LucideIcons.banknote;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_typeIcon, size: 20, color: colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(account.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(account.type, style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant)),
                ),
                const SizedBox(width: 6),
                Text(account.currency, style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant)),
              ]),
            ]),
          ),
          Text(formatCurrency(account.balance, currencyCode: account.currency),
              style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700,
                color: account.balance >= 0 ? colorScheme.onSurface : AppColors.expense,
              )),
        ]),
      ),
    );
  }
}

class _ContribDetailCard extends StatelessWidget {
  final String label;
  final double yourShare;
  final double employerShare;
  final Color color;
  const _ContribDetailCard({
    required this.label,
    required this.yourShare,
    required this.employerShare,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final total = yourShare + employerShare;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.surfaceContainerHighest),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        // Color indicator
        Container(
          width: 4, height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        // Label + total
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
            const SizedBox(height: 2),
            Text('Total: ${formatCurrency(total)}',
                style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
          ]),
        ),
        // Your share / Employer share
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('Your share', style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant)),
          Text(formatCurrency(yourShare), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text('Employer', style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant)),
          Text(formatCurrency(employerShare),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: colorScheme.onSurfaceVariant)),
        ]),
      ]),
    );
  }
}
