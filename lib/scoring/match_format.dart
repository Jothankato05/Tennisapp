/// How the deciding set is played when the match reaches it.
enum FinalSet {
  /// A normal set with a 7-point tiebreak at 6-6.
  tiebreak,

  /// A 10-point match tiebreak replaces the deciding set.
  matchTiebreak,

  /// A normal set with no tiebreak: play on until someone leads by two games.
  advantage,
}

class MatchFormat {
  const MatchFormat({
    this.bestOf = 3,
    this.gamesPerSet = 6,
    this.noAd = false,
    this.finalSet = FinalSet.tiebreak,
    this.doubles = false,
  }) : assert(bestOf == 1 || bestOf == 3 || bestOf == 5),
       assert(gamesPerSet == 4 || gamesPerSet == 6);

  final int bestOf;
  final int gamesPerSet;
  final bool noAd;
  final FinalSet finalSet;
  final bool doubles;

  int get setsToWin => bestOf ~/ 2 + 1;

  MatchFormat copyWith({int? bestOf, int? gamesPerSet, bool? noAd, FinalSet? finalSet, bool? doubles}) {
    return MatchFormat(
      bestOf: bestOf ?? this.bestOf,
      gamesPerSet: gamesPerSet ?? this.gamesPerSet,
      noAd: noAd ?? this.noAd,
      finalSet: finalSet ?? this.finalSet,
      doubles: doubles ?? this.doubles,
    );
  }

  String describe() {
    final parts = <String>[
      doubles ? 'Doubles' : 'Singles',
      bestOf == 1 ? 'One set' : 'Best of $bestOf sets',
      if (gamesPerSet == 4) 'Short sets (to 4)',
      if (noAd) 'No-ad',
      if (bestOf > 1 && finalSet == FinalSet.matchTiebreak) 'Match tiebreak decider',
      if (finalSet == FinalSet.advantage) 'Advantage final set',
    ];
    return parts.join(' · ');
  }

  Map<String, dynamic> toJson() => {
    'bestOf': bestOf,
    'gamesPerSet': gamesPerSet,
    'noAd': noAd,
    'finalSet': finalSet.name,
    'doubles': doubles,
  };

  factory MatchFormat.fromJson(Map<String, dynamic> json) => MatchFormat(
    bestOf: json['bestOf'] as int? ?? 3,
    gamesPerSet: json['gamesPerSet'] as int? ?? 6,
    noAd: json['noAd'] as bool? ?? false,
    finalSet: FinalSet.values.asNameMap()[json['finalSet']] ?? FinalSet.tiebreak,
    doubles: json['doubles'] as bool? ?? false,
  );

  @override
  bool operator ==(Object other) =>
      other is MatchFormat &&
      other.bestOf == bestOf &&
      other.gamesPerSet == gamesPerSet &&
      other.noAd == noAd &&
      other.finalSet == finalSet &&
      other.doubles == doubles;

  @override
  int get hashCode => Object.hash(bestOf, gamesPerSet, noAd, finalSet, doubles);
}
