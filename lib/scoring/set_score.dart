/// The final score of one completed set, from side A's (index 0) point of view.
class SetScore {
  const SetScore(this.a, this.b, {this.tiebreakA, this.tiebreakB, this.matchTiebreak = false});

  final int a;
  final int b;

  /// Tiebreak points, when the set was decided by a tiebreak.
  final int? tiebreakA;
  final int? tiebreakB;

  /// True when this "set" was a 10-point match tiebreak.
  final bool matchTiebreak;

  int gamesFor(int side) => side == 0 ? a : b;

  int get winner {
    if (matchTiebreak) return (tiebreakA ?? 0) > (tiebreakB ?? 0) ? 0 : 1;
    return a > b ? 0 : 1;
  }

  bool get hasTiebreak => tiebreakA != null && tiebreakB != null;

  /// e.g. "6-4", "7-6(5)" or "[10-8]", always listed from [side]'s perspective.
  String label({int side = 0}) {
    if (matchTiebreak) {
      final mine = side == 0 ? tiebreakA : tiebreakB;
      final theirs = side == 0 ? tiebreakB : tiebreakA;
      return '[$mine-$theirs]';
    }
    final base = '${gamesFor(side)}-${gamesFor(1 - side)}';
    if (!hasTiebreak) return base;
    final loserPoints = tiebreakA! < tiebreakB! ? tiebreakA : tiebreakB;
    return '$base($loserPoints)';
  }

  Map<String, dynamic> toJson() => {
    'a': a,
    'b': b,
    if (tiebreakA != null) 'tbA': tiebreakA,
    if (tiebreakB != null) 'tbB': tiebreakB,
    if (matchTiebreak) 'mtb': true,
  };

  factory SetScore.fromJson(Map<String, dynamic> json) => SetScore(
    json['a'] as int,
    json['b'] as int,
    tiebreakA: json['tbA'] as int?,
    tiebreakB: json['tbB'] as int?,
    matchTiebreak: json['mtb'] as bool? ?? false,
  );

  @override
  bool operator ==(Object other) =>
      other is SetScore &&
      other.a == a &&
      other.b == b &&
      other.tiebreakA == tiebreakA &&
      other.tiebreakB == tiebreakB &&
      other.matchTiebreak == matchTiebreak;

  @override
  int get hashCode => Object.hash(a, b, tiebreakA, tiebreakB, matchTiebreak);

  @override
  String toString() => label();
}

/// Parses scores typed by players such as "6-4 3-6 7-6(5) [10-8]".
/// Returns null if any part is not a valid set score.
List<SetScore>? parseSetScores(String input) {
  final tokens = input.trim().split(RegExp(r'[\s,;]+')).where((t) => t.isNotEmpty).toList();
  if (tokens.isEmpty || tokens.length > 5) return null;
  final setRe = RegExp(r'^(\d{1,2})-(\d{1,2})(?:\((\d{1,2})\))?$');
  final mtbRe = RegExp(r'^\[(\d{1,2})-(\d{1,2})\]$');
  final sets = <SetScore>[];
  for (final token in tokens) {
    final m = mtbRe.firstMatch(token);
    if (m != null) {
      final a = int.parse(m[1]!), b = int.parse(m[2]!);
      if (a == b) return null;
      sets.add(SetScore(a > b ? 1 : 0, b > a ? 1 : 0, tiebreakA: a, tiebreakB: b, matchTiebreak: true));
      continue;
    }
    final s = setRe.firstMatch(token);
    if (s == null) return null;
    final a = int.parse(s[1]!), b = int.parse(s[2]!);
    if (a == b) return null;
    if (s[3] != null) {
      final loser = int.parse(s[3]!);
      final winner = loser < 6 ? 7 : loser + 2;
      sets.add(SetScore(a, b, tiebreakA: a > b ? winner : loser, tiebreakB: a > b ? loser : winner));
    } else {
      sets.add(SetScore(a, b));
    }
  }
  return sets;
}

/// Which side won more sets, or null if level.
int? winnerFromSets(List<SetScore> sets) {
  final a = sets.where((s) => s.winner == 0).length;
  final b = sets.length - a;
  if (a == b) return null;
  return a > b ? 0 : 1;
}

String scoreLine(List<SetScore> sets, {int side = 0}) => sets.map((s) => s.label(side: side)).join('  ');
