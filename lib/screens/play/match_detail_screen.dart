import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_store.dart';
import '../../models/match_record.dart';
import '../../theme.dart';
import '../../util/device.dart';
import '../../util/format.dart';
import '../../widgets/common.dart';
import '../../widgets/match_widgets.dart';
import 'live_match_screen.dart';

class MatchDetailScreen extends StatelessWidget {
  const MatchDetailScreen({super.key, required this.matchId, this.justFinished = false});

  final String matchId;
  final bool justFinished;

  String _shareText(MatchRecord m) {
    if (m.winnerSide == null) {
      return '${m.sideName(0)} vs ${m.sideName(1)}: ${m.scoreFor(0)} (unfinished) — Veritas University tennis court';
    }
    final w = m.winnerSide!;
    final verb = m.completed ? 'beat' : 'beat (retired)';
    return '${m.sideName(w)} $verb ${m.sideName(1 - w)} ${m.scoreFor(w)} — Veritas University tennis court, '
        '${fmtDate(m.playedAt)}';
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final m = store.matchById(matchId);
    if (m == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Match not found')),
      );
    }
    final theme = Theme.of(context);
    final ratingNote = _ratingNote(store, m);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Match'),
        actions: [
          Builder(
            builder: (btn) => IconButton(
              tooltip: 'Share result',
              icon: const Icon(Icons.share_outlined),
              onPressed: () => shareText(btn, _shareText(m)),
            ),
          ),
          IconButton(
            tooltip: 'Delete match',
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final ok = await confirm(
                context,
                title: 'Delete this match?',
                message: m.isRanked ? 'Ladder ratings will be recalculated without it.' : 'This cannot be undone.',
                confirmLabel: 'Delete',
                destructive: true,
              );
              if (!ok || !context.mounted) return;
              Navigator.pop(context);
              store.deleteMatch(m.id);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (justFinished)
            Card(
              color: VeritasColors.ball,
              child: ListTile(
                leading: const Icon(Icons.check_circle, color: VeritasColors.navy),
                title: const Text(
                  'Match saved',
                  style: TextStyle(color: VeritasColors.navy, fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  ratingNote ?? 'Added to your history.',
                  style: const TextStyle(color: VeritasColors.navy),
                ),
              ),
            ),
          if (justFinished) const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fmtDate(m.playedAt), style: theme.textTheme.bodySmall),
                  const SizedBox(height: 8),
                  ScoreTable(names: [m.sideName(0), m.sideName(1)], sets: m.sets, winnerSide: m.winnerSide),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(label: Text(m.format.describe())),
                      if (m.durationMinutes != null && m.durationMinutes! > 0)
                        Chip(
                          avatar: const Icon(Icons.timer_outlined, size: 18),
                          label: Text(fmtMinutes(m.durationMinutes!)),
                        ),
                      if (!m.completed) Chip(label: Text(m.winnerSide == null ? 'Abandoned' : 'Ended by retirement')),
                      if (m.isRanked) const Chip(avatar: Icon(Icons.leaderboard, size: 18), label: Text('Ranked')),
                      Chip(label: Text(m.source == MatchSource.live ? 'Scored live' : 'Logged result')),
                    ],
                  ),
                  if (!justFinished && ratingNote != null) ...[
                    const SizedBox(height: 8),
                    Text(ratingNote, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                  if (m.notes.isNotEmpty) ...[const SizedBox(height: 8), Text(m.notes)],
                ],
              ),
            ),
          ),
          if (m.stats != null) ...[
            const SectionHeader('Stats'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: StatsComparison(names: [m.sideName(0), m.sideName(1)], stats: m.stats!),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String? _ratingNote(AppStore store, MatchRecord m) {
    if (!m.isRanked) {
      if (m.isDoubles) return 'Doubles matches count in your stats but not the singles ladder.';
      if (m.winnerSide == null) return 'No result, so the ladder is unchanged.';
      return 'Matches with guests are not ranked. Add them as club players to rank future matches.';
    }
    final w = m.side(m.winnerSide!).first;
    final l = m.side(1 - m.winnerSide!).first;
    return 'Ladder: ${w.name} ${store.ratingOf(w.playerId!)} · ${l.name} ${store.ratingOf(l.playerId!)}';
  }
}
