import 'package:flutter_test/flutter_test.dart';
import 'package:veritas_tennis/logic/bracket.dart';
import 'package:veritas_tennis/logic/ratings.dart';
import 'package:veritas_tennis/logic/stats.dart';
import 'package:veritas_tennis/models/match_record.dart';
import 'package:veritas_tennis/models/tournament.dart';
import 'package:veritas_tennis/scoring/match_format.dart';
import 'package:veritas_tennis/scoring/set_score.dart';

MatchRecord singles(String a, String b, int winner, String score, {int day = 1}) => MatchRecord(
  id: '$a$b$day',
  playedAt: DateTime(2026, 9, day),
  format: const MatchFormat(),
  sideA: [Participant(playerId: a, name: a)],
  sideB: [Participant(playerId: b, name: b)],
  sets: parseSetScores(score)!,
  winnerSide: winner,
);

void main() {
  group('knockout', () {
    test('seed positions', () {
      expect(seedPositions(4), [1, 4, 2, 3]);
      expect(seedPositions(8), [1, 8, 4, 5, 2, 7, 3, 6]);
    });

    test('byes go to top seeds and advance automatically', () {
      final rounds = createKnockout(['p1', 'p2', 'p3', 'p4', 'p5', 'p6']);
      expect(rounds.length, 3);
      expect(rounds.first.length, 4);
      final first = rounds.first;
      expect(first[0].a, 'p1');
      expect(first[0].b, isNull);
      expect(first[0].winner, 'p1');
      expect(rounds[1][0].a, 'p1');
      expect(first.where((f) => f.isReady).length, 2);
    });

    test('changing an early result clears later rounds', () {
      final rounds = createKnockout(['a', 'b', 'c', 'd']);
      rounds[0][0].winner = 'a';
      rounds[0][1].winner = 'b';
      propagateKnockout(rounds);
      expect(rounds[1][0].isReady, isTrue);
      rounds[1][0].winner = 'a';
      rounds[0][0].winner = 'd';
      propagateKnockout(rounds);
      expect(rounds[1][0].a, 'd');
      expect(rounds[1][0].winner, isNull);
    });

    test('round names', () {
      expect(knockoutRoundName(0, 3), 'Quarter-finals');
      expect(knockoutRoundName(2, 3), 'Final');
      expect(knockoutRoundName(0, 5), 'Round of 32');
    });
  });

  group('round robin', () {
    test('everyone meets everyone once', () {
      final ids = ['a', 'b', 'c', 'd', 'e'];
      final rounds = createRoundRobin(ids);
      final pairs = rounds.expand((r) => r).map((f) => ({f.a, f.b}..remove(null)).toList()..sort()).toList();
      expect(pairs.length, 10);
      expect(pairs.map((p) => p.join()).toSet().length, 10);
    });

    test('standings rank by wins then set difference', () {
      final t = Tournament(
        id: 't',
        name: 'Test',
        type: TournamentType.roundRobin,
        playerIds: ['a', 'b', 'c'],
        rounds: createRoundRobin(['a', 'b', 'c']),
        createdAt: DateTime(2026),
      );
      for (final f in t.fixtures) {
        final pair = {f.a, f.b};
        if (pair.containsAll({'a', 'b'})) {
          f.winner = 'a';
          f.score = '6-0 6-0';
        } else if (pair.containsAll({'b', 'c'})) {
          f.winner = 'b';
          f.score = '6-4 6-4';
        } else {
          f.winner = 'c';
          f.score = '6-4 3-6 6-4';
        }
      }
      final table = roundRobinStandings(t);
      // All on 1 win; a has +1 sets, b is 0 sets (+2 -2), c is +0 … use set diff.
      expect(table.map((s) => s.won), [1, 1, 1]);
      expect(table.first.playerId, 'a');
      expect(tournamentChampion(t), 'a');
    });
  });

  group('ratings and stats', () {
    test('winner gains what loser drops; upsets pay more', () {
      expect(ratingDelta(1200, 1200), 16);
      expect(ratingDelta(1100, 1300), greaterThan(16));
      final r = computeRatings([singles('a', 'b', 0, '6-1 6-1', day: 1), singles('a', 'c', 1, '6-4 6-4', day: 2)]);
      expect(r['a']!.wins, 1);
      expect(r['a']!.losses, 1);
      expect(r['a']!.rating + r['b']!.rating + r['c']!.rating, 3600);
      expect(r['a']!.history.length, 2);
    });

    test('player stats, streaks and head to head', () {
      final matches = [
        singles('me', 'x', 0, '6-3 7-6(4)', day: 1),
        singles('me', 'x', 1, '4-6 4-6', day: 2),
        singles('y', 'me', 1, '2-6 6-4 [7-10]', day: 3),
        singles('me', 'y', 0, '6-0 6-0', day: 4),
      ];
      final s = statsFor('me', matches);
      expect(s.played, 4);
      expect(s.wins, 3);
      expect(s.streak, 2);
      expect(s.bestWinStreak, 2);
      expect(s.form.first, isTrue);
      expect(s.tiebreaksWon, 2); // 7-6(4) and the match tiebreak
      expect(s.headToHead['x']!.wins, 1);
      expect(s.headToHead['x']!.losses, 1);
      expect(s.headToHead['y']!.wins, 2);
      expect(s.gamesWon, 6 + 7 + 4 + 4 + 6 + 4 + 12);
    });
  });
}
