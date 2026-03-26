import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/constants/legal.dart';
import '../../../core/services/premium_service.dart';

class AboutSection extends StatefulWidget {
  final Widget back;
  const AboutSection({super.key, required this.back});

  @override
  State<AboutSection> createState() => _AboutSectionState();
}

class _AboutSectionState extends State<AboutSection> {
  String _version = '';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = info.version;
        _buildNumber = info.buildNumber;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final premium = PremiumService.instance;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      children: [
        widget.back,

        // App info header
        Center(child: Column(children: [
          const SizedBox(height: 16),
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFF6366F1), Color(0xFF3B82F6)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.3),
                    blurRadius: 16, offset: const Offset(0, 4)),
              ],
            ),
            child: const Icon(LucideIcons.footprints, size: 36, color: Colors.white),
          ),
          const SizedBox(height: 12),
          const Text('Sandalan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text('Your Filipino adulting companion',
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
          const SizedBox(height: 6),
          Text('v$_version ($_buildNumber)',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant.withOpacity(0.5))),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: premium.isBetaPeriod
                  ? const Color(0xFF10B981).withOpacity(0.1)
                  : premium.isPremium
                      ? const Color(0xFF6366F1).withOpacity(0.1)
                      : cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              premium.isBetaPeriod ? 'Beta — All Features Free'
                  : premium.isPremium ? 'Premium' : 'Free Tier',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                  color: premium.isBetaPeriod ? const Color(0xFF10B981)
                      : premium.isPremium ? const Color(0xFF6366F1)
                      : cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 24),
        ])),

        // Links
        _InfoTile(
          icon: LucideIcons.shield,
          title: 'Privacy Policy',
          onTap: () => _showLegal(context, 'Privacy Policy', kPrivacyPolicy),
        ),
        _InfoTile(
          icon: LucideIcons.fileText,
          title: 'Terms of Service',
          onTap: () => _showLegal(context, 'Terms of Service', kTermsOfService),
        ),
        _InfoTile(
          icon: LucideIcons.heart,
          title: 'Credits',
          onTap: () => _showCredits(context),
        ),
        _InfoTile(
          icon: LucideIcons.github,
          title: 'Open Source Licenses',
          onTap: () => showLicensePage(
            context: context,
            applicationName: 'Sandalan',
            applicationVersion: 'v$_version',
          ),
        ),

        const SizedBox(height: 24),
        Center(child: Text('Made with malasakit in the Philippines',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant.withOpacity(0.4)))),
        const SizedBox(height: 4),
        Center(child: Text('© 2026 Jet Timothy Cerezo',
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant.withOpacity(0.3)))),
      ],
    );
  }

  void _showLegal(BuildContext context, String title, String content) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text(title, style: const TextStyle(fontSize: 16))),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Text(content, style: const TextStyle(fontSize: 13, height: 1.6)),
        ),
      ),
    ));
  }

  void _showCredits(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Credits', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Built by', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          const Text('Jet Timothy Cerezo', style: TextStyle(fontSize: 14)),
          const SizedBox(height: 12),
          const Text('Powered by', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          const Text('Flutter, Supabase, Drift, Riverpod', style: TextStyle(fontSize: 13)),
          const SizedBox(height: 12),
          const Text('Icons', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          const Text('Lucide Icons (ISC License)', style: TextStyle(fontSize: 13)),
          const SizedBox(height: 12),
          Text('Salamat sa pagtitiwala!',
              style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: cs.onSurfaceVariant)),
        ]),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _InfoTile({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: Row(children: [
          Icon(icon, size: 18, color: cs.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 14))),
          Icon(LucideIcons.chevronRight, size: 16, color: cs.onSurfaceVariant.withOpacity(0.4)),
        ]),
      ),
    );
  }
}
