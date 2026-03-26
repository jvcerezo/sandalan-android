import 'dart:io';
import '../constants/categories.dart';
import 'auto_categorize_service.dart';

/// Supported bank/wallet CSV formats.
enum ImportSource {
  sandalan,  // Our own export format
  gcash,     // GCash transaction history
  maya,      // Maya (PayMaya) transaction history
  bdo,       // BDO statement
  bpi,       // BPI statement
  metrobank, // Metrobank statement
  generic,   // Best-effort: date, description, amount columns
}

/// A single parsed transaction from CSV import.
class ImportedTransaction {
  final DateTime date;
  final String description;
  final double amount; // negative = expense, positive = income
  final String category;
  final String? reference;

  const ImportedTransaction({
    required this.date,
    required this.description,
    required this.amount,
    required this.category,
    this.reference,
  });
}

/// Result of parsing a CSV file.
class ImportResult {
  final ImportSource detectedSource;
  final List<ImportedTransaction> transactions;
  final int skippedRows;
  final List<String> warnings;

  const ImportResult({
    required this.detectedSource,
    required this.transactions,
    this.skippedRows = 0,
    this.warnings = const [],
  });
}

/// Parses CSV files from various Philippine bank/wallet formats.
class CsvImportService {
  CsvImportService._();

  /// Parse a CSV file and return structured transactions.
  static Future<ImportResult> parseFile(File file) async {
    final content = await file.readAsString();
    final lines = content.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    if (lines.isEmpty) {
      return const ImportResult(
        detectedSource: ImportSource.generic,
        transactions: [],
        warnings: ['File is empty'],
      );
    }

    // Detect source from header row
    final header = lines.first.toLowerCase();
    final source = _detectSource(header);

    switch (source) {
      case ImportSource.sandalan:
        return _parseSandalan(lines);
      case ImportSource.gcash:
        return _parseGCash(lines);
      case ImportSource.maya:
        return _parseMaya(lines);
      case ImportSource.bdo:
        return _parseBDO(lines);
      case ImportSource.bpi:
        return _parseBPI(lines);
      case ImportSource.metrobank:
        return _parseMetrobank(lines);
      case ImportSource.generic:
        return _parseGeneric(lines);
    }
  }

  static ImportSource _detectSource(String header) {
    if (header.contains('date') && header.contains('description') && header.contains('category') && header.contains('amount')) {
      return ImportSource.sandalan;
    }
    if (header.contains('reference no') && header.contains('type') && header.contains('gcash')) {
      return ImportSource.gcash;
    }
    if (header.contains('transaction') && header.contains('maya')) {
      return ImportSource.maya;
    }
    if (header.contains('posting date') && header.contains('bdo')) {
      return ImportSource.bdo;
    }
    if (header.contains('transaction date') && header.contains('bpi')) {
      return ImportSource.bpi;
    }
    if (header.contains('metrobank') || (header.contains('value date') && header.contains('check'))) {
      return ImportSource.metrobank;
    }
    return ImportSource.generic;
  }

  // ─── Sandalan's own CSV format ──────────────────────────────────────────

  static ImportResult _parseSandalan(List<String> lines) {
    final transactions = <ImportedTransaction>[];
    int skipped = 0;

    for (var i = 1; i < lines.length; i++) {
      try {
        final cols = _parseCsvLine(lines[i]);
        if (cols.length < 5) { skipped++; continue; }

        final date = _parseDate(cols[0]);
        if (date == null) { skipped++; continue; }

        final amount = double.tryParse(cols[3].replaceAll(',', ''));
        if (amount == null) { skipped++; continue; }

        transactions.add(ImportedTransaction(
          date: date,
          description: _sanitize(cols[1]),
          amount: amount,
          category: cols[2].isNotEmpty ? cols[2] : 'Other',
        ));
      } catch (_) { skipped++; }
    }

    return ImportResult(
      detectedSource: ImportSource.sandalan,
      transactions: transactions,
      skippedRows: skipped,
    );
  }

  // ─── GCash CSV format ───────────────────────────────────────────────────
  // Typical columns: Reference No., Date, Type, Amount, Description, Status

  static ImportResult _parseGCash(List<String> lines) {
    final transactions = <ImportedTransaction>[];
    int skipped = 0;

    for (var i = 1; i < lines.length; i++) {
      try {
        final cols = _parseCsvLine(lines[i]);
        if (cols.length < 5) { skipped++; continue; }

        final date = _parseDate(cols[1]);
        if (date == null) { skipped++; continue; }

        final amount = double.tryParse(cols[3].replaceAll(',', '').replaceAll('PHP', '').trim());
        if (amount == null || amount == 0) { skipped++; continue; }

        final type = cols[2].toLowerCase();
        final description = _sanitize(cols[4]);
        final isIncome = type.contains('receive') || type.contains('cash in') || type.contains('refund');
        final signedAmount = isIncome ? amount.abs() : -amount.abs();
        final category = AutoCategorizeService.suggest(description, isIncome: isIncome) ?? 'Other';

        transactions.add(ImportedTransaction(
          date: date,
          description: description,
          amount: signedAmount,
          category: category,
          reference: cols[0],
        ));
      } catch (_) { skipped++; }
    }

    return ImportResult(
      detectedSource: ImportSource.gcash,
      transactions: transactions,
      skippedRows: skipped,
    );
  }

  // ─── Maya CSV format ────────────────────────────────────────────────────

  static ImportResult _parseMaya(List<String> lines) {
    return _parseGCash(lines); // Maya uses a similar format to GCash
  }

  // ─── BDO CSV format ─────────────────────────────────────────────────────
  // Typical: Posting Date, Description, Debit, Credit, Running Balance

  static ImportResult _parseBDO(List<String> lines) {
    final transactions = <ImportedTransaction>[];
    int skipped = 0;

    for (var i = 1; i < lines.length; i++) {
      try {
        final cols = _parseCsvLine(lines[i]);
        if (cols.length < 4) { skipped++; continue; }

        final date = _parseDate(cols[0]);
        if (date == null) { skipped++; continue; }

        final description = _sanitize(cols[1]);
        final debit = double.tryParse(cols[2].replaceAll(',', '').trim());
        final credit = double.tryParse(cols[3].replaceAll(',', '').trim());

        double amount;
        bool isIncome;
        if (debit != null && debit > 0) {
          amount = -debit; // debit = money out
          isIncome = false;
        } else if (credit != null && credit > 0) {
          amount = credit; // credit = money in
          isIncome = true;
        } else {
          skipped++; continue;
        }

        final category = AutoCategorizeService.suggest(description, isIncome: isIncome) ?? 'Other';

        transactions.add(ImportedTransaction(
          date: date,
          description: description,
          amount: amount,
          category: category,
        ));
      } catch (_) { skipped++; }
    }

    return ImportResult(
      detectedSource: ImportSource.bdo,
      transactions: transactions,
      skippedRows: skipped,
    );
  }

  // ─── BPI CSV format ─────────────────────────────────────────────────────

  static ImportResult _parseBPI(List<String> lines) {
    return _parseBDO(lines); // BPI uses a similar Debit/Credit format
  }

  // ─── Metrobank CSV format ───────────────────────────────────────────────

  static ImportResult _parseMetrobank(List<String> lines) {
    return _parseBDO(lines); // Metrobank uses similar Debit/Credit columns
  }

  // ─── Generic CSV (best-effort) ──────────────────────────────────────────

  static ImportResult _parseGeneric(List<String> lines) {
    final transactions = <ImportedTransaction>[];
    int skipped = 0;
    final warnings = <String>[];

    // Try to detect column positions from header
    final headerCols = _parseCsvLine(lines.first).map((c) => c.toLowerCase()).toList();
    int dateCol = -1, descCol = -1, amountCol = -1, debitCol = -1, creditCol = -1;

    for (var i = 0; i < headerCols.length; i++) {
      final h = headerCols[i];
      if (dateCol == -1 && (h.contains('date') || h.contains('petsa'))) dateCol = i;
      if (descCol == -1 && (h.contains('desc') || h.contains('particular') || h.contains('memo') || h.contains('detail'))) descCol = i;
      if (amountCol == -1 && h.contains('amount') && !h.contains('debit') && !h.contains('credit')) amountCol = i;
      if (debitCol == -1 && (h.contains('debit') || h.contains('withdrawal'))) debitCol = i;
      if (creditCol == -1 && (h.contains('credit') || h.contains('deposit'))) creditCol = i;
    }

    if (dateCol == -1) {
      warnings.add('Could not find a date column. Tried: date, petsa');
      return ImportResult(detectedSource: ImportSource.generic, transactions: [], skippedRows: lines.length - 1, warnings: warnings);
    }
    if (amountCol == -1 && debitCol == -1) {
      warnings.add('Could not find an amount column. Tried: amount, debit, withdrawal');
      return ImportResult(detectedSource: ImportSource.generic, transactions: [], skippedRows: lines.length - 1, warnings: warnings);
    }

    for (var i = 1; i < lines.length; i++) {
      try {
        final cols = _parseCsvLine(lines[i]);
        final date = _parseDate(cols[dateCol]);
        if (date == null) { skipped++; continue; }

        final description = descCol >= 0 && descCol < cols.length ? _sanitize(cols[descCol]) : '';

        double amount;
        if (amountCol >= 0 && amountCol < cols.length) {
          amount = double.tryParse(cols[amountCol].replaceAll(',', '').trim()) ?? 0;
        } else {
          final debit = debitCol >= 0 && debitCol < cols.length
              ? double.tryParse(cols[debitCol].replaceAll(',', '').trim()) : null;
          final credit = creditCol >= 0 && creditCol < cols.length
              ? double.tryParse(cols[creditCol].replaceAll(',', '').trim()) : null;
          if (debit != null && debit > 0) {
            amount = -debit;
          } else if (credit != null && credit > 0) {
            amount = credit;
          } else {
            skipped++; continue;
          }
        }

        if (amount == 0) { skipped++; continue; }
        final isIncome = amount > 0;
        final category = AutoCategorizeService.suggest(description, isIncome: isIncome) ?? 'Other';

        transactions.add(ImportedTransaction(
          date: date,
          description: description,
          amount: amount,
          category: category,
        ));
      } catch (_) { skipped++; }
    }

    return ImportResult(
      detectedSource: ImportSource.generic,
      transactions: transactions,
      skippedRows: skipped,
      warnings: warnings,
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────────────

  /// Parse a CSV line respecting quoted fields.
  static List<String> _parseCsvLine(String line) {
    final result = <String>[];
    var current = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final c = line[i];
      if (c == '"') {
        inQuotes = !inQuotes;
      } else if (c == ',' && !inQuotes) {
        result.add(current.toString().trim());
        current = StringBuffer();
      } else {
        current.write(c);
      }
    }
    result.add(current.toString().trim());
    return result;
  }

  /// Try multiple date formats common in PH bank statements.
  static DateTime? _parseDate(String s) {
    final cleaned = s.trim().replaceAll('"', '');
    if (cleaned.isEmpty) return null;

    // ISO format: 2024-03-15
    final iso = DateTime.tryParse(cleaned);
    if (iso != null) return iso;

    // MM/DD/YYYY or M/D/YYYY
    final slashMatch = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(cleaned);
    if (slashMatch != null) {
      return DateTime.tryParse(
          '${slashMatch.group(3)}-${slashMatch.group(1)!.padLeft(2, '0')}-${slashMatch.group(2)!.padLeft(2, '0')}');
    }

    // DD-MMM-YYYY (e.g., 15-Mar-2024)
    final monthNames = {'jan': '01', 'feb': '02', 'mar': '03', 'apr': '04',
        'may': '05', 'jun': '06', 'jul': '07', 'aug': '08',
        'sep': '09', 'oct': '10', 'nov': '11', 'dec': '12'};
    final dmmyMatch = RegExp(r'^(\d{1,2})[-\s](\w{3})[-\s](\d{4})$').firstMatch(cleaned);
    if (dmmyMatch != null) {
      final month = monthNames[dmmyMatch.group(2)!.toLowerCase()];
      if (month != null) {
        return DateTime.tryParse(
            '${dmmyMatch.group(3)}-$month-${dmmyMatch.group(1)!.padLeft(2, '0')}');
      }
    }

    return null;
  }

  /// Sanitize imported description strings.
  static String _sanitize(String s) {
    var result = s.trim();
    result = result.replaceAll(RegExp(r'<[^>]*>'), '');
    result = result.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');
    if (result.length > 200) result = result.substring(0, 200);
    return result;
  }
}
