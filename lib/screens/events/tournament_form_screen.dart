import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_store.dart';
import '../../models/ids.dart';
import '../../models/tournament.dart';
import '../../widgets/common.dart';
import 'tournament_screen.dart';

class TournamentFormScreen extends StatefulWidget {
  const TournamentFormScreen({super.key});

  @override
  State<TournamentFormScreen> createState() => _TournamentFormScreenState();
}

class _TournamentFormScreenState extends State<TournamentFormScreen> {
  final _name = TextEditingController(text: 'Veritas Open ${DateTime.now().year}');
  TournamentType _type = TournamentType.knockout;
  bool _seedByRating = true;
  final Set<String> _selected = {};

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _create() {
    if (_name.text.trim().isEmpty) {
      showSnack(context, 'Give the tournament a name');
      return;
    }
    final max = _type == TournamentType.knockout ? 64 : 16;
    if (_selected.length < 2 || _selected.length > max) {
      showSnack(context, 'Choose between 2 and $max players');
      return;
    }
    final t = context.read<AppStore>().createTournament(
      id: newId(),
      name: _name.text.trim(),
      type: _type,
      playerIds: _selected.toList(),
      seedByRating: _seedByRating,
    );
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute<void>(builder: (_) => TournamentScreen(tournamentId: t.id)));
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final n = _selected.length;
    final matches = _type == TournamentType.knockout ? (n < 2 ? 0 : n - 1) : n * (n - 1) ~/ 2;
    return Scaffold(
      appBar: AppBar(title: const Text('New tournament')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _create,
            child: Text(n < 2 ? 'Select at least 2 players' : 'Create draw · $n players · $matches matches'),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Tournament name'),
          ),
          const SizedBox(height: 16),
          SegmentedButton<TournamentType>(
            segments: [for (final t in TournamentType.values) ButtonSegment(value: t, label: Text(t.label))],
            selected: {_type},
            onSelectionChanged: (s) => setState(() => _type = s.first),
          ),
          const SizedBox(height: 6),
          Text(
            _type == TournamentType.knockout
                ? 'Single elimination. Lose once and you are out. Top seeds get byes if numbers are uneven.'
                : 'Everyone plays everyone once. Ranked by wins, then set and game difference. Best for 3–8 players.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          if (_type == TournamentType.knockout)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Seed by ladder rating'),
              subtitle: const Text('Off = random draw'),
              value: _seedByRating,
              onChanged: (v) => setState(() => _seedByRating = v),
            ),
          SectionHeader(
            'Players ($n selected)',
            action: _selected.length == store.players.length ? 'Clear' : 'Select all',
            onAction: () => setState(() {
              if (_selected.length == store.players.length) {
                _selected.clear();
              } else {
                _selected.addAll(store.players.map((p) => p.id));
              }
            }),
          ),
          if (store.players.length < 2) const EmptyState(icon: Icons.group_add_outlined, title: 'Add players first'),
          for (final p in store.players)
            CheckboxListTile(
              value: _selected.contains(p.id),
              title: Text(p.name),
              subtitle: Text('${p.level.label} · ${store.ratingOf(p.id)}'),
              onChanged: (v) => setState(() => v == true ? _selected.add(p.id) : _selected.remove(p.id)),
            ),
        ],
      ),
    );
  }
}
