import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../data/models/chat_models.dart';

class ConfirmationCard extends StatefulWidget {
  final ParseResult parseResult;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final VoidCallback? onEditCategory;

  const ConfirmationCard({
    super.key,
    required this.parseResult,
    required this.onConfirm,
    required this.onCancel,
    this.onEditCategory,
  });

  @override
  State<ConfirmationCard> createState() => _ConfirmationCardState();
}

class _ConfirmationCardState extends State<ConfirmationCard> {
  String _status = 'pending'; // pending, confirmed, cancelled

  String _formatAmount(double amount) {
    if (amount == amount.roundToDouble()) {
      final str = amount.toInt().toString();
      final result = StringBuffer();
      for (var i = 0; i < str.length; i++) {
        if (i > 0 && (str.length - i) % 3 == 0) result.write(',');
        result.write(str[i]);
      }
      return result.toString();
    }
    return amount.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isIncome = widget.parseResult.isIncome;

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        child: Card(
          elevation: 0,
          color: cs.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      _status == 'confirmed'
                          ? LucideIcons.checkCircle2
                          : _status == 'cancelled'
                              ? LucideIcons.xCircle
                              : isIncome
                                  ? LucideIcons.trendingUp
                                  : LucideIcons.trendingDown,
                      size: 16,
                      color: _status == 'confirmed'
                          ? Colors.green
                          : _status == 'cancelled'
                              ? cs.onSurfaceVariant
                              : isIncome
                                  ? Colors.green
                                  : cs.error,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _status == 'confirmed'
                          ? '${isIncome ? "Income" : "Expense"} logged!'
                          : _status == 'cancelled'
                              ? 'Cancelled'
                              : 'Log this ${isIncome ? "income" : "expense"}?',
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _status == 'cancelled' ? cs.onSurfaceVariant : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Details
                Opacity(
                  opacity: _status == 'cancelled' ? 0.5 : 1.0,
                  child: Column(children: [
                    _DetailRow(label: 'Amount', value: 'PHP ${_formatAmount(widget.parseResult.amount ?? 0)}', cs: cs, tt: tt),
                    _DetailRow(label: 'Category', value: widget.parseResult.category ?? 'Unknown', cs: cs, tt: tt),
                    _DetailRow(label: 'Description', value: widget.parseResult.description ?? '-', cs: cs, tt: tt),
                    _DetailRow(label: 'Account', value: widget.parseResult.accountName ?? 'Default', cs: cs, tt: tt),
                    _DetailRow(label: 'Date', value: 'Today', cs: cs, tt: tt),
                  ]),
                ),

                const SizedBox(height: 14),

                // Buttons or status
                if (_status == 'pending')
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            setState(() => _status = 'confirmed');
                            widget.onConfirm();
                          },
                          child: const Text('Confirm'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () {
                          setState(() => _status = 'cancelled');
                          widget.onCancel();
                        },
                        child: const Text('Cancel'),
                      ),
                    ],
                  )
                else
                  Center(
                    child: Text(
                      _status == 'confirmed' ? '✓ Transaction saved' : '✗ Transaction cancelled',
                      style: TextStyle(
                        fontSize: 12,
                        color: _status == 'confirmed' ? Colors.green : cs.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme cs;
  final TextTheme tt;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.cs,
    required this.tt,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
