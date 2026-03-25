import 'dart:convert';
import 'dart:ui' show VoidCallback;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/chat_dictionary.dart';
import '../../../core/constants/categories.dart';
import '../../../core/services/chat_engine.dart';
import '../../../core/services/groq_ai_service.dart';
import '../../../data/chat/personality_templates.dart';
import '../../../data/models/chat_models.dart';
import '../../../data/repositories/chat_report_repository.dart';
import '../../../data/repositories/learned_keyword_repository.dart';
import '../../../core/services/guide_search_service.dart';
import '../../../core/services/spending_insights_service.dart';
import '../../../core/services/guest_mode_service.dart';
import '../../../data/local/app_database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/repositories/local_account_repository.dart';
import '../../../data/repositories/local_transaction_repository.dart';

class ChatNotifier extends StateNotifier<ChatUiState> {
  final ChatEngine engine;
  final LocalTransactionRepository transactionRepo;
  final LocalAccountRepository accountRepo;
  final LearnedKeywordRepository learnedRepo;
  final ChatReportRepository reportRepo;
  final VoidCallback invalidateProviders;

  ChatNotifier({
    required this.engine,
    required this.transactionRepo,
    required this.accountRepo,
    required this.learnedRepo,
    required this.reportRepo,
    required this.invalidateProviders,
  }) : super(const ChatUiState());

  int _idCounter = 0;
  String _nextId() => 'msg-${DateTime.now().millisecondsSinceEpoch}-${_idCounter++}';

  AppDatabase? _getDb() {
    try { return AppDatabase.instance; } catch (_) { return null; }
  }

  String _getUserId() {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) return user.id;
    } catch (_) {}
    return GuestModeService.getGuestIdSync() ?? 'guest';
  }

  /// Build a JSON summary of user's financial state for the AI.
  Future<String> _buildFinancialContext() async {
    try {
      final accounts = await accountRepo.getAccounts();
      final summary = await transactionRepo.getTransactionsSummary();
      final recentTx = await transactionRepo.getTransactions();

      final ctx = {
        'accounts': accounts.map((a) => {'name': a.name, 'type': a.type, 'balance': a.balance}).toList(),
        'total_balance': summary.balance,
        'this_month_income': summary.income,
        'this_month_expenses': summary.expenses,
        'recent_transactions': recentTx.map((t) => {
          'description': t.description, 'amount': t.amount,
          'category': t.category, 'date': t.date,
        }).toList(),
      };
      return jsonEncode(ctx);
    } catch (_) {
      return '{"error": "Could not load financial data"}';
    }
  }

  /// Search guides for relevant context based on user's query.
  String _buildGuideContext(String query) {
    try {
      final results = GuideSearchService.search(query);
      if (results.isEmpty) return '';
      return results.take(2).map((r) => '${r.title}: ${r.excerpt}').join('\n\n');
    } catch (_) {
      return '';
    }
  }

  // ─── Public API ────────────────────────────────────────────────────────

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    // Add user message
    _addMessage(ChatMessage(
      id: _nextId(),
      type: ChatMessageType.user,
      text: trimmed,
      timestamp: DateTime.now(),
    ));

    // Check conversation state first
    switch (state.conversationState) {
      case ChatConversationState.pendingConfirmation:
        await _handleConfirmationResponse(trimmed);
        return;
      case ChatConversationState.pendingCategory:
        await _handleCategoryResponse(trimmed);
        return;
      case ChatConversationState.pendingClarification:
        await _handleClarificationResponse(trimmed);
        return;
      case ChatConversationState.pendingAmountConfirmation:
        await _handleAmountConfirmationResponse(trimmed);
        return;
      case ChatConversationState.pendingIncomeConfirmation:
        await _handleIncomeConfirmationResponse(trimmed);
        return;
      case ChatConversationState.pendingAccountSelection:
        await _handleAccountSelectionResponse(trimmed);
        return;
      case ChatConversationState.idle:
        break;
    }

    // Try Groq AI first, fall back to local dictionary engine
    state = state.copyWith(isProcessing: true);

    try {
      final financialContext = await _buildFinancialContext();
      final guideContext = _buildGuideContext(trimmed);

      await engine.ensurePersonalityLoaded();
      final groqResponse = await GroqAiService.chat(
        userMessage: trimmed,
        personality: engine.personality.key,
        assistantName: engine.assistantName,
        financialContext: financialContext,
        guideContext: guideContext,
      );

      state = state.copyWith(isProcessing: false);

      if (!groqResponse.isError) {
        // Groq responded successfully
        if (groqResponse.action != null) {
          // AI wants to create a transaction — use the local engine to handle it
          final action = groqResponse.action!;
          if (action.type == 'add_expense' || action.type == 'add_income') {
            final isIncome = action.type == 'add_income';

            // Try to match account name from user's message
            final accounts = await accountRepo.getAccounts();
            String? matchedAccountId;
            String? matchedAccountName;
            final lowerMsg = trimmed.toLowerCase();
            for (final acc in accounts) {
              if (lowerMsg.contains(acc.name.toLowerCase())) {
                matchedAccountId = acc.id;
                matchedAccountName = acc.name;
                break;
              }
            }

            final result = ParseResult(
              intent: isIncome ? ChatIntent.logIncome : ChatIntent.logExpense,
              amount: action.amount ?? 0,
              category: action.category ?? (isIncome ? 'Salary' : 'Other'),
              description: action.description,
              isIncome: isIncome,
              categorySource: 'ai',
              accountId: matchedAccountId,
              accountName: matchedAccountName,
            );

            if (matchedAccountId != null) {
              // User specified account → show confirmation card directly
              state = state.copyWith(
                conversationState: ChatConversationState.pendingConfirmation,
                pendingResult: result,
                pendingRawInput: trimmed,
              );
              _addMessage(ChatMessage(
                id: _nextId(),
                type: ChatMessageType.confirmation,
                text: '',
                timestamp: DateTime.now(),
                parseResult: result,
              ));
            } else {
              // No account specified → ask which account first
              await _showConfirmation(result, trimmed);
            }
            return;
          }
        }
        // Plain text response from AI
        _addMessage(ChatMessage(
          id: _nextId(),
          type: ChatMessageType.bot,
          text: groqResponse.message,
          timestamp: DateTime.now(),
        ));
        return;
      }
    } catch (e) {
      // Groq failed — fall through to local engine
    }

    // Fallback: local dictionary engine
    final result = await engine.parse(trimmed);
    state = state.copyWith(isProcessing: false);
    await _handleParseResult(result, trimmed);
  }

  Future<void> selectCategory(String category) async {
    final pending = state.pendingResult;
    if (pending == null) return;

    final updated = pending.copyWith(category: category, categorySource: 'user_pick');

    // Learn this keyword → category mapping
    final desc = pending.description?.toLowerCase().trim();
    if (desc != null && desc.isNotEmpty) {
      learnedRepo.learn(desc, category, source: 'user_pick');
    }

    // Show confirmation
    await _showConfirmation(updated, state.pendingRawInput ?? '');
  }

  bool _actionInProgress = false;

  Future<void> confirmTransaction() async {
    final pending = state.pendingResult;
    if (pending == null || _actionInProgress) return;
    _actionInProgress = true;

    // Check if user has at least one account
    final accounts = await accountRepo.getAccounts();
    if (accounts.isEmpty) {
      _actionInProgress = false;
      _addBotMessage(
        'You need to create an account first before logging transactions. '
        'Go to Menu → Accounts → Add to create one!'
      );
      state = state.copyWith(
        conversationState: ChatConversationState.idle,
        clearPending: true,
      );
      return;
    }

    final amount = pending.amount!;
    final signedAmount = pending.isIncome ? amount.abs() : -amount.abs();

    // Use the first account if none specified
    final accountId = pending.accountId ?? accounts.first.id;

    final tx = await transactionRepo.createTransaction(
      amount: signedAmount,
      category: pending.category ?? 'Other',
      description: pending.description ?? '',
      date: DateTime.now(),
      accountId: accountId,
    );

    invalidateProviders();

    final formatted = _formatAmount(amount);
    final catLabel = pending.category ?? 'Other';

    // Use personality-flavored response for the confirmation message
    await engine.ensurePersonalityLoaded();
    final responseCategory = pending.isIncome
        ? ResponseCategory.incomeLogged
        : engine.contextualExpenseCategory(amount, catLabel);
    final personalityMsg = getPersonalityResponse(
      engine.personality,
      responseCategory,
      engine.assistantName,
      data: {'amount': formatted, 'category': catLabel},
      addFiller: false,
    );

    // Find account name for the confirmation message
    final accName = accounts.firstWhere((a) => a.id == accountId, orElse: () => accounts.first).name;

    // Replace the confirmation card with a single clean message
    final savedAiMsg = pending.message;
    final confirmText = savedAiMsg != null && savedAiMsg.isNotEmpty
        ? '$savedAiMsg\n\n✓ ${pending.isIncome ? "Added" : "Deducted"} ₱${_formatAmount(amount)} (${pending.category ?? "Other"}) → $accName'
        : '$personalityMsg\n\n✓ ${pending.isIncome ? "Added" : "Deducted"} ₱${_formatAmount(amount)} (${pending.category ?? "Other"}) → $accName';

    _replaceLastConfirmation(confirmText);

    _actionInProgress = false;
    state = state.copyWith(
      conversationState: ChatConversationState.idle,
      clearPending: true,
    );
  }

  void cancelTransaction() {
    if (_actionInProgress) return;
    _actionInProgress = true;

    // Replace the confirmation card with a cancelled message
    _replaceLastConfirmation('✗ Transaction cancelled');

    _actionInProgress = false;
    state = state.copyWith(
      conversationState: ChatConversationState.idle,
      clearPending: true,
    );
  }

  /// Replace the last confirmation-type message with a plain bot message.
  void _replaceLastConfirmation(String text) {
    final messages = List<ChatMessage>.from(state.messages);
    final idx = messages.lastIndexWhere((m) => m.type == ChatMessageType.confirmation);
    if (idx >= 0) {
      messages[idx] = ChatMessage(
        id: messages[idx].id,
        type: ChatMessageType.bot,
        text: text,
        timestamp: messages[idx].timestamp,
      );
      state = state.copyWith(messages: messages);
    }
  }

  /// Report an error on a committed transaction.
  Future<void> reportError({
    required String messageId,
    required CorrectionType errorType,
    String? correctedCategory,
    double? correctedAmount,
    String? correctedAccount,
    String? correctedType, // 'income' or 'expense'
    String? userComment,
  }) async {
    // Find the message
    final msg = state.messages.firstWhere((m) => m.id == messageId);
    final pr = msg.parseResult;
    final txId = msg.transactionId;

    // 1. Correct the transaction locally
    if (txId != null) {
      switch (errorType) {
        case CorrectionType.category:
          if (correctedCategory != null) {
            await transactionRepo.updateTransaction(id: txId, category: correctedCategory);
            // Learn the correction
            final desc = pr?.description?.toLowerCase().trim();
            if (desc != null && desc.isNotEmpty) {
              await learnedRepo.learn(desc, correctedCategory, source: 'correction');
            }
          }
          break;
        case CorrectionType.amount:
          if (correctedAmount != null) {
            final signed = (pr?.isIncome ?? false) ? correctedAmount.abs() : -correctedAmount.abs();
            await transactionRepo.updateTransaction(id: txId, amount: signed);
          }
          break;
        case CorrectionType.account:
          if (correctedAccount != null) {
            await transactionRepo.updateTransaction(id: txId, accountId: correctedAccount);
          }
          break;
        case CorrectionType.type:
          if (pr != null) {
            // Flip the sign
            final currentAmount = pr.amount ?? 0;
            final flipped = pr.isIncome ? -currentAmount.abs() : currentAmount.abs();
            await transactionRepo.updateTransaction(id: txId, amount: flipped);
          }
          break;
        case CorrectionType.other:
          break;
      }
      invalidateProviders();
    }

    // 2. Queue report for sync
    await reportRepo.queueReport(
      userInput: msg.rawUserInput ?? '',
      parsedIntent: pr?.intent.name ?? 'unknown',
      parsedAmount: pr?.amount,
      parsedCategory: pr?.category,
      parsedDescription: pr?.description,
      parsedAccount: pr?.accountName,
      parsedType: (pr?.isIncome ?? false) ? 'income' : 'expense',
      categorySource: pr?.categorySource,
      errorType: errorType.name,
      correctedCategory: correctedCategory,
      correctedAmount: correctedAmount,
      correctedAccount: correctedAccount,
      correctedType: correctedType,
      userComment: userComment,
    );

    _addBotMessage("Got it! Fixed. I'll remember that for next time.");
  }

  // ─── Query Execution ──────────────────────────────────────────────────

  Future<void> _executeQuery(ParseResult result) async {
    try {
      switch (result.queryType) {
        case QueryType.netWorth:
          await _queryNetWorth();
          break;
        case QueryType.spendingSummary:
          await _querySpendingSummary();
          break;
        case QueryType.spendingByCategory:
          await _querySpendingByCategory(result.queryCategory ?? 'Food');
          break;
        case QueryType.budgetStatus:
          await _queryBudgetStatus();
          break;
        case QueryType.goalProgress:
          await _queryGoalProgress();
          break;
        case QueryType.debtSummary:
          await _queryDebtSummary();
          break;
        case QueryType.billsDue:
          await _queryBillsDue();
          break;
        case QueryType.recentTransactions:
          await _queryRecentTransactions();
          break;
        case QueryType.accountBalance:
          await _queryNetWorth(); // same data, different framing
          break;
        case QueryType.spendingInsights:
          await _queryInsights();
          break;
        case QueryType.exportCsv:
          _addBotMessage("To export your transactions as CSV, go to Transactions and tap the download icon, or go to Settings > Privacy & Data.");
          break;
        case QueryType.currencyConvert:
          _addBotMessage("Open the Currency Converter in Tools to convert between currencies. You can find it under Calculators & Tools > Utilities.");
          break;
        case null:
          _addBotMessage("I'm not sure what to look up. Try 'net worth' or 'gastos ko'");
      }
    } catch (e) {
      _addBotMessage("Something went wrong looking that up. Try again?");
    }
  }

  Future<void> _queryNetWorth() async {
    final accounts = await accountRepo.getAccounts();
    if (accounts.isEmpty) {
      _addBotMessage("You don't have any accounts yet. Add one in the Accounts tab.");
      return;
    }
    final total = accounts.fold<double>(0, (sum, a) => sum + a.balance);
    final lines = accounts.map((a) => "  ${a.name} — PHP ${_formatAmount(a.balance)}").join('\n');
    _addBotMessage("Your net worth is PHP ${_formatAmount(total)} across ${accounts.length} account${accounts.length == 1 ? '' : 's'}:\n$lines");
  }

  Future<void> _queryInsights() async {
    try {
      final db = _getDb();
      if (db == null) {
        _addBotMessage("Can't access the database right now. Try again later.");
        return;
      }
      final userId = _getUserId();
      final insights = await SpendingInsightsService.getInsights(db, userId);
      if (insights.isEmpty) {
        _addBotMessage("No insights available yet. Keep logging transactions and I'll find patterns for you!");
        return;
      }
      final top3 = insights.take(3);
      final lines = top3.map((i) => "  \u2022 ${i.text}").join('\n');
      _addBotMessage("Here are your top insights:\n$lines\n\nCheck the Dashboard for more details.");
    } catch (_) {
      _addBotMessage("Couldn't load insights right now. Try the Dashboard instead.");
    }
  }

  Future<void> _querySpendingSummary() async {
    final summary = await transactionRepo.getTransactionsSummary();
    final txns = await transactionRepo.getCurrentMonthTransactions();
    final expenses = txns.where((t) => t.isExpense && t.category != 'Transfer');

    // Group by category
    final catTotals = <String, double>{};
    for (final t in expenses) {
      catTotals[t.category] = (catTotals[t.category] ?? 0) + t.amount.abs();
    }

    if (catTotals.isEmpty) {
      _addBotMessage("No expenses this month yet.");
      return;
    }

    final sorted = catTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final totalExpenses = summary.expenses;
    final lines = sorted.map((e) {
      final pct = totalExpenses > 0 ? (e.value / totalExpenses * 100).round() : 0;
      return "  ${e.key} — PHP ${_formatAmount(e.value)} ($pct%)";
    }).join('\n');

    final savingsRate = summary.income > 0
        ? ((summary.income - summary.expenses) / summary.income * 100).round()
        : 0;

    _addBotMessage(
      "This month you've spent PHP ${_formatAmount(summary.expenses)}:\n$lines\n\n"
      "Income: PHP ${_formatAmount(summary.income)} | Savings rate: $savingsRate%",
    );
  }

  Future<void> _querySpendingByCategory(String category) async {
    final txns = await transactionRepo.getCurrentMonthTransactions();
    final catTxns = txns.where((t) => t.isExpense && t.category == category);
    final total = catTxns.fold<double>(0, (sum, t) => sum + t.amount.abs());

    if (total == 0) {
      _addBotMessage("No $category expenses this month.");
      return;
    }

    _addBotMessage("You've spent PHP ${_formatAmount(total)} on $category this month (${catTxns.length} transaction${catTxns.length == 1 ? '' : 's'}).");
  }

  Future<void> _queryBudgetStatus() async {
    _addBotMessage("Check your budget status in the Budgets tab for detailed tracking.");
  }

  Future<void> _queryGoalProgress() async {
    _addBotMessage("Check your goals progress in the Goals tab for detailed tracking.");
  }

  Future<void> _queryDebtSummary() async {
    _addBotMessage("Check your debts in the Debts tool for detailed tracking.");
  }

  Future<void> _queryBillsDue() async {
    _addBotMessage("Check your upcoming bills in the Bills tool for due dates.");
  }

  Future<void> _queryRecentTransactions() async {
    final txns = await transactionRepo.getRecentTransactions();
    if (txns.isEmpty) {
      _addBotMessage("No transactions yet.");
      return;
    }
    final lines = txns.take(5).map((t) {
      final sign = t.isIncome ? '+' : '-';
      return "  $sign PHP ${_formatAmount(t.amount.abs())} ${t.category} — ${t.description} (${t.date})";
    }).join('\n');
    _addBotMessage("Recent transactions:\n$lines");
  }

  // ─── State Machine Handlers ────────────────────────────────────────────

  Future<void> _handleParseResult(ParseResult result, String rawInput) async {
    switch (result.intent) {
      case ChatIntent.help:
      case ChatIntent.transfer:
        _addBotMessage(result.message ?? "I didn't understand that. Try 'lunch 250' or 'net worth ko'");
        break;

      case ChatIntent.unknown:
        // Before giving up, search guide content
        final guideResults = GuideSearchService.search(rawInput);
        if (guideResults.isNotEmpty) {
          _addBotMessage(_buildGuideResponse(guideResults));
        } else {
          _addBotMessage(result.message ?? "I didn't understand that. Try 'lunch 250' or 'net worth ko'");
        }
        break;

      case ChatIntent.query:
        await _executeQuery(result);
        break;

      case ChatIntent.logExpense:
      case ChatIntent.logIncome:
        if (result.needsAmountConfirmation) {
          state = state.copyWith(
            conversationState: ChatConversationState.pendingAmountConfirmation,
            pendingResult: result,
            pendingRawInput: rawInput,
          );
          _addBotMessage("That's PHP ${_formatAmount(result.amount!)} — is that right?");
          return;
        }

        if (result.category == null) {
          // Need category from user
          state = state.copyWith(
            conversationState: ChatConversationState.pendingCategory,
            pendingResult: result,
            pendingRawInput: rawInput,
          );
          _addBotMessage("What category for '${result.description}'?");
          _addMessage(ChatMessage(
            id: _nextId(),
            type: ChatMessageType.categoryPicker,
            text: '',
            timestamp: DateTime.now(),
          ));
          return;
        }

        await _showConfirmation(result, rawInput);
        break;
    }
  }

  Future<void> _handleConfirmationResponse(String text) async {
    final lower = text.toLowerCase().trim();

    if (kAffirmativeWords.contains(lower)) {
      await confirmTransaction();
      return;
    }

    if (kNegativeWords.contains(lower)) {
      cancelTransaction();
      return;
    }

    if (lower == 'edit' || lower == 'baguhin' || lower == 'palitan') {
      _addBotMessage("Use the Edit button to modify the details.");
      return;
    }

    // New input — discard pending, process new
    _addBotMessage("Previous entry discarded.");
    state = state.copyWith(
      conversationState: ChatConversationState.idle,
      clearPending: true,
    );
    state = state.copyWith(isProcessing: true);
    final result = await engine.parse(text);
    state = state.copyWith(isProcessing: false);
    await _handleParseResult(result, text);
  }

  Future<void> _handleCategoryResponse(String text) async {
    final lower = text.toLowerCase().trim();

    // Check if user typed a category name
    for (final cat in kCategories) {
      if (lower == cat.toLowerCase() || lower.startsWith(cat.toLowerCase())) {
        selectCategory(cat);
        return;
      }
    }

    // Common abbreviations
    final abbrevMap = {
      'transpo': 'Transportation',
      'entertain': 'Entertainment',
      'health': 'Healthcare',
      'educ': 'Education',
      'fam': 'Family Support',
    };
    for (final entry in abbrevMap.entries) {
      if (lower.startsWith(entry.key)) {
        selectCategory(entry.value);
        return;
      }
    }

    // Doesn't match a category — might be new input
    _addBotMessage("Previous entry discarded.");
    state = state.copyWith(
      conversationState: ChatConversationState.idle,
      clearPending: true,
    );
    state = state.copyWith(isProcessing: true);
    final result = await engine.parse(text);
    state = state.copyWith(isProcessing: false);
    await _handleParseResult(result, text);
  }

  Future<void> _handleClarificationResponse(String text) async {
    final lower = text.toLowerCase().trim();
    final pending = state.pendingResult;

    if (pending?.ambiguousAmounts != null) {
      final parsed = double.tryParse(lower.replaceAll(RegExp(r'[^\d.]'), ''));
      if (parsed != null) {
        final updated = pending!.copyWith(amount: parsed, ambiguousAmounts: null);
        state = state.copyWith(
          conversationState: ChatConversationState.idle,
          clearPending: true,
        );
        await _handleParseResult(updated, state.pendingRawInput ?? text);
        return;
      }
    }

    // Unrecognized — discard and process as new input
    state = state.copyWith(
      conversationState: ChatConversationState.idle,
      clearPending: true,
    );
    state = state.copyWith(isProcessing: true);
    final result = await engine.parse(text);
    state = state.copyWith(isProcessing: false);
    await _handleParseResult(result, text);
  }

  Future<void> _handleAmountConfirmationResponse(String text) async {
    final lower = text.toLowerCase().trim();
    final pending = state.pendingResult;
    if (pending == null) return;

    if (kAffirmativeWords.contains(lower)) {
      // Amount confirmed, continue with flow
      state = state.copyWith(conversationState: ChatConversationState.idle);
      final result = pending.copyWith(needsAmountConfirmation: false);
      await _handleParseResult(result, state.pendingRawInput ?? text);
      return;
    }

    if (kNegativeWords.contains(lower)) {
      cancelTransaction();
      return;
    }

    // They might have typed the correct amount (strip currency symbols/text)
    final cleaned = lower.replaceAll(RegExp(r'[^\d.]'), '');
    final corrected = cleaned.isNotEmpty ? double.tryParse(cleaned) : null;
    if (corrected != null) {
      state = state.copyWith(conversationState: ChatConversationState.idle);
      final result = pending.copyWith(amount: corrected, needsAmountConfirmation: false);
      await _handleParseResult(result, state.pendingRawInput ?? text);
      return;
    }

    // New input
    state = state.copyWith(
      conversationState: ChatConversationState.idle,
      clearPending: true,
    );
    state = state.copyWith(isProcessing: true);
    final result = await engine.parse(text);
    state = state.copyWith(isProcessing: false);
    await _handleParseResult(result, text);
  }

  Future<void> _handleIncomeConfirmationResponse(String text) async {
    final lower = text.toLowerCase().trim();
    final pending = state.pendingResult;
    if (pending == null) return;

    if (kAffirmativeWords.contains(lower) || lower == 'income' || lower == 'yes income') {
      state = state.copyWith(conversationState: ChatConversationState.idle);
      final result = pending.copyWith(intent: ChatIntent.logIncome, isIncome: true);
      await _handleParseResult(result, state.pendingRawInput ?? text);
      return;
    }

    if (lower == 'expense' || lower == 'no' || lower == 'hindi') {
      state = state.copyWith(conversationState: ChatConversationState.idle);
      final result = pending.copyWith(intent: ChatIntent.logExpense, isIncome: false);
      await _handleParseResult(result, state.pendingRawInput ?? text);
      return;
    }

    // New input
    state = state.copyWith(
      conversationState: ChatConversationState.idle,
      clearPending: true,
    );
    state = state.copyWith(isProcessing: true);
    final result = await engine.parse(text);
    state = state.copyWith(isProcessing: false);
    await _handleParseResult(result, text);
  }

  Future<void> _handleAccountSelectionResponse(String text) async {
    final pending = state.pendingResult;
    if (pending == null) return;

    final accounts = await accountRepo.getAccounts();
    final lower = text.toLowerCase().trim();

    // Try matching by number (1, 2, 3...)
    final num = int.tryParse(lower);
    String? matchedId;
    String? matchedName;

    if (num != null && num >= 1 && num <= accounts.length) {
      matchedId = accounts[num - 1].id;
      matchedName = accounts[num - 1].name;
    } else {
      // Try matching by name
      for (final acc in accounts) {
        if (acc.name.toLowerCase().contains(lower) || lower.contains(acc.name.toLowerCase())) {
          matchedId = acc.id;
          matchedName = acc.name;
          break;
        }
      }
    }

    if (matchedId != null) {
      final updated = pending.copyWith(accountId: matchedId, accountName: matchedName);
      state = state.copyWith(
        conversationState: ChatConversationState.pendingConfirmation,
        pendingResult: updated,
        pendingRawInput: state.pendingRawInput,
      );
      _addMessage(ChatMessage(
        id: _nextId(),
        type: ChatMessageType.confirmation,
        text: '',
        timestamp: DateTime.now(),
        parseResult: updated,
      ));
    } else {
      _addBotMessage('Hindi ko nahanap yan. Reply with the number (1, 2, 3...) or the account name.');
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────

  Future<void> _showConfirmation(ParseResult result, String rawInput) async {
    // Always ask which account to use
    final accounts = await accountRepo.getAccounts();
    if (accounts.isEmpty) {
      _addBotMessage(
        'You need to create an account first before logging transactions. '
        'Go to Menu → Accounts → Add to create one!'
      );
      return;
    }

    if (accounts.length == 1) {
      // Only one account — use it automatically
      final updated = result.copyWith(
        accountId: accounts.first.id,
        accountName: accounts.first.name,
      );
      state = state.copyWith(
        conversationState: ChatConversationState.pendingConfirmation,
        pendingResult: updated,
        pendingRawInput: rawInput,
      );
      _addMessage(ChatMessage(
        id: _nextId(),
        type: ChatMessageType.confirmation,
        text: '',
        timestamp: DateTime.now(),
        parseResult: updated,
      ));
    } else {
      // Multiple accounts — ask user to pick
      state = state.copyWith(
        conversationState: ChatConversationState.pendingAccountSelection,
        pendingResult: result,
        pendingRawInput: rawInput,
      );
      final accountList = accounts.asMap().entries
          .map((e) => '${e.key + 1}. ${e.value.name} (₱${_formatAmount(e.value.balance)})')
          .join('\n');
      final action = result.isIncome ? 'add this to' : 'deduct this from';
      _addBotMessage('Which account should I $action?\n\n$accountList\n\nReply with the number or name.');
    }
  }

  String _buildGuideResponse(List<GuideSearchResult> results) {
    final name = engine.assistantName;
    final personality = engine.personality;

    if (results.length == 1) {
      final r = results.first;
      final icon = r.type == 'guide' ? '📖' : '✅';
      final prefix = switch (personality) {
        AiPersonality.strictNanay => 'Eto, anak, nabasa ko sa guide natin:',
        AiPersonality.chillBestFriend => 'Oh nice question! Based sa guide natin:',
        AiPersonality.professionalAdvisor => 'Based on our guide "${r.title}":',
        AiPersonality.motivationalCoach => 'Great question! Here\'s what I found:',
        AiPersonality.kuripotTita => 'Ay alam ko yan! Sabi sa guide:',
      };
      return '$prefix\n\n${r.excerpt}\n\n$icon ${r.title}\n→ ${r.route}';
    }

    // Multiple results
    final prefix = switch (personality) {
      AiPersonality.strictNanay => 'May nakita akong related sa tanong mo, anak:',
      AiPersonality.chillBestFriend => 'Found a few things about that, bro:',
      AiPersonality.professionalAdvisor => 'I found several relevant resources:',
      AiPersonality.motivationalCoach => 'Great question! Here are some helpful guides:',
      AiPersonality.kuripotTita => 'Marami akong nakita, basahin mo lahat para sulit:',
    };

    final items = results.asMap().entries.map((e) {
      final r = e.value;
      final icon = r.type == 'guide' ? '📖' : '✅';
      return '${e.key + 1}. $icon ${r.title}\n   ${r.excerpt.length > 100 ? '${r.excerpt.substring(0, 100)}...' : r.excerpt}\n   → ${r.route}';
    }).join('\n\n');

    return '$prefix\n\n$items';
  }

  void _addBotMessage(String text) {
    _addMessage(ChatMessage(
      id: _nextId(),
      type: ChatMessageType.bot,
      text: text,
      timestamp: DateTime.now(),
    ));
  }

  void _addMessage(ChatMessage msg) {
    state = state.copyWith(messages: [...state.messages, msg]);
  }

  String _formatAmount(double amount) {
    if (amount == amount.roundToDouble()) {
      return _formatWithCommas(amount.toInt().toString());
    }
    final parts = amount.toStringAsFixed(2).split('.');
    return '${_formatWithCommas(parts[0])}.${parts[1]}';
  }

  String _formatWithCommas(String number) {
    final result = StringBuffer();
    final len = number.length;
    for (var i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0) result.write(',');
      result.write(number[i]);
    }
    return result.toString();
  }
}
