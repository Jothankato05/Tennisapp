import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_store.dart';
import '../../logic/ratings.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/sync_widgets.dart';
import 'player_form_screen.dart';
import 'player_screen.dart';

class LadderScreen extends StatelessWidget {
  const LadderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ladder'),
          actions: [
            IconButton(
              tooltip: 'How ratings work',
              icon: const Icon(Icons.info_outline_rounded),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('How ratings work'),
                  content: const Text(
                    'Everyone starts at $startingRating. Win a ranked singles match to gain points. '
                    'Beating a higher-rated player earns more.',
                  ),
                  actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Got it'))],
                ),
              ),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Rankings'),
              Tab(text: 'Players'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'add-player',
          onPressed: () =>
              Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const PlayerFormScreen())),
          tooltip: 'Add player',
          child: const Icon(Icons.person_add_alt_1_rounded),
        ),
        body: const SyncRefresh(child: TabBarView(children: [_Rankings(), _Players()])),
      ),
    );
  }
}

void openPlayer(BuildContext context, String id) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PlayerScreen(playerId: id)));

class _Rankings extends StatelessWidget {
  const _Rankings();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final ladder = store.ladder;
    final theme = Theme.of(context);
    final podium = ladder.take(3).toList();
    final rest = ladder.skip(3).toList();
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
      children: [
        if (ladder.isEmpty)
          const EmptyState(icon: Icons.leaderboard_outlined, title: 'No ranked matches yet')
        else ...[
          _Podium(entries: podium, meId: store.meId),
          if (rest.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (final e in rest) ...[
                    if (e.rank > 4) const Divider(height: 1, indent: 64),
                    ListTile(
                      tileColor: e.player.id == store.meId ? VeritasColors.ball.withValues(alpha: 0.12) : null,
                      shape: const RoundedRectangleBorder(),
                      leading: _RankBadge(rank: e.rank),
                      title: Text(e.player.id == store.meId ? '${e.player.name} (you)' : e.player.name),
                      subtitle: Text('${e.info.wins}–${e.info.losses}'),
                      trailing: Text(
                        '${e.info.rating}',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      onTap: () => openPlayer(context, e.player.id),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }
}

/// Top three as a podium: 2nd · 1st · 3rd.
class _Podium extends StatelessWidget {
  const _Podium({required this.entries, required this.meId});

  final List<LadderEntry> entries;
  final String? meId;

  @override
  Widget build(BuildContext context) {
    final order = [if (entries.length > 1) entries[1], entries[0], if (entries.length > 2) entries[2]];
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 22, 12, 0),
      decoration: BoxDecoration(gradient: VeritasColors.heroGradient, borderRadius: BorderRadius.circular(28)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final e in order)
            Expanded(
              child: GestureDetector(
                onTap: () => openPlayer(context, e.player.id),
                child: Column(
                  children: [
                    PlayerAvatar(
                      initials: e.player.initials,
                      radius: e.rank == 1 ? 30 : 24,
                      highlight: e.rank == 1 || e.player.id == meId,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      e.player.firstName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${e.info.rating}',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 12.5),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: switch (e.rank) {
                        1 => 64.0,
                        2 => 44.0,
                        _ => 30.0,
                      },
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: e.rank == 1 ? VeritasColors.ball : Colors.white.withValues(alpha: 0.12),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                      ),
                      child: Text(
                        '${e.rank}',
                        style: TextStyle(
                          color: e.rank == 1 ? VeritasColors.navy : Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
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

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});
  final int rank;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      child: Text(
        '$rank',
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _Players extends StatefulWidget {
  const _Players();

  @override
  State<_Players> createState() => _PlayersState();
}

class _PlayersState extends State<_Players> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final q = _query.toLowerCase();
    final players = store.players
        .where((p) => q.isEmpty || p.name.toLowerCase().contains(q) || p.department.toLowerCase().contains(q))
        .toList();
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        TextField(
          decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search by name or department'),
          onChanged: (v) => setState(() => _query = v.trim()),
        ),
        const SizedBox(height: 12),
        Text(
          '${store.players.length} player${store.players.length == 1 ? '' : 's'} in your club list',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        for (final p in players)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              child: ListTile(
                leading: PlayerAvatar(initials: p.initials, highlight: p.id == store.meId),
                title: Text(p.id == store.meId ? '${p.name} (you)' : p.name),
                subtitle: Text([p.level.label, if (p.department.isNotEmpty) p.department].join(' · ')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => openPlayer(context, p.id),
              ),
            ),
          ),
        if (store.players.length <= 1)
          const EmptyState(icon: Icons.group_add_outlined, title: 'Add your playing partners'),
      ],
    );
  }
}
