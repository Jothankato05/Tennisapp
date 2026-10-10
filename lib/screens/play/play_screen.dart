import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_store.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/sync_widgets.dart';
import '../../widgets/match_widgets.dart';
import 'live_match_screen.dart';
import 'log_result_screen.dart';
import 'match_detail_screen.dart';
import 'new_match_screen.dart';

void openNewMatch(BuildContext context) {
  final store = context.read<AppStore>();
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => store.liveMatch != null ? const LiveMatchScreen() : const NewMatchScreen()),
  );
}

class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key});

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  bool _mineOnly = true;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final meId = store.meId;
    final matches = _mineOnly && meId != null ? store.matchesFor(meId) : store.matches;

    return Scaffold(
      appBar: AppBar(title: const Text('Play')),
      body: SyncRefresh(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    icon: Icons.scoreboard,
                    title: store.liveMatch != null ? 'Resume' : 'Score live',
                    color: VeritasColors.navy,
                    onTap: () => openNewMatch(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionCard(
                    icon: Icons.edit_note,
                    title: 'Log result',
                    color: VeritasColors.court,
                    onTap: () =>
                        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const LogResultScreen())),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('History', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                const Spacer(),
                SegmentedButton<bool>(
                  showSelectedIcon: false,
                  style: const ButtonStyle(visualDensity: VisualDensity.compact),
                  segments: const [
                    ButtonSegment(value: true, label: Text('Mine')),
                    ButtonSegment(value: false, label: Text('All')),
                  ],
                  selected: {_mineOnly},
                  onSelectionChanged: (s) => setState(() => _mineOnly = s.first),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (matches.isEmpty)
              const EmptyState(icon: Icons.sports_tennis, title: 'No matches yet')
            else
              for (final m in matches)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: MatchCard(
                    match: m,
                    perspectiveId: meId,
                    onTap: () =>
                        Navigator.of(context)
                            .push(MaterialPageRoute<void>(builder: (_) => MatchDetailScreen(matchId: m.id))),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.icon, required this.title, required this.color, required this.onTap});

  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: VeritasColors.ball, size: 30),
              const SizedBox(height: 22),
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
