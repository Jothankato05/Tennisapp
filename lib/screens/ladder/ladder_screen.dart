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
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Rankings'),
              Tab(text: 'Players'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'add-player',
          onPressed: () =>
              Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const PlayerFormScreen())),
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text('Add player'),
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
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        Card(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              'Everyone starts on $startingRating. Win a ranked singles match to gain points; beating a '
              'higher-rated player earns more. Log every match so the ladder stays fair.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (ladder.isEmpty)
          const EmptyState(
            icon: Icons.leaderboard_outlined,
            title: 'The ladder is empty',
            message: 'Add the players you hit with, then score or log singles matches against them.',
          )
        else
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final e in ladder) ...[
                  if (e.rank > 1) const Divider(height: 1),
                  ListTile(
                    tileColor: e.player.id == store.meId ? VeritasColors.ball.withValues(alpha: 0.25) : null,
                    leading: _RankBadge(rank: e.rank),
                    title: Text(
                      e.player.id == store.meId ? '${e.player.name} (you)' : e.player.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text('${e.info.wins}W – ${e.info.losses}L · ${e.player.level.label}'),
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
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});
  final int rank;

  @override
  Widget build(BuildContext context) {
    final colors = {1: const Color(0xFFF5D76E), 2: const Color(0xFFD9DEE5), 3: const Color(0xFFE7B98A)};
    return CircleAvatar(
      radius: 18,
      backgroundColor: colors[rank] ?? Theme.of(context).colorScheme.surfaceContainerHighest,
      foregroundColor: rank <= 3 ? Colors.black87 : null,
      child: Text('$rank', style: const TextStyle(fontWeight: FontWeight.w800)),
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
          const EmptyState(
            icon: Icons.group_add_outlined,
            title: 'Build your club list',
            message: 'Add the students and staff you play with so you can track results and head-to-heads.',
          ),
      ],
    );
  }
}
