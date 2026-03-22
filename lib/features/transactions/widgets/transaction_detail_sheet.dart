import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../data/models/transaction.dart';
import '../../../data/models/account.dart';
import '../../../data/repositories/transaction_repository.dart';
import 'package:go_router/go_router.dart';
import '../providers/transaction_providers.dart';
import 'add_transaction_dialog.dart';

/// Shows a bottom sheet with full transaction details plus edit/delete actions.
void showTransactionDetailSheet(
  BuildContext context,
  WidgetRef ref,
  Transaction t,
  List<Account> accounts,
) {
  final colorScheme = Theme.of(context).colorScheme;
  final isTransfer = t.transferId != null;
  final isIncome = !isTransfer && t.amount > 0;
  final accountName = accounts.where((a) => a.id == t.accountId).firstOrNull?.name ?? 'Unknown';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Drag handle
        Center(child: Container(
          width: 36, height: 4, margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: colorScheme.outline.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(2)),
        )),

        // Header
        Row(children: [
          const Text('Transaction Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.of(ctx).pop(),
            child: Icon(LucideIcons.x, size: 20, color: colorScheme.onSurfaceVariant),
          ),
        ]),
        const SizedBox(height: 16),

        // Amount
        Text(
          isTransfer
              ? formatCurrency(t.amount.abs())
              : '${isIncome ? '+' : '-'}${formatCurrency(t.amount.abs())}',
          style: TextStyle(
            fontSize: 28, fontWeight: FontWeight.w600,
            color: isTransfer ? colorScheme.onSurface : (isIncome ? AppColors.income : colorScheme.onSurface),
          ),
        ),
        const SizedBox(height: 16),

        // Detail rows
        _DetailRow(label: 'Category', value: t.category, colorScheme: colorScheme),
        if (t.description.isNotEmpty)
          _DetailRow(label: 'Description', value: t.description, colorScheme: colorScheme),
        _DetailRow(label: 'Date', value: formatDate(DateTime.parse(t.date)), colorScheme: colorScheme),
        _DetailRow(label: 'Account', value: accountName, colorScheme: colorScheme),
        if (t.tags != null && t.tags!.isNotEmpty) ...[
          Builder(builder: (_) {
            final userTags = t.tags!.where((tag) =>
              !RegExp(r'^[0-9a-f]{8}-').hasMatch(tag) &&
              !const ['bill', 'debt', 'insurance', 'contribution', 'auto-generated'].contains(tag.toLowerCase())
            ).toList();
            if (userTags.isEmpty) return const SizedBox.shrink();
            return _DetailRow(label: 'Tags', value: userTags.map((tag) => '#$tag').join(', '), colorScheme: colorScheme);
          }),
        ],
        const SizedBox(height: 20),

        // Action buttons
        Row(children: [
          Expanded(child: OutlinedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => AddTransactionDialog(
                  isIncome: isIncome,
                  defaultAccountId: t.accountId,
                  editTransaction: t,
                ),
              ).then((result) {
                if (result == true) {
                  ref.invalidate(transactionsProvider);
                  ref.invalidate(transactionsCountProvider);
                  ref.invalidate(transactionsSummaryProvider);
                }
              });
            },
            icon: const Icon(LucideIcons.pencil, size: 16),
            label: const Text('Edit'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          )),
          const SizedBox(width: 8),
          Expanded(child: OutlinedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              _confirmDelete(context, ref, t);
            },
            icon: Icon(LucideIcons.trash2, size: 16, color: AppColors.error),
            label: Text('Delete', style: TextStyle(color: AppColors.error)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
            ),
          )),
        ]),

        // Split this (only for expenses)
        if (!isIncome && !isTransfer) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.go('/split-bills');
              },
              icon: const Icon(LucideIcons.users, size: 16),
              label: const Text('Split this'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ]),
    ),
  );
}

void _confirmDelete(BuildContext context, WidgetRef ref, Transaction t) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete Transaction'),
      content: const Text('Are you sure you want to delete this transaction? This cannot be undone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            Navigator.of(ctx).pop();
            await ref.read(transactionRepositoryProvider).deleteTransaction(t.id);
            ref.invalidate(transactionsProvider);
            ref.invalidate(transactionsCountProvider);
            ref.invalidate(transactionsSummaryProvider);
          },
          child: Text('Delete', style: TextStyle(color: AppColors.error)),
        ),
      ],
    ),
  );
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme colorScheme;

  const _DetailRow({required this.label, required this.value, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        SizedBox(
          width: 90,
          child: Text(label, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
      ]),
    );
  }
}
