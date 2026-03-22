import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/local/app_database.dart';

/// Service to export transactions as CSV.
class CsvExportService {
  /// Export transactions to a CSV file.
  /// Returns the file path on success, or null on error.
  static Future<String?> exportTransactions({
    required AppDatabase db,
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Fetch transactions
      final rows = await db.getFilteredTransactions(
        userId,
        startDate: startDate?.toIso8601String().substring(0, 10),
        endDate: endDate?.toIso8601String().substring(0, 10),
        pageSize: 999999,
      );

      // Fetch accounts for name lookup
      final accounts = await db.getAllAccounts(userId);
      final accountMap = <String, String>{};
      for (final a in accounts) {
        accountMap[a['id'] as String] = a['name'] as String;
      }

      // Build CSV
      final buffer = StringBuffer();
      buffer.writeln('Date,Description,Category,Amount,Type,Account,Tags,Note');

      for (final row in rows) {
        final date = row['date'] as String? ?? '';
        final description = _escapeCsv(row['description'] as String? ?? '');
        final category = _escapeCsv(row['category'] as String? ?? '');
        final amount = (row['amount'] as num?)?.toDouble() ?? 0;
        final accountId = row['account_id'] as String?;
        final accountName = accountId != null ? _escapeCsv(accountMap[accountId] ?? 'Unknown') : '';
        final tagsStr = row['tags'] as String? ?? '';
        final tags = _escapeCsv(tagsStr);

        // Determine type
        final transferId = row['transfer_id'] as String?;
        String type;
        if (transferId != null) {
          type = 'Transfer';
        } else if (amount > 0) {
          type = 'Income';
        } else {
          type = 'Expense';
        }

        // Amount: negative for expenses, positive for income (as-is from DB)
        final amountStr = amount.toStringAsFixed(2);

        buffer.writeln('$date,$description,$category,$amountStr,$type,$accountName,$tags,');
      }

      // Save to file
      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final fileName = 'sandalan_transactions_$dateStr.csv';

      Directory? dir;
      if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Download');
        if (!await dir.exists()) {
          dir = await getApplicationDocumentsDirectory();
        }
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      final file = File('${dir.path}/$fileName');
      await file.writeAsString(buffer.toString());

      return file.path;
    } catch (e) {
      debugPrint('CSV export failed: $e');
      return null;
    }
  }

  /// Get the count of transactions matching the given filters.
  static Future<int> getTransactionCount({
    required AppDatabase db,
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return await db.getFilteredTransactionsCount(
        userId,
        startDate: startDate?.toIso8601String().substring(0, 10),
        endDate: endDate?.toIso8601String().substring(0, 10),
      );
    } catch (_) {
      return 0;
    }
  }

  /// Escape a value for CSV (handle commas, quotes, newlines).
  static String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
