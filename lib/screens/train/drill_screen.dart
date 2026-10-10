import 'package:flutter/material.dart';

import '../../data/drills.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'practice_form_screen.dart';

class DrillScreen extends StatelessWidget {
  const DrillScreen({super.key, required this.drill});

  final Drill drill;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final d = drill;
    return Scaffold(
      appBar: AppBar(title: Text(d.category.label)),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: () =>
                Navigator.of(context)
                    .push(MaterialPageRoute<void>(builder: (_) => PracticeFormScreen(initialDrill: d))),
            icon: const Icon(Icons.check),
            label: const Text('Log this drill'),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(d.name, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(d.summary, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(avatar: const Icon(Icons.timer_outlined, size: 18), label: Text('${d.minutes} min')),
              Chip(avatar: const Icon(Icons.people_outline, size: 18), label: Text('${d.players} players')),
              Chip(avatar: const Icon(Icons.trending_up, size: 18), label: Text(d.level)),
              Chip(avatar: const Icon(Icons.sports_baseball_outlined, size: 18), label: Text(d.equipment)),
            ],
          ),
          const SectionHeader('How to do it'),
          for (var i = 0; i < d.steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 13,
                    backgroundColor: VeritasColors.court,
                    child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(d.steps[i], style: const TextStyle(height: 1.4))),
                ],
              ),
            ),
          const SectionHeader('Coaching tips'),
          Card(
            color: VeritasColors.ball.withValues(alpha: 0.25),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final tip in d.tips)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.lightbulb_outline, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(tip)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
