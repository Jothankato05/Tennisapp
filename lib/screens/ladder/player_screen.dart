import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_store.dart';
import '../../models/match_record.dart';
import '../../util/device.dart';
import '../../util/format.dart';
import '../../widgets/common.dart';
import '../../widgets/match_widgets.dart';
import '../../widgets/player_picker.dart';
import '../../widgets/rating_chart.dart';
import '../play/log_result_screen.dart';
import '../play/match_detail_screen.dart';
import '../play/new_match_screen.dart';
import 'player_form_screen.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key, required this.playerId});

  final String playerId;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final p = store.playerById(playerId);
    if (p == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Player not found')),
      );
    }
    final isMe = p.id == store.meId;
    final stats = store.statsOf(p.id);
    final info = store.ratings[p.id];
    final rank = store.rankOf(p.id);
    final matches = store.matchesFor(p.id);
    final theme = Theme.of(context);
    final me = store.me;

    final h2hList = stats.headToHead.entries.toList()
      ..sort((a, b) => (b.value.wins + b.value.losses).compareTo(a.value.wins + a.value.losses));
    final vsMe = (!isMe && me != null) ? store.statsOf(me.id).headToHead[p.id] : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isMe ? 'My profile' : p.firstName),
        actions: [
          IconButton(
            tooltip: 'Same person as…',
            icon: const Icon(Icons.merge_type),
            onPressed: () async {
              final target = await pickParticipant(
                context,
                title: 'Who is ${p.firstName} the same person as?',
                exclude: {p.id},
                allowGuest: false,
              );
              if (target?.playerId == null || !context.mounted) return;
              final ok = await confirm(
                context,
                title: 'Merge ${p.name} into ${target!.name}?',
                message: isMe
                    ? 'Your matches and tournament places move to ${target.name}, and that profile becomes yours.'
                    : '${p.firstName}\'s matches and tournament places move to ${target.name}, and this '
                          'duplicate profile is removed.',
                confirmLabel: 'Merge',
              );
              if (!ok || !context.mounted) return;
              Navigator.pop(context);
              store.mergePlayers(p.id, target.playerId!);
              showSnack(context, 'Merged into ${target.name}');
            },
          ),
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () =>
                Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PlayerFormScreen(player: p))),
          ),
          if (!isMe)
            IconButton(
              tooltip: 'Remove player',
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final inEvent = store.playerInTournament(p.id);
                final ok = await confirm(
                  context,
                  title: 'Remove ${p.name}?',
                  message: inEvent
                      ? '${p.firstName} is in a tournament. Their name will show as "Former player" there. Past matches stay in history.'
                      : 'Past matches stay in history, but ${p.firstName} will leave the ladder.',
                  confirmLabel: 'Remove',
                  destructive: true,
                );
                if (!ok || !context.mounted) return;
                Navigator.pop(context);
                store.deletePlayer(p.id);
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              PlayerAvatar(initials: p.initials, radius: 32, highlight: isMe),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                    Text(
                      [p.level.label, p.hand.label, if (p.department.isNotEmpty) p.department].join(' · '),
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (p.notes.isNotEmpty) ...[const SizedBox(height: 12), Text(p.notes)],
          if (p.phone.isNotEmpty && !isMe) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => callNumber(context, p.phone),
                    icon: const Icon(Icons.phone_outlined),
                    label: const Text('Call'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => openWhatsApp(
                      context,
                      p.phone,
                      message: 'Hi ${p.firstName}, fancy a game on the Veritas court?',
                    ),
                    icon: const Icon(Icons.chat_outlined),
                    label: const Text('WhatsApp'),
                  ),
                ),
              ],
            ),
          ],
          if (!isMe) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => NewMatchScreen(
                          sideB: Participant(playerId: p.id, name: p.name),
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.scoreboard_outlined),
                    label: const Text('Play now'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => LogResultScreen(
                          opponent: Participant(playerId: p.id, name: p.name),
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.edit_note),
                    label: const Text('Log result'),
                  ),
                ),
              ],
            ),
          ],
          if (vsMe != null) ...[
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.compare_arrows),
                title: Text('You vs ${p.firstName}: ${vsMe.wins}–${vsMe.losses}'),
                subtitle: Text(
                  vsMe.wins > vsMe.losses
                      ? 'You lead the head-to-head'
                      : vsMe.wins < vsMe.losses
                      ? '${p.firstName} leads the head-to-head'
                      : 'All square',
                ),
              ),
            ),
          ],
          const SectionHeader('Overview'),
          StatGrid(
            children: [
              StatTile(value: rank == null ? '—' : '#$rank', label: 'Ladder rank'),
              StatTile(value: '${store.ratingOf(p.id)}', label: 'Rating'),
              StatTile(value: '${stats.wins}–${stats.losses}', label: 'Win–loss'),
              StatTile(value: stats.played == 0 ? '—' : fmtPercent(stats.winRate), label: 'Win rate'),
              StatTile(
                value: stats.streak == 0 ? '—' : '${stats.streak > 0 ? 'W' : 'L'}${stats.streak.abs()}',
                label: 'Current streak',
              ),
              StatTile(value: '${stats.bestWinStreak}', label: 'Best win streak'),
              StatTile(value: '${stats.setsWon}–${stats.setsLost}', label: 'Sets'),
              StatTile(value: '${stats.tiebreaksWon}–${stats.tiebreaksLost}', label: 'Tiebreaks'),
              StatTile(
                value: stats.breakPointChances == 0 ? '—' : fmtPercent(stats.breakPointsWon / stats.breakPointChances),
                label: 'Break points',
              ),
            ],
          ),
          if (stats.form.isNotEmpty) ...[const SectionHeader('Recent form'), FormDots(stats.form, max: 10)],
          if (info != null && info.history.isNotEmpty) ...[
            const SectionHeader('Rating history'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: RatingChart(history: info.history),
              ),
            ),
          ],
          if (h2hList.isNotEmpty) ...[
            const SectionHeader('Head to head (singles)'),
            Card(
              child: Column(
                children: [
                  for (final e in h2hList.take(8))
                    ListTile(
                      dense: true,
                      title: Text(store.playerById(e.key)?.name ?? e.value.opponentName),
                      trailing: Text(
                        '${e.value.wins}–${e.value.losses}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                    ),
                ],
              ),
            ),
          ],
          SectionHeader('Matches (${matches.length})'),
          if (matches.isEmpty)
            const EmptyState(icon: Icons.sports_tennis, title: 'No matches yet')
          else
            for (final m in matches.take(20))
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: MatchCard(
                  match: m,
                  perspectiveId: p.id,
                  onTap: () =>
                      Navigator.of(context)
                          .push(MaterialPageRoute<void>(builder: (_) => MatchDetailScreen(matchId: m.id))),
                ),
              ),
        ],
      ),
    );
  }
}
