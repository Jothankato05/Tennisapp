import '../models/match_record.dart';

class HeadToHead {
  HeadToHead(this.opponentName);
  final String opponentName;
  int wins = 0;
  int losses = 0;
}

class PlayerStats {
  int played = 0;
  int wins = 0;
  int losses = 0;
  int setsWon = 0;
  int setsLost = 0;
  int gamesWon = 0;
  int gamesLost = 0;
  int tiebreaksWon = 0;
  int tiebreaksLost = 0;
  int aces = 0;
  int doubleFaults = 0;
  int breakPointsWon = 0;
  int breakPointChances = 0;

  /// Positive = current winning streak, negative = losing streak.
  int streak = 0;
  int bestWinStreak = 0;

  /// Most recent first; true = win.
  final List<bool> form = [];
  final Map<String, HeadToHead> headToHead = {};

  double get winRate => played == 0 ? 0 : wins / played;
}

/// Aggregates every match [playerId] took part in (singles and doubles).
PlayerStats statsFor(String playerId, Iterable<MatchRecord> matches) {
  final stats = PlayerStats();
  final mine = matches.where((m) => m.involves(playerId) && m.winnerSide != null).toList()
    ..sort((a, b) => a.playedAt.compareTo(b.playedAt));

  var run = 0;
  for (final m in mine) {
    final side = m.sideOf(playerId)!;
    final won = m.winnerSide == side;
    stats.played++;
    if (won) {
      stats.wins++;
      run = run > 0 ? run + 1 : 1;
    } else {
      stats.losses++;
      run = run < 0 ? run - 1 : -1;
    }
    if (run > stats.bestWinStreak) stats.bestWinStreak = run;
    stats.form.insert(0, won);

    for (final s in m.sets) {
      if (s.winner == side) {
        stats.setsWon++;
      } else {
        stats.setsLost++;
      }
      if (!s.matchTiebreak) {
        stats.gamesWon += s.gamesFor(side);
        stats.gamesLost += s.gamesFor(1 - side);
      }
      if (s.hasTiebreak) {
        if (s.winner == side) {
          stats.tiebreaksWon++;
        } else {
          stats.tiebreaksLost++;
        }
      }
    }

    final live = m.stats;
    if (live != null && !m.isDoubles) {
      stats.aces += live[side].aces;
      stats.doubleFaults += live[side].doubleFaults;
      stats.breakPointsWon += live[side].breakPointsWon;
      stats.breakPointChances += live[side].breakPointChances;
    }

    if (!m.isDoubles) {
      final opp = m.side(1 - side).first;
      final key = opp.playerId ?? 'guest:${opp.name.toLowerCase()}';
      final h2h = stats.headToHead.putIfAbsent(key, () => HeadToHead(opp.name));
      if (won) {
        h2h.wins++;
      } else {
        h2h.losses++;
      }
    }
  }
  stats.streak = run;
  if (stats.form.length > 10) stats.form.removeRange(10, stats.form.length);
  return stats;
}
