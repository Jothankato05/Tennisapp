import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../data/app_store.dart';
import '../data/drills.dart';
import '../logic/bracket.dart';
import '../theme.dart';
import '../util/format.dart';
import '../widgets/common.dart';
import '../widgets/match_widgets.dart';
import 'events/events_screen.dart';
import 'events/tournament_form_screen.dart';
import 'ladder/player_screen.dart';
import 'play/log_result_screen.dart';
import 'play/match_detail_screen.dart';
import 'play/play_screen.dart';
import 'settings_screen.dart';
import 'train/practice_form_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final me = store.me!;
    final stats = store.statsOf(me.id);
    final rank = store.rankOf(me.id);
    final recent = store.matchesFor(me.id).take(3).toList();
    final activeEvents = store.tournaments.where((t) => tournamentChampion(t) == null).take(2).toList();
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final matchesThisWeek = store.matchesFor(me.id).where((m) => m.playedAt.isAfter(weekAgo)).length;
    final theme = Theme.of(context);

    void push(Widget screen) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(greeting(), style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                      Text(me.firstName, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Settings',
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => push(const SettingsScreen()),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ProfileHero(
              rating: store.ratingOf(me.id),
              rank: rank,
              record: '${stats.wins}–${stats.losses}',
              streak: stats.streak,
              onTap: () => push(PlayerScreen(playerId: me.id)),
            ),
            const SectionHeader('Quick actions'),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.85,
              children: [
                _QuickAction(
                  icon: Icons.scoreboard_outlined,
                  label: store.liveMatch == null ? 'Score match' : 'Resume',
                  onTap: () => openNewMatch(context),
                ),
                _QuickAction(icon: Icons.edit_note, label: 'Log result', onTap: () => push(const LogResultScreen())),
                _QuickAction(
                  icon: Icons.fitness_center,
                  label: 'Log practice',
                  onTap: () => push(const PracticeFormScreen()),
                ),
                _QuickAction(
                  icon: Icons.emoji_events_outlined,
                  label: 'Tournament',
                  onTap: () => push(const TournamentFormScreen()),
                ),
              ],
            ),
            const SectionHeader('This week'),
            StatGrid(
              children: [
                StatTile(value: '$matchesThisWeek', label: 'Matches', icon: Icons.sports_tennis),
                StatTile(
                  value: fmtMinutes(store.practiceMinutesThisWeek()),
                  label: 'Practice',
                  icon: Icons.timer_outlined,
                ),
                StatTile(
                  value: '${store.activeDayStreak()}',
                  label: 'Day streak',
                  icon: Icons.local_fire_department_outlined,
                ),
              ],
            ),
            SectionHeader(
              'Recent matches',
              action: recent.isEmpty ? null : 'See all',
              onAction: () => TabSwitcher.of(context, AppTab.play),
            ),
            if (stats.form.isNotEmpty) ...[
              Row(
                children: [
                  Text('Form ', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                  FormDots(stats.form),
                ],
              ),
              const SizedBox(height: 10),
            ],
            if (recent.isEmpty)
              EmptyState(
                icon: Icons.sports_tennis,
                title: 'Ready for your first match?',
                message: 'Score it live on court and your stats and ladder rating update automatically.',
                action: FilledButton.icon(
                  onPressed: () => openNewMatch(context),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start a match'),
                ),
              )
            else
              for (final m in recent)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: MatchCard(
                    match: m,
                    perspectiveId: me.id,
                    onTap: () => push(MatchDetailScreen(matchId: m.id)),
                  ),
                ),
            if (activeEvents.isNotEmpty) ...[
              SectionHeader('Tournaments', action: 'See all', onAction: () => TabSwitcher.of(context, AppTab.events)),
              for (final t in activeEvents)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TournamentCard(tournament: t),
                ),
            ],
            const SectionHeader('Coach\'s tip'),
            _TipCard(),
          ],
        ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.rating,
    required this.rank,
    required this.record,
    required this.streak,
    required this.onTap,
  });

  final int rating;
  final int? rank;
  final String record;
  final int streak;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Widget item(String value, String label) => Expanded(
      child: Column(
        children: [
          FittedBox(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
            ),
          ),
          Text(label, style: const TextStyle(color: Color(0xFFB9C7DA), fontSize: 12)),
        ],
      ),
    );
    return Material(
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [VeritasColors.navy, Color(0xFF1B4A7A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              const Positioned(
                right: -30,
                top: -30,
                child: CircleAvatar(radius: 60, backgroundColor: Color(0x22D9E84A)),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.sports_tennis, color: VeritasColors.ball, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'VERITAS UNIVERSITY TENNIS',
                          style: TextStyle(
                            color: VeritasColors.ball,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        item('$rating', 'Rating'),
                        item(rank == null ? '—' : '#$rank', 'Ladder'),
                        item(record, 'Win–loss'),
                        item(streak == 0 ? '—' : '${streak > 0 ? 'W' : 'L'}${streak.abs()}', 'Streak'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: VeritasColors.ball,
                child: Icon(icon, color: VeritasColors.navy, size: 22),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tips = [
      for (final d in drills)
        for (final t in d.tips) (t, d),
    ];
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year)).inDays;
    final (tip, drill) = tips[dayOfYear % tips.length];
    return Card(
      color: VeritasColors.ball.withValues(alpha: 0.25),
      child: ListTile(
        leading: const Icon(Icons.lightbulb_outline),
        title: Text(tip),
        subtitle: Text('From the drill: ${drill.name}'),
        onTap: () => TabSwitcher.of(context, AppTab.train),
      ),
    );
  }
}
