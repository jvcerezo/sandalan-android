import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../data/models/account.dart';
import '../../../shared/widgets/sandalan_loading.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../shared/widgets/staggered_fade_in.dart';
import '../../../shared/widgets/animated_counter.dart';
import '../../../shared/widgets/error_retry.dart';
import '../providers/account_providers.dart';
import '../../tools/providers/tool_providers.dart';
import '../../../core/services/premium_service.dart';
import '../widgets/add_account_dialog.dart';
import '../widgets/transfer_dialog.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final accounts = ref.watch(accountsProvider);
    final totalBalance = ref.watch(totalBalanceProvider);
    final contribSummary = ref.watch(contributionSummaryProvider);

    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.mediumImpact();
        ref.invalidate(accountsProvider);
        ref.invalidate(contributionSummaryProvider);
        await ref.read(accountsProvider.future);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          // Header
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Accounts', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 2),
              Text('Manage your wallets and bank accounts', style: TextStyle(fontSize: 13)),
            ])),
          Row(children: [
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
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              icon: const Icon(Icons.add, size: 14),
              label: const Text('Add'),
              onPressed: () {
                final accounts = ref.read(accountsProvider).valueOrNull ?? [];
                if (accounts.length >= 2 && !PremiumService.instance.hasAccess(PremiumFeature.unlimitedAccounts)) {
                  showPremiumGateWithPaywall(context, PremiumFeature.unlimitedAccounts);
                  return;
                }
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const AddAccountDialog(),
                ).then((_) => ref.invalidate(accountsProvider));
              },
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
            ),
          ]),
        ]),
        const SizedBox(height: 4),
        AnimatedCurrency(
          value: totalBalance,
          style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 14),

        // Payday Splitter shortcut
        InkWell(
          onTap: () => context.go('/salary-allocation'),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.05),
              border: Border.all(color: colorScheme.primary.withOpacity(0.12)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              Icon(LucideIcons.piggyBank, size: 16, color: colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(child: Text('Payday Splitter',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colorScheme.primary))),
              Icon(LucideIcons.chevronRight, size: 16, color: colorScheme.primary.withOpacity(0.5)),
            ]),
          ),
        ),
        const SizedBox(height: 16),

        // Active accounts
        accounts.when(
          data: (accs) => accs.isEmpty
              ? AnimatedEmptyState(
                  icon: LucideIcons.landmark,
                  title: 'No accounts yet',
                  subtitle: 'Add your first bank, e-wallet, or cash account.',
                  action: FilledButton.icon(
                    onPressed: () => _showAddAccount(context, ref),
                    icon: const Icon(LucideIcons.plus, size: 16),
                    label: const Text('Add Account'),
                  ),
                )
              : Column(children: accs.asMap().entries.map((e) {
                  final account = e.value;
                  return StaggeredFadeIn(
                    index: e.key,
                    child: Dismissible(
                      key: ValueKey(account.id),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (_) async {
                        // Let the card's delete confirmation handle it
                        return false; // Don't auto-dismiss, show dialog instead
                      },
                      onUpdate: (details) {
                        // Trigger delete dialog when swiped far enough
                        if (details.progress > 0.4 && !details.previousReached) {
                          // Will be handled by background tap
                        }
                      },
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: AppColors.expense.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(LucideIcons.trash2, color: AppColors.expense, size: 20),
                      ),
                      child: _AccountCard(account: account),
                    ),
                  );
                }).toList()),
          loading: () => Column(children: List.generate(3, (_) => const ShimmerCard(height: 72))),
          error: (_, __) => ErrorRetry(
            message: 'Could not load accounts',
            onRetry: () => ref.invalidate(accountsProvider),
          ),
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
    });
  }
}

class _AccountCard extends ConsumerWidget {
  final Account account;

  const _AccountCard({required this.account});

  IconData get _typeIcon {
    switch (account.type) {
      case 'bank': return LucideIcons.landmark;
      case 'e-wallet': return LucideIcons.smartphone;
      case 'credit-card': return LucideIcons.creditCard;
      case 'cash': return LucideIcons.banknote;
      default: return LucideIcons.wallet;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onLongPress: () => _showDeleteConfirmation(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
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
            AnimatedCurrency(
                value: account.balance,
                currencyCode: account.currency,
                style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700,
                  color: account.balance >= 0 ? colorScheme.onSurface : AppColors.expense,
                )),
          ]),
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(accountRepositoryProvider);
    final txnCount = await repo.countTransactions(account.id);

    if (!context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: Text(
          'Delete ${account.name}? This will permanently delete this account '
          'and all $txnCount transaction${txnCount == 1 ? '' : 's'} associated with it. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await repo.deleteAccount(account.id);
      ref.invalidate(accountsProvider);
    }
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

