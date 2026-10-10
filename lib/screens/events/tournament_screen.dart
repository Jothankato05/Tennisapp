import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_store.dart';
import '../../logic/bracket.dart';
import '../../models/ids.dart';
import '../../models/match_record.dart';
import '../../models/tournament.dart';
import '../../scoring/match_format.dart';
import '../../scoring/set_score.dart';
import '../../theme.dart';
import '../../util/device.dart';
import '../../widgets/common.dart';
import '../play/match_detail_screen.dart';
import '../play/new_match_screen.dart';

class TournamentScreen extends StatelessWidget {
  const TournamentScreen({super.key, required this.tournamentId});

  final String tournamentId;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final t = store.tournamentById(tournamentId);
    if (t == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Tournament not found')),
      );
    }
    final champion = tournamentChampion(t);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.name),
        actions: [
          Builder(
            builder: (btn) => IconButton(
              tooltip: 'Share draw and results',
              icon: const Icon(Icons.share_outlined),
              onPressed: () => shareText(btn, _summary(store, t), subject: t.name),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'rename') {
                final name = await _rename(context, t.name);
                if (name != null && name.isNotEmpty) {
                  t.name = name;
                  store.touch();
                }
              } else if (v == 'delete') {
                final ok = await confirm(
                  context,
                  title: 'Delete ${t.name}?',
                  message: 'The draw will be deleted. Matches already saved stay in history.',
                  confirmLabel: 'Delete',
                  destructive: true,
                );
                if (ok && context.mounted) {
                  Navigator.pop(context);
                  store.deleteTournament(t.id);
                }
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'rename', child: Text('Rename')),
              PopupMenuItem(value: 'delete', child: Text('Delete tournament')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          Text(
            '${t.type.label} · ${t.playerIds.length} players · ${t.venue}',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          if (champion != null) ...[
            const SizedBox(height: 12),
            Card(
              color: VeritasColors.navy,
              child: ListTile(
                leading: const Icon(Icons.emoji_events, color: VeritasColors.ball, size: 36),
                title: Text(
                  store.nameOf(champion),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                ),
                subtitle: const Text('Champion', style: TextStyle(color: Color(0xFFD5DEEA))),
              ),
            ),
          ],
          if (t.type == TournamentType.roundRobin) ...[
            const SectionHeader('Standings'),
            _StandingsTable(tournament: t),
          ],
          for (var r = 0; r < t.rounds.length; r++) ...[
            SectionHeader(t.type == TournamentType.knockout ? knockoutRoundName(r, t.rounds.length) : 'Round ${r + 1}'),
            for (final f in t.rounds[r])
              if (!(t.type == TournamentType.knockout && r == 0 && !f.isReady && f.isPlayed))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _FixtureCard(tournament: t, fixture: f),
                ),
            if (t.type == TournamentType.knockout && r == 0 && t.rounds[0].any((f) => !f.isReady && f.isPlayed))
              Text(
                'Byes: ${t.rounds[0].where((f) => !f.isReady && f.isPlayed).map((f) => store.nameOf(f.winner)).join(', ')}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ],
      ),
    );
  }

  Future<String?> _rename(BuildContext context, String current) {
    final controller = TextEditingController(text: current);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename tournament'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Save')),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  String _summary(AppStore store, Tournament t) {
    final b = StringBuffer('🎾 ${t.name} — ${t.type.label}\n${t.venue}\n');
    final champion = tournamentChampion(t);
    if (champion != null) b.writeln('🏆 Champion: ${store.nameOf(champion)}');
    if (t.type == TournamentType.roundRobin) {
      b.writeln('\nStandings:');
      final table = roundRobinStandings(t, nameOf: store.nameOf);
      for (var i = 0; i < table.length; i++) {
        final s = table[i];
        b.writeln('${i + 1}. ${store.nameOf(s.playerId)} — ${s.won}W ${s.lost}L (sets ${s.setsWon}-${s.setsLost})');
      }
    }
    for (var r = 0; r < t.rounds.length; r++) {
      final fixtures = t.rounds[r].where((f) => f.isReady).toList();
      if (fixtures.isEmpty) continue;
      b.writeln('\n${t.type == TournamentType.knockout ? knockoutRoundName(r, t.rounds.length) : 'Round ${r + 1}'}:');
      for (final f in fixtures) {
        if (f.isPlayed) {
          b.writeln('${store.nameOf(f.winner)} bt ${store.nameOf(f.loser)} ${f.score}');
        } else {
          b.writeln('${store.nameOf(f.a)} vs ${store.nameOf(f.b)}');
        }
      }
    }
    return b.toString().trim();
  }
}

class _StandingsTable extends StatelessWidget {
  const _StandingsTable({required this.tournament});

  final Tournament tournament;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final table = roundRobinStandings(tournament, nameOf: store.nameOf);
    const head = TextStyle(fontWeight: FontWeight.w700, fontSize: 12);
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 18,
          headingRowHeight: 40,
          dataRowMinHeight: 40,
          dataRowMaxHeight: 44,
          columns: const [
            DataColumn(label: Text('#', style: head)),
            DataColumn(label: Text('Player', style: head)),
            DataColumn(label: Text('P', style: head), numeric: true),
            DataColumn(label: Text('W', style: head), numeric: true),
            DataColumn(label: Text('L', style: head), numeric: true),
            DataColumn(label: Text('Sets', style: head), numeric: true),
            DataColumn(label: Text('Games', style: head), numeric: true),
          ],
          rows: [
            for (var i = 0; i < table.length; i++)
              DataRow(
                cells: [
                  DataCell(Text('${i + 1}')),
                  DataCell(Text(store.nameOf(table[i].playerId), style: const TextStyle(fontWeight: FontWeight.w600))),
                  DataCell(Text('${table[i].played}')),
                  DataCell(Text('${table[i].won}')),
                  DataCell(Text('${table[i].lost}')),
                  DataCell(Text('${table[i].setsWon}-${table[i].setsLost}')),
                  DataCell(Text('${table[i].gamesWon}-${table[i].gamesLost}')),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _FixtureCard extends StatelessWidget {
  const _FixtureCard({required this.tournament, required this.fixture});

  final Tournament tournament;
  final Fixture fixture;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final f = fixture;
    final theme = Theme.of(context);
    Widget line(String? id) {
      final won = f.winner != null && f.winner == id;
      return Row(
        children: [
          SizedBox(width: 20, child: won ? const Icon(Icons.check, size: 16, color: VeritasColors.win) : null),
          Expanded(
            child: Text(
              id == null ? 'TBD' : store.nameOf(id),
              style: TextStyle(
                fontWeight: won ? FontWeight.w800 : FontWeight.w500,
                color: id == null ? theme.colorScheme.onSurfaceVariant : null,
              ),
            ),
          ),
        ],
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: f.isReady ? () => _openFixture(context) : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(child: Column(children: [line(f.a), const SizedBox(height: 6), line(f.b)])),
              if (f.isPlayed)
                Text(f.score, style: const TextStyle(fontWeight: FontWeight.w700))
              else if (f.isReady)
                Text(
                  'Tap to play',
                  style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openFixture(BuildContext context) async {
    final store = context.read<AppStore>();
    final f = fixture;
    final title = '${store.nameOf(f.a)} vs ${store.nameOf(f.b)}';
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
            ListTile(
              leading: const Icon(Icons.scoreboard_outlined),
              title: const Text('Score this match live'),
              onTap: () => Navigator.pop(ctx, 'live'),
            ),
            ListTile(
              leading: const Icon(Icons.edit_note),
              title: Text(f.isPlayed ? 'Change result' : 'Enter result'),
              onTap: () => Navigator.pop(ctx, 'enter'),
            ),
            if (f.matchId != null && store.matchById(f.matchId!) != null)
              ListTile(
                leading: const Icon(Icons.bar_chart),
                title: const Text('View match details'),
                onTap: () => Navigator.pop(ctx, 'view'),
              ),
            if (f.isPlayed)
              ListTile(
                leading: const Icon(Icons.restart_alt),
                title: const Text('Clear result'),
                onTap: () => Navigator.pop(ctx, 'clear'),
              ),
          ],
        ),
      ),
    );
    if (!context.mounted || action == null) return;
    switch (action) {
      case 'live':
        if (store.liveMatch != null) {
          showSnack(context, 'Finish or discard the match in progress first');
          return;
        }
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => NewMatchScreen(
              title: tournament.name,
              sideA: Participant(playerId: f.a, name: store.nameOf(f.a)),
              sideB: Participant(playerId: f.b, name: store.nameOf(f.b)),
              tournamentId: tournament.id,
              fixtureId: f.id,
            ),
          ),
        );
      case 'enter':
        final result = await showDialog<(String, String)>(
          context: context,
          builder: (_) => _ResultDialog(a: f.a!, b: f.b!, initialWinner: f.winner, initialScore: f.score),
        );
        if (result == null || !context.mounted) return;
        final (winnerId, score) = result;
        _unlinkManualRecord(store, f);
        final sets = parseSetScores(score)!;
        final loserId = winnerId == f.a ? f.b! : f.a!;
        // Also add it to match history so the ladder and player stats pick it up.
        final record = MatchRecord(
          id: newId(),
          playedAt: DateTime.now(),
          format: MatchFormat(bestOf: sets.length <= 1 ? 1 : (sets.length <= 3 ? 3 : 5)),
          sideA: [Participant(playerId: winnerId, name: store.nameOf(winnerId))],
          sideB: [Participant(playerId: loserId, name: store.nameOf(loserId))],
          sets: sets,
          winnerSide: 0,
          tournamentId: tournament.id,
          notes: tournament.name,
        );
        store.addMatch(record);
        store.setFixtureResult(tournament, f, winnerId: winnerId, score: score, matchId: record.id);
      case 'view':
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => MatchDetailScreen(matchId: f.matchId!)));
      case 'clear':
        _unlinkManualRecord(store, f);
        store.setFixtureResult(tournament, f, winnerId: null);
    }
  }

  /// Results typed in by hand are replaced when edited. Live-scored matches
  /// stay in history because they really happened.
  void _unlinkManualRecord(AppStore store, Fixture f) {
    final linked = f.matchId == null ? null : store.matchById(f.matchId!);
    if (linked != null && linked.source == MatchSource.manual) store.deleteMatch(linked.id);
    f.matchId = null;
  }
}

class _ResultDialog extends StatefulWidget {
  const _ResultDialog({required this.a, required this.b, this.initialWinner, this.initialScore = ''});

  final String a;
  final String b;
  final String? initialWinner;
  final String initialScore;

  @override
  State<_ResultDialog> createState() => _ResultDialogState();
}

class _ResultDialogState extends State<_ResultDialog> {
  late String _winner = widget.initialWinner ?? widget.a;
  late final _score = TextEditingController(text: widget.initialScore);

  @override
  void dispose() {
    _score.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.read<AppStore>();
    final parsed = parseSetScores(_score.text);
    final valid = parsed != null && winnerFromSets(parsed) == 0;
    return AlertDialog(
      title: const Text('Match result'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Winner', style: TextStyle(fontWeight: FontWeight.w600)),
          RadioGroup<String>(
            groupValue: _winner,
            onChanged: (v) => setState(() => _winner = v!),
            child: Column(
              children: [
                for (final id in [widget.a, widget.b])
                  RadioListTile<String>(contentPadding: EdgeInsets.zero, value: id, title: Text(store.nameOf(id))),
              ],
            ),
          ),
          TextField(
            controller: _score,
            keyboardType: TextInputType.visiblePassword,
            decoration: InputDecoration(
              labelText: 'Score (winner first)',
              hintText: '6-4 7-6(3)',
              errorText: _score.text.isNotEmpty && !valid ? 'Enter the score with the winner\'s games first' : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: valid ? () => Navigator.pop(context, (_winner, parsed.map((s) => s.label()).join(' '))) : null,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
