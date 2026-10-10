import '../scoring/match_format.dart';
import '../scoring/tennis_scorer.dart';
import 'match_record.dart';

/// A match being scored point by point. Only the point log is stored; the
/// score is rebuilt by replaying it, which also makes undo trivial.
class LiveMatch {
  LiveMatch({
    required this.id,
    required this.format,
    required this.sideA,
    required this.sideB,
    required this.firstServerSide,
    required this.startedAt,
    List<PointEvent>? events,
    this.tournamentId,
    this.fixtureId,
  }) : events = events ?? [];

  final String id;
  final MatchFormat format;
  final List<Participant> sideA;
  final List<Participant> sideB;
  final int firstServerSide;
  final DateTime startedAt;
  final List<PointEvent> events;
  final String? tournamentId;
  final String? fixtureId;

  TennisScorer? _cache;

  TennisScorer get scorer => _cache ??= TennisScorer.replay(format, firstServerSide, events);

  List<Participant> side(int s) => s == 0 ? sideA : sideB;

  String sideName(int s) => side(s).map((p) => p.name).join(' / ');

  /// Name of whoever is serving right now.
  String get serverName {
    final team = side(scorer.servingSide);
    return team[scorer.servingPlayer.clamp(0, team.length - 1)].name;
  }

  PointOutcome play(PointEvent e) {
    if (scorer.isOver) return PointOutcome();
    events.add(e);
    return scorer.play(e);
  }

  bool get canUndo => events.isNotEmpty;

  void undo() {
    if (events.isEmpty) return;
    events.removeLast();
    _cache = null;
  }

  MatchRecord toRecord({required DateTime endedAt, int? winnerOverride, bool completed = true, String notes = ''}) {
    final s = scorer;
    return MatchRecord(
      id: id,
      playedAt: startedAt,
      format: format,
      sideA: sideA,
      sideB: sideB,
      sets: s.isOver ? List.of(s.sets) : s.setsIncludingCurrent(),
      winnerSide: s.winner ?? winnerOverride,
      completed: completed && s.isOver,
      stats: [s.stats[0].clone(), s.stats[1].clone()],
      durationMinutes: endedAt.difference(startedAt).inMinutes,
      notes: notes,
      source: MatchSource.live,
      tournamentId: tournamentId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'format': format.toJson(),
    'sideA': sideA.map((p) => p.toJson()).toList(),
    'sideB': sideB.map((p) => p.toJson()).toList(),
    'first': firstServerSide,
    'startedAt': startedAt.toIso8601String(),
    'events': events.map((e) => e.toJson()).toList(),
    'tournamentId': tournamentId,
    'fixtureId': fixtureId,
  };

  factory LiveMatch.fromJson(Map<String, dynamic> json) => LiveMatch(
    id: json['id'] as String,
    format: MatchFormat.fromJson((json['format'] as Map).cast<String, dynamic>()),
    sideA: (json['sideA'] as List).map((p) => Participant.fromJson((p as Map).cast<String, dynamic>())).toList(),
    sideB: (json['sideB'] as List).map((p) => Participant.fromJson((p as Map).cast<String, dynamic>())).toList(),
    firstServerSide: json['first'] as int? ?? 0,
    startedAt: DateTime.parse(json['startedAt'] as String),
    events: (json['events'] as List).map((e) => PointEvent.fromJson((e as Map).cast<String, dynamic>())).toList(),
    tournamentId: json['tournamentId'] as String?,
    fixtureId: json['fixtureId'] as String?,
  );
}
