enum TournamentType {
  knockout('Knockout'),
  roundRobin('Round robin');

  const TournamentType(this.label);
  final String label;
}

/// A fixture inside a tournament. [a]/[b] are player ids; null means a bye
/// (knockout) or a slot still waiting for the previous round's winner.
class Fixture {
  Fixture({required this.id, this.a, this.b, this.winner, this.score = '', this.matchId});

  final String id;
  String? a;
  String? b;
  String? winner;
  String score;

  /// The MatchRecord this result came from, if it was scored in the app.
  String? matchId;

  bool get isPlayed => winner != null;
  bool get isReady => a != null && b != null;

  String? get loser => winner == null ? null : (winner == a ? b : a);

  Fixture copy() => Fixture(id: id, a: a, b: b, winner: winner, score: score, matchId: matchId);

  Map<String, dynamic> toJson() => {'id': id, 'a': a, 'b': b, 'winner': winner, 'score': score, 'matchId': matchId};

  factory Fixture.fromJson(Map<String, dynamic> json) => Fixture(
    id: json['id'] as String,
    a: json['a'] as String?,
    b: json['b'] as String?,
    winner: json['winner'] as String?,
    score: json['score'] as String? ?? '',
    matchId: json['matchId'] as String?,
  );
}

class Tournament {
  Tournament({
    required this.id,
    required this.name,
    required this.type,
    required this.playerIds,
    required this.rounds,
    required this.createdAt,
    this.venue = 'Veritas University Tennis Court',
  });

  final String id;
  String name;
  final TournamentType type;
  final List<String> playerIds;

  /// Knockout: one list per round (first round first).
  /// Round robin: one list per "matchday".
  final List<List<Fixture>> rounds;
  final DateTime createdAt;
  String venue;

  Iterable<Fixture> get fixtures => rounds.expand((r) => r);

  /// Real matches (byes excluded) that have a result.
  int get playedCount => fixtures.where((f) => f.isPlayed && f.isReady).length;

  /// Real matches whose two players are known.
  int get readyCount => fixtures.where((f) => f.isReady).length;

  /// Replaces a player id everywhere in the draw. Returns true if anything changed.
  bool replacePlayer(String from, String to) {
    var changed = false;
    for (var i = 0; i < playerIds.length; i++) {
      if (playerIds[i] == from) {
        playerIds[i] = to;
        changed = true;
      }
    }
    for (final f in fixtures) {
      if (f.a == from) f.a = to;
      if (f.b == from) f.b = to;
      if (f.winner == from) f.winner = to;
      changed |= f.a == to || f.b == to;
    }
    return changed;
  }

  Fixture? fixtureById(String fixtureId) {
    for (final f in fixtures) {
      if (f.id == fixtureId) return f;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'players': playerIds,
    'rounds': rounds.map((r) => r.map((f) => f.toJson()).toList()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'venue': venue,
  };

  factory Tournament.fromJson(Map<String, dynamic> json) => Tournament(
    id: json['id'] as String,
    name: json['name'] as String,
    type: TournamentType.values.asNameMap()[json['type']] ?? TournamentType.knockout,
    playerIds: (json['players'] as List).cast<String>(),
    rounds: (json['rounds'] as List)
        .map((r) => (r as List).map((f) => Fixture.fromJson((f as Map).cast<String, dynamic>())).toList())
        .toList(),
    createdAt: DateTime.parse(json['createdAt'] as String),
    venue: json['venue'] as String? ?? 'Veritas University Tennis Court',
  );
}
