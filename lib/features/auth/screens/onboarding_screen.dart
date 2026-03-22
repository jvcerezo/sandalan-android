import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/guest_mode_service.dart';
import '../../../shared/widgets/brand_mark.dart';
import '../../../shared/widgets/tour_overlay.dart';
import '../../../core/constants/account_types.dart';
import '../providers/auth_provider.dart';

// ─── Data ─────────────────────────────────────────────────────────────────────

class _LifeStageOption {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  const _LifeStageOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
  });
}

final _lifeStages = [
  _LifeStageOption(
      id: 'unang-hakbang', title: 'Unang Hakbang', subtitle: 'Fresh grad / First job',
      description: 'Getting IDs, first payslip, learning the basics', icon: LucideIcons.graduationCap),
  _LifeStageOption(
      id: 'pundasyon', title: 'Pundasyon', subtitle: 'Building foundations',
      description: 'Saving, budgeting, building credit', icon: LucideIcons.toyBrick),
  _LifeStageOption(
      id: 'tahanan', title: 'Tahanan', subtitle: 'Establishing a home',
      description: 'Renting, buying property, starting a family', icon: LucideIcons.home),
  _LifeStageOption(
      id: 'tugatog', title: 'Tugatog', subtitle: 'Career peak',
      description: 'Growing wealth, investments, insurance', icon: LucideIcons.mountain),
  _LifeStageOption(
      id: 'paghahanda', title: 'Paghahanda', subtitle: 'Pre-retirement',
      description: 'Estate planning, retirement prep', icon: LucideIcons.clock),
  _LifeStageOption(
      id: 'gintong-taon', title: 'Gintong Taon', subtitle: 'Golden years',
      description: 'Enjoying retirement, legacy planning', icon: LucideIcons.gem),
];

class _UserTypeOption {
  final String id;
  final String label;
  final String description;
  final IconData icon;
  const _UserTypeOption({required this.id, required this.label, required this.description, required this.icon});
}

final _userTypes = [
  _UserTypeOption(
      id: 'student', label: 'Student', icon: LucideIcons.bookOpen,
      description: 'Managing baon, part-time income, school expenses'),
  _UserTypeOption(
      id: 'fresh-grad', label: 'Fresh Graduate', icon: LucideIcons.graduationCap,
      description: 'First job, first salary, first adulting steps'),
  _UserTypeOption(
      id: 'employee', label: 'Employee', icon: LucideIcons.briefcase,
      description: 'Regular salary, benefits, payslip deductions'),
  _UserTypeOption(
      id: 'freelancer', label: 'Freelancer / Self-Employed', icon: LucideIcons.laptop,
      description: 'Irregular income, own taxes, no employer benefits'),
  _UserTypeOption(
      id: 'ofw', label: 'OFW', icon: LucideIcons.plane,
      description: 'Remittances, dual currency, family support'),
  _UserTypeOption(
      id: 'business-owner', label: 'Business Owner', icon: LucideIcons.store,
      description: 'Revenue vs personal, BIR compliance, payroll'),
  _UserTypeOption(
      id: 'homemaker', label: 'Homemaker', icon: LucideIcons.home,
      description: 'Household budget, family finances, side income'),
];

class _FocusArea {
  final String id;
  final String label;
  final IconData icon;
  const _FocusArea({required this.id, required this.label, required this.icon});
}

final _focusAreas = [
  _FocusArea(id: 'track-expenses', label: 'Track my daily expenses', icon: LucideIcons.receipt),
  _FocusArea(id: 'budget-salary', label: 'Budget my salary', icon: LucideIcons.wallet),
  _FocusArea(id: 'pay-off-debt', label: 'Pay off debt', icon: LucideIcons.creditCard),
  _FocusArea(id: 'build-emergency', label: 'Build an emergency fund', icon: LucideIcons.shield),
  _FocusArea(id: 'save-for-goal', label: 'Save for a big purchase', icon: LucideIcons.target),
  _FocusArea(id: 'grow-wealth', label: 'Grow my wealth', icon: LucideIcons.trendingUp),
  _FocusArea(id: 'get-ids', label: 'Get my government IDs', icon: LucideIcons.landmark),
  _FocusArea(id: 'understand-benefits', label: 'Understand my benefits & contributions', icon: LucideIcons.piggyBank),
];

class _AddedAccount {
  String name;
  String type;
  String balance;
  _AddedAccount({required this.name, required this.type, this.balance = ''});
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;
  bool _saving = false;

  // Step 1
  String _selectedStage = '';

  // Step 2
  String _selectedUserType = '';

  // Step 3
  final Set<String> _selectedFocusAreas = {};

  // Step 4
  final List<_AddedAccount> _addedAccounts = [];
  bool _showCustomForm = false;
  final _customNameController = TextEditingController();
  String _customType = 'bank';

  @override
  void dispose() {
    _customNameController.dispose();
    super.dispose();
  }

  void _togglePreset(CommonAccount preset) {
    setState(() {
      final idx = _addedAccounts.indexWhere((a) => a.name == preset.name);
      if (idx >= 0) {
        _addedAccounts.removeAt(idx);
      } else {
        _addedAccounts.add(_AddedAccount(name: preset.name, type: preset.type));
      }
    });
  }

  void _addCustomAccount() {
    final name = _customNameController.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _addedAccounts.add(_AddedAccount(name: name, type: _customType));
      _customNameController.clear();
      _customType = 'bank';
      _showCustomForm = false;
    });
  }

  Future<void> _handleFinish() async {
    setState(() => _saving = true);
    try {
      final isGuest = GuestModeService.isGuestSync();

      if (isGuest) {
        // Guest mode: save selections locally via SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        if (_selectedStage.isNotEmpty) await prefs.setString('life_stage', _selectedStage);
        if (_selectedUserType.isNotEmpty) await prefs.setString('user_type', _selectedUserType);
        if (_selectedFocusAreas.isNotEmpty) {
          await prefs.setStringList('focus_areas', _selectedFocusAreas.toList());
        }
        await scheduleTour();
        if (mounted) context.go('/home');
        return;
      }

      final client = ref.read(supabaseClientProvider);
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;

      // Save profile personalization
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.updateProfile(
        lifeStage: _selectedStage.isNotEmpty ? _selectedStage : null,
        userType: _selectedUserType.isNotEmpty ? _selectedUserType : null,
        focusAreas: _selectedFocusAreas.isNotEmpty ? _selectedFocusAreas.toList() : null,
      );

      // Create accounts
      for (final acc in _addedAccounts) {
        final balance = double.tryParse(acc.balance) ?? 0.0;
        await client.from('accounts').insert({
          'user_id': userId,
          'name': acc.name,
          'type': acc.type,
          'currency': 'PHP',
          'balance': balance,
        });
      }

      // Complete onboarding
      await authRepo.completeOnboarding();

      // Schedule the tour to auto-start on the home screen.
      await scheduleTour();

      if (mounted) {
        final targetPath = _selectedStage.isNotEmpty ? '/guide' : '/home';
        context.go(targetPath);
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final firstName = profile.valueOrNull?.firstName ?? '';

    return Scaffold(
      body: SafeArea(
        child: _step == 0
            ? _buildWelcome(firstName)
            : _buildStepContent(),
      ),
    );
  }

  // ─── Step 0: Welcome ────────────────────────────────────────────────

  Widget _buildWelcome(String firstName) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BrandMark(size: 80, showText: false),
            const SizedBox(height: 24),
            Text(
              firstName.isNotEmpty ? 'Hey $firstName!' : 'Welcome!',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Sandalan is your companion for every stage of Filipino adult life — from your first ID to retirement.',
              style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ...[
              (LucideIcons.target, 'Step-by-step guides for every life stage'),
              (LucideIcons.wallet, 'Track finances across all your accounts'),
              (LucideIcons.landmark, 'Government IDs, taxes, contributions & more'),
            ].map((item) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(item.$1, size: 16, color: colorScheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(item.$2, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                  ]),
                )),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => setState(() => _step = 1),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [Text("Let's Go"), SizedBox(width: 6), Icon(LucideIcons.arrowRight, size: 16)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Steps 1-3 with header ──────────────────────────────────────────

  Widget _buildStepContent() {
    return Column(children: [
      // Header with progress
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Row(children: [
          SizedBox(
            width: 32, height: 32,
            child: IconButton(
              onPressed: () => setState(() => _step = _step - 1),
              icon: const Icon(LucideIcons.arrowLeft, size: 16),
              padding: EdgeInsets.zero,
              style: IconButton.styleFrom(
                side: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: _StepProgress(current: _step, total: 5)),
          const SizedBox(width: 12),
          Text('$_step/4',
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ]),
      ),
      const SizedBox(height: 16),
      Expanded(
        child: _step == 1
            ? _buildStep1()
            : _step == 2
                ? _buildStep2UserType()
                : _step == 3
                    ? _buildStep3FocusAreas()
                    : _buildStep4Accounts(),
      ),
    ]);
  }

  // ─── Step 1: Life Stage ─────────────────────────────────────────────

  Widget _buildStep1() {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Where are you in your adulting journey?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('This helps us show you the most relevant guides and checklists.',
              style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text('You can change this anytime in Settings.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6))),
        ]),
      ),
      const SizedBox(height: 16),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _lifeStages.length,
          itemBuilder: (context, i) {
            final stage = _lifeStages[i];
            final isSelected = _selectedStage == stage.id;
            return GestureDetector(
              onTap: () => setState(() => _selectedStage = stage.id),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected ? colorScheme.primary : colorScheme.outline.withValues(alpha: 0.15),
                    width: isSelected ? 1.5 : 1,
                  ),
                  color: isSelected ? colorScheme.primary.withValues(alpha: 0.05) : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: isSelected ? colorScheme.primary : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(stage.icon, size: 20,
                        color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Text(stage.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 6),
                        Text('· ${stage.subtitle}',
                            style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                      ]),
                      const SizedBox(height: 2),
                      Text(stage.description,
                          style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                    ]),
                  ),
                  if (isSelected)
                    Icon(LucideIcons.checkCircle2, size: 20, color: colorScheme.primary),
                ]),
              ),
            );
          },
        ),
      ),
      _buildFooterButtons(
        onSkip: () => setState(() => _step = 2),
        onContinue: _selectedStage.isNotEmpty ? () => setState(() => _step = 2) : null,
      ),
    ]);
  }

  // ─── Step 2: User Type ──────────────────────────────────────────────

  Widget _buildStep2UserType() {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('What best describes you?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('This helps us tailor tools, tips, and guides to your situation.',
              style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text('You can change this anytime in Settings.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6))),
        ]),
      ),
      const SizedBox(height: 16),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _userTypes.length,
          itemBuilder: (context, i) {
            final type = _userTypes[i];
            final isSelected = _selectedUserType == type.id;
            return GestureDetector(
              onTap: () => setState(() => _selectedUserType = type.id),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected ? colorScheme.primary : colorScheme.outline.withValues(alpha: 0.15),
                    width: isSelected ? 1.5 : 1,
                  ),
                  color: isSelected ? colorScheme.primary.withValues(alpha: 0.05) : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: isSelected ? colorScheme.primary : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(type.icon, size: 20,
                        color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(type.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(type.description,
                          style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                    ]),
                  ),
                  if (isSelected)
                    Icon(LucideIcons.checkCircle2, size: 20, color: colorScheme.primary),
                ]),
              ),
            );
          },
        ),
      ),
      _buildFooterButtons(
        onSkip: () => setState(() => _step = 3),
        onContinue: _selectedUserType.isNotEmpty ? () => setState(() => _step = 3) : null,
      ),
    ]);
  }

  // ─── Step 3: Focus Areas ────────────────────────────────────────────

  Widget _buildStep3FocusAreas() {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('What do you want to focus on?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text("Pick as many as you like. We'll personalize your experience.",
              style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
        ]),
      ),
      const SizedBox(height: 16),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _focusAreas.length,
          itemBuilder: (context, i) {
            final focus = _focusAreas[i];
            final isSelected = _selectedFocusAreas.contains(focus.id);
            return GestureDetector(
              onTap: () => setState(() {
                if (isSelected) {
                  _selectedFocusAreas.remove(focus.id);
                } else {
                  _selectedFocusAreas.add(focus.id);
                }
              }),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected ? colorScheme.primary : colorScheme.outline.withValues(alpha: 0.15),
                    width: isSelected ? 1.5 : 1,
                  ),
                  color: isSelected ? colorScheme.primary.withValues(alpha: 0.05) : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: isSelected ? colorScheme.primary : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(focus.icon, size: 16,
                        color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(focus.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                  if (isSelected)
                    Icon(LucideIcons.checkCircle2, size: 16, color: colorScheme.primary),
                ]),
              ),
            );
          },
        ),
      ),
      _buildFooterButtons(
        onSkip: () => setState(() => _step = 4),
        onContinue: _selectedFocusAreas.isNotEmpty ? () => setState(() => _step = 4) : null,
      ),
    ]);
  }

  // ─── Step 4: Add Accounts ───────────────────────────────────────────

  Widget _buildStep4Accounts() {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Where do you keep your money?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Add your accounts with their current balances. You can add more later.',
              style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
        ]),
      ),
      const SizedBox(height: 16),

      // Preset pills
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Wrap(spacing: 8, runSpacing: 8, children: [
          ...kCommonAccounts.map((preset) {
            final isAdded = _addedAccounts.any((a) => a.name == preset.name);
            return GestureDetector(
              onTap: () => _togglePreset(preset),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isAdded ? colorScheme.primary : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: isAdded ? Border.all(color: colorScheme.primary) : null,
                ),
                child: Text(preset.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isAdded ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                    )),
              ),
            );
          }),
          GestureDetector(
            onTap: () => setState(() => _showCustomForm = true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(LucideIcons.plus, size: 12, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text('Custom',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: colorScheme.onSurfaceVariant)),
              ]),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 12),

      // Custom form
      if (_showCustomForm)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Custom Account', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                GestureDetector(
                  onTap: () => setState(() {
                    _showCustomForm = false;
                    _customNameController.clear();
                  }),
                  child: Icon(LucideIcons.x, size: 16, color: colorScheme.onSurfaceVariant),
                ),
              ]),
              const SizedBox(height: 12),
              TextField(
                controller: _customNameController,
                decoration: const InputDecoration(labelText: 'Name', hintText: 'e.g., BDO, BPI, Tonik'),
                autofocus: true,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _customType,
                decoration: const InputDecoration(labelText: 'Type'),
                items: kAccountTypes.map((t) => DropdownMenuItem(value: t.value, child: Text(t.label))).toList(),
                onChanged: (v) => setState(() => _customType = v ?? 'bank'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _customNameController.text.trim().isEmpty ? null : _addCustomAccount,
                child: const Text('Add Account'),
              ),
            ]),
          ),
        ),

      // Account list with balances
      Expanded(
        child: _addedAccounts.isEmpty && !_showCustomForm
            ? Center(
                child: Text('Tap an account above to get started, or add a custom one.',
                    style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                itemCount: _addedAccounts.length,
                itemBuilder: (context, i) {
                  final acc = _addedAccounts[i];
                  final typeLabel = kAccountTypes
                      .firstWhere((t) => t.value == acc.type, orElse: () => kAccountTypes.first)
                      .label;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(children: [
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(LucideIcons.landmark, size: 16, color: colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(acc.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          Text(typeLabel, style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                        ]),
                      ),
                      Text('₱', style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 80,
                        child: TextField(
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          decoration: const InputDecoration(
                            hintText: '0',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                          onChanged: (v) => acc.balance = v.replaceAll(',', ''),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() => _addedAccounts.removeAt(i)),
                        child: Icon(LucideIcons.x, size: 16, color: colorScheme.onSurfaceVariant),
                      ),
                    ]),
                  );
                },
              ),
      ),

      // Footer
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Row(children: [
          TextButton(
            onPressed: _saving ? null : _handleFinish,
            child: _saving
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : Text('Skip', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: _saving ? null : _handleFinish,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 18, width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Finish Setup'),
                        SizedBox(width: 6),
                        Icon(LucideIcons.arrowRight, size: 16),
                      ],
                    ),
            ),
          ),
        ]),
      ),
    ]);
  }

  // ─── Shared footer ──────────────────────────────────────────────────

  Widget _buildFooterButtons({required VoidCallback onSkip, VoidCallback? onContinue}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(children: [
        TextButton(
          onPressed: onSkip,
          child: Text('Skip', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: onContinue,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Text('Continue'), SizedBox(width: 6), Icon(LucideIcons.arrowRight, size: 16)],
            ),
          ),
        ),
      ]),
    );
  }
}

// ─── Step Progress Bar ────────────────────────────────────────────────────────

class _StepProgress extends StatelessWidget {
  final int current;
  final int total;
  const _StepProgress({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: List.generate(total, (i) {
        return Expanded(
          child: Container(
            height: 3,
            margin: EdgeInsets.only(right: i < total - 1 ? 4 : 0),
            decoration: BoxDecoration(
              color: i < current
                  ? colorScheme.primary
                  : i == current
                      ? colorScheme.primary.withValues(alpha: 0.5)
                      : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}
