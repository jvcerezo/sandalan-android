/// Parses raw OCR text from a receipt into structured data.

class ParsedReceipt {
  final String? storeName;
  final double? totalAmount;
  final DateTime? date;
  final List<ReceiptLineItem> items;
  final String rawText;

  const ParsedReceipt({
    this.storeName,
    this.totalAmount,
    this.date,
    this.items = const [],
    required this.rawText,
  });
}

class ReceiptLineItem {
  final String name;
  final double? amount;

  const ReceiptLineItem({required this.name, this.amount});
}

class ReceiptParser {
  /// Parse raw OCR text into a structured receipt.
  static ParsedReceipt parse(String rawText) {
    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return ParsedReceipt(rawText: rawText);
    }

    final storeName = _extractStoreName(lines);
    final totalAmount = _extractTotalAmount(lines);
    final date = _extractDate(lines);
    final items = _extractLineItems(lines);

    return ParsedReceipt(
      storeName: storeName,
      totalAmount: totalAmount,
      date: date,
      items: items,
      rawText: rawText,
    );
  }

  /// Extract store name — usually the first 1-2 lines, often in caps.
  static String? _extractStoreName(List<String> lines) {
    // Skip lines that look like dates, amounts, or receipt metadata
    final skipPatterns = [
      RegExp(r'^\d{1,2}[/\-]\d{1,2}[/\-]\d{2,4}'),
      RegExp(r'^(official|or|si|tin|vat|non)', caseSensitive: false),
      RegExp(r'^\*+$'),
      RegExp(r'^-+$'),
      RegExp(r'^=+$'),
      RegExp(r'^\d+$'),
    ];

    final candidates = <String>[];

    for (var i = 0; i < lines.length && i < 5 && candidates.length < 2; i++) {
      final line = lines[i];
      if (line.length < 3) continue;
      if (skipPatterns.any((p) => p.hasMatch(line))) continue;

      // Skip lines that are mostly numbers/symbols
      final letterCount = line.replaceAll(RegExp(r'[^a-zA-Z]'), '').length;
      if (letterCount < line.length * 0.3) continue;

      candidates.add(line);
    }

    if (candidates.isEmpty) return null;

    // Return the first candidate, cleaned up
    var name = candidates.first;
    // Remove common suffixes like "INC", "CORP", "CO."
    name = name
        .replaceAll(RegExp(r'\s*(INC\.?|CORP\.?|CO\.?|LTD\.?)$', caseSensitive: false), '')
        .trim();

    return name.isEmpty ? null : name;
  }

  /// Extract total amount — look for keywords near numbers.
  static double? _extractTotalAmount(List<String> lines) {
    final totalKeywords = [
      'grand total',
      'total due',
      'total amount',
      'amount due',
      'amount tendered',
      'total',
      'net amount',
      'balance due',
      'amount payable',
    ];

    final amountPattern = RegExp(
      r'[₱P]?\s*(\d{1,3}(?:[,\s]\d{3})*(?:\.\d{1,2})?)',
    );

    double? bestAmount;
    int bestPriority = 999;

    for (final line in lines) {
      final lower = line.toLowerCase();

      for (var priority = 0; priority < totalKeywords.length; priority++) {
        if (lower.contains(totalKeywords[priority])) {
          // Found a total keyword — extract the amount on this line
          final match = amountPattern.firstMatch(line);
          if (match != null) {
            final amountStr = match.group(1)!.replaceAll(RegExp(r'[,\s]'), '');
            final amount = double.tryParse(amountStr);
            if (amount != null && amount > 0 && priority < bestPriority) {
              bestAmount = amount;
              bestPriority = priority;
            }
          }
          break;
        }
      }
    }

    // If no keyword-based match, look for the largest amount with ₱/P prefix
    if (bestAmount == null) {
      final pesoPattern = RegExp(r'[₱P]\s*(\d{1,3}(?:[,\s]\d{3})*(?:\.\d{1,2})?)');
      double largest = 0;
      for (final line in lines) {
        for (final match in pesoPattern.allMatches(line)) {
          final amountStr = match.group(1)!.replaceAll(RegExp(r'[,\s]'), '');
          final amount = double.tryParse(amountStr) ?? 0;
          if (amount > largest) largest = amount;
        }
      }
      if (largest > 0) bestAmount = largest;
    }

    return bestAmount;
  }

  /// Extract date from receipt text.
  static DateTime? _extractDate(List<String> lines) {
    // Common date patterns found on Filipino receipts
    final patterns = [
      // MM/DD/YYYY or MM-DD-YYYY
      RegExp(r'(\d{1,2})[/\-](\d{1,2})[/\-](\d{4})'),
      // YYYY-MM-DD
      RegExp(r'(\d{4})[/\-](\d{1,2})[/\-](\d{1,2})'),
      // Mon DD, YYYY (e.g., Mar 21, 2026)
      RegExp(
        r'(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+(\d{1,2}),?\s+(\d{4})',
        caseSensitive: false,
      ),
      // DD Mon YYYY (e.g., 21 Mar 2026)
      RegExp(
        r'(\d{1,2})\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+(\d{4})',
        caseSensitive: false,
      ),
    ];

    for (final line in lines) {
      // Pattern 1: MM/DD/YYYY
      var match = patterns[0].firstMatch(line);
      if (match != null) {
        final m = int.tryParse(match.group(1)!);
        final d = int.tryParse(match.group(2)!);
        final y = int.tryParse(match.group(3)!);
        if (m != null && d != null && y != null && _isValidDate(y, m, d)) {
          return DateTime(y, m, d);
        }
      }

      // Pattern 2: YYYY-MM-DD
      match = patterns[1].firstMatch(line);
      if (match != null) {
        final y = int.tryParse(match.group(1)!);
        final m = int.tryParse(match.group(2)!);
        final d = int.tryParse(match.group(3)!);
        if (y != null && m != null && d != null && _isValidDate(y, m, d)) {
          return DateTime(y, m, d);
        }
      }

      // Pattern 3: Mon DD, YYYY
      match = patterns[2].firstMatch(line);
      if (match != null) {
        final m = _monthFromAbbr(match.group(1)!);
        final d = int.tryParse(match.group(2)!);
        final y = int.tryParse(match.group(3)!);
        if (m != null && d != null && y != null && _isValidDate(y, m, d)) {
          return DateTime(y, m, d);
        }
      }

      // Pattern 4: DD Mon YYYY
      match = patterns[3].firstMatch(line);
      if (match != null) {
        final d = int.tryParse(match.group(1)!);
        final m = _monthFromAbbr(match.group(2)!);
        final y = int.tryParse(match.group(3)!);
        if (d != null && m != null && y != null && _isValidDate(y, m, d)) {
          return DateTime(y, m, d);
        }
      }
    }

    return null;
  }

  /// Extract line items with amounts.
  static List<ReceiptLineItem> _extractLineItems(List<String> lines) {
    final items = <ReceiptLineItem>[];
    final itemPattern = RegExp(
      r'^(.+?)\s+[₱P]?\s*(\d{1,3}(?:[,]\d{3})*(?:\.\d{1,2}))\s*$',
    );

    // Skip keywords that indicate totals, not items
    final skipKeywords = [
      'total', 'subtotal', 'sub total', 'vat', 'tax', 'discount',
      'change', 'cash', 'tendered', 'amount due', 'balance',
    ];

    for (final line in lines) {
      final match = itemPattern.firstMatch(line);
      if (match != null) {
        final name = match.group(1)!.trim();
        final lower = name.toLowerCase();
        if (skipKeywords.any((k) => lower.contains(k))) continue;
        if (name.length < 2) continue;

        final amountStr = match.group(2)!.replaceAll(',', '');
        final amount = double.tryParse(amountStr);
        items.add(ReceiptLineItem(name: name, amount: amount));
      }
    }

    return items;
  }

  static bool _isValidDate(int year, int month, int day) {
    if (month < 1 || month > 12) return false;
    if (day < 1 || day > 31) return false;
    if (year < 2000 || year > 2100) return false;
    return true;
  }

  static int? _monthFromAbbr(String abbr) {
    const months = {
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4,
      'may': 5, 'jun': 6, 'jul': 7, 'aug': 8,
      'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
    };
    return months[abbr.toLowerCase()];
  }
}
