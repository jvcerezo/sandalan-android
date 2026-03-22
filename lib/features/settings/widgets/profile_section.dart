import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/input_sanitizer.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/services/guest_mode_service.dart';
import '../../auth/providers/auth_provider.dart';
import 'settings_shared.dart';

class ProfileSection extends ConsumerStatefulWidget {
  final Widget back;
  const ProfileSection({super.key, required this.back});

  @override
  ConsumerState<ProfileSection> createState() => _ProfileSectionState();
}

class _ProfileSectionState extends ConsumerState<ProfileSection> {
  late TextEditingController _nameCtl;
  bool _initialized = false;

  @override
  void dispose() {
    _nameCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final profile = ref.watch(profileProvider).valueOrNull;

    // Initialize controller once when profile is available
    if (!_initialized) {
      _nameCtl = TextEditingController(text: profile?.fullName ?? '');
      _initialized = true;
    }

    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 80), children: [
      widget.back,
      SettingsCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        Text('Your personal information and account details',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        const SizedBox(height: 16),
        // Avatar
        Row(children: [
          CircleAvatar(
              radius: 32,
              backgroundColor: cs.surfaceContainerHighest,
              backgroundImage: profile?.avatarUrl != null && profile!.avatarUrl!.isNotEmpty
                  ? NetworkImage(profile.avatarUrl!)
                  : null,
              child: profile?.avatarUrl == null || profile!.avatarUrl!.isEmpty
                  ? Icon(LucideIcons.user, size: 28, color: cs.onSurfaceVariant)
                  : null),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(profile?.fullName ?? 'User',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            Text(profile?.email ?? '', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            const SizedBox(height: 6),
            Row(children: [
              OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      textStyle: const TextStyle(fontSize: 11)),
                  child: const Text('Change Photo')),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Row(children: [
                    Icon(LucideIcons.x, size: 12, color: AppColors.expense),
                    const SizedBox(width: 2),
                    const Text('Remove',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.expense,
                            fontWeight: FontWeight.w500)),
                  ]),
                ),
              ),
            ]),
            Text('JPG, PNG or WebP \u00B7 Max 2 MB',
                style: TextStyle(fontSize: 9, color: cs.onSurfaceVariant)),
          ]),
        ]),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 12),
        // Email
        const Text('Email', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        TextField(
            readOnly: true,
            decoration: InputDecoration(isDense: true, hintText: profile?.email ?? '')),
        Text('Your email address cannot be changed',
            style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
        const SizedBox(height: 14),
        // Full Name
        const Text('Full Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        TextField(controller: _nameCtl, decoration: const InputDecoration(isDense: true)),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 12),
        // Life Stage
        const Text('Life Stage', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: _lifeStageOptions.containsKey(profile?.lifeStage) ? profile?.lifeStage : null,
          decoration: const InputDecoration(isDense: true, hintText: 'Select your life stage'),
          items: _lifeStageOptions.entries
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: (v) async {
            if (v == null) return;
            if (GuestModeService.isGuestSync()) {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('life_stage', v);
            } else {
              await ref.read(authRepositoryProvider).updateProfile(lifeStage: v);
            }
            ref.invalidate(profileProvider);
          },
        ),
        const SizedBox(height: 14),
        // User Type
        const Text('I am a...', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: _userTypeOptions.containsKey(profile?.userType) ? profile?.userType : null,
          decoration: const InputDecoration(isDense: true, hintText: 'Select what describes you'),
          items: _userTypeOptions.entries
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: (v) async {
            if (v == null) return;
            if (GuestModeService.isGuestSync()) {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('user_type', v);
            } else {
              await ref.read(authRepositoryProvider).updateProfile(userType: v);
            }
            ref.invalidate(profileProvider);
          },
        ),
        Text('Changing this updates which guides are recommended for you.',
            style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
        const SizedBox(height: 16),
        FilledButton(
            onPressed: () async {
              await ref
                  .read(profileRepositoryProvider)
                  .updateProfile(fullName: InputSanitizer.sanitize(_nameCtl.text));
              ref.invalidate(profileProvider);
            },
            style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                minimumSize: const Size(double.infinity, 0)),
            child: const Text('Save Name')),
        const SizedBox(height: 8),
        Text('Member since ${profile?.createdAt.substring(0, 10) ?? ''}',
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
      ])),
    ]);
  }
}

const _lifeStageOptions = {
  'unang-hakbang': 'Unang Hakbang — Fresh grad / First job',
  'pundasyon': 'Pundasyon — Building foundations',
  'tahanan': 'Tahanan — Establishing a home',
  'tugatog': 'Tugatog — Career peak',
  'paghahanda': 'Paghahanda — Pre-retirement',
  'gintong-taon': 'Gintong Taon — Golden years',
};

const _userTypeOptions = {
  'student': 'Student',
  'fresh-grad': 'Fresh Graduate',
  'employee': 'Employee',
  'freelancer': 'Freelancer / Self-Employed',
  'ofw': 'OFW',
  'business-owner': 'Business Owner',
  'homemaker': 'Homemaker',
};
