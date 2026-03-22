import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/services/csv_export_service.dart';
import '../../../core/services/guest_mode_service.dart';
import '../../../data/local/app_database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Shows a bottom sheet for exporting transactions as CSV.
void showExportDialog(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _ExportSheet(),
  );
}

class _ExportSheet extends StatefulWidget {
  const _ExportSheet();

  @override
  State<_ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends State<_ExportSheet> {
  String _dateRange = 'all';
  int _txCount = 0;
  bool _loading = true;
  bool _exporting = false;

  String get _userId {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) return user.id;
    return GuestModeService.getGuestIdSync() ?? 'guest';
  }

  @override
  void initState() {
    super.initState();
    _updateCount();
  }

  DateTime? get _startDate {
    final now = DateTime.now();
    switch (_dateRange) {
      case 'month': return DateTime(now.year, now.month, 1);
      case '3months': return DateTime(now.year, now.month - 2, 1);
      default: return null;
    }
  }

  DateTime? get _endDate {
    final now = DateTime.now();
    switch (_dateRange) {
      case 'month':
      case '3months':
        return DateTime(now.year, now.month + 1, 0);
      default: return null;
    }
  }

  Future<void> _updateCount() async {
    setState(() => _loading = true);
    final count = await CsvExportService.getTransactionCount(
      db: AppDatabase.instance,
      userId: _userId,
      startDate: _startDate,
      endDate: _endDate,
    );
    if (mounted) setState(() { _txCount = count; _loading = false; });
  }

  Future<void> _export() async {
    setState(() => _exporting = true);
    final path = await CsvExportService.exportTransactions(
      db: AppDatabase.instance,
      userId: _userId,
      startDate: _startDate,
      endDate: _endDate,
    );
    if (!mounted) return;
    setState(() => _exporting = false);

    if (path != null) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Exported to:\n$path', style: const TextStyle(fontSize: 12)),
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Share',
          onPressed: () => Share.shareXFiles(
            [XFile(path)],
            text: 'My Sandalan transactions export',
          ),
        ),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Export failed. Please try again.'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
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
            borderRadius: BorderRadius.circular(2),
          ),
        )),

        Row(children: [
          const Text('Export Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Icon(LucideIcons.x, size: 20, color: colorScheme.onSurfaceVariant),
          ),
        ]),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Download your transactions as a CSV file',
              style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
        ),
        const SizedBox(height: 16),

        // Date range chips
        const Align(
          alignment: Alignment.centerLeft,
          child: Text('Date Range', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: [
          ChoiceChip(label: const Text('All Time', style: TextStyle(fontSize: 12)),
              selected: _dateRange == 'all',
              onSelected: (_) { setState(() => _dateRange = 'all'); _updateCount(); }),
          ChoiceChip(label: const Text('This Month', style: TextStyle(fontSize: 12)),
              selected: _dateRange == 'month',
              onSelected: (_) { setState(() => _dateRange = 'month'); _updateCount(); }),
          ChoiceChip(label: const Text('Last 3 Months', style: TextStyle(fontSize: 12)),
              selected: _dateRange == '3months',
              onSelected: (_) { setState(() => _dateRange = '3months'); _updateCount(); }),
        ]),
        const SizedBox(height: 12),

        // Format (just CSV for now)
        const Align(
          alignment: Alignment.centerLeft,
          child: Text('Format', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: [
          ChoiceChip(
            label: const Text('CSV', style: TextStyle(fontSize: 12)),
            selected: true,
            onSelected: (_) {},
          ),
        ]),
        const SizedBox(height: 12),

        // Transaction count
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _loading
              ? const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
              : Text('$_txCount transactions',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colorScheme.onSurfaceVariant)),
        ),
        const SizedBox(height: 16),

        // Export button
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _exporting || _txCount == 0 ? null : _export,
            icon: _exporting
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(LucideIcons.download, size: 16),
            label: Text(_exporting ? 'Exporting...' : 'Export CSV'),
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
        ),
      ]),
    );
  }
}
