import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_store.dart';
import '../../logic/bracket.dart';
import '../../models/tournament.dart';
import '../../theme.dart';
import '../../util/format.dart';
import '../../widgets/common.dart';
import '../../widgets/sync_widgets.dart';
import 'tournament_form_screen.dart';
import 'tournament_screen.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    return Scaffold(
      appBar: AppBar(title: const Text('Events')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'new-tournament',
        onPressed: () =>
            Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const TournamentFormScreen())),
        icon: const Icon(Icons.add),
        label: const Text('New tournament'),
      ),
      body: SyncRefresh(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
          children: [
            Text(
              'Run hall, departmental or club tournaments: build the draw, score matches live and share results.',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            if (store.tournaments.isEmpty)
              const EmptyState(
                icon: Icons.emoji_events_outlined,
                title: 'No tournaments yet',
                message: 'Create a knockout or round robin with players from your club list.',
              )
            else
              for (final t in store.tournaments)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TournamentCard(tournament: t),
                ),
          ],
        ),
      ),
    );
  }
}

class TournamentCard extends StatelessWidget {
  const TournamentCard({super.key, required this.tournament});

  final Tournament tournament;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final t = tournament;
    final champion = tournamentChampion(t);
    final total = t.readyCount + t.fixtures.where((f) => !f.isReady && !f.isPlayed).length;
    final progress = total == 0 ? 0.0 : t.playedCount / total;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () =>
            Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => TournamentScreen(tournamentId: t.id))),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    champion != null ? Icons.emoji_events : Icons.emoji_events_outlined,
                    color: champion != null ? VeritasColors.gold : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(t.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${t.type.label} · ${t.playerIds.length} players · ${fmtShortDate(t.createdAt)}',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 10),
              if (champion != null)
                Text('Champion: ${store.nameOf(champion)}', style: const TextStyle(fontWeight: FontWeight.w700))
              else ...[
                LinearProgressIndicator(value: progress, borderRadius: BorderRadius.circular(4)),
                const SizedBox(height: 4),
                Text('${t.playedCount} of $total matches played', style: Theme.of(context).textTheme.bodySmall),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
