import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../data/models/chat_models.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isUser;
  final VoidCallback? onReport;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isUser,
    this.onReport,
  });

  bool get _isReportVisible {
    if (!message.reportable || onReport == null) return false;
    // Report button visible for 24 hours after message
    final age = DateTime.now().difference(message.timestamp);
    return age.inHours < 24;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? cs.primary : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
                  bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
                ),
              ),
              child: _RichMarkdownText(
                text: message.text,
                baseStyle: tt.bodyMedium?.copyWith(
                  color: isUser ? cs.onPrimary : cs.onSurface,
                  height: 1.4,
                ) ?? const TextStyle(),
              ),
            ),
            if (_isReportVisible)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: GestureDetector(
                  onTap: onReport,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.flag, size: 12, color: cs.onSurfaceVariant.withOpacity(0.5)),
                      const SizedBox(width: 4),
                      Text(
                        'Report',
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant.withOpacity(0.5),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Lightweight inline markdown renderer for chat bubbles.
/// Supports **bold** and *italic* without pulling in a full markdown package.
class _RichMarkdownText extends StatelessWidget {
  final String text;
  final TextStyle baseStyle;

  const _RichMarkdownText({required this.text, required this.baseStyle});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      _parse(text),
      style: baseStyle,
    );
  }

  TextSpan _parse(String input) {
    final spans = <InlineSpan>[];
    // Match **bold**, *italic*, and plain text segments
    final regex = RegExp(r'\*\*(.+?)\*\*|\*(.+?)\*');
    int lastEnd = 0;

    for (final match in regex.allMatches(input)) {
      // Add plain text before this match
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: input.substring(lastEnd, match.start)));
      }

      if (match.group(1) != null) {
        // **bold**
        spans.add(TextSpan(
          text: match.group(1),
          style: baseStyle.copyWith(fontWeight: FontWeight.w700),
        ));
      } else if (match.group(2) != null) {
        // *italic*
        spans.add(TextSpan(
          text: match.group(2),
          style: baseStyle.copyWith(fontStyle: FontStyle.italic),
        ));
      }

      lastEnd = match.end;
    }

    // Remaining plain text
    if (lastEnd < input.length) {
      spans.add(TextSpan(text: input.substring(lastEnd)));
    }

    return TextSpan(children: spans);
  }
}
