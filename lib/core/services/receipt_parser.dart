/// Parses raw OCR text from a receipt into structured data.
/// Handles purchases, ATM withdrawals, bank transfers, bill payments,
/// and digital wallet transactions.

// ═══════════════════════════════════════════════════════════════════════
// RECEIPT TYPE
// ═══════════════════════════════════════════════════════════════════════

enum ReceiptType {
  purchase,
  atmWithdrawal,
  bankTransfer,
  billPayment,
  digitalWallet,
  unknown,
}

// ═══════════════════════════════════════════════════════════════════════
// DIGITAL WALLET SUB-TYPES
// ═══════════════════════════════════════════════════════════════════════

enum DigitalWalletAction {
  cashIn,
  cashOut,
  sendMoney,
  payQr,
  unknown,
}

// ═══════════════════════════════════════════════════════════════════════
// PARSED RECEIPT
// ═══════════════════════════════════════════════════════════════════════

class ParsedReceipt {
  final String? storeName;
  final double? totalAmount;
  final DateTime? date;
  final List<ReceiptLineItem> items;
  final String rawText;
  final ReceiptType receiptType;

  // ATM withdrawal fields
  final String? bankName;
  final String? maskedCardNumber;
  final double? availableBalance;

  // Bank transfer fields
  final String? sourceAccount;
  final String? destinationAccount;
  final String? transferType; // INSTAPAY, PESONET, etc.

  // Bill payment fields
  final String? billerName;
  final String? accountNumber;

  // Digital wallet fields
  final String? walletName; // GCash, Maya, etc.
  final DigitalWalletAction? walletAction;
  final String? merchantName;

  const ParsedReceipt({
    this.storeName,
    this.totalAmount,
    this.date,
    this.items = const [],
    required this.rawText,
    this.receiptType = ReceiptType.unknown,
    this.bankName,
    this.maskedCardNumber,
    this.availableBalance,
    this.sourceAccount,
    this.destinationAccount,
    this.transferType,
    this.billerName,
    this.accountNumber,
    this.walletName,
    this.walletAction,
    this.merchantName,
  });
}

class ReceiptLineItem {
  final String name;
  final double? amount;

  const ReceiptLineItem({required this.name, this.amount});
}

// ═══════════════════════════════════════════════════════════════════════
// KEYWORD MAPS
// ═══════════════════════════════════════════════════════════════════════

const _atmKeywords = [
  'withdrawal', 'cash withdrawal', 'atm withdrawal',
  'atm transaction', 'cash dispensed', 'withdraw',
];

const _bankTransferKeywords = [
  'fund transfer', 'funds transfer', 'online transfer',
  'instapay', 'pesonet', 'bank transfer', 'money transfer',
  'inter-bank', 'interbank',
];

const _billPaymentKeywords = [
  'bill payment', 'bills payment', 'payment for',
  'payment to', 'bills pay', 'pay bill',
];

const _digitalWalletKeywords = [
  'gcash', 'g-cash', 'maya', 'paymaya', 'pay maya',
  'grabpay', 'grab pay', 'coins.ph', 'shopeepay', 'shopee pay',
];

const _cashInKeywords = [
  'cash in', 'cash-in', 'cashin', 'top up', 'top-up',
  'load wallet', 'add money',
];

const _cashOutKeywords = [
  'cash out', 'cash-out', 'cashout', 'withdraw',
  'encash',
];

const _sendMoneyKeywords = [
  'send money', 'send to', 'transfer to', 'padala',
  'remittance', 'express send',
];

const _payQrKeywords = [
  'pay qr', 'qr payment', 'qr pay', 'scan to pay',
  'merchant payment', 'pay merchant',
];

const _bankNames = [
  'bdo', 'bdo unibank', 'bpi', 'bank of the philippine islands',
  'metrobank', 'metropolitan bank', 'landbank', 'land bank',
  'pnb', 'philippine national bank', 'unionbank', 'union bank',
  'rcbc', 'rizal commercial', 'chinabank', 'china bank',
  'securitybank', 'security bank', 'eastwest', 'east west',
  'psbank', 'ps bank', 'aub', 'asia united bank',
  'robinsons bank', 'cimb', 'ing', 'tonik', 'maya bank',
  'gotime', 'overseas filipino bank', 'dbp', 'development bank',
];

const _billerNames = [
  'meralco', 'manila electric',
  'maynilad', 'manila water',
  'pldt', 'smart', 'globe', 'converge', 'dito',
  'sky cable', 'skycable', 'cignal',
  'sss', 'philhealth', 'pag-ibig', 'pagibig', 'hdmf',
  'bpi credit', 'bdo credit', 'metrobank credit',
  'rcbc credit', 'unionbank credit', 'chinabank credit',
  'axa', 'sunlife', 'sun life', 'pru life', 'manulife',
  'insular life', 'bpi ms',
];

// ═══════════════════════════════════════════════════════════════════════
// RECEIPT PARSER
// ═══════════════════════════════════════════════════════════════════════

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

    final lower = rawText.toLowerCase();

    // Detect receipt type
    final receiptType = _detectReceiptType(lower);

    switch (receiptType) {
      case ReceiptType.atmWithdrawal:
        return _parseAtmWithdrawal(lines, lower, rawText);
      case ReceiptType.bankTransfer:
        return _parseBankTransfer(lines, lower, rawText);
      case ReceiptType.billPayment:
        return _parseBillPayment(lines, lower, rawText);
      case ReceiptType.digitalWallet:
        return _parseDigitalWallet(lines, lower, rawText);
      case ReceiptType.purchase:
      case ReceiptType.unknown:
        return _parsePurchase(lines, rawText);
    }
  }

  // ─── Receipt Type Detection ────────────────────────────────────────

  static ReceiptType _detectReceiptType(String lower) {
    // Check digital wallet FIRST (most specific)
    for (final kw in _digitalWalletKeywords) {
      if (lower.contains(kw)) return ReceiptType.digitalWallet;
    }

    // ATM withdrawal
    for (final kw in _atmKeywords) {
      if (lower.contains(kw)) return ReceiptType.atmWithdrawal;
    }

    // Bank transfer
    for (final kw in _bankTransferKeywords) {
      if (lower.contains(kw)) return ReceiptType.bankTransfer;
    }

    // Bill payment
    for (final kw in _billPaymentKeywords) {
      if (lower.contains(kw)) return ReceiptType.billPayment;
    }

    // Check for biller names without explicit "bill payment" keyword
    for (final biller in _billerNames) {
      if (lower.contains(biller)) {
        // If it also has payment-like context
        if (lower.contains('payment') ||
            lower.contains('bayad') ||
            lower.contains('paid') ||
            lower.contains('amount due') ||
            lower.contains('due date')) {
          return ReceiptType.billPayment;
        }
      }
    }

    // Default to purchase
    return ReceiptType.purchase;
  }

  // ─── ATM Withdrawal Parser ─────────────────────────────────────────

  static ParsedReceipt _parseAtmWithdrawal(
      List<String> lines, String lower, String rawText) {
    final bankName = _extractBankName(lower);
    final amount = _extractTotalAmount(lines);
    final date = _extractDate(lines);
    final maskedCard = _extractMaskedCard(lower);
    final balance = _extractAvailableBalance(lines);

    return ParsedReceipt(
      rawText: rawText,
      receiptType: ReceiptType.atmWithdrawal,
      bankName: bankName,
      totalAmount: amount,
      date: date,
      maskedCardNumber: maskedCard,
      availableBalance: balance,
      storeName: bankName != null ? '$bankName ATM' : 'ATM',
    );
  }

  // ─── Bank Transfer Parser ──────────────────────────────────────────

  static ParsedReceipt _parseBankTransfer(
      List<String> lines, String lower, String rawText) {
    final amount = _extractTotalAmount(lines);
    final date = _extractDate(lines);
    String? transferType;
    String? source;
    String? destination;

    // Detect transfer type
    if (lower.contains('instapay')) {
      transferType = 'InstaPay';
    } else if (lower.contains('pesonet')) {
      transferType = 'PESONet';
    } else {
      transferType = 'Fund Transfer';
    }

    // Try to extract source and destination
    source = _extractBankName(lower);

    // Look for "to" or "receiver" or "beneficiary" patterns
    final toPatterns = [
      RegExp(r'(?:to|receiver|beneficiary|recipient)\s*[:\-]?\s*(.+)',
          caseSensitive: false),
    ];
    for (final line in lines) {
      for (final pattern in toPatterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          destination = match.group(1)!.trim();
          if (destination.length > 50) {
            destination = destination.substring(0, 50);
          }
          break;
        }
      }
      if (destination != null) break;
    }

    // Look for "from" or "sender" patterns
    final fromPatterns = [
      RegExp(r'(?:from|sender|source)\s*[:\-]?\s*(.+)',
          caseSensitive: false),
    ];
    for (final line in lines) {
      for (final pattern in fromPatterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          final extracted = match.group(1)!.trim();
          if (extracted.length <= 50) {
            source = extracted;
          }
          break;
        }
      }
      if (source != null) break;
    }

    return ParsedReceipt(
      rawText: rawText,
      receiptType: ReceiptType.bankTransfer,
      totalAmount: amount,
      date: date,
      transferType: transferType,
      sourceAccount: source,
      destinationAccount: destination,
      storeName: transferType,
    );
  }

  // ─── Bill Payment Parser ───────────────────────────────────────────

  static ParsedReceipt _parseBillPayment(
      List<String> lines, String lower, String rawText) {
    final amount = _extractTotalAmount(lines);
    final date = _extractDate(lines);
    final billerName = _extractBillerName(lower);
    final accountNumber = _extractAccountNumber(lines);

    return ParsedReceipt(
      rawText: rawText,
      receiptType: ReceiptType.billPayment,
      totalAmount: amount,
      date: date,
      billerName: billerName,
      accountNumber: accountNumber,
      storeName: billerName,
    );
  }

  // ─── Digital Wallet Parser ─────────────────────────────────────────

  static ParsedReceipt _parseDigitalWallet(
      List<String> lines, String lower, String rawText) {
    final amount = _extractTotalAmount(lines);
    final date = _extractDate(lines);

    // Detect wallet
    String? walletName;
    if (lower.contains('gcash') || lower.contains('g-cash')) {
      walletName = 'GCash';
    } else if (lower.contains('maya') || lower.contains('paymaya')) {
      walletName = 'Maya';
    } else if (lower.contains('grabpay') || lower.contains('grab pay')) {
      walletName = 'GrabPay';
    } else if (lower.contains('shopeepay') || lower.contains('shopee pay')) {
      walletName = 'ShopeePay';
    } else if (lower.contains('coins.ph')) {
      walletName = 'Coins.ph';
    }

    // Detect action
    DigitalWalletAction action = DigitalWalletAction.unknown;
    for (final kw in _cashInKeywords) {
      if (lower.contains(kw)) {
        action = DigitalWalletAction.cashIn;
        break;
      }
    }
    if (action == DigitalWalletAction.unknown) {
      for (final kw in _cashOutKeywords) {
        if (lower.contains(kw)) {
          action = DigitalWalletAction.cashOut;
          break;
        }
      }
    }
    if (action == DigitalWalletAction.unknown) {
      for (final kw in _sendMoneyKeywords) {
        if (lower.contains(kw)) {
          action = DigitalWalletAction.sendMoney;
          break;
        }
      }
    }
    if (action == DigitalWalletAction.unknown) {
      for (final kw in _payQrKeywords) {
        if (lower.contains(kw)) {
          action = DigitalWalletAction.payQr;
          break;
        }
      }
    }

    // Extract merchant for Pay QR
    String? merchantName;
    if (action == DigitalWalletAction.payQr ||
        action == DigitalWalletAction.unknown) {
      final merchantPatterns = [
        RegExp(r'(?:merchant|paid to|store|shop)\s*[:\-]?\s*(.+)',
            caseSensitive: false),
      ];
      for (final line in lines) {
        for (final pattern in merchantPatterns) {
          final match = pattern.firstMatch(line);
          if (match != null) {
            merchantName = match.group(1)!.trim();
            if (merchantName!.length > 50) {
              merchantName = merchantName.substring(0, 50);
            }
            break;
          }
        }
        if (merchantName != null) break;
      }
    }

    // Build display name
    String? displayName;
    switch (action) {
      case DigitalWalletAction.cashIn:
        displayName = '${walletName ?? 'Wallet'} Cash In';
      case DigitalWalletAction.cashOut:
        displayName = '${walletName ?? 'Wallet'} Cash Out';
      case DigitalWalletAction.sendMoney:
        displayName = '${walletName ?? 'Wallet'} Send Money';
      case DigitalWalletAction.payQr:
        displayName = merchantName ?? '${walletName ?? 'Wallet'} Payment';
      case DigitalWalletAction.unknown:
        displayName = walletName ?? 'Digital Wallet';
    }

    return ParsedReceipt(
      rawText: rawText,
      receiptType: ReceiptType.digitalWallet,
      totalAmount: amount,
      date: date,
      walletName: walletName,
      walletAction: action,
      merchantName: merchantName,
      storeName: displayName,
    );
  }

  // ─── Purchase Parser (original logic) ──────────────────────────────

  static ParsedReceipt _parsePurchase(List<String> lines, String rawText) {
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
      receiptType: ReceiptType.purchase,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // EXTRACTION HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  /// Extract bank name from text.
  static String? _extractBankName(String lower) {
    // Check longer names first to avoid partial matches
    final sortedBanks = List<String>.from(_bankNames)
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final bank in sortedBanks) {
      if (lower.contains(bank)) {
        // Return properly capitalized version
        return _capitalizeBankName(bank);
      }
    }
    return null;
  }

  static String _capitalizeBankName(String bank) {
    const properNames = {
      'bdo': 'BDO',
      'bdo unibank': 'BDO',
      'bpi': 'BPI',
      'bank of the philippine islands': 'BPI',
      'metrobank': 'Metrobank',
      'metropolitan bank': 'Metrobank',
      'landbank': 'Landbank',
      'land bank': 'Landbank',
      'pnb': 'PNB',
      'philippine national bank': 'PNB',
      'unionbank': 'UnionBank',
      'union bank': 'UnionBank',
      'rcbc': 'RCBC',
      'rizal commercial': 'RCBC',
      'chinabank': 'ChinaBank',
      'china bank': 'ChinaBank',
      'securitybank': 'Security Bank',
      'security bank': 'Security Bank',
      'eastwest': 'EastWest',
      'east west': 'EastWest',
      'psbank': 'PSBank',
      'ps bank': 'PSBank',
      'aub': 'AUB',
      'asia united bank': 'AUB',
      'robinsons bank': 'Robinsons Bank',
      'cimb': 'CIMB',
      'ing': 'ING',
      'tonik': 'Tonik',
      'maya bank': 'Maya Bank',
      'gotime': 'GoTyme',
      'overseas filipino bank': 'OFBank',
      'dbp': 'DBP',
      'development bank': 'DBP',
    };
    return properNames[bank] ?? bank;
  }

  /// Extract masked card number (e.g., ****1234, *1234, XXXX1234).
  static String? _extractMaskedCard(String lower) {
    final patterns = [
      RegExp(r'[\*xX]{3,}\s*(\d{4})'),
      RegExp(r'card\s*(?:no|number|#)?\s*[:\-]?\s*[\*xX]*(\d{4})',
          caseSensitive: false),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(lower);
      if (match != null) {
        return '****${match.group(1)}';
      }
    }
    return null;
  }

  /// Extract available balance from ATM receipt.
  static double? _extractAvailableBalance(List<String> lines) {
    final balanceKeywords = [
      'available balance',
      'avail bal',
      'avail. bal',
      'remaining balance',
      'current balance',
      'balance',
    ];

    final amountPattern = RegExp(
      r'[₱P]?\s*(\d{1,3}(?:[,\s]\d{3})*(?:\.\d{1,2})?)',
    );

    for (final line in lines) {
      final lineLower = line.toLowerCase();
      for (final keyword in balanceKeywords) {
        if (lineLower.contains(keyword)) {
          final match = amountPattern.firstMatch(line);
          if (match != null) {
            final amountStr =
                match.group(1)!.replaceAll(RegExp(r'[,\s]'), '');
            return double.tryParse(amountStr);
          }
        }
      }
    }
    return null;
  }

  /// Extract biller name from bill payment receipt.
  static String? _extractBillerName(String lower) {
    final sortedBillers = List<String>.from(_billerNames)
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final biller in sortedBillers) {
      if (lower.contains(biller)) {
        return _capitalizeBillerName(biller);
      }
    }
    return null;
  }

  static String _capitalizeBillerName(String biller) {
    const properNames = {
      'meralco': 'Meralco',
      'manila electric': 'Meralco',
      'maynilad': 'Maynilad',
      'manila water': 'Manila Water',
      'pldt': 'PLDT',
      'smart': 'Smart',
      'globe': 'Globe',
      'converge': 'Converge',
      'dito': 'DITO',
      'sky cable': 'Sky Cable',
      'skycable': 'Sky Cable',
      'cignal': 'Cignal',
      'sss': 'SSS',
      'philhealth': 'PhilHealth',
      'pag-ibig': 'Pag-IBIG',
      'pagibig': 'Pag-IBIG',
      'hdmf': 'Pag-IBIG',
    };
    return properNames[biller] ?? biller;
  }

  /// Extract account/reference number from bill payment.
  static String? _extractAccountNumber(List<String> lines) {
    final patterns = [
      RegExp(
          r'(?:account|acct|ref|reference)\s*(?:no|number|#)?\s*[:\-]?\s*(\S+)',
          caseSensitive: false),
    ];
    for (final line in lines) {
      for (final pattern in patterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          return match.group(1);
        }
      }
    }
    return null;
  }

  /// Extract store name -- usually the first 1-2 lines, often in caps.
  static String? _extractStoreName(List<String> lines) {
    // Skip lines that look like dates, amounts, receipt metadata, or addresses
    final skipPatterns = [
      RegExp(r'^\d{1,2}[/\-]\d{1,2}[/\-]\d{2,4}'),
      RegExp(r'^(official|or |si |tin|vat|non-vat|receipt|invoice|pos|terminal|cashier|employee|date|time)', caseSensitive: false),
      RegExp(r'^\*+$'),
      RegExp(r'^-+$'),
      RegExp(r'^=+$'),
      RegExp(r'^\d+$'),
      RegExp(r'(city|province|brgy|barangay|ave|avenue|street|st\.|blvd|road|rd\.)', caseSensitive: false), // addresses
      RegExp(r'\d{4,}'), // phone numbers, TINs, reference numbers
    ];

    // First pass: try to match a known merchant name anywhere in the first 8 lines
    final allText = lines.take(8).join(' ').toLowerCase();
    // Known merchants — includes both trade names AND corporate names
    // (BIR requires the registered corporate name on receipts, which OCR reads)
    final knownMerchants = [
      // Fast food (trade name → corporate name)
      'jollibee', 'jollibee foods', 'mcdonalds', "mcdonald's", 'golden arches',
      'kfc', 'chowking', 'mang inasal', 'greenwich', 'pizza hut',
      'starbucks', 'tim hortons', 'bonchon', 'army navy', 'yellow cab',
      "shakey's", 'max\'s', 'goldilocks', 'red ribbon', 'burger king',
      'wendys', "wendy's", 'subway', 'kenny rogers', 'pancake house',
      'turks', 'potato corner', 'angels pizza',
      // Convenience stores
      'ministop', '7-eleven', '7 eleven', 'philippine seven',
      'family mart', 'familymart', 'alfamart',
      // Supermarkets/grocery
      'sm supermarket', 'sm hypermarket', 'sm retail', 'sm marketplace',
      'puregold', 'puregold price club', 'savemore', 'robinsons supermarket',
      'robinsons retail', 'waltermart', 'landers', 's&r', 'metro supermarket',
      'ever gotesco', 'metro gaisano', 'gaisano', 'nccc', 'shopwise',
      'rustans', "rustan's", 'landmark', 'south supermarket',
      // Pharmacy
      'mercury drug', 'watsons', 'southstar', 'generika', 'rose pharmacy',
      'the generics pharmacy', 'tgp',
      // Retail
      'national bookstore', 'fully booked', 'uniqlo', 'h&m', 'miniso',
      'daiso', 'handyman', 'ace hardware', 'true value', 'cdr king',
      // Gas stations
      'shell', 'pilipinas shell', 'petron', 'caltex', 'chevron',
      'seaoil', 'phoenix', 'total', 'flying v', 'ptt',
      // Utilities (bill payment receipts)
      'meralco', 'manila electric', 'maynilad', 'manila water',
      'pldt', 'globe', 'smart', 'converge', 'dito',
    ];
    for (final merchant in knownMerchants) {
      if (allText.contains(merchant)) {
        // Return properly capitalized
        return merchant.split(' ').map((w) =>
          w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w
        ).join(' ');
      }
    }

    // Second pass: collect candidate lines from the first 8 lines
    final candidates = <String>[];

    for (var i = 0; i < lines.length && i < 8 && candidates.length < 3; i++) {
      final line = lines[i].trim();
      if (line.length < 3) continue;
      if (skipPatterns.any((p) => p.hasMatch(line))) continue;

      // Skip lines that are mostly numbers/symbols
      final letterCount = line.replaceAll(RegExp(r'[^a-zA-Z]'), '').length;
      if (letterCount < line.length * 0.3) continue;

      // Skip lines that look like amounts
      if (RegExp(r'[₱P]\s*\d').hasMatch(line)) continue;

      candidates.add(line);
    }

    if (candidates.isEmpty) return null;

    // Pick the best candidate — prefer the longest text-heavy line (usually the store name)
    // But if a candidate has uppercase letters (store names are often in caps), prefer it
    String best = candidates.first;
    int bestScore = 0;
    for (final c in candidates) {
      int score = 0;
      final upper = c.replaceAll(RegExp(r'[^A-Z]'), '').length;
      final total = c.replaceAll(RegExp(r'[^a-zA-Z]'), '').length;
      if (total > 0 && upper / total > 0.5) score += 20; // mostly uppercase = likely store name
      score += c.length; // longer = more likely to be a name
      if (score > bestScore) {
        bestScore = score;
        best = c;
      }
    }

    // Clean up
    var name = best
        .replaceAll(RegExp(r'\s*(INC\.?|CORP\.?|CO\.?|LTD\.?|TCLB-POS|POS)$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // Title case if all caps
    if (name == name.toUpperCase() && name.length > 3) {
      name = name.split(' ').map((w) =>
        w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}' : w
      ).join(' ');
    }

    return name.isEmpty ? null : name;
  }

  /// Extract total amount -- look for keywords near numbers.
  static double? _extractTotalAmount(List<String> lines) {
    // Keywords that represent the ACTUAL COST (what you owe) — highest priority first
    // Based on BIR RR 10-2015 mandated receipt format for all PH establishments
    final totalKeywords = [
      'grand total',
      'total due',
      'total amount due',
      'total amount',
      'amount due',
      'balance due',
      'net amount',
      'amount payable',
      'sub total',
      'subtotal',
      'total',
    ];

    // Keywords that represent PAYMENT/TENDER (what customer paid) — EXCLUDE these
    final paymentKeywords = [
      'amount tendered',
      'amount paid',
      'cash tendered',
      'cash received',
      'cash peso',
      'tendered',
      'tender',
      'paid amount',
    ];

    // Keywords that represent CHANGE — EXCLUDE these too
    final changeKeywords = [
      'change',
      'change due',
      'your change',
    ];

    // Keywords from the VAT breakdown section — EXCLUDE these
    // These appear BEFORE the total on BIR-mandated receipts and show
    // sales breakdowns, not the amount owed
    final vatSectionKeywords = [
      'vatable sale',
      'vatable sales',
      'vat exempt',
      'vat-exempt',
      'zero rated',
      'zero-rated',
      'vat amount',
      'vat amt',
      '12% vat',
      'total sales', // gross sales, not payment total
      'sc disc',
      'sc discount',
      'pwd disc',
      'pwd discount',
      'senior citizen',
    ];

    // Match amounts: handles ₱125.00, P 1,234.56, 125.00, 125
    // Uses rightmost match on the line (amounts are usually right-aligned)
    final amountPattern = RegExp(
      r'[₱P]?\s*(\d{1,3}(?:[,\s]\d{3})*(?:\.\d{1,2})?)',
    );

    double? bestAmount;
    int bestPriority = 999;

    for (var lineIdx = 0; lineIdx < lines.length; lineIdx++) {
      final line = lines[lineIdx];
      final lower = line.toLowerCase().trim();

      // Skip lines with payment/tender/change keywords
      if (paymentKeywords.any((k) => lower.contains(k))) continue;
      if (changeKeywords.any((k) => lower.contains(k))) continue;
      // Skip VAT breakdown lines (appear before total on BIR receipts)
      if (vatSectionKeywords.any((k) => lower.contains(k))) continue;
      // Skip standalone "CASH" or "PAYMENT" lines (tender, not total)
      // but NOT lines like "CASH TOTAL" or "TOTAL CASH" which are totals
      if ((lower.startsWith('cash') || lower.startsWith('payment') || lower.startsWith('paid'))
          && !lower.contains('total') && !lower.contains('due') && !lower.contains('amount')) continue;

      for (var priority = 0;
          priority < totalKeywords.length;
          priority++) {
        if (lower.contains(totalKeywords[priority])) {
          // Clean the line: strip filler dots/dashes between keyword and amount
          // e.g. "TOTAL.............125.00" -> "TOTAL 125.00"
          // e.g. "TOTAL-----------125.00" -> "TOTAL 125.00"
          final cleaned = line.replaceAll(RegExp(r'[.]{2,}'), ' ')
                              .replaceAll(RegExp(r'[-]{2,}'), ' ')
                              .replaceAll(RegExp(r'[=]{2,}'), ' ')
                              .replaceAll(RegExp(r'[*]{2,}'), ' ');

          // Use the LAST (rightmost) amount on the line — totals are right-aligned
          double? lineAmount;
          for (final match in amountPattern.allMatches(cleaned)) {
            final amountStr = match.group(1)!.replaceAll(RegExp(r'[,\s]'), '');
            final amount = double.tryParse(amountStr);
            if (amount != null && amount > 0) {
              lineAmount = amount; // Keep overwriting — last match wins
            }
          }

          if (lineAmount != null && priority < bestPriority) {
            bestAmount = lineAmount;
            bestPriority = priority;
          } else if (lineAmount == null && lineIdx + 1 < lines.length) {
            // Amount might be on the NEXT line (common in grocery receipts)
            final nextLine = lines[lineIdx + 1];
            for (final match in amountPattern.allMatches(nextLine)) {
              final amountStr = match.group(1)!.replaceAll(RegExp(r'[,\s]'), '');
              final amount = double.tryParse(amountStr);
              if (amount != null && amount > 0 && priority < bestPriority) {
                bestAmount = amount;
                bestPriority = priority;
              }
            }
          }
          break;
        }
      }
    }

    // If no keyword-based match, look for the largest amount with peso prefix
    if (bestAmount == null) {
      final pesoPattern = RegExp(
          r'[₱P]\s*(\d{1,3}(?:[,\s]\d{3})*(?:\.\d{1,2})?)');
      double largest = 0;
      for (final line in lines) {
        for (final match in pesoPattern.allMatches(line)) {
          final amountStr =
              match.group(1)!.replaceAll(RegExp(r'[,\s]'), '');
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
      r'^(.+?)\s+[₱P]?\s*(\d{1,3}(?:[,]\d{3})*(?:\.\d{1,2})?)\s*$',
    );

    // Skip keywords that indicate totals, not items
    final skipKeywords = [
      'total',
      'subtotal',
      'sub total',
      'vat',
      'tax',
      'discount',
      'change',
      'cash',
      'tendered',
      'amount due',
      'balance',
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

  /// Get a user-friendly label for the receipt type.
  static String receiptTypeLabel(ReceiptType type) {
    switch (type) {
      case ReceiptType.purchase:
        return 'Purchase';
      case ReceiptType.atmWithdrawal:
        return 'ATM Withdrawal';
      case ReceiptType.bankTransfer:
        return 'Bank Transfer';
      case ReceiptType.billPayment:
        return 'Bill Payment';
      case ReceiptType.digitalWallet:
        return 'Digital Wallet';
      case ReceiptType.unknown:
        return 'Receipt';
    }
  }

  /// Whether this receipt type represents a transfer (not an expense).
  static bool isTransferType(ReceiptType type) {
    switch (type) {
      case ReceiptType.atmWithdrawal:
      case ReceiptType.bankTransfer:
        return true;
      case ReceiptType.digitalWallet:
        return true; // Could be transfer or expense, handled in UI
      case ReceiptType.purchase:
      case ReceiptType.billPayment:
      case ReceiptType.unknown:
        return false;
    }
  }
}
