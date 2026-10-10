import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_store.dart';
import '../../models/ids.dart';
import '../../models/match_record.dart';
import '../../scoring/match_format.dart';
import '../../scoring/set_score.dart';
import '../../util/format.dart';
import '../../widgets/common.dart';
import '../../widgets/match_widgets.dart';
import '../../widgets/player_picker.dart';

/// Record a match that was not scored live in the app.
class LogResultScreen extends StatefulWidget {
  const LogResultScreen({super.key, this.opponent});

  final Participant? opponent;

  @override
  State<LogResultScreen> createState() => _LogResultScreenState();
}

class _LogResultScreenState extends State<LogResultScreen> {
  bool _doubles = false;
  final List<Participant?> _a = [null, null];
  final List<Participant?> _b = [null, null];
  final _score = TextEditingController();
  final _notes = TextEditingController();
  DateTime _date = DateTime.now();
  bool _retired = false;
  int _retiredWinner = 0;

  @override
  void initState() {
    super.initState();
    final me = context.read<AppStore>().me;
    if (me != null) _a[0] = Participant(playerId: me.id, name: me.name);
    _b[0] = widget.opponent;
  }

  @override
  void dispose() {
    _score.dispose();
    _notes.dispose();
    super.dispose();
  }

  int get _perSide => _doubles ? 2 : 1;

  List<SetScore>? get _sets => parseSetScores(_score.text);

  int? get _winner => _retired ? _retiredWinner : (_sets == null ? null : winnerFromSets(_sets!));

  String _name(List<Participant?> side, String fallback) {
    final names = side.take(_perSide).whereType<Participant>().map((p) => p.name).toList();
    return names.isEmpty ? fallback : names.join(' / ');
  }

  Future<void> _pick(List<Participant?> side, int i) async {
    final exclude = {
      for (final p in [..._a.take(_perSide), ..._b.take(_perSide)])
        if (p?.playerId != null && p != side[i]) p!.playerId!,
    };
    final picked = await pickParticipant(context, exclude: exclude);
    if (picked != null) setState(() => side[i] = picked);
  }

  Future<void> _save() async {
    final players = [..._a.take(_perSide), ..._b.take(_perSide)];
    String? problem;
    if (players.any((p) => p == null)) {
      problem = 'Choose every player';
    } else if (players.map((p) => p!.playerId ?? 'g:${p.name.toLowerCase()}').toSet().length != players.length) {
      problem = 'The same player is listed twice';
    } else if (_sets == null) {
      problem = 'Enter the score set by set, e.g. 6-4 3-6 7-6(5)';
    } else if (_winner == null) {
      problem = 'Both sides won the same number of sets. Tick "ended early" and choose who won.';
    }
    if (problem != null) {
      showSnack(context, problem);
      return;
    }
    final sets = _sets!;
    final bestOf = sets.length <= 1 ? 1 : (sets.length <= 3 ? 3 : 5);
    final store = context.read<AppStore>();
    final record = MatchRecord(
      id: newId(),
      playedAt: _date,
      format: MatchFormat(bestOf: bestOf, doubles: _doubles),
      sideA: [for (final p in _a.take(_perSide)) p!],
      sideB: [for (final p in _b.take(_perSide)) p!],
      sets: sets,
      winnerSide: _winner,
      completed: !_retired,
      notes: _notes.text.trim(),
    );
    if (store.findDuplicate(record) != null) {
      final ok = await confirm(
        context,
        title: 'Already recorded?',
        message:
            'A match between these players with the same score on the same day is already saved '
            '(perhaps your opponent logged it). Saving again would count it twice on the ladder.',
        confirmLabel: 'Save anyway',
      );
      if (!ok || !mounted) return;
    }
    store.addMatch(record);
    showSnack(context, 'Result saved');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sets = _sets;
    Widget slot(List<Participant?> side, int i, String label) => Card(
      child: ListTile(
        leading: const Icon(Icons.person_outline),
        title: Text(side[i]?.name ?? label),
        subtitle: side[i] == null ? const Text('Tap to choose') : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _pick(side, i),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log a result'),
        actions: [TextButton(onPressed: _save, child: const Text('SAVE'))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Singles')),
              ButtonSegment(value: true, label: Text('Doubles')),
            ],
            selected: {_doubles},
            onSelectionChanged: (s) => setState(() => _doubles = s.first),
          ),
          const SectionHeader('Side A'),
          slot(_a, 0, 'Player'),
          if (_doubles) ...[const SizedBox(height: 8), slot(_a, 1, 'Partner')],
          const SectionHeader('Side B'),
          slot(_b, 0, 'Opponent'),
          if (_doubles) ...[const SizedBox(height: 8), slot(_b, 1, 'Opponent partner')],
          const SectionHeader('Score'),
          TextField(
            controller: _score,
            keyboardType: TextInputType.visiblePassword,
            decoration: InputDecoration(
              labelText: 'Score from side A\'s view',
              hintText: '6-4 3-6 7-6(5)   or   6-3 4-6 [10-8]',
              helperText: 'Side A\'s games first. Tiebreak loser points in ( ), match tiebreak in [ ].',
              errorText: _score.text.trim().isNotEmpty && sets == null ? 'That score does not look right' : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
          if (sets != null) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ScoreTable(names: [_name(_a, 'Side A'), _name(_b, 'Side B')], sets: sets, winnerSide: _winner),
              ),
            ),
          ],
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _retired,
            title: const Text('Match ended early (retirement)'),
            onChanged: (v) => setState(() => _retired = v ?? false),
          ),
          if (_retired)
            SegmentedButton<int>(
              segments: [
                ButtonSegment(value: 0, label: Text('${_name(_a, 'Side A')} won', overflow: TextOverflow.ellipsis)),
                ButtonSegment(value: 1, label: Text('${_name(_b, 'Side B')} won', overflow: TextOverflow.ellipsis)),
              ],
              selected: {_retiredWinner},
              onSelectionChanged: (s) => setState(() => _retiredWinner = s.first),
            ),
          const SectionHeader('Details'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.event),
              title: Text(fmtDate(_date)),
              subtitle: const Text('Date played'),
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
          const SizedBox(height: 12),
          TextField(
            controller: _notes,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Notes (optional)', alignLabelWithHint: true),
          ),
          const SizedBox(height: 8),
          Text(
            'Singles results between two club players count towards the ladder.',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
