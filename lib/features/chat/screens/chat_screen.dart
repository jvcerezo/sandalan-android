import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../data/models/chat_models.dart';
import '../providers/chat_providers.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/confirmation_card.dart';
import '../widgets/category_picker_inline.dart';
import 'ai_setup_screen.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  bool _showWelcome = true;
  bool _checkingSetup = true;
  String _assistantName = 'Sandalan AI';

  @override
  void initState() {
    super.initState();
    _checkSetup();
  }

  bool _showSetup = false;

  Future<void> _checkSetup() async {
    final isComplete = await AiSetupScreen.isSetupComplete();
    if (!isComplete && mounted) {
      setState(() {
        _showSetup = true;
        _checkingSetup = false;
      });
    } else if (mounted) {
      final name = await AiSetupScreen.getAssistantName();
      setState(() {
        _assistantName = name;
        _checkingSetup = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    setState(() => _showWelcome = false);
    ref.read(chatStateProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingSetup) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_showSetup) {
      return AiSetupScreen(
        onComplete: () async {
          final name = await AiSetupScreen.getAssistantName();
          if (mounted) {
            setState(() {
              _assistantName = name;
              _showSetup = false;
              _checkingSetup = false;
            });
          }
        },
      );
    }

    final chatState = ref.watch(chatStateProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Auto-scroll when messages change
    if (chatState.messages.isNotEmpty) {
      _scrollToBottom();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_assistantName),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.settings2, size: 20),
            onPressed: () async {
              await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => const AiSetupScreen()),
              );
              if (mounted) {
                final name = await AiSetupScreen.getAssistantName();
                setState(() => _assistantName = name);
              }
            },
            tooltip: 'AI Settings',
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── Messages ─────────────────────────────────────────────
          Expanded(
            child: chatState.messages.isEmpty && _showWelcome
                ? _buildWelcome(cs, tt)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: chatState.messages.length,
                    itemBuilder: (context, index) {
                      final msg = chatState.messages[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildMessage(msg, cs),
                      );
                    },
                  ),
          ),

          // ─── Processing indicator ──────────────────────────────────
          if (chatState.isProcessing)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
                  ),
                  const SizedBox(width: 8),
                  Text('Thinking...', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
            ),

          // ─── Input bar ─────────────────────────────────────────────
          _buildInputBar(cs, tt),
        ],
      ),
    );
  }

  Widget _buildWelcome(ColorScheme cs, TextTheme tt) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.messageCircle, size: 48, color: cs.primary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(_assistantName, style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Log transactions or ask about your finances using natural language.',
              textAlign: TextAlign.center,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _QuickChip(label: 'lunch 250', onTap: () => _quickSend('lunch 250')),
                _QuickChip(label: 'net worth ko', onTap: () => _quickSend('net worth ko')),
                _QuickChip(label: 'gastos ko', onTap: () => _quickSend('gastos ko')),
                _QuickChip(label: 'salary 30k', onTap: () => _quickSend('salary 30k')),
                _QuickChip(label: 'payo naman', onTap: () => _quickSend('payo naman')),
                _QuickChip(label: 'hello', onTap: () => _quickSend('hello')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _quickSend(String text) {
    _controller.text = text;
    _send();
  }

  Widget _buildMessage(ChatMessage msg, ColorScheme cs) {
    switch (msg.type) {
      case ChatMessageType.user:
        return ChatBubble(message: msg, isUser: true);
      case ChatMessageType.bot:
        return ChatBubble(
          message: msg,
          isUser: false,
          onReport: msg.reportable ? () => _showReportDialog(msg) : null,
        );
      case ChatMessageType.confirmation:
        return ConfirmationCard(
          parseResult: msg.parseResult!,
          onConfirm: () => ref.read(chatStateProvider.notifier).confirmTransaction(),
          onCancel: () => ref.read(chatStateProvider.notifier).cancelTransaction(),
          onEditCategory: () {
            // Show category picker
            ref.read(chatStateProvider.notifier).cancelTransaction();
          },
        );
      case ChatMessageType.categoryPicker:
        return CategoryPickerInline(
          isIncome: ref.read(chatStateProvider).pendingResult?.isIncome ?? false,
          onSelected: (cat) => ref.read(chatStateProvider.notifier).selectCategory(cat),
        );
    }
  }

  void _showReportDialog(ChatMessage msg) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ReportSheet(
        message: msg,
        onReport: (type, {correctedCategory, correctedAmount, userComment}) {
          ref.read(chatStateProvider.notifier).reportError(
            messageId: msg.id,
            errorType: type,
            correctedCategory: correctedCategory,
            correctedAmount: correctedAmount,
            userComment: userComment,
          );
          Navigator.pop(ctx);
        },
      ),
    );
  }

  Widget _buildInputBar(ColorScheme cs, TextTheme tt) {
    return Container(
      padding: EdgeInsets.only(
        left: 16, right: 8, top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: "lunch 250, net worth ko...",
                hintStyle: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: cs.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: cs.primary),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                isDense: true,
              ),
              style: tt.bodyMedium,
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: _send,
            icon: Icon(LucideIcons.send, color: cs.primary),
            style: IconButton.styleFrom(
              backgroundColor: cs.primary.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quick action chip ───────────────────────────────────────────────────

class _QuickChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _QuickChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, color: cs.onSurface)),
      ),
    );
  }
}

// ─── Report bottom sheet ─────────────────────────────────────────────────

class _ReportSheet extends StatefulWidget {
  final ChatMessage message;
  final void Function(
    CorrectionType type, {
    String? correctedCategory,
    double? correctedAmount,
    String? userComment,
  }) onReport;

  const _ReportSheet({required this.message, required this.onReport});

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  CorrectionType? _selectedType;
  String? _selectedCategory;
  final _amountController = TextEditingController();
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What did I get wrong?', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          if (_selectedType == null) ...[
            // Step 1: Pick error type
            _ErrorTypeButton('Wrong category', CorrectionType.category, cs),
            _ErrorTypeButton('Wrong amount', CorrectionType.amount, cs),
            _ErrorTypeButton('Wrong account', CorrectionType.account, cs),
            _ErrorTypeButton('Wrong type (income/expense)', CorrectionType.type, cs),
            _ErrorTypeButton('Something else', CorrectionType.other, cs),
          ] else ...[
            // Step 2: Correction input
            _buildCorrectionInput(cs, tt),
          ],

          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _ErrorTypeButton(String label, CorrectionType type, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () {
            if (type == CorrectionType.type) {
              // Instant — just flip it
              widget.onReport(type);
              return;
            }
            setState(() => _selectedType = type);
          },
          style: OutlinedButton.styleFrom(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: Text(label),
        ),
      ),
    );
  }

  Widget _buildCorrectionInput(ColorScheme cs, TextTheme tt) {
    switch (_selectedType!) {
      case CorrectionType.category:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('What should it be?', style: tt.bodyMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                'Food', 'Housing', 'Transportation', 'Entertainment',
                'Healthcare', 'Education', 'Family Support', 'Other',
              ].map((cat) => ChoiceChip(
                label: Text(cat, style: const TextStyle(fontSize: 12)),
                selected: _selectedCategory == cat,
                onSelected: (sel) {
                  if (sel) {
                    widget.onReport(CorrectionType.category, correctedCategory: cat);
                  }
                },
              )).toList(),
            ),
          ],
        );

      case CorrectionType.amount:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('What\'s the correct amount?', style: tt.bodyMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      prefixText: 'PHP ',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    final amount = double.tryParse(_amountController.text.replaceAll(',', ''));
                    if (amount != null && amount > 0) {
                      widget.onReport(CorrectionType.amount, correctedAmount: amount);
                    }
                  },
                  child: const Text('Fix'),
                ),
              ],
            ),
          ],
        );

      case CorrectionType.other:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('What went wrong?', style: tt.bodyMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Describe the issue...',
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () {
                widget.onReport(CorrectionType.other, userComment: _commentController.text);
              },
              child: const Text('Submit'),
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }
}
