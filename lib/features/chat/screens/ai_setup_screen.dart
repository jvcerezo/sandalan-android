import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/chat/personality_templates.dart';

/// First-time setup flow for the Sandalan AI assistant.
/// Shows a 3-step onboarding: name, personality, tutorial.
class AiSetupScreen extends StatefulWidget {
  final VoidCallback? onComplete;
  const AiSetupScreen({super.key, this.onComplete});

  /// Check if AI setup has been completed.
  static Future<bool> isSetupComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('ai_setup_complete') ?? false;
  }

  /// Get the saved assistant name.
  static Future<String> getAssistantName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('ai_assistant_name') ?? 'Sandalan AI';
  }

  /// Get the saved personality.
  static Future<AiPersonality> getPersonality() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString('ai_personality') ?? 'chill_best_friend';
    return AiPersonalityX.fromKey(key);
  }

  @override
  State<AiSetupScreen> createState() => _AiSetupScreenState();
}

class _AiSetupScreenState extends State<AiSetupScreen> {
  int _step = 0; // 0 = name, 1 = personality, 2 = tutorial
  final _nameController = TextEditingController(text: 'Sandalan AI');
  AiPersonality _selectedPersonality = AiPersonality.chillBestFriend;

  final _nameSuggestions = [
    'Aling Nena',
    'Kuya Jun',
    'Ate Sam',
    'Buddy',
    'Peso',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _completeSetup() async {
    final prefs = await SharedPreferences.getInstance();
    final name = _nameController.text.trim().isEmpty
        ? 'Sandalan AI'
        : _nameController.text.trim();
    await prefs.setString('ai_assistant_name', name);
    await prefs.setString('ai_personality', _selectedPersonality.key);
    await prefs.setBool('ai_setup_complete', true);

    if (mounted) {
      if (widget.onComplete != null) {
        widget.onComplete!();
      } else {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Up Your AI'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () {
            if (widget.onComplete != null) {
              // Inline mode — just skip setup and show chat
              widget.onComplete!();
            } else if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop(false);
            } else {
              GoRouter.of(context).go('/home');
            }
          },
        ),
      ),
      body: Column(
        children: [
          // Step indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                _StepDot(active: _step >= 0, current: _step == 0, cs: cs),
                Expanded(child: Container(
                  height: 2,
                  color: _step >= 1 ? cs.primary : cs.outlineVariant,
                )),
                _StepDot(active: _step >= 1, current: _step == 1, cs: cs),
                Expanded(child: Container(
                  height: 2,
                  color: _step >= 2 ? cs.primary : cs.outlineVariant,
                )),
                _StepDot(active: _step >= 2, current: _step == 2, cs: cs),
              ],
            ),
          ),

          // Content
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _step == 0
                  ? _buildNameStep(cs, tt)
                  : _step == 1
                      ? _buildPersonalityStep(cs, tt)
                      : _buildTutorialStep(cs, tt),
            ),
          ),

          // Navigation buttons
          Padding(
            padding: EdgeInsets.only(
              left: 24, right: 24, top: 12,
              bottom: MediaQuery.of(context).padding.bottom + 12,
            ),
            child: Row(
              children: [
                if (_step > 0)
                  TextButton(
                    onPressed: () => setState(() => _step--),
                    child: const Text('Back'),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: () {
                    if (_step < 2) {
                      setState(() => _step++);
                    } else {
                      _completeSetup();
                    }
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(_step < 2 ? 'Next' : 'Get Started'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step 1: Name ────────────────────────────────────────────────────

  Widget _buildNameStep(ColorScheme cs, TextTheme tt) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Name your assistant',
              style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('What should I call your AI assistant?',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 24),

          // Name input
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Assistant name',
              hintText: 'Enter a name...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(LucideIcons.bot, size: 20),
            ),
            style: tt.bodyLarge,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),

          // Suggestions
          Text('Suggestions', style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _nameSuggestions.map((name) => ActionChip(
              label: Text(name),
              onPressed: () {
                _nameController.text = name;
                _nameController.selection = TextSelection.fromPosition(
                  TextPosition(offset: name.length),
                );
              },
            )).toList(),
          ),
        ],
      ),
    );
  }

  // ─── Step 2: Personality ─────────────────────────────────────────────

  Widget _buildPersonalityStep(ColorScheme cs, TextTheme tt) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Choose a personality',
              style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('How should your assistant talk to you?',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 20),

          ...AiPersonality.values.map((p) => _PersonalityCard(
            personality: p,
            selected: _selectedPersonality == p,
            onTap: () => setState(() => _selectedPersonality = p),
            cs: cs,
            tt: tt,
          )),
        ],
      ),
    );
  }

  // ─── Step 3: Tutorial ────────────────────────────────────────────────

  Widget _buildTutorialStep(ColorScheme cs, TextTheme tt) {
    final name = _nameController.text.trim().isEmpty
        ? 'Sandalan AI'
        : _nameController.text.trim();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Meet $name!',
              style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Here\'s what you can do:',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 24),

          _ExampleCard(
            icon: LucideIcons.plus,
            title: 'Log transactions',
            examples: [
              '"lunch 250"',
              '"sahod 30k"',
              '"grab 150 gcash"',
              '"bumili kape 150"',
            ],
            cs: cs,
            tt: tt,
          ),
          const SizedBox(height: 12),

          _ExampleCard(
            icon: LucideIcons.search,
            title: 'Ask about your money',
            examples: [
              '"net worth ko"',
              '"gastos ko this month"',
              '"magkano sa food?"',
              '"bayarin ko"',
            ],
            cs: cs,
            tt: tt,
          ),
          const SizedBox(height: 12),

          _ExampleCard(
            icon: LucideIcons.lightbulb,
            title: 'Get financial tips',
            examples: [
              '"payo naman"',
              '"paano mag-ipon?"',
              '"compute tax sa 30000"',
              '"magkano SSS ko?"',
            ],
            cs: cs,
            tt: tt,
          ),
          const SizedBox(height: 24),

          Center(
            child: Text(
              '$name uses ${_selectedPersonality.emoji} ${_selectedPersonality.label} personality',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helper widgets ──────────────────────────────────────────────────

class _StepDot extends StatelessWidget {
  final bool active;
  final bool current;
  final ColorScheme cs;

  const _StepDot({required this.active, required this.current, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: current ? 12 : 8,
      height: current ? 12 : 8,
      decoration: BoxDecoration(
        color: active ? cs.primary : cs.outlineVariant,
        shape: BoxShape.circle,
        border: current ? Border.all(color: cs.primary, width: 2) : null,
      ),
    );
  }
}

class _PersonalityCard extends StatelessWidget {
  final AiPersonality personality;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme cs;
  final TextTheme tt;

  const _PersonalityCard({
    required this.personality,
    required this.selected,
    required this.onTap,
    required this.cs,
    required this.tt,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? cs.primary.withOpacity(0.06) : cs.surfaceContainerLowest,
          border: Border.all(
            color: selected ? cs.primary : cs.outlineVariant.withOpacity(0.5),
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(personality.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(personality.label,
                      style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(personality.description,
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.3)),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, color: cs.primary, size: 22),
          ],
        ),
      ),
    );
  }
}

class _ExampleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> examples;
  final ColorScheme cs;
  final TextTheme tt;

  const _ExampleCard({
    required this.icon,
    required this.title,
    required this.examples,
    required this.cs,
    required this.tt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: cs.primary),
            const SizedBox(width: 8),
            Text(title, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 8),
          ...examples.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(children: [
              const SizedBox(width: 24),
              Icon(LucideIcons.chevronRight, size: 12, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(e, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            ]),
          )),
        ],
      ),
    );
  }
}
