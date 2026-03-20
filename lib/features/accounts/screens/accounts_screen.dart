import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../data/models/account.dart';
import '../../../shared/widgets/empty_state.dart';
import '../providers/account_providers.dart';
import '../../tools/providers/tool_providers.dart';
import '../widgets/add_account_dialog.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final accounts = ref.watch(accountsProvider);
    final archived = ref.watch(archivedAccountsProvider);
    final totalBalance = ref.watch(totalBalanceProvider);
    final contribSummary = ref.watch(contributionSummaryProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Accounts', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          FilledButton.icon(
            onPressed: () => _showAddAccount(context, ref),
            icon: const Icon(LucideIcons.plus, size: 16),
            label: const Text('Add'),
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
          ),
        ]),
        const SizedBox(height: 4),
        Text('Total: ${formatCurrency(totalBalance)}',
            style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
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
              : Column(children: accs.map((a) => _AccountCard(account: a)).toList()),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
        const SizedBox(height: 20),

        // Government contributions
        contribSummary.when(
          data: (cs) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('GOVERNMENT CONTRIBUTIONS',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 1.2,
                    color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            Row(children: [
              _ContribCard(label: 'SSS', amount: cs.sssPaid, color: AppColors.info),
              const SizedBox(width: 8),
              _ContribCard(label: 'PhilHealth', amount: cs.philhealthPaid, color: AppColors.income),
              const SizedBox(width: 8),
              _ContribCard(label: 'Pag-IBIG', amount: cs.pagibigPaid, color: AppColors.warning),
            ]),
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

class _ContribCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  const _ContribCard({required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(formatCurrency(amount), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}
