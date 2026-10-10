import 'package:flutter/material.dart';

import '../models/match_record.dart';
import '../scoring/set_score.dart';
import '../theme.dart';
import '../util/format.dart';
import 'common.dart';

/// Two-row scoreboard: one row per side with a column per set.
class ScoreTable extends StatelessWidget {
  const ScoreTable({
    super.key,
    required this.names,
    required this.sets,
    this.winnerSide,
    this.servingSide,
    this.compact = false,
  });

  final List<String> names;
  final List<SetScore> sets;
  final int? winnerSide;
  final int? servingSide;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget row(int side) {
      final isWinner = winnerSide == side;
      final style = (compact ? theme.textTheme.bodyMedium : theme.textTheme.titleMedium)?.copyWith(
        fontWeight: isWinner ? FontWeight.w800 : FontWeight.w500,
      );
      return Padding(
        padding: EdgeInsets.symmetric(vertical: compact ? 2 : 4),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              child: servingSide == side
                  ? const Icon(Icons.circle, size: 9, color: VeritasColors.ball)
                  : (isWinner ? const Icon(Icons.check, size: 14, color: VeritasColors.win) : null),
            ),
            Expanded(
              child: Text(names[side], style: style, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            for (final s in sets)
              SizedBox(
                width: s.matchTiebreak ? 40 : 30,
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: s.matchTiebreak ? '${side == 0 ? s.tiebreakA : s.tiebreakB}' : '${s.gamesFor(side)}',
                        style: style?.copyWith(
                          fontWeight: s.winner == side ? FontWeight.w800 : FontWeight.w400,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      if (s.hasTiebreak && !s.matchTiebreak && s.winner != side)
                        TextSpan(text: '${side == 0 ? s.tiebreakA : s.tiebreakB}', style: theme.textTheme.labelSmall),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      );
    }

    return Column(children: [row(0), row(1)]);
  }
}

class MatchCard extends StatelessWidget {
  const MatchCard({super.key, required this.match, this.perspectiveId, this.onTap});

  final MatchRecord match;
  final String? perspectiveId;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mySide = perspectiveId == null ? null : match.sideOf(perspectiveId!);
    final won = mySide == null || match.winnerSide == null ? null : match.winnerSide == mySide;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (mySide != null) ...[ResultBadge(won: won), const SizedBox(width: 8)],
                  Expanded(
                    child: Text(
                      [
                        fmtRelativeDay(match.playedAt),
                        if (match.isDoubles) 'Doubles',
                        if (!match.completed) match.winnerSide == null ? 'Unfinished' : 'Retired',
                        if (match.tournamentId != null) 'Tournament',
                      ].join(' · '),
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                  if (match.isRanked)
                    Icon(Icons.leaderboard_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
                ],
              ),
              const SizedBox(height: 6),
              ScoreTable(
                names: [match.sideName(0), match.sideName(1)],
                sets: match.sets,
                winnerSide: match.winnerSide,
                compact: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
