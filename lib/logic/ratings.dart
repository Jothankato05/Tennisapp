import 'dart:math' as math;

import '../models/match_record.dart';

const startingRating = 1200;
const kFactor = 32;

double expectedScore(num rating, num opponent) => 1 / (1 + math.pow(10, (opponent - rating) / 400));

/// Points the winner gains (and the loser drops) for one result.
int ratingDelta(int winnerRating, int loserRating) =>
    math.max(1, (kFactor * (1 - expectedScore(winnerRating, loserRating))).round());

class RatingPoint {
  const RatingPoint(this.date, this.rating);
  final DateTime date;
  final int rating;
}

class RatingInfo {
  RatingInfo(this.playerId);

  final String playerId;
  int rating = startingRating;
  int wins = 0;
  int losses = 0;
  final List<RatingPoint> history = [];

  int get played => wins + losses;
}

/// Replays every ranked singles result in date order to produce Elo ratings.
Map<String, RatingInfo> computeRatings(Iterable<MatchRecord> matches) {
  final ranked = matches.where((m) => m.isRanked).toList()..sort((a, b) => a.playedAt.compareTo(b.playedAt));
  final table = <String, RatingInfo>{};
  for (final m in ranked) {
    final winner = m.side(m.winnerSide!).first.playerId!;
    final loser = m.side(1 - m.winnerSide!).first.playerId!;
    if (winner == loser) continue;
    final w = table.putIfAbsent(winner, () => RatingInfo(winner));
    final l = table.putIfAbsent(loser, () => RatingInfo(loser));
    final delta = ratingDelta(w.rating, l.rating);
    w.rating += delta;
    w.wins += 1;
    w.history.add(RatingPoint(m.playedAt, w.rating));
    l.rating -= delta;
    l.losses += 1;
    l.history.add(RatingPoint(m.playedAt, l.rating));
  }
  return table;
}
