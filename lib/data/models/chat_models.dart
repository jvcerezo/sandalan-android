/// Chat AI models — message types, parse results, intents, and state machine.

// ─── Enums ────────────────────────────────────────────────────────────────

enum ChatMessageType { user, bot, confirmation, categoryPicker }

enum ChatIntent { logExpense, logIncome, query, help, transfer, unknown }

enum ChatConversationState {
  idle,
  pendingConfirmation,
  pendingCategory,
  pendingClarification,
  pendingAmountConfirmation,
  pendingIncomeConfirmation,
}

enum QueryType {
  netWorth,
  spendingSummary,
  spendingByCategory,
  budgetStatus,
  goalProgress,
  debtSummary,
  billsDue,
  recentTransactions,
  accountBalance,
  spendingInsights,
  exportCsv,
  currencyConvert,
}

enum CorrectionType {
  category,
  amount,
  account,
  type, // income vs expense
  other,
}

// ─── Parse Result ─────────────────────────────────────────────────────────

class ParseResult {
  final ChatIntent intent;
  final double? amount;
  final String? category;
  final String? description;
  final String? accountId;
  final String? accountName;
  final bool isIncome;
  final String? categorySource;
  final String? message; // bot response text for queries/errors
  final QueryType? queryType;
  final String? queryCategory; // for spending-by-category queries
  final List<double>? ambiguousAmounts; // for amount clarification
  final bool needsAmountConfirmation; // for amounts > 100k

  const ParseResult({
    required this.intent,
    this.amount,
    this.category,
    this.description,
    this.accountId,
    this.accountName,
    this.isIncome = false,
    this.categorySource,
    this.message,
    this.queryType,
    this.queryCategory,
    this.ambiguousAmounts,
    this.needsAmountConfirmation = false,
  });

  ParseResult copyWith({
    ChatIntent? intent,
    double? amount,
    String? category,
    String? description,
    String? accountId,
    String? accountName,
    bool? isIncome,
    String? categorySource,
    String? message,
    QueryType? queryType,
    String? queryCategory,
    List<double>? ambiguousAmounts,
    bool? needsAmountConfirmation,
  }) {
    return ParseResult(
      intent: intent ?? this.intent,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
      accountId: accountId ?? this.accountId,
      accountName: accountName ?? this.accountName,
      isIncome: isIncome ?? this.isIncome,
      categorySource: categorySource ?? this.categorySource,
      message: message ?? this.message,
      queryType: queryType ?? this.queryType,
      queryCategory: queryCategory ?? this.queryCategory,
      ambiguousAmounts: ambiguousAmounts ?? this.ambiguousAmounts,
      needsAmountConfirmation: needsAmountConfirmation ?? this.needsAmountConfirmation,
    );
  }
}

// ─── Chat Message ─────────────────────────────────────────────────────────

class ChatMessage {
  final String id;
  final ChatMessageType type;
  final String text;
  final DateTime timestamp;
  final ParseResult? parseResult;
  final String? transactionId; // set after commit — enables [Report] button
  final bool reportable; // true for post-commit bot messages
  final String? rawUserInput; // original user input that produced this result

  const ChatMessage({
    required this.id,
    required this.type,
    required this.text,
    required this.timestamp,
    this.parseResult,
    this.transactionId,
    this.reportable = false,
    this.rawUserInput,
  });

  ChatMessage copyWith({
    String? id,
    ChatMessageType? type,
    String? text,
    DateTime? timestamp,
    ParseResult? parseResult,
    String? transactionId,
    bool? reportable,
    String? rawUserInput,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      type: type ?? this.type,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      parseResult: parseResult ?? this.parseResult,
      transactionId: transactionId ?? this.transactionId,
      reportable: reportable ?? this.reportable,
      rawUserInput: rawUserInput ?? this.rawUserInput,
    );
  }
}

// ─── Chat UI State ────────────────────────────────────────────────────────

class ChatUiState {
  final List<ChatMessage> messages;
  final ChatConversationState conversationState;
  final ParseResult? pendingResult;
  final String? pendingRawInput;
  final bool isProcessing;

  const ChatUiState({
    this.messages = const [],
    this.conversationState = ChatConversationState.idle,
    this.pendingResult,
    this.pendingRawInput,
    this.isProcessing = false,
  });

  ChatUiState copyWith({
    List<ChatMessage>? messages,
    ChatConversationState? conversationState,
    ParseResult? pendingResult,
    String? pendingRawInput,
    bool? isProcessing,
    bool clearPending = false,
  }) {
    return ChatUiState(
      messages: messages ?? this.messages,
      conversationState: conversationState ?? this.conversationState,
      pendingResult: clearPending ? null : (pendingResult ?? this.pendingResult),
      pendingRawInput: clearPending ? null : (pendingRawInput ?? this.pendingRawInput),
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }
}
