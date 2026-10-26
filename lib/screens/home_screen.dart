import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../data/app_store.dart';
import '../logic/bracket.dart';
import '../theme.dart';
import '../util/format.dart';
import '../widgets/common.dart';
import '../widgets/install_banner.dart';
import '../widgets/match_widgets.dart';
import '../widgets/sync_widgets.dart';
import 'club_screen.dart';
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
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Row(
              children: [
                Image.asset('assets/brand/racqueteers_cutout.png', height: 40, filterQuality: FilterQuality.high),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting(),
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                      Text(me.firstName, style: theme.textTheme.titleLarge),
                    ],
                  ),
                ),
                SyncStatusIcon(onPressed: () => push(const ClubScreen())),
                IconButton(
                  tooltip: 'Settings',
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => push(const SettingsScreen()),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _ProfileHero(
              rating: store.ratingOf(me.id),
              rank: rank,
              record: '${stats.wins}–${stats.losses}',
              streak: stats.streak,
              onTap: () => push(PlayerScreen(playerId: me.id)),
            ),
            const InstallBanner(),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _QuickAction(
                  icon: store.liveMatch == null ? Icons.scoreboard_outlined : Icons.play_arrow_rounded,
                  label: store.liveMatch == null ? 'Score' : 'Resume',
                  primary: true,
                  onTap: () => openNewMatch(context),
                ),
                _QuickAction(icon: Icons.edit_note_rounded, label: 'Log', onTap: () => push(const LogResultScreen())),
                _QuickAction(
                  icon: Icons.fitness_center_rounded,
                  label: 'Practice',
                  onTap: () => push(const PracticeFormScreen()),
                ),
                _QuickAction(
                  icon: Icons.emoji_events_outlined,
                  label: 'Event',
                  onTap: () => push(const TournamentFormScreen()),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    _WeekStat(value: '$matchesThisWeek', label: 'Matches'),
                    _divider(context),
                    _WeekStat(value: fmtMinutes(store.practiceMinutesThisWeek()), label: 'Practice'),
                    _divider(context),
                    _WeekStat(value: '${store.activeDayStreak()}', label: 'Day streak'),
                  ],
                ),
              ),
            ),
            SectionHeader(
              'Recent',
              action: recent.isEmpty ? null : 'See all',
              onAction: () => TabSwitcher.of(context, AppTab.play),
            ),
            if (recent.isEmpty)
              EmptyState(
                icon: Icons.sports_tennis,
                title: 'No matches yet',
                action: FilledButton.icon(
                  onPressed: () => openNewMatch(context),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Start a match'),
                ),
              )
            else ...[
              if (stats.form.isNotEmpty) ...[FormDots(stats.form), const SizedBox(height: 12)],
              for (final m in recent)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: MatchCard(
                    match: m,
                    perspectiveId: me.id,
                    onTap: () => push(MatchDetailScreen(matchId: m.id)),
                  ),
                ),
            ],
            if (activeEvents.isNotEmpty) ...[
              SectionHeader('Events', action: 'See all', onAction: () => TabSwitcher.of(context, AppTab.events)),
              for (final t in activeEvents)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TournamentCard(tournament: t),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _divider(BuildContext context) =>
      Container(width: 1, height: 32, color: Theme.of(context).colorScheme.outlineVariant);
}

class _WeekStat extends StatelessWidget {
  const _WeekStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Text(value, style: theme.textTheme.titleLarge?.copyWith(fontSize: 20)),
          const SizedBox(height: 2),
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
        ],
      ),
    );
    return Material(
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: const BoxDecoration(gradient: VeritasColors.heroGradient),
          child: Stack(
            children: [
              Positioned(
                right: -36,
                top: -20,
                bottom: -20,
                child: Opacity(
                  opacity: 0.07,
                  child: Image.asset('assets/brand/racqueteers_cutout.png', fit: BoxFit.contain),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RATING',
                      style: TextStyle(
                        color: VeritasColors.ball.withValues(alpha: 0.9),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      '$rating',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 46,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.5,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        item(rank == null ? '—' : '#$rank', 'Ladder'),
                        item(record, 'Won–lost'),
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
  const _QuickAction({required this.icon, required this.label, required this.onTap, this.primary = false});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: primary ? VeritasColors.ball : theme.colorScheme.surface,
                shape: BoxShape.circle,
                border: primary ? null : Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Icon(
                icon,
                size: 26,
                color: primary ? VeritasColors.navy : (dark ? Colors.white : VeritasColors.navy),
              ),
            ),
            const SizedBox(height: 8),
            Text(label, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
