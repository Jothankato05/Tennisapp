import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_store.dart';
import '../../data/drills.dart';
import '../../models/ids.dart';
import '../../models/practice_session.dart';
import '../../util/format.dart';
import '../../widgets/common.dart';

class PracticeFormScreen extends StatefulWidget {
  const PracticeFormScreen({super.key, this.session, this.initialDrill});

  final PracticeSession? session;
  final Drill? initialDrill;

  @override
  State<PracticeFormScreen> createState() => _PracticeFormScreenState();
}

class _PracticeFormScreenState extends State<PracticeFormScreen> {
  late DateTime _date = widget.session?.date ?? DateTime.now();
  late int _minutes = widget.session?.minutes ?? widget.initialDrill?.minutes ?? 60;
  late final Set<String> _focus = {...?widget.session?.focus};
  late final Set<String> _drills = {...?widget.session?.drillIds, ?widget.initialDrill?.id};
  late int _intensity = widget.session?.intensity ?? 3;
  late final _notes = TextEditingController(text: widget.session?.notes);

  @override
  void initState() {
    super.initState();
    final drill = widget.initialDrill;
    if (drill != null && widget.session == null) {
      final focus = switch (drill.category) {
        DrillCategory.serveReturn => ['Serve', 'Return'],
        DrillCategory.netPlay => ['Volleys'],
        DrillCategory.footwork => ['Footwork', 'Fitness'],
        DrillCategory.matchPlay => ['Match play'],
        DrillCategory.groundstrokes => ['Forehand', 'Backhand'],
        DrillCategory.warmUp => <String>[],
      };
      _focus.addAll(focus);
    }
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  void _save() {
    context.read<AppStore>().savePractice(
      PracticeSession(
        id: widget.session?.id ?? newId(),
        date: _date,
        minutes: _minutes,
        focus: practiceFocusAreas.where(_focus.contains).toList(),
        drillIds: _drills.toList(),
        intensity: _intensity,
        notes: _notes.text.trim(),
      ),
    );
    showSnack(context, 'Practice saved');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.session != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Edit practice' : 'Log practice'),
        actions: [
          if (editing)
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final ok = await confirm(
                  context,
                  title: 'Delete this session?',
                  message: 'This cannot be undone.',
                  confirmLabel: 'Delete',
                  destructive: true,
                );
                if (!ok || !context.mounted) return;
                context.read<AppStore>().deletePractice(widget.session!.id);
                Navigator.pop(context);
              },
            ),
          TextButton(onPressed: _save, child: const Text('SAVE')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.event),
              title: Text(fmtDate(_date)),
              subtitle: const Text('Date'),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (d != null) setState(() => _date = DateTime(d.year, d.month, d.day, 12));
              },
            ),
          ),
          SectionHeader('Duration: ${fmtMinutes(_minutes)}'),
          Slider(
            value: _minutes.toDouble(),
            min: 10,
            max: 240,
            divisions: 23,
            label: fmtMinutes(_minutes),
            onChanged: (v) => setState(() => _minutes = v.round()),
          ),
          const SectionHeader('What did you work on?'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final f in practiceFocusAreas)
                FilterChip(
                  label: Text(f),
                  selected: _focus.contains(f),
                  onSelected: (v) => setState(() => v ? _focus.add(f) : _focus.remove(f)),
                ),
            ],
          ),
          const SectionHeader('Drills'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final d in drills)
                FilterChip(
                  label: Text(d.name),
                  selected: _drills.contains(d.id),
                  onSelected: (v) => setState(() => v ? _drills.add(d.id) : _drills.remove(d.id)),
                ),
            ],
          ),
          const SectionHeader('How hard was it?'),
          SegmentedButton<int>(
            segments: [for (var i = 1; i <= 5; i++) ButtonSegment(value: i, label: Text('$i'))],
            selected: {_intensity},
            onSelectionChanged: (s) => setState(() => _intensity = s.first),
          ),
          const SizedBox(height: 4),
          const Text('1 = easy hit · 5 = exhausting', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 16),
          TextField(
            controller: _notes,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notes',
              hintText: 'What went well? What to work on next time?',
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
    );
  }
}
