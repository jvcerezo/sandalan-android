import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/env.dart';

/// Service that sends chat messages to Groq API (Qwen model)
/// with Sandalan-specific system prompt and user financial context.
class GroqAiService {
  static const _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const _model = 'qwen/qwen3-32b'; // Qwen 3 32B on Groq

  /// Send a message to Groq and get an AI response.
  ///
  /// [userMessage] — what the user typed
  /// [personality] — one of: strict_nanay, chill_best_friend, professional_advisor, motivational_coach, kuripot_tita
  /// [assistantName] — the user's chosen name for the AI
  /// [financialContext] — JSON string with user's accounts, balances, recent transactions, budgets, goals, debts
  /// [guideContext] — relevant guide excerpts from search (optional)
  static Future<GroqResponse> chat({
    required String userMessage,
    required String personality,
    required String assistantName,
    String financialContext = '',
    String guideContext = '',
  }) async {
    final systemPrompt = _buildSystemPrompt(
      personality: personality,
      assistantName: assistantName,
      financialContext: financialContext,
      guideContext: guideContext,
    );

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer ${Env.groqApiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userMessage},
          ],
          'max_tokens': 1024,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        var content = data['choices'][0]['message']['content'] as String;

        // Strip <think>...</think> reasoning blocks from Qwen 3 responses
        content = content.replaceAll(RegExp(r'<think>[\s\S]*?</think>\s*', multiLine: true), '').trim();

        // Check if the response contains a JSON action
        final action = _parseAction(content);

        return GroqResponse(
          message: action?.message ?? content,
          action: action,
          isError: false,
        );
      } else if (response.statusCode == 429) {
        return const GroqResponse(
          message: 'Rate limited — sandali lang, try again in a few seconds.',
          isError: true,
        );
      } else {
        return GroqResponse(
          message: 'AI error (${response.statusCode}). Using offline mode.',
          isError: true,
        );
      }
    } catch (e) {
      return GroqResponse(
        message: 'Cannot reach AI server. Using offline mode.',
        isError: true,
      );
    }
  }

  static String _buildSystemPrompt({
    required String personality,
    required String assistantName,
    required String financialContext,
    required String guideContext,
  }) {
    final personalityDesc = _personalityDescriptions[personality] ?? _personalityDescriptions['chill_best_friend']!;

    return '''You are "$assistantName", a Filipino personal finance assistant for the app "Sandalan — Gabay sa Bawat Hakbang".

PERSONALITY: $personalityDesc

LANGUAGE RULES:
- Respond in Taglish (mixed Tagalog-English), matching the user's style
- Keep responses concise (2-4 sentences max unless they ask for detail)
- Use Filipino expressions naturally: "Uy", "Ay", "Nako", "Sige", "Ayos"
- Never use formal/academic Filipino — be conversational

CAPABILITIES:
1. LOG TRANSACTIONS: When the user wants to add an expense or income, respond with a JSON block:
   ```json
   {"action": "add_expense", "amount": 500, "category": "Food", "description": "lunch"}
   ```
   or
   ```json
   {"action": "add_income", "amount": 25000, "category": "Salary", "description": "monthly salary"}
   ```
   Always include a conversational message BEFORE the JSON.

2. ANSWER FINANCIAL QUESTIONS: Use the user's actual financial data below.

3. ADULTING GUIDANCE: Answer questions about Philippine government IDs, SSS, PhilHealth, Pag-IBIG, BIR, etc.

4. FINANCIAL ADVICE: Give practical, Filipino-context advice.

PHILIPPINE FINANCIAL KNOWLEDGE:
- SSS: 14% total contribution (employee 4.5%, employer 9.5%), MSC range ₱4,000-₱30,000
- PhilHealth: 5% premium split 50/50, salary cap ₱100,000
- Pag-IBIG: 2% employee + 2% employer, max ₱5,000 salary base, MP2 earns 6-7% dividends
- TRAIN Law brackets: 0% up to ₱250K, 15% ₱250K-₱400K, 20% ₱400K-₱800K, 25% ₱800K-₱2M, 30% ₱2M-₱8M, 35% above ₱8M
- 13th month pay: (Basic Salary × Months Worked) ÷ 12, tax-exempt up to ₱90,000

USER'S FINANCIAL DATA:
$financialContext

${guideContext.isNotEmpty ? 'RELEVANT GUIDE CONTENT:\n$guideContext' : ''}

IMPORTANT RULES:
- NEVER make up financial data. Only use what's provided above.
- If you don't know something, say "Hindi ko sure, but..." and suggest where to check.
- Always use ₱ for Philippine Peso.
- Keep it warm, helpful, and in-character.''';
  }

  static final _personalityDescriptions = {
    'strict_nanay': 'You are a strict but caring Filipino nanay. You scold gently when they overspend but always show love. Use expressions like "Hay nako, anak!", "Sige na nga", "Mag-ipon ka na!"',
    'chill_best_friend': 'You are their chill best friend. Casual, supportive, uses Taglish slang. "Uy nice!", "Solid!", "Chill lang bro". Never judgmental, always encouraging.',
    'professional_advisor': 'You are a professional financial advisor. Data-driven, precise, gives analysis with numbers. Still warm but formal. "Based on your data...", "I recommend..."',
    'motivational_coach': 'You are an energetic motivational coach. Always positive, celebrates every win, encourages on setbacks. "You got this!", "Every peso counts!", "Amazing progress!"',
    'kuripot_tita': 'You are the ultimate kuripot (frugal) tita. Always finding ways to save, questions every purchase. "Bakit ka bumili nyan?!", "Mag-tipid ka!", "Mas mura sa palengke!"',
  };

  /// Parse a JSON action from the AI response if present.
  static _AiAction? _parseAction(String content) {
    try {
      // Look for JSON block in the response
      final jsonMatch = RegExp(r'\{[^{}]*"action"[^{}]*\}').firstMatch(content);
      if (jsonMatch == null) return null;

      final json = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
      final action = json['action'] as String?;
      if (action == null) return null;

      // Extract the message (everything before the JSON block)
      final messageEnd = content.indexOf(jsonMatch.group(0)!);
      final message = content.substring(0, messageEnd).trim();

      return _AiAction(
        type: action,
        amount: (json['amount'] as num?)?.toDouble(),
        category: json['category'] as String?,
        description: json['description'] as String?,
        message: message.isNotEmpty ? message : null,
      );
    } catch (_) {
      return null;
    }
  }
}

class GroqResponse {
  final String message;
  final _AiAction? action;
  final bool isError;

  const GroqResponse({
    required this.message,
    this.action,
    this.isError = false,
  });
}

class _AiAction {
  final String type; // add_expense, add_income, transfer
  final double? amount;
  final String? category;
  final String? description;
  final String? message;

  const _AiAction({
    required this.type,
    this.amount,
    this.category,
    this.description,
    this.message,
  });
}
