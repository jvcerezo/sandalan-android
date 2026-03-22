import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../../data/chat/personality_templates.dart';
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

  // Personality state (loaded from SharedPreferences)
  AiPersonality _personality = AiPersonality.chillBestFriend;
  String _assistantName = 'Sandalan AI';
  bool _personalityLoaded = false;

  // Session context for "add another one" style inputs
  ChatIntent? _lastIntent;
  String? _lastCategory;
  String? _lastAccountId;

  ChatEngine(this._learnedRepo, this._getAccounts);

  /// Reset session context (call on user change to prevent state leaks).
  void clearSessionContext() {
    _lastIntent = null;
    _lastCategory = null;
    _lastAccountId = null;
  }

  /// Force personality to reload from SharedPreferences on next parse.
  void reloadPersonality() {
    _personalityLoaded = false;
  }

  /// Load personality from SharedPreferences.
  Future<void> _ensurePersonalityLoaded() async {
    if (_personalityLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = prefs.getString('ai_personality') ?? 'chill_best_friend';
      _personality = AiPersonalityX.fromKey(key);
      _assistantName = prefs.getString('ai_assistant_name') ?? 'Sandalan AI';
    } catch (_) {
      // Fallback to defaults on error
    }
    _personalityLoaded = true;
  }

  /// Get a personality-flavored response.
  String _pr(ResponseCategory category, {Map<String, String>? data, bool addFiller = false}) {
    return getPersonalityResponse(_personality, category, _assistantName, data: data, addFiller: addFiller);
  }

  /// Get personality and assistant name for external callers.
  AiPersonality get personality => _personality;
  String get assistantName => _assistantName;

  /// Ensure personality is loaded (for external callers).
  Future<void> ensurePersonalityLoaded() => _ensurePersonalityLoaded();

  /// Determine the best ResponseCategory for an expense based on context.
  ResponseCategory contextualExpenseCategory(double amount, String category) {
    final random = Random();

    // Amount-based categories take priority
    if (amount >= 5000) return ResponseCategory.hugeExpense;
    if (amount < 100) return ResponseCategory.smallExpense;

    // 30% chance of using a more specific time-aware category
    final roll = random.nextInt(10);
    if (roll < 3) {
      final hour = DateTime.now().hour;
      if (hour >= 23 || hour < 5) return ResponseCategory.nightOwl;
      if (hour < 7) return ResponseCategory.earlyBird;
      final weekday = DateTime.now().weekday;
      if (weekday == DateTime.saturday || weekday == DateTime.sunday) {
        return ResponseCategory.weekendSpending;
      }
    }

    // Medium expense range (100-999)
    if (amount >= 100 && amount < 1000) return ResponseCategory.mediumExpense;

    // Large purchase range (1000-4999)
    if (amount >= 1000) return ResponseCategory.largePurchase;

    return ResponseCategory.expenseLogged;
  }

  /// Main entry point: parse raw user input into a structured result.
  Future<ParseResult> parse(String rawInput) async {
    await _ensurePersonalityLoaded();

    // ─── 1. Sanitize ─────────────────────────────────────────────────
    final sanitized = _sanitize(rawInput);
    if (sanitized == null) {
      return ParseResult(
        intent: ChatIntent.unknown,
        message: _pr(ResponseCategory.didntUnderstand),
      );
    }

    final lower = sanitized.toLowerCase();

    // ─── 2. Greetings & small talk ────────────────────────────────────
    final smallTalkResult = _checkSmallTalk(lower);
    if (smallTalkResult != null) return smallTalkResult;

    // ─── 2b. App navigation ────────────────────────────────────────────
    final navResult = _checkNavigation(lower);
    if (navResult != null) return navResult;

    // ─── 2c. Correction / undo ─────────────────────────────────────────
    if (_isCorrectionRequest(lower)) {
      return ParseResult(
        intent: ChatIntent.unknown,
        message: _pr(ResponseCategory.didntUnderstand,
            data: {'fallback': 'Use the [Report] button on the message you want to fix.'}),
      );
    }

    // ─── 3. Check help ───────────────────────────────────────────────
    if (_isHelp(lower)) {
      return ParseResult(
        intent: ChatIntent.help,
        message: _pr(ResponseCategory.whatCanYouDo) + "\n\n"
            "Try:\n"
            "  'lunch 250' — log expense\n"
            "  'sahod 30k' — log income\n"
            "  'net worth ko' — check balance\n"
            "  'gastos ko this month' — spending summary\n"
            "  'budget status' — check budgets\n"
            "  'bayarin ko' — upcoming bills\n"
            "  'payo naman' — financial tip",
      );
    }

    // ─── 4. Check financial advice triggers ──────────────────────────
    final adviceResult = _checkAdvice(lower);
    if (adviceResult != null) return adviceResult;

    // ─── 5. Check negation ───────────────────────────────────────────
    final negationResult = _checkNegation(lower);
    if (negationResult != null) return negationResult;

    // ─── 6. Check libre ──────────────────────────────────────────────
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

    // ─── 7. Check utang ──────────────────────────────────────────────
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

    // ─── 8. Query override ───────────────────────────────────────────
    final queryResult = _checkQuery(lower);
    if (queryResult != null) return queryResult;

    // ─── 9. Check session context ("add another one", "isa pa") ──────
    final contextResult = _checkSessionContext(lower);
    if (contextResult != null) return contextResult;

    // ─── 10. Extract amount ──────────────────────────────────────────
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
      return ParseResult(
        intent: ChatIntent.unknown,
        message: _pr(ResponseCategory.needAmount),
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

    // ─── 11. Validate amount ─────────────────────────────────────────
    if (amount < 1) {
      return const ParseResult(
        intent: ChatIntent.unknown,
        message: "Amount must be at least PHP 1",
      );
    }

    final needsConfirmation = amount > 100000;

    // ─── 12. Extract account ─────────────────────────────────────────
    final accounts = await _getAccounts();
    final accountMatch = _extractAccount(lower, accounts);

    // ─── 13. Build description ───────────────────────────────────────
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

    // ─── 14. Check income vs expense ─────────────────────────────────
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

    // ─── 15. Resolve category ────────────────────────────────────────
    final categoryResult = await _resolveCategory(description.toLowerCase(), lower);

    final intent = isIncome ? ChatIntent.logIncome : ChatIntent.logExpense;

    // Save to session context
    _lastIntent = intent;
    _lastCategory = categoryResult?.category;
    _lastAccountId = accountMatch?.accountId;

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
  // SMALL TALK
  // ═══════════════════════════════════════════════════════════════════════

  ParseResult? _checkSmallTalk(String lower) {
    // Greetings
    for (final g in kGreetingWords) {
      if (lower == g || lower.startsWith('$g ') || lower.startsWith('$g!') || lower.startsWith('$g,')) {
        return ParseResult(
          intent: ChatIntent.unknown,
          message: _pr(ResponseCategory.greeting),
        );
      }
    }

    // Farewell
    for (final f in kFarewellWords) {
      if (lower == f || lower.startsWith('$f ') || lower.startsWith('$f!')) {
        return ParseResult(
          intent: ChatIntent.unknown,
          message: _pr(ResponseCategory.farewell),
        );
      }
    }

    // Thank you
    for (final t in kThankYouWords) {
      if (lower == t || lower.startsWith('$t ') || lower.startsWith('$t!')) {
        return ParseResult(
          intent: ChatIntent.unknown,
          message: _pr(ResponseCategory.thankYou),
        );
      }
    }

    // Who are you
    for (final w in kWhoAreYouWords) {
      if (lower.contains(w)) {
        return ParseResult(
          intent: ChatIntent.unknown,
          message: _pr(ResponseCategory.whoAreYou),
        );
      }
    }

    // What can you do
    for (final w in kWhatCanYouDoWords) {
      if (lower.contains(w)) {
        return ParseResult(
          intent: ChatIntent.help,
          message: _pr(ResponseCategory.whatCanYouDo),
        );
      }
    }

    // How are you
    for (final h in kHowAreYouWords) {
      if (lower.contains(h)) {
        return ParseResult(
          intent: ChatIntent.unknown,
          message: _pr(ResponseCategory.howAreYou),
        );
      }
    }

    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // APP NAVIGATION
  // ═══════════════════════════════════════════════════════════════════════

  ParseResult? _checkNavigation(String lower) {
    for (final entry in kNavigationTriggers.entries) {
      if (lower == entry.key || lower.contains(entry.key)) {
        return ParseResult(
          intent: ChatIntent.unknown,
          message: '→ ${entry.value}',
          // The notifier/UI layer reads this route to navigate
        );
      }
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CORRECTION / UNDO
  // ═══════════════════════════════════════════════════════════════════════

  bool _isCorrectionRequest(String lower) {
    for (final word in kCorrectionWords) {
      if (lower == word || lower.startsWith('$word ')) return true;
    }
    return false;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // FINANCIAL ADVICE
  // ═══════════════════════════════════════════════════════════════════════

  ParseResult? _checkAdvice(String lower) {
    for (final trigger in kAdviceTriggers) {
      if (lower.contains(trigger)) {
        // Investment advice
        if (lower.contains('invest')) {
          return ParseResult(
            intent: ChatIntent.unknown,
            message: _pr(ResponseCategory.investmentAdvice),
          );
        }
        // Budget advice
        if (lower.contains('budget')) {
          return ParseResult(
            intent: ChatIntent.unknown,
            message: _pr(ResponseCategory.budgetAdvice),
          );
        }
        // Generic saving tip
        return ParseResult(
          intent: ChatIntent.unknown,
          message: _pr(ResponseCategory.savingTip),
        );
      }
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SESSION CONTEXT
  // ═══════════════════════════════════════════════════════════════════════

  ParseResult? _checkSessionContext(String lower) {
    for (final phrase in kRepeatWords) {
      if (lower.contains(phrase)) {
        // Check if we have context from a previous action
        if (_lastIntent != null) {
          // Try to extract amount from this message
          final amountExtraction = _extractAmount(lower);
          if (amountExtraction.amounts.length == 1) {
            final amount = amountExtraction.amounts.first;
            return ParseResult(
              intent: _lastIntent!,
              amount: _roundAmount(amount),
              category: _lastCategory,
              description: 'Same as previous',
              accountId: _lastAccountId,
              isIncome: _lastIntent == ChatIntent.logIncome,
              categorySource: _lastCategory != null ? 'context' : null,
            );
          }
          // No amount — ask for it
          return ParseResult(
            intent: ChatIntent.unknown,
            message: "Sure, same as before! How much this time?",
          );
        }
        break;
      }
    }
    return null;
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

    // "hindi pa bayad X" -> query about unpaid
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
    if (_containsAny(lower, ['net worth', 'networth', 'pera ko', 'total balance', 'total money',
        'magkano pera ko', 'how much do i have'])) {
      return const ParseResult(intent: ChatIntent.query, queryType: QueryType.netWorth, message: '');
    }
    if (_containsAny(lower, ['show my accounts', 'mga account ko', 'account ko'])) {
      return const ParseResult(intent: ChatIntent.query, queryType: QueryType.accountBalance, message: '');
    }
    if (_containsAny(lower, ['budget', 'over budget', 'kumusta budget', 'how\'s my budget',
        'lumagpas', 'magkano pa pwede', 'how much can i still spend'])) {
      return const ParseResult(intent: ChatIntent.query, queryType: QueryType.budgetStatus, message: '');
    }
    if (_containsAny(lower, ['goal', 'goals', 'savings progress', 'ipon',
        'kumusta goals', 'how are my goals', 'gaano na kalaki', 'how close'])) {
      return const ParseResult(intent: ChatIntent.query, queryType: QueryType.goalProgress, message: '');
    }
    if (_containsAny(lower, ['utang', 'debt', 'debts', 'owe', 'naiutang',
        'magkano utang', 'how much do i owe'])) {
      return const ParseResult(intent: ChatIntent.query, queryType: QueryType.debtSummary, message: '');
    }
    if (_containsAny(lower, ['bill', 'bills', 'bayarin', 'due', 'upcoming bills',
        'anong bills', 'what bills', 'when is', 'kailan due'])) {
      return const ParseResult(intent: ChatIntent.query, queryType: QueryType.billsDue, message: '');
    }
    if (_containsAny(lower, ['recent', 'last', 'history', 'huling'])) {
      return const ParseResult(intent: ChatIntent.query, queryType: QueryType.recentTransactions, message: '');
    }
    if (_containsAny(lower, ['compare', 'versus', 'vs', 'last month', 'compare sa'])) {
      return const ParseResult(intent: ChatIntent.query, queryType: QueryType.spendingSummary, message: '');
    }
    if (_containsAny(lower, ['saan napupunta', 'where does my money go', 'top expenses',
        'pinaka malaki', 'pinakamalaki'])) {
      return const ParseResult(intent: ChatIntent.query, queryType: QueryType.spendingSummary, message: '');
    }

    // Contribution / tax queries
    for (final trigger in kContributionTriggers) {
      if (lower.contains(trigger)) {
        return const ParseResult(
          intent: ChatIntent.query,
          queryType: QueryType.spendingSummary,
          message: 'Check your contribution details in the Government Contributions tool.',
        );
      }
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
    if (_containsAny(lower, ['gastos', 'ginastos', 'nagastos', 'spent', 'spending', 'expenses',
        'magkano gastos', 'how much did i spend', 'spending this week'])) {
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

      // If one is <=10 and other > 10, smaller is likely quantity
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

    // Remove action words
    words = words.where((w) {
      final wl = w.toLowerCase();
      return !kExpenseActionWords.contains(wl) &&
          !kIncomeActionWords.contains(wl) &&
          wl != 'add' && wl != 'log' && wl != 'expense' && wl != 'income';
    }).toList();

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

    // Check expanded income verb patterns
    for (final verb in kIncomeVerbsExpanded) {
      if (_containsWord(lower, verb)) return _IncomeResult.income;
    }

    // "binigay sa akin" / "natanggap" = income
    if (lower.contains('sa akin') || lower.contains('natanggap') || lower.contains('tinanggap')) {
      return _IncomeResult.income;
    }

    // "may pumasok" = income
    if (lower.contains('may pumasok') || lower.contains('pumasok')) {
      return _IncomeResult.income;
    }

    // "binigay/bigay" + family word = expense (giving TO family)
    if (_containsAny(lower, ['binigay', 'bigay', 'ibinigay', 'ibigay'])) {
      for (final fw in kFamilyWords) {
        if (_containsWord(lower, fw)) return _IncomeResult.expense;
      }
    }

    // Check ambiguous
    for (final kw in kAmbiguousIncomeKeywords) {
      if (_containsWord(lower, kw)) return _IncomeResult.ambiguous;
    }

    // Check expanded expense verb patterns (reinforces expense default)
    for (final verb in kExpenseVerbsExpanded) {
      if (_containsWord(lower, verb)) return _IncomeResult.expense;
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
