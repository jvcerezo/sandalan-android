import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../app.dart';
import 'settings_shared.dart';

class HomePageSection extends ConsumerStatefulWidget {
  final Widget back;
  const HomePageSection({super.key, required this.back});

  @override
  ConsumerState<HomePageSection> createState() => _HomePageSectionState();
}

class _HomePageSectionState extends ConsumerState<HomePageSection> {
  bool _upcoming = true, _nextSteps = true, _financial = true, _stage = true;

  static const _landingPages = <String, String>{
    '/home': 'Home',
    '/dashboard': 'Dashboard',
    '/transactions': 'Transactions',
    '/guide': 'Guide',
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final landingPage = ref.watch(defaultLandingPageProvider);

    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 80), children: [
      widget.back,
      // Default Landing Page
      SettingsCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(LucideIcons.home, size: 18, color: cs.onSurface),
          const SizedBox(width: 8),
          const Text('Start Page', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ]),
        Text('Choose which page opens when you launch Sandalan',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        const SizedBox(height: 10),
        ..._landingPages.entries.map((e) => InkWell(
              onTap: () => ref.read(defaultLandingPageProvider.notifier).setPage(e.key),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(children: [
                  Icon(
                    landingPage == e.key ? Icons.radio_button_checked : Icons.radio_button_off,
                    size: 18,
                    color: landingPage == e.key ? cs.primary : cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10),
                  Text(e.value,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: landingPage == e.key ? FontWeight.w600 : FontWeight.w400)),
                ]),
              ),
            )),
      ])),
      const SizedBox(height: 12),
      // Home page sections
      SettingsCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(LucideIcons.layoutGrid, size: 18, color: cs.onSurface),
          const SizedBox(width: 8),
          const Text('Home Sections', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ]),
        Text('Choose which sections appear on your Home page',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        const SizedBox(height: 8),
        SettingsToggleRow(
            title: 'Upcoming Payments',
            sub: 'Show bills, contributions, debts, and insurance due soon',
            value: _upcoming,
            onChanged: (v) => setState(() => _upcoming = v)),
        SettingsToggleRow(
            title: 'Next Steps',
            sub: 'Show suggested next actions from your adulting journey',
            value: _nextSteps,
            onChanged: (v) => setState(() => _nextSteps = v)),
        SettingsToggleRow(
            title: 'Financial Summary',
            sub: 'Show balance, income, and expenses at a glance',
            value: _financial,
            onChanged: (v) => setState(() => _financial = v)),
        SettingsToggleRow(
            title: 'Current Life Stage',
            sub: 'Show your current adulting journey stage and progress',
            value: _stage,
            onChanged: (v) => setState(() => _stage = v)),
      ])),
    ]);
  }
}
