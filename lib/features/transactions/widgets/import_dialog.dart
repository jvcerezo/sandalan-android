import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/services/csv_import_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/provider_utils.dart';
import '../../../data/repositories/local_transaction_repository.dart';
import '../../../data/local/app_database.dart';
import '../../../shared/utils/snackbar_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../accounts/providers/account_providers.dart';

/// Shows the import transactions bottom sheet.
void showImportDialog(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _ImportSheet(),
  );
}

class _ImportSheet extends ConsumerStatefulWidget {
  const _ImportSheet();

  @override
  ConsumerState<_ImportSheet> createState() => _ImportSheetState();
}

class _ImportSheetState extends ConsumerState<_ImportSheet> {
  ImportResult? _result;
  bool _picking = false;
  bool _importing = false;
  String? _selectedAccountId;
  final Set<int> _deselected = {};

  Future<void> _pickFile() async {
    setState(() => _picking = true);
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
      );
      if (picked != null && picked.files.single.path != null) {
        final file = File(picked.files.single.path!);
        final result = await CsvImportService.parseFile(file);
        setState(() => _result = result);
      }
    } catch (e) {
      if (mounted) showAppSnackBar(context, 'Error reading file: $e', isError: true);
    }
    setState(() => _picking = false);
  }

  Future<void> _importTransactions() async {
    if (_result == null || _selectedAccountId == null) return;
    setState(() => _importing = true);

    try {
      final repo = LocalTransactionRepository(
        AppDatabase.instance,
        Supabase.instance.client,
      );

      int imported = 0;
      for (var i = 0; i < _result!.transactions.length; i++) {
        if (_deselected.contains(i)) continue;
        final t = _result!.transactions[i];

        await repo.createTransaction(
          amount: t.amount,
          category: t.category,
          description: t.description,
          date: t.date,
          accountId: _selectedAccountId!,
        );
        imported++;
      }

      invalidateTransactionProviders(ref);

      if (mounted) {
        showSuccessSnackBar(context, '$imported transactions imported!');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) showAppSnackBar(context, 'Import failed: $e', isError: true);
    }
    setState(() => _importing = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accounts = ref.watch(accountsProvider).valueOrNull ?? [];

    // Auto-select first account
    if (_selectedAccountId == null && accounts.isNotEmpty) {
      _selectedAccountId = accounts.first.id;
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: cs.onSurfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(children: [
              Icon(LucideIcons.upload, size: 20, color: cs.primary),
              const SizedBox(width: 8),
              const Expanded(child: Text('Import Transactions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              if (_result != null)
                GestureDetector(
                  onTap: () => setState(() { _result = null; _deselected.clear(); }),
                  child: Text('Clear', style: TextStyle(fontSize: 13, color: cs.primary)),
                ),
            ]),
          ),

          if (_result == null) ...[
            // Pick file
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(children: [
                Text('Import transactions from GCash, Maya, BDO, BPI, Metrobank, or any CSV file.',
                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _picking ? null : _pickFile,
                    icon: _picking
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(LucideIcons.file, size: 16),
                    label: Text(_picking ? 'Reading...' : 'Choose CSV File'),
                  ),
                ),
                const SizedBox(height: 8),
                Text('Supported: .csv, .txt',
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant.withOpacity(0.5))),
                const SizedBox(height: 20),
              ]),
            ),
          ] else ...[
            // Preview results
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Source badge
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(_sourceLabel(_result!.detectedSource),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.primary)),
                  ),
                  const SizedBox(width: 8),
                  Text('${_result!.transactions.length} transactions found',
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  if (_result!.skippedRows > 0) ...[
                    const SizedBox(width: 8),
                    Text('(${_result!.skippedRows} skipped)',
                        style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant.withOpacity(0.5))),
                  ],
                ]),
                const SizedBox(height: 12),

                // Account selector
                Text('Import to account:', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedAccountId,
                  decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                  items: accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (v) => setState(() => _selectedAccountId = v),
                ),
                const SizedBox(height: 12),

                // Warnings
                for (final w in _result!.warnings)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(children: [
                      Icon(LucideIcons.alertTriangle, size: 14, color: cs.error),
                      const SizedBox(width: 6),
                      Expanded(child: Text(w, style: TextStyle(fontSize: 12, color: cs.error))),
                    ]),
                  ),
              ]),
            ),

            // Transaction list
            if (_result!.transactions.isNotEmpty)
              Flexible(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  shrinkWrap: true,
                  itemCount: _result!.transactions.length,
                  itemBuilder: (ctx, i) {
                    final t = _result!.transactions[i];
                    final selected = !_deselected.contains(i);
                    return GestureDetector(
                      onTap: () => setState(() {
                        if (selected) { _deselected.add(i); } else { _deselected.remove(i); }
                      }),
                      child: Opacity(
                        opacity: selected ? 1.0 : 0.4,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(children: [
                            Icon(selected ? LucideIcons.checkCircle2 : LucideIcons.circle,
                                size: 18, color: selected ? cs.primary : cs.onSurfaceVariant),
                            const SizedBox(width: 10),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(t.description.isEmpty ? t.category : t.description,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text('${formatDate(t.date)} · ${t.category}',
                                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                            ])),
                            Text(formatCurrency(t.amount),
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                                    color: t.amount >= 0 ? const Color(0xFF16A34A) : cs.onSurface)),
                          ]),
                        ),
                      ),
                    );
                  },
                ),
              ),

            // Import button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _importing || _selectedAccountId == null || _result!.transactions.isEmpty
                      ? null
                      : _importTransactions,
                  child: _importing
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text('Import ${_result!.transactions.length - _deselected.length} Transactions'),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _sourceLabel(ImportSource source) {
    switch (source) {
      case ImportSource.sandalan: return 'Sandalan';
      case ImportSource.gcash: return 'GCash';
      case ImportSource.maya: return 'Maya';
      case ImportSource.bdo: return 'BDO';
      case ImportSource.bpi: return 'BPI';
      case ImportSource.metrobank: return 'Metrobank';
      case ImportSource.generic: return 'CSV';
    }
  }
}
