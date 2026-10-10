import 'package:flutter_test/flutter_test.dart';
import 'package:veritas_tennis/scoring/match_format.dart';
import 'package:veritas_tennis/scoring/set_score.dart';
import 'package:veritas_tennis/scoring/tennis_scorer.dart';

void winPoints(TennisScorer s, int side, int n) {
  for (var i = 0; i < n; i++) {
    s.play(PointEvent.to(side));
  }
}

void winGames(TennisScorer s, int side, int n) => winPoints(s, side, 4 * n);

void main() {
  group('games', () {
    test('counts 15, 30, 40 and wins at four points', () {
      final s = TennisScorer(const MatchFormat());
      winPoints(s, 0, 1);
      expect(s.pointLabel(0), '15');
      winPoints(s, 0, 2);
      expect(s.pointLabel(0), '40');
      expect(s.pointLabel(1), '0');
      winPoints(s, 0, 1);
      expect(s.games, [1, 0]);
      expect(s.points, [0, 0]);
    });

    test('deuce and advantage', () {
      final s = TennisScorer(const MatchFormat());
      winPoints(s, 0, 3);
      winPoints(s, 1, 3);
      expect(s.situation, 'Deuce');
      winPoints(s, 1, 1);
      expect(s.pointLabel(1), 'AD');
      expect(s.pointLabel(0), '40');
      winPoints(s, 0, 1);
      expect(s.situation, 'Deuce');
      winPoints(s, 0, 2);
      expect(s.games, [1, 0]);
    });

    test('no-ad plays a deciding point at 40-40', () {
      final s = TennisScorer(const MatchFormat(noAd: true));
      winPoints(s, 0, 3);
      winPoints(s, 1, 3);
      expect(s.situation, isNot('Deuce'));
      winPoints(s, 1, 1);
      expect(s.games, [0, 1]);
    });
  });

  group('serving', () {
    test('alternates every game in singles', () {
      final s = TennisScorer(const MatchFormat(), firstServerSide: 1);
      expect(s.servingSide, 1);
      winGames(s, 0, 1);
      expect(s.servingSide, 0);
      winGames(s, 0, 1);
      expect(s.servingSide, 1);
    });

    test('rotates through all four players in doubles', () {
      final s = TennisScorer(const MatchFormat(doubles: true));
      final order = <(int, int)>[];
      for (var i = 0; i < 4; i++) {
        order.add((s.servingSide, s.servingPlayer));
        winGames(s, i.isEven ? 0 : 1, 1);
      }
      expect(order, [(0, 0), (1, 0), (0, 1), (1, 1)]);
      expect((s.servingSide, s.servingPlayer), (0, 0));
    });

    test('ace and double fault credit the right side', () {
      final s = TennisScorer(const MatchFormat());
      s.play(const PointEvent(PointKind.ace));
      expect(s.points, [1, 0]);
      s.play(const PointEvent(PointKind.doubleFault));
      expect(s.points, [1, 1]);
      expect(s.stats[0].aces, 1);
      expect(s.stats[0].doubleFaults, 1);
      s.play(const PointEvent(PointKind.unforcedError, 1));
      expect(s.points, [2, 1]);
      expect(s.stats[1].unforcedErrors, 1);
    });
  });

  group('sets and tiebreaks', () {
    test('6-4 wins a set; 6-5 does not', () {
      final s = TennisScorer(const MatchFormat());
      winGames(s, 0, 5);
      winGames(s, 1, 4);
      winGames(s, 0, 1);
      expect(s.sets, [const SetScore(6, 4)]);

      winGames(s, 0, 5);
      winGames(s, 1, 5);
      winGames(s, 0, 1);
      expect(s.sets.length, 1);
      expect(s.games, [6, 5]);
    });

    test('tiebreak at 6-6, first to 7 by two, server rotation', () {
      final s = TennisScorer(const MatchFormat());
      for (var i = 0; i < 6; i++) {
        winGames(s, 0, 1);
        winGames(s, 1, 1);
      }
      expect(s.inTiebreak, isTrue);
      final tbFirstServer = s.servingSide;
      expect(tbFirstServer, 0); // 12 games played, A served first
      winPoints(s, 1, 1);
      expect(s.servingSide, 1);
      winPoints(s, 1, 1);
      expect(s.servingSide, 1);
      winPoints(s, 0, 1);
      expect(s.servingSide, 0);
      // From 1-2 to 6-6 then 8-6 to A.
      winPoints(s, 0, 5);
      winPoints(s, 1, 4);
      expect(s.points, [6, 6]);
      winPoints(s, 0, 2);
      expect(s.sets.single, const SetScore(7, 6, tiebreakA: 8, tiebreakB: 6));
      expect(s.sets.single.label(), '7-6(6)');
      // Receiver of the first tiebreak point serves the next set.
      expect(s.servingSide, 1);
    });

    test('best of three ends after two sets', () {
      final s = TennisScorer(const MatchFormat());
      winGames(s, 1, 12);
      expect(s.winner, 1);
      expect(s.sets.map((x) => x.label()).toList(), ['0-6', '0-6']);
      winPoints(s, 0, 4);
      expect(s.sets.length, 2, reason: 'points after the match are ignored');
    });

    test('match tiebreak replaces the deciding set', () {
      final s = TennisScorer(const MatchFormat(finalSet: FinalSet.matchTiebreak));
      winGames(s, 0, 6);
      winGames(s, 1, 6);
      expect(s.inTiebreak, isTrue);
      expect(s.isMatchTiebreak, isTrue);
      winPoints(s, 0, 9);
      winPoints(s, 1, 9);
      expect(s.winner, isNull);
      winPoints(s, 1, 2);
      expect(s.winner, 1);
      expect(s.sets.last.label(side: 1), '[11-9]');
    });

    test('advantage final set has no tiebreak', () {
      final s = TennisScorer(const MatchFormat(finalSet: FinalSet.advantage));
      winGames(s, 0, 6);
      winGames(s, 1, 6);
      for (var i = 0; i < 6; i++) {
        winGames(s, 0, 1);
        winGames(s, 1, 1);
      }
      expect(s.inTiebreak, isFalse);
      winGames(s, 0, 2);
      expect(s.winner, 0);
      expect(s.sets.last, const SetScore(8, 6));
    });

    test('short sets go to 4 with a tiebreak at 4-4', () {
      final s = TennisScorer(const MatchFormat(gamesPerSet: 4, bestOf: 1));
      for (var i = 0; i < 4; i++) {
        winGames(s, 0, 1);
        winGames(s, 1, 1);
      }
      expect(s.inTiebreak, isTrue);
      winPoints(s, 0, 7);
      expect(s.winner, 0);
      expect(s.sets.single.label(), '5-4(0)');
    });
  });

  group('situations and stats', () {
    test('break point, set point and match point', () {
      final s = TennisScorer(const MatchFormat(bestOf: 1));
      // A serves first; B gets to 0-40.
      winPoints(s, 1, 3);
      expect(s.situation, 'Break point');
      winPoints(s, 1, 1);
      expect(s.stats[1].breakPointChances, 1);
      expect(s.stats[1].breakPointsWon, 1);
      winGames(s, 1, 4); // 0-5
      winPoints(s, 1, 3);
      expect(s.situation, 'Match point');
    });

    test('change of ends after odd games', () {
      final s = TennisScorer(const MatchFormat());
      winPoints(s, 0, 3);
      final o = s.play(const PointEvent.to(0));
      expect(o.changeEnds, isTrue);
      winPoints(s, 0, 3);
      expect(s.play(const PointEvent.to(0)).changeEnds, isFalse);
    });

    test('replay reproduces the same state (undo)', () {
      const format = MatchFormat();
      final events = [for (var i = 0; i < 37; i++) PointEvent.to(i % 3 == 0 ? 1 : 0)];
      final full = TennisScorer.replay(format, 0, events);
      final undone = TennisScorer.replay(format, 0, events.take(36));
      undone.play(events.last);
      expect(undone.games, full.games);
      expect(undone.points, full.points);
      expect(undone.sets, full.sets);
      expect(undone.stats[0].pointsWon, full.stats[0].pointsWon);
    });
  });

  group('score parsing', () {
    test('parses sets, tiebreaks and match tiebreaks', () {
      final sets = parseSetScores('6-4, 6-7(5) [10-8]')!;
      expect(sets.length, 3);
      expect(sets[0], const SetScore(6, 4));
      expect(sets[1].label(), '6-7(5)');
      expect(sets[1].winner, 1);
      expect(sets[2].matchTiebreak, isTrue);
      expect(winnerFromSets(sets), 0);
    });

    test('rejects nonsense', () {
      expect(parseSetScores(''), isNull);
      expect(parseSetScores('6-6'), isNull);
      expect(parseSetScores('six-four'), isNull);
    });
  });
}
