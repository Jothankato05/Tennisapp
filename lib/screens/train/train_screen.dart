import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_store.dart';
import '../../data/drills.dart';
import '../../data/guide.dart';
import '../../util/format.dart';
import '../../widgets/common.dart';
import 'drill_screen.dart';
import 'practice_form_screen.dart';

class TrainScreen extends StatelessWidget {
  const TrainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Train'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Drills'),
              Tab(text: 'Practice log'),
              Tab(text: 'Rules'),
            ],
          ),
        ),
        body: const TabBarView(children: [_DrillsTab(), _LogTab(), _RulesTab()]),
      ),
    );
  }
}

class _DrillsTab extends StatefulWidget {
  const _DrillsTab();

  @override
  State<_DrillsTab> createState() => _DrillsTabState();
}

class _DrillsTabState extends State<_DrillsTab> {
  DrillCategory? _category;

  @override
  Widget build(BuildContext context) {
    final list = drills.where((d) => _category == null || d.category == _category).toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: _category == null,
                onSelected: (_) => setState(() => _category = null),
              ),
              for (final c in DrillCategory.values) ...[
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(c.label),
                  selected: _category == c,
                  onSelected: (_) => setState(() => _category = c),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final d in list)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                title: Text(d.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('${d.category.label} · ${d.minutes} min'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => DrillScreen(drill: d))),
              ),
            ),
          ),
      ],
    );
  }
}

class _LogTab extends StatelessWidget {
  const _LogTab();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final sessions = store.sessions;
    final total = sessions.fold<int>(0, (sum, s) => sum + s.minutes);
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'log-practice',
        onPressed: () =>
            Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const PracticeFormScreen())),
        icon: const Icon(Icons.add),
        label: const Text('Log practice'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          StatGrid(
            children: [
              StatTile(value: fmtMinutes(store.practiceMinutesThisWeek()), label: 'Last 7 days', icon: Icons.today),
              StatTile(value: '${store.activeDayStreak()}', label: 'Day streak', icon: Icons.local_fire_department),
              StatTile(value: fmtMinutes(total), label: 'All time', icon: Icons.timer_outlined),
            ],
          ),
          const SizedBox(height: 16),
          if (sessions.isEmpty) const EmptyState(icon: Icons.fitness_center, title: 'No practice logged'),
          for (final s in sessions)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text('${s.minutes}', style: const TextStyle(fontSize: 13))),
                  title: Text(
                    s.focus.isEmpty ? 'Practice' : s.focus.join(', '),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    [
                      '${fmtRelativeDay(s.date)} · ${fmtMinutes(s.minutes)} · ${'●' * s.intensity}${'○' * (5 - s.intensity)}',
                      if (s.drillIds.isNotEmpty)
                        s.drillIds.map((id) => drillById(id)?.name).whereType<String>().join(', '),
                      if (s.notes.isNotEmpty) s.notes,
                    ].join('\n'),
                  ),
                  isThreeLine: s.drillIds.isNotEmpty || s.notes.isNotEmpty,
                  onTap: () =>
                      Navigator.of(context)
                          .push(MaterialPageRoute<void>(builder: (_) => PracticeFormScreen(session: s))),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RulesTab extends StatelessWidget {
  const _RulesTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final section in guideSections)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: ExpansionTile(
                leading: Icon(section.icon),
                title: Text(section.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                shape: const Border(),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  for (final point in section.points)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(padding: EdgeInsets.only(top: 7), child: Icon(Icons.circle, size: 6)),
                          const SizedBox(width: 10),
                          Expanded(child: Text(point, style: const TextStyle(height: 1.4))),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
