import '../../data/models/chat_models.dart';
import '../../data/repositories/learned_keyword_repository.dart';
import '../constants/chat_dictionary.dart';
import '../constants/categories.dart';

/// Account info passed to the engine for account resolution.
class AccountInfo {
  final String id;
  final String name;
  final String type;
  const AccountInfo({required this.id, required this.name, required this.type});
}

/// Core NLP parsing engine. Stateless — all conversation state lives in ChatNotifier.
/// Takes raw user input and produces a ParseResult describing the intent.
class ChatEngine {
  final LearnedKeywordRepository _learnedRepo;
  final Future<List<AccountInfo>> Function() _getAccounts;

  ChatEngine(this._learnedRepo, this._getAccounts);

  /// Main entry point: parse raw user input into a structured result.
  Future<ParseResult> parse(String rawInput) async {
    // ─── 1. Sanitize ─────────────────────────────────────────────────
    final sanitized = _sanitize(rawInput);
    if (sanitized == null) {
      return const ParseResult(
        intent: ChatIntent.unknown,
        message: "Type a transaction like 'lunch 250' or ask me something like 'net worth ko'",
      );
    }

    final lower = sanitized.toLowerCase();

    // ─── 2. Check help ───────────────────────────────────────────────
    if (_isHelp(lower)) {
      return const ParseResult(
        intent: ChatIntent.help,
        message: "I can help you with:\n"
            "• Log expenses: 'lunch 250', 'grab 150 gcash'\n"
            "• Log income: 'salary 30k', 'freelance 5000'\n"
            "• Check net worth: 'net worth ko'\n"
            "• Check spending: 'gastos ko this month'\n"
            "• Check budgets: 'budget status'\n"
            "• Check goals: 'goal progress'\n"
            "• Check debts: 'utang ko'\n"
            "• Check bills: 'bayarin ko'",
      );
    }

    // ─── 3. Check negation ───────────────────────────────────────────
    final negationResult = _checkNegation(lower);
    if (negationResult != null) return negationResult;

    // ─── 4. Check libre ──────────────────────────────────────────────
    if (_containsWord(lower, 'libre')) {
      final amount = _extractSingleAmount(lower);
      if (amount != null) {
        return ParseResult(
          intent: ChatIntent.unknown,
          message: "Did you pay PHP ${_formatAmount(amount)}, or was it free?",
          ambiguousAmounts: [amount, 0],
        );
      }
      return const ParseResult(
        intent: ChatIntent.unknown,
        message: "Was it free? If not, how much was it?",
      );
    }

    // ─── 5. Check utang ──────────────────────────────────────────────
    if (_containsWord(lower, 'utang') && !_isQuery(lower)) {
      final amount = _extractSingleAmount(lower);
      if (amount != null) {
        return ParseResult(
          intent: ChatIntent.unknown,
          message: "PHP ${_formatAmount(amount)} — is this a new debt, a debt payment, or a regular expense?",
          amount: amount,
        );
      }
      // No amount = query about debts
      return const ParseResult(
        intent: ChatIntent.query,
        queryType: QueryType.debtSummary,
        message: '',
      );
    }

    // ─── 6. Query override ───────────────────────────────────────────
    final queryResult = _checkQuery(lower);
    if (queryResult != null) return queryResult;

    // ─── 7. Extract amount ───────────────────────────────────────────
    final amountExtraction = _extractAmount(lower);

    if (amountExtraction.amounts.isEmpty) {
      // No amount found — could be a query keyword or unrecognized
      final categoryFromKeyword = _resolveFromKeyword(lower);
      if (categoryFromKeyword != null) {
        return ParseResult(
          intent: ChatIntent.query,
          queryType: QueryType.spendingByCategory,
          queryCategory: categoryFromKeyword,
          message: '',
        );
      }
      return const ParseResult(
        intent: ChatIntent.unknown,
        message: "I need an amount. Try something like 'lunch 250' or ask 'gastos ko'",
      );
    }

    if (amountExtraction.amounts.length > 1) {
      return ParseResult(
        intent: ChatIntent.unknown,
        message: "I see multiple amounts. Which is the total?",
        ambiguousAmounts: amountExtraction.amounts,
      );
    }

    final amount = amountExtraction.amounts.first;

    // ─── 8. Validate amount ──────────────────────────────────────────
    if (amount < 1) {
      return const ParseResult(
        intent: ChatIntent.unknown,
        message: "Amount must be at least PHP 1",
      );
    }

    final needsConfirmation = amount > 100000;

    // ─── 9. Extract account ──────────────────────────────────────────
    final accounts = await _getAccounts();
    final accountMatch = _extractAccount(lower, accounts);

    // ─── 10. Build description ───────────────────────────────────────
    final description = _cleanDescription(
      sanitized,
      amountExtraction.matchedTokens,
      accountMatch?.matchedToken,
    );

    // Check transfer (two account names)
    if (accountMatch != null && accountMatch.isTransfer) {
      return const ParseResult(
        intent: ChatIntent.transfer,
        message: "For transfers, use the Transfer button in Accounts",
      );
    }

    // Empty description after cleanup
    if (description.isEmpty) {
      if (accountMatch != null) {
        return ParseResult(
          intent: ChatIntent.unknown,
          amount: amount,
          accountId: accountMatch.accountId,
          accountName: accountMatch.accountName,
          message: "PHP ${_formatAmount(amount)} from ${accountMatch.accountName}. What's it for?",
        );
      }
      return ParseResult(
        intent: ChatIntent.unknown,
        amount: amount,
        message: "PHP ${_formatAmount(amount)} for what?",
      );
    }

    // ─── 11. Check income vs expense ─────────────────────────────────
    final incomeCheck = _checkIncome(lower, description.toLowerCase());

    if (incomeCheck == _IncomeResult.ambiguous) {
      return ParseResult(
        intent: ChatIntent.unknown,
        amount: amount,
        description: description,
        accountId: accountMatch?.accountId,
        accountName: accountMatch?.accountName,
        message: "Is this income you received or an expense?",
      );
    }

    final isIncome = incomeCheck == _IncomeResult.income;

    // ─── 12. Resolve category ────────────────────────────────────────
    final categoryResult = await _resolveCategory(description.toLowerCase(), lower);

    final intent = isIncome ? ChatIntent.logIncome : ChatIntent.logExpense;

    return ParseResult(
      intent: intent,
      amount: _roundAmount(amount),
      category: categoryResult?.category,
      description: description,
      accountId: accountMatch?.accountId,
      accountName: accountMatch?.accountName,
      isIncome: isIncome,
      categorySource: categoryResult?.source,
      needsAmountConfirmation: needsConfirmation,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SANITIZE
  // ═══════════════════════════════════════════════════════════════════════

  String? _sanitize(String input) {
    var s = input.trim();
    // Collapse whitespace
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    if (s.isEmpty) return null;
    if (s.length > 200) return null;
    // Strip HTML tags
    s = s.replaceAll(RegExp(r'<[^>]*>'), '');
    // Strip control characters (keep basic unicode)
    s = s.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');
    // Check if only special characters remain
    final alphanumeric = s.replaceAll(RegExp(r'[^a-zA-Z0-9\u00C0-\u024F\u1700-\u171F]'), '');
    if (alphanumeric.isEmpty) return null;
    return s;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HELP
  // ═══════════════════════════════════════════════════════════════════════

  bool _isHelp(String lower) {
    for (final trigger in kHelpTriggers) {
      if (lower == trigger || lower.contains(trigger)) return true;
    }
    return false;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // NEGATION
  // ═══════════════════════════════════════════════════════════════════════

  ParseResult? _checkNegation(String lower) {
    final words = lower.split(' ');
    if (words.isEmpty) return null;

    // "hindi pa bayad X" → query about unpaid
    if (lower.contains('hindi pa bayad') || lower.contains('di pa bayad')) {
      return const ParseResult(
        intent: ChatIntent.query,
        queryType: QueryType.billsDue,
        message: '',
      );
    }

    // General negation + verb = not a transaction
    for (final neg in kNegationPrefixes) {
      if (words.first == neg && words.length > 1) {
        return const ParseResult(
          intent: ChatIntent.unknown,
          message: "Got it, no expense to log.",
        );
      }
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // QUERY DETECTION
  // ═══════════════════════════════════════════════════════════════════════

  bool _isQuery(String lower) {
    return _checkQuery(lower) != null;
  }

  ParseResult? _checkQuery(String lower) {
    // Question mark at end
    final hasQuestionMark = lower.endsWith('?');

    // Filipino question particle "ba"
    final hasBa = _endsWithParticle(lower);

    // Starts with query word
    final startsWithQuery = kQueryWords.any((q) => lower.startsWith(q));

    // Contains query keywords
    final hasQueryKeyword = kQueryWords.any((q) => _containsWord(lower, q));

    final isQuestionForm = hasQuestionMark || hasBa || startsWithQuery;

    if (!isQuestionForm && !hasQueryKeyword) return null;

    // Determine query type
    if (_containsAny(lower, ['net worth', 'networth', 'pera ko', 'total balance', 'total money'])) {
      return const ParseResult(intent: ChatIntent.query, queryType: QueryType.netWorth, message: '');
    }
    if (_containsAny(lower, ['budget', 'over budget'])) {
      return const ParseResult(intent: ChatIntent.query, queryType: QueryType.budgetStatus, message: '');
    }
    if (_containsAny(lower, ['goal', 'goals', 'savings progress', 'ipon'])) {
      return const ParseResult(intent: ChatIntent.query, queryType: QueryType.goalProgress, message: '');
    }
    if (_containsAny(lower, ['utang', 'debt', 'debts', 'owe', 'naiutang'])) {
      return const ParseResult(intent: ChatIntent.query, queryType: QueryType.debtSummary, message: '');
    }
    if (_containsAny(lower, ['bill', 'bills', 'bayarin', 'due'])) {
      return const ParseResult(intent: ChatIntent.query, queryType: QueryType.billsDue, message: '');
    }
    if (_containsAny(lower, ['recent', 'last', 'history', 'huling'])) {
      return const ParseResult(intent: ChatIntent.query, queryType: QueryType.recentTransactions, message: '');
    }

    // Check for specific category spending query
    for (final cat in kCategories) {
      if (_containsWord(lower, cat.toLowerCase())) {
        return ParseResult(
          intent: ChatIntent.query,
          queryType: QueryType.spendingByCategory,
          queryCategory: cat,
          message: '',
        );
      }
    }

    // Check dictionary keywords for category-specific queries
    if (isQuestionForm) {
      final catFromDict = _resolveFromKeyword(lower);
      if (catFromDict != null) {
        return ParseResult(
          intent: ChatIntent.query,
          queryType: QueryType.spendingByCategory,
          queryCategory: catFromDict,
          message: '',
        );
      }
    }

    // Generic spending query
    if (_containsAny(lower, ['gastos', 'ginastos', 'nagastos', 'spent', 'spending', 'expenses'])) {
      return const ParseResult(intent: ChatIntent.query, queryType: QueryType.spendingSummary, message: '');
    }

    // If it's a question but we can't determine the type, show summary
    if (isQuestionForm) {
      return const ParseResult(intent: ChatIntent.query, queryType: QueryType.spendingSummary, message: '');
    }

    return null;
  }

  bool _endsWithParticle(String lower) {
    for (final particle in kQuestionParticles) {
      if (lower.endsWith(' $particle') || lower.endsWith(' $particle?')) return true;
    }
    return false;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // AMOUNT EXTRACTION
  // ═══════════════════════════════════════════════════════════════════════

  _AmountExtraction _extractAmount(String lower) {
    final tokens = lower.split(' ');
    final amounts = <double>[];
    final matchedTokens = <String>[];

    // Phase 1: Check peso-prefixed amounts first (highest priority)
    final pesoMatch = kPesoPrefix.firstMatch(lower);
    if (pesoMatch != null) {
      final numStr = pesoMatch.group(1)!.replaceAll(',', '');
      final val = double.tryParse(numStr);
      if (val != null) {
        return _AmountExtraction([val], [pesoMatch.group(0)!]);
      }
    }

    // Phase 2: Filter out brand names, promo patterns, date-adjacent numbers
    final filteredTokens = <_TokenInfo>[];
    for (var i = 0; i < tokens.length; i++) {
      final token = tokens[i];

      // Skip brand names
      if (_isBrandToken(token, tokens, i)) continue;

      // Skip promo pattern numbers
      if (_isPromoNumber(token, lower)) continue;

      // Check K suffix: 30k, 1.5K
      final kMatch = kAmountKSuffix.firstMatch(token);
      if (kMatch != null) {
        final base = double.tryParse(kMatch.group(1)!);
        if (base != null) {
          filteredTokens.add(_TokenInfo(token, base * 1000, i));
          continue;
        }
      }

      // Plain number
      final cleaned = token.replaceAll(',', '');
      if (kPlainNumber.hasMatch(cleaned)) {
        final val = double.tryParse(cleaned);
        if (val != null) {
          // Skip if date-adjacent
          if (_isDateAdjacent(tokens, i)) continue;
          // Skip if quantity-marked
          if (_isQuantityMarked(tokens, i, val)) continue;

          filteredTokens.add(_TokenInfo(token, val, i));
        }
      }
    }

    if (filteredTokens.isEmpty) {
      return _AmountExtraction([], []);
    }

    if (filteredTokens.length == 1) {
      return _AmountExtraction(
        [filteredTokens.first.value],
        [filteredTokens.first.token],
      );
    }

    // Two numbers: apply heuristics
    if (filteredTokens.length == 2) {
      final a = filteredTokens[0];
      final b = filteredTokens[1];

      // If one is ≤ 10 and other > 10, smaller is likely quantity
      if (a.value <= 10 && b.value > 10) {
        return _AmountExtraction([b.value], [b.token]);
      }
      if (b.value <= 10 && a.value > 10) {
        return _AmountExtraction([a.value], [a.token]);
      }

      // Ambiguous — return both for user to pick
      return _AmountExtraction(
        [a.value, b.value],
        [a.token, b.token],
      );
    }

    // 3+ numbers — too ambiguous
    return _AmountExtraction(
      filteredTokens.map((t) => t.value).toList(),
      filteredTokens.map((t) => t.token).toList(),
    );
  }

  /// Quick single-amount extraction (for libre/utang checks).
  double? _extractSingleAmount(String lower) {
    final result = _extractAmount(lower);
    if (result.amounts.length == 1) return result.amounts.first;
    return null;
  }

  bool _isBrandToken(String token, List<String> tokens, int index) {
    final lowerToken = token.toLowerCase();
    // Check exact brand match
    if (kBrandFilter.contains(lowerToken)) return true;
    // Check combined with adjacent token (e.g., "7" "eleven")
    if (index < tokens.length - 1) {
      final combined = '$lowerToken${tokens[index + 1]}';
      if (kBrandFilter.contains(combined)) return true;
    }
    return false;
  }

  bool _isPromoNumber(String token, String fullInput) {
    for (final pattern in kPromoPatterns) {
      final match = pattern.firstMatch(fullInput);
      if (match != null && match.group(0)!.contains(token)) return true;
    }
    return false;
  }

  bool _isDateAdjacent(List<String> tokens, int index) {
    // Check token before and after for month names
    if (index > 0 && kMonthNames.contains(tokens[index - 1].toLowerCase())) return true;
    if (index < tokens.length - 1 && kMonthNames.contains(tokens[index + 1].toLowerCase())) return true;
    return false;
  }

  bool _isQuantityMarked(List<String> tokens, int index, double value) {
    // Check if next or previous token is a quantity marker
    if (index < tokens.length - 1) {
      final next = tokens[index + 1].toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
      if (kQuantityMarkers.contains(next)) return true;
    }
    if (index > 0) {
      final prev = tokens[index - 1].toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
      if (kQuantityMarkers.contains(prev)) return true;
      // "2x" pattern: "2x grab 75"
      if (prev.endsWith('x') && prev.length > 1) {
        final numPart = prev.substring(0, prev.length - 1);
        if (double.tryParse(numPart) != null) return true;
      }
    }
    // Token itself is "2x", "3x"
    if (RegExp(r'^\d+x$', caseSensitive: false).hasMatch(tokens[index])) return true;
    return false;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ACCOUNT EXTRACTION
  // ═══════════════════════════════════════════════════════════════════════

  _AccountMatch? _extractAccount(String lower, List<AccountInfo> accounts) {
    if (accounts.isEmpty) return null;

    final matches = <_AccountMatchInfo>[];

    for (final account in accounts) {
      final accLower = account.name.toLowerCase();
      if (_containsWord(lower, accLower) || lower.contains(accLower)) {
        matches.add(_AccountMatchInfo(account.id, account.name, accLower));
      }
    }

    if (matches.isEmpty) {
      // Use first non-archived account as default
      return _AccountMatch(accounts.first.id, accounts.first.name, null, false);
    }

    if (matches.length == 1) {
      return _AccountMatch(matches.first.id, matches.first.name, matches.first.matchedToken, false);
    }

    // Two account names — check for transfer pattern
    if (matches.length == 2) {
      for (final tw in kTransferWords) {
        if (_containsWord(lower, tw)) {
          return _AccountMatch(matches.first.id, matches.first.name, matches.first.matchedToken, true);
        }
      }
      // No transfer word — ambiguous, use first match
      return _AccountMatch(matches.first.id, matches.first.name, matches.first.matchedToken, false);
    }

    // Multiple matches — use first
    return _AccountMatch(matches.first.id, matches.first.name, matches.first.matchedToken, false);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // DESCRIPTION CLEANUP
  // ═══════════════════════════════════════════════════════════════════════

  String _cleanDescription(String original, List<String> amountTokens, String? accountToken) {
    var words = original.split(' ');

    // Remove amount tokens
    for (final at in amountTokens) {
      words = words.where((w) => w.toLowerCase() != at.toLowerCase()).toList();
    }

    // Remove peso signs
    words = words.where((w) => !RegExp(r'^[₱Pp][Hh]?[Pp]?$').hasMatch(w)).toList();

    // Remove account token
    if (accountToken != null) {
      words = words.where((w) => w.toLowerCase() != accountToken.toLowerCase()).toList();
    }

    // Remove filler words
    words = words.where((w) => !kFillerWords.contains(w.toLowerCase())).toList();

    // Remove question particles
    words = words.where((w) => !kQuestionParticles.contains(w.toLowerCase().replaceAll('?', ''))).toList();

    // Strip dangling prepositions at start/end
    while (words.isNotEmpty && kDanglingPrepositions.contains(words.first.toLowerCase())) {
      words.removeAt(0);
    }
    while (words.isNotEmpty && kDanglingPrepositions.contains(words.last.toLowerCase())) {
      words.removeLast();
    }

    // Remove trailing question mark
    var result = words.join(' ').replaceAll(RegExp(r'\?+$'), '').trim();

    // Truncate to 100 chars
    if (result.length > 100) result = result.substring(0, 100);

    // Capitalize first letter
    if (result.isNotEmpty) {
      result = result[0].toUpperCase() + result.substring(1);
    }

    return result;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // INCOME CHECK
  // ═══════════════════════════════════════════════════════════════════════

  _IncomeResult _checkIncome(String lower, String descLower) {
    // Check unambiguous income keywords
    for (final kw in kIncomeKeywords) {
      if (_containsWord(lower, kw)) return _IncomeResult.income;
    }

    // "binigay sa akin" / "natanggap" = income
    if (lower.contains('sa akin') || lower.contains('natanggap') || lower.contains('tinanggap')) {
      return _IncomeResult.income;
    }

    // Check ambiguous
    for (final kw in kAmbiguousIncomeKeywords) {
      if (_containsWord(lower, kw)) return _IncomeResult.ambiguous;
    }

    // Default: expense
    return _IncomeResult.expense;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CATEGORY RESOLUTION
  // ═══════════════════════════════════════════════════════════════════════

  Future<_CategoryResult?> _resolveCategory(String descLower, String fullLower) async {
    // 1. Compound patterns (longest match first)
    for (final (pattern, category) in kCompoundPatterns) {
      if (fullLower.contains(pattern) || descLower.contains(pattern)) {
        return _CategoryResult(category, 'compound');
      }
    }

    // 2. "pang-" prefix stripping
    final words = descLower.split(' ');
    for (final word in words) {
      final pangMatch = kPangPrefix.firstMatch(word);
      if (pangMatch != null) {
        final root = pangMatch.group(1)!;
        // Check root in dictionary
        final cat = kCategoryDictionary[root];
        if (cat != null) return _CategoryResult(cat, 'dictionary');
      }
    }

    // 3. Filipino verb map
    for (final word in words) {
      final verbCat = kVerbCategories[word];
      if (verbCat != null) {
        // If there's also a noun keyword, noun wins (more specific)
        final nounCat = _resolveFromKeyword(descLower);
        if (nounCat != null && nounCat != verbCat) {
          return _CategoryResult(nounCat, 'dictionary');
        }
        return _CategoryResult(verbCat, 'verb');
      }
    }

    // 4. Learned keywords (user corrections > user picks)
    for (final word in words) {
      final learnedCat = await _learnedRepo.getCategoryForKeyword(word);
      if (learnedCat != null) return _CategoryResult(learnedCat, 'learned');
    }
    // Also check multi-word learned keywords
    final learnedCat = await _learnedRepo.getCategoryForKeyword(descLower);
    if (learnedCat != null) return _CategoryResult(learnedCat, 'learned');

    // 5. Built-in dictionary with conflict resolution
    final dictResult = _resolveDictionaryWithConflicts(descLower, fullLower);
    if (dictResult != null) return _CategoryResult(dictResult, 'dictionary');

    // 6. No match — return null (caller will ask user)
    return null;
  }

  /// Look up a single keyword in the dictionary (used for query detection).
  String? _resolveFromKeyword(String lower) {
    final words = lower.split(' ');
    for (final word in words) {
      final cat = kCategoryDictionary[word];
      if (cat != null) return cat;
    }
    return null;
  }

  /// Dictionary lookup with conflict resolution when multiple keywords
  /// match different categories.
  String? _resolveDictionaryWithConflicts(String descLower, String fullLower) {
    final categoryCounts = <String, int>{};
    final categoryLastIndex = <String, int>{};
    final words = fullLower.split(' ');

    for (var i = 0; i < words.length; i++) {
      final word = words[i];
      final cat = kCategoryDictionary[word];
      if (cat != null) {
        categoryCounts[cat] = (categoryCounts[cat] ?? 0) + 1;
        categoryLastIndex[cat] = i;
      }
    }

    if (categoryCounts.isEmpty) return null;
    if (categoryCounts.length == 1) return categoryCounts.keys.first;

    // Multiple categories matched — resolve conflicts
    // 1. Most matches wins
    final maxCount = categoryCounts.values.reduce((a, b) => a > b ? a : b);
    final topCats = categoryCounts.entries.where((e) => e.value == maxCount).map((e) => e.key).toList();
    if (topCats.length == 1) return topCats.first;

    // 2. Tied — last keyword position wins
    String? winner;
    int maxIdx = -1;
    for (final cat in topCats) {
      final idx = categoryLastIndex[cat] ?? -1;
      if (idx > maxIdx) {
        maxIdx = idx;
        winner = cat;
      }
    }
    return winner;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  bool _containsWord(String text, String word) {
    return RegExp('\\b${RegExp.escape(word)}\\b', caseSensitive: false).hasMatch(text);
  }

  bool _containsAny(String text, List<String> words) {
    return words.any((w) => text.contains(w));
  }

  double _roundAmount(double amount) {
    return (amount * 100).roundToDouble() / 100;
  }

  String _formatAmount(double amount) {
    if (amount == amount.roundToDouble()) {
      return amount.toInt().toString();
    }
    return amount.toStringAsFixed(2);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// INTERNAL TYPES
// ═══════════════════════════════════════════════════════════════════════

class _AmountExtraction {
  final List<double> amounts;
  final List<String> matchedTokens;
  _AmountExtraction(this.amounts, this.matchedTokens);
}

class _TokenInfo {
  final String token;
  final double value;
  final int index;
  _TokenInfo(this.token, this.value, this.index);
}

class _AccountMatch {
  final String accountId;
  final String accountName;
  final String? matchedToken;
  final bool isTransfer;
  _AccountMatch(this.accountId, this.accountName, this.matchedToken, this.isTransfer);
}

class _AccountMatchInfo {
  final String id;
  final String name;
  final String matchedToken;
  _AccountMatchInfo(this.id, this.name, this.matchedToken);
}

class _CategoryResult {
  final String category;
  final String source;
  _CategoryResult(this.category, this.source);
}

enum _IncomeResult { income, expense, ambiguous }
