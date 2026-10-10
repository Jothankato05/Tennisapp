import '../models/ids.dart';
import '../models/tournament.dart';
import '../scoring/set_score.dart';

/// Standard seeding positions for a bracket of [size] (a power of two):
/// 2 → [1, 2], 4 → [1, 4, 2, 3], 8 → [1, 8, 4, 5, 2, 7, 3, 6] …
List<int> seedPositions(int size) {
  var order = [1, 2];
  while (order.length < size) {
    final total = order.length * 2 + 1;
    order = [
      for (final s in order) ...[s, total - s],
    ];
  }
  return order;
}

int bracketSize(int players) {
  var size = 2;
  while (size < players) {
    size *= 2;
  }
  return size;
}

/// Builds a single-elimination draw. [seededIds] is in seed order (best first).
/// Top seeds receive byes when the field is not a power of two.
List<List<Fixture>> createKnockout(List<String> seededIds) {
  assert(seededIds.length >= 2);
  final size = bracketSize(seededIds.length);
  final positions = seedPositions(size);
  String? bySeed(int seed) => seed <= seededIds.length ? seededIds[seed - 1] : null;

  final rounds = <List<Fixture>>[
    [for (var i = 0; i < size; i += 2) Fixture(id: newId(), a: bySeed(positions[i]), b: bySeed(positions[i + 1]))],
  ];
  for (var n = size ~/ 4; n >= 1; n ~/= 2) {
    rounds.add([for (var i = 0; i < n; i++) Fixture(id: newId())]);
  }
  for (final f in rounds.first) {
    if (f.a != null && f.b == null) f.winner = f.a;
    if (f.b != null && f.a == null) f.winner = f.b;
  }
  propagateKnockout(rounds);
  return rounds;
}

/// Moves winners into the next round, clearing any later results that no
/// longer make sense after an earlier result changed.
void propagateKnockout(List<List<Fixture>> rounds) {
  for (var r = 0; r < rounds.length - 1; r++) {
    for (var i = 0; i < rounds[r].length; i++) {
      final from = rounds[r][i];
      final to = rounds[r + 1][i ~/ 2];
      if (i.isEven) {
        to.a = from.winner;
      } else {
        to.b = from.winner;
      }
      if (to.winner != null && to.winner != to.a && to.winner != to.b) {
        to
          ..winner = null
          ..score = ''
          ..matchId = null;
      }
      if (to.winner != null && !to.isReady) {
        to
          ..winner = null
          ..score = ''
          ..matchId = null;
      }
    }
  }
}

String knockoutRoundName(int roundIndex, int totalRounds) {
  final fromEnd = totalRounds - roundIndex;
  return switch (fromEnd) {
    1 => 'Final',
    2 => 'Semi-finals',
    3 => 'Quarter-finals',
    _ => 'Round of ${1 << fromEnd}',
  };
}

/// Round-robin schedule using the circle method; every player meets every other once.
List<List<Fixture>> createRoundRobin(List<String> ids) {
  final list = <String?>[...ids];
  if (list.length.isOdd) list.add(null);
  final n = list.length;
  final rounds = <List<Fixture>>[];
  for (var r = 0; r < n - 1; r++) {
    final round = <Fixture>[];
    for (var i = 0; i < n ~/ 2; i++) {
      final a = list[i], b = list[n - 1 - i];
      if (a != null && b != null) round.add(Fixture(id: newId(), a: a, b: b));
    }
    rounds.add(round);
    // Keep the first entry fixed and rotate the rest clockwise.
    list.insert(1, list.removeLast());
  }
  return rounds;
}

class Standing {
  Standing(this.playerId);

  final String playerId;
  int played = 0;
  int won = 0;
  int lost = 0;
  int setsWon = 0;
  int setsLost = 0;
  int gamesWon = 0;
  int gamesLost = 0;

  int get setDiff => setsWon - setsLost;
  int get gameDiff => gamesWon - gamesLost;
}

/// Round-robin table. Scores are stored from the winner's point of view.
List<Standing> roundRobinStandings(Tournament t, {String Function(String id)? nameOf}) {
  final table = {for (final id in t.playerIds) id: Standing(id)};
  for (final f in t.fixtures) {
    if (!f.isPlayed || !f.isReady) continue;
    final w = table[f.winner], l = table[f.loser];
    if (w == null || l == null) continue;
    w
      ..played += 1
      ..won += 1;
    l
      ..played += 1
      ..lost += 1;
    for (final s in parseSetScores(f.score) ?? const <SetScore>[]) {
      final winnerTookSet = s.winner == 0;
      if (winnerTookSet) {
        w.setsWon++;
        l.setsLost++;
      } else {
        l.setsWon++;
        w.setsLost++;
      }
      if (!s.matchTiebreak) {
        w
          ..gamesWon += s.a
          ..gamesLost += s.b;
        l
          ..gamesWon += s.b
          ..gamesLost += s.a;
      }
    }
  }
  final list = table.values.toList()
    ..sort((x, y) {
      for (final c in [y.won - x.won, y.setDiff - x.setDiff, y.gameDiff - x.gameDiff]) {
        if (c != 0) return c;
      }
      // Head to head between two tied players.
      for (final f in t.fixtures) {
        if (f.isPlayed && {f.a, f.b}.containsAll({x.playerId, y.playerId})) {
          return f.winner == x.playerId ? -1 : 1;
        }
      }
      if (nameOf != null) return nameOf(x.playerId).compareTo(nameOf(y.playerId));
      return 0;
    });
  return list;
}

/// The overall winner, once decided.
String? tournamentChampion(Tournament t) {
  if (t.type == TournamentType.knockout) return t.rounds.last.single.winner;
  if (t.fixtures.any((f) => f.isReady && !f.isPlayed)) return null;
  final table = roundRobinStandings(t);
  return table.isEmpty ? null : table.first.playerId;
}
