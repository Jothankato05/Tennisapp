import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/app_store.dart';
import '../../models/live_match.dart';
import '../../models/match_record.dart';
import '../../scoring/tennis_scorer.dart';
import '../../theme.dart';
import '../../util/device.dart';
import '../../widgets/common.dart';
import '../../widgets/match_widgets.dart';
import 'match_detail_screen.dart';

class LiveMatchScreen extends StatefulWidget {
  const LiveMatchScreen({super.key});

  @override
  State<LiveMatchScreen> createState() => _LiveMatchScreenState();
}

class _LiveMatchScreenState extends State<LiveMatchScreen> {
  String? _banner;
  int _bannerSeq = 0;

  @override
  void initState() {
    super.initState();
    keepScreenOn(true);
  }

  @override
  void dispose() {
    keepScreenOn(false);
    super.dispose();
  }

  void _play(LiveMatch live, PointEvent e) {
    final store = context.read<AppStore>();
    final outcome = live.play(e);
    HapticFeedback.selectionClick();
    final messages = <String>[
      if (outcome.matchWonBy != null)
        'Game, set and match — ${live.sideName(outcome.matchWonBy!)}!'
      else if (outcome.setWonBy != null)
        'Set to ${live.sideName(outcome.setWonBy!)}'
      else if (outcome.gameWonBy != null)
        'Game ${live.sideName(outcome.gameWonBy!)}',
      if (outcome.tiebreakStarted)
        live.scorer.isMatchTiebreak ? 'Match tiebreak — first to 10' : 'Tiebreak — first to 7',
      if (outcome.changeEnds) 'Change ends',
    ];
    if (messages.isNotEmpty) _flash(messages.join(' · '));
    store.touch();
    if (outcome.matchWonBy != null) {
      HapticFeedback.heavyImpact();
    }
  }

  void _flash(String text) {
    final seq = ++_bannerSeq;
    setState(() => _banner = text);
    Future<void>.delayed(const Duration(seconds: 3), () {
      if (mounted && seq == _bannerSeq) setState(() => _banner = null);
    });
  }

  void _undo(LiveMatch live) {
    live.undo();
    context.read<AppStore>().touch();
    setState(() => _banner = null);
  }

  void _save(LiveMatch live, {int? winnerOverride, bool completed = true}) {
    final store = context.read<AppStore>();
    final record = live.toRecord(endedAt: DateTime.now(), winnerOverride: winnerOverride, completed: completed);
    store.addMatch(record);
    _recordFixture(store, live, record);
    store.clearLive();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => MatchDetailScreen(matchId: record.id, justFinished: true)),
    );
  }

  void _recordFixture(AppStore store, LiveMatch live, MatchRecord record) {
    if (live.tournamentId == null || live.fixtureId == null || record.winnerSide == null) return;
    final t = store.tournamentById(live.tournamentId!);
    final f = t?.fixtureById(live.fixtureId!);
    if (t == null || f == null) return;
    final previous = f.matchId == null ? null : store.matchById(f.matchId!);
    if (previous != null && previous.source == MatchSource.manual) store.deleteMatch(previous.id);
    final winnerId = record.side(record.winnerSide!).first.playerId;
    store.setFixtureResult(
      t,
      f,
      winnerId: winnerId,
      score: record.scoreFor(record.winnerSide!) + (record.completed ? '' : ' ret.'),
      matchId: record.id,
    );
  }

  Future<void> _endEarly(LiveMatch live) async {
    final choice = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text('End match early', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
            for (final side in [0, 1])
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: Text('${live.sideName(1 - side)} retired'),
                subtitle: Text('${live.sideName(side)} wins'),
                onTap: () => Navigator.pop(ctx, side),
              ),
            ListTile(
              leading: const Icon(Icons.cloud_outlined),
              title: const Text('Abandoned — no result'),
              subtitle: const Text('Rain, light, or out of court time. Saved to history, not ranked.'),
              onTap: () => Navigator.pop(ctx, -1),
            ),
          ],
        ),
      ),
    );
    if (choice == null) return;
    _save(live, winnerOverride: choice >= 0 ? choice : null, completed: false);
  }

  Future<void> _discard() async {
    final ok = await confirm(
      context,
      title: 'Discard this match?',
      message: 'The score will be deleted and not saved to your history.',
      confirmLabel: 'Discard',
      destructive: true,
    );
    if (!ok || !mounted) return;
    context.read<AppStore>().clearLive();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final live = context.watch<AppStore>().liveMatch;
    if (live == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('No match in progress')),
      );
    }
    final s = live.scorer;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(live.format.describe(), style: theme.textTheme.titleSmall),
        actions: [
          IconButton(
            tooltip: 'Undo last point',
            onPressed: live.canUndo ? () => _undo(live) : null,
            icon: const Icon(Icons.undo),
          ),
          PopupMenuButton<String>(
            onSelected: (v) => v == 'end' ? _endEarly(live) : _discard(),
            itemBuilder: (_) => [
              if (!s.isOver) const PopupMenuItem(value: 'end', child: Text('End match early…')),
              const PopupMenuItem(value: 'discard', child: Text('Discard match')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ScoreTable(
                  names: [live.sideName(0), live.sideName(1)],
                  sets: s.setsIncludingCurrent(),
                  winnerSide: s.winner,
                  servingSide: s.isOver ? null : s.servingSide,
                ),
              ),
            ),
            const SizedBox(height: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _InfoStrip(
                key: ValueKey('${_banner ?? ''}${s.situation}${s.isOver}'),
                text: _banner ?? (s.isOver ? null : s.situation),
                highlight: _banner != null,
              ),
            ),
            const SizedBox(height: 10),
            if (s.isOver)
              _FinishedCard(live: live, onSave: () => _save(live))
            else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final side in [0, 1]) ...[
                    if (side == 1) const SizedBox(width: 10),
                    Expanded(
                      child: _SidePanel(live: live, side: side, onEvent: (e) => _play(live, e)),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.sports_tennis, size: 18, color: VeritasColors.court),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${live.serverName} serving'
                              '${s.inTiebreak ? '' : ' · ${(s.points[0] + s.points[1]).isEven ? 'deuce' : 'ad'} side'}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _play(live, const PointEvent(PointKind.ace)),
                              icon: const Icon(Icons.bolt),
                              label: const Text('Ace'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _play(live, const PointEvent(PointKind.doubleFault)),
                              icon: const Icon(Icons.close),
                              label: const Text('Double fault'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            _StatsCard(live: live),
          ],
        ),
      ),
    );
  }
}

class _InfoStrip extends StatelessWidget {
  const _InfoStrip({super.key, required this.text, required this.highlight});

  final String? text;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    if (text == null) return const SizedBox(height: 40);
    return Container(
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: highlight ? VeritasColors.navy : VeritasColors.ball,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text!,
        style: TextStyle(
          color: highlight ? Colors.white : VeritasColors.navy,
          fontWeight: FontWeight.w800,
          fontSize: 15,
        ),
      ),
    );
  }
}

class _SidePanel extends StatelessWidget {
  const _SidePanel({required this.live, required this.side, required this.onEvent});

  final LiveMatch live;
  final int side;
  final ValueChanged<PointEvent> onEvent;

  @override
  Widget build(BuildContext context) {
    final s = live.scorer;
    final serving = s.servingSide == side;
    final color = side == 0 ? VeritasColors.navy : VeritasColors.court;
    return Column(
      children: [
        Material(
          color: color,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => onEvent(PointEvent.to(side)),
            child: Semantics(
              button: true,
              label: 'Point to ${live.sideName(side)}. Score ${s.pointLabel(side)}',
              child: Container(
                height: 220,
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        if (serving) ...[
                          const Icon(Icons.circle, size: 10, color: VeritasColors.ball),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            live.sideName(side),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: FittedBox(
                        child: Text(
                          s.pointLabel(side),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 80,
                            fontWeight: FontWeight.w900,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                    Text(
                      s.inTiebreak ? 'Games ${s.games[side]}' : 'Games ${s.games[side]} · Sets ${s.setsWon(side)}',
                      style: const TextStyle(color: Color(0xFFD5DEEA)),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'TAP FOR POINT',
                      style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => onEvent(PointEvent(PointKind.winner, side)),
                child: const Text('Winner'),
              ),
            ),
            Expanded(
              child: TextButton(
                onPressed: () => onEvent(PointEvent(PointKind.unforcedError, side)),
                child: const Text('Error'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FinishedCard extends StatelessWidget {
  const _FinishedCard({required this.live, required this.onSave});

  final LiveMatch live;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final w = live.scorer.winner!;
    return Card(
      color: VeritasColors.navy,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.emoji_events, color: VeritasColors.ball, size: 48),
            const SizedBox(height: 8),
            Text(
              '${live.sideName(w)} won',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              live.scorer.sets.map((x) => x.label(side: w)).join('  '),
              style: const TextStyle(color: Color(0xFFD5DEEA), fontSize: 16),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: VeritasColors.ball, foregroundColor: VeritasColors.navy),
              onPressed: onSave,
              icon: const Icon(Icons.save_alt),
              label: const Text('Save match'),
            ),
            const SizedBox(height: 4),
            const Text('Made a mistake? Use undo at the top.', style: TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.live});

  final LiveMatch live;

  @override
  Widget build(BuildContext context) {
    final st = live.scorer.stats;
    if (st[0].pointsWon + st[1].pointsWon == 0) return const SizedBox.shrink();
    return Card(
      child: ExpansionTile(
        title: const Text('Match stats', style: TextStyle(fontWeight: FontWeight.w700)),
        shape: const Border(),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: StatsComparison(names: [live.sideName(0), live.sideName(1)], stats: st),
          ),
        ],
      ),
    );
  }
}

/// Side-by-side stat rows used on the live screen and match details.
class StatsComparison extends StatelessWidget {
  const StatsComparison({super.key, required this.names, required this.stats});

  final List<String> names;
  final List<SideStats> stats;

  @override
  Widget build(BuildContext context) {
    String pct(int won, int played) => played == 0 ? '—' : '${(won * 100 / played).round()}%';
    final rows = <(String, String, String)>[
      ('Points won', '${stats[0].pointsWon}', '${stats[1].pointsWon}'),
      ('Aces', '${stats[0].aces}', '${stats[1].aces}'),
      ('Double faults', '${stats[0].doubleFaults}', '${stats[1].doubleFaults}'),
      ('Winners', '${stats[0].winners}', '${stats[1].winners}'),
      ('Unforced errors', '${stats[0].unforcedErrors}', '${stats[1].unforcedErrors}'),
      (
        'Service points won',
        pct(stats[0].servicePointsWon, stats[0].servicePointsPlayed),
        pct(stats[1].servicePointsWon, stats[1].servicePointsPlayed),
      ),
      (
        'Break points won',
        '${stats[0].breakPointsWon}/${stats[0].breakPointChances}',
        '${stats[1].breakPointsWon}/${stats[1].breakPointChances}',
      ),
    ];
    final bold = Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(names[0], style: bold, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(names[1], style: bold, textAlign: TextAlign.end, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        const Divider(),
        for (final (label, a, b) in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                SizedBox(width: 56, child: Text(a, style: bold)),
                Expanded(child: Text(label, textAlign: TextAlign.center)),
                SizedBox(
                  width: 56,
                  child: Text(b, style: bold, textAlign: TextAlign.end),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
