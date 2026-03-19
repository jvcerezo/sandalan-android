import 'package:flutter/material.dart';

class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Your Adulting Journey',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Level up through every stage of Filipino adult life.',
            style: TextStyle(fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 24),
        // TODO: Overall progress card
        // TODO: Journey map (Phase 7 — CRITICAL)
      ],
    );
  }
}
