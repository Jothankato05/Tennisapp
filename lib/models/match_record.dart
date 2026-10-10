import '../scoring/match_format.dart';
import '../scoring/set_score.dart';
import '../scoring/tennis_scorer.dart';

/// Someone on court. Club members carry a [playerId]; guests only a name.
class Participant {
  const Participant({this.playerId, required this.name});

  final String? playerId;
  final String name;

  Map<String, dynamic> toJson() => {if (playerId != null) 'id': playerId, 'name': name};

  factory Participant.fromJson(Map<String, dynamic> json) =>
      Participant(playerId: json['id'] as String?, name: json['name'] as String? ?? 'Player');
}

enum MatchSource { live, manual }

class MatchRecord {
  const MatchRecord({
    required this.id,
    required this.playedAt,
    required this.format,
    required this.sideA,
    required this.sideB,
    required this.sets,
    required this.winnerSide,
    this.completed = true,
    this.stats,
    this.durationMinutes,
    this.notes = '',
    this.source = MatchSource.manual,
    this.tournamentId,
  });

  final String id;
  final DateTime playedAt;
  final MatchFormat format;
  final List<Participant> sideA;
  final List<Participant> sideB;
  final List<SetScore> sets;

  /// 0 = side A, 1 = side B, null = no result (abandoned).
  final int? winnerSide;

  /// False when the match ended early (retirement or abandoned).
  final bool completed;
  final List<SideStats>? stats;
  final int? durationMinutes;
  final String notes;
  final MatchSource source;
  final String? tournamentId;

  List<Participant> side(int s) => s == 0 ? sideA : sideB;

  String sideName(int s) => side(s).map((p) => p.name).join(' / ');

  bool get isDoubles => sideA.length > 1 || sideB.length > 1;

  /// Index of the side containing [playerId], or null.
  int? sideOf(String playerId) {
    if (sideA.any((p) => p.playerId == playerId)) return 0;
    if (sideB.any((p) => p.playerId == playerId)) return 1;
    return null;
  }

  bool involves(String playerId) => sideOf(playerId) != null;

  /// Singles results between two club members count towards the ladder.
  bool get isRanked =>
      !isDoubles &&
      winnerSide != null &&
      sideA.length == 1 &&
      sideB.length == 1 &&
      sideA.first.playerId != null &&
      sideB.first.playerId != null;

  String scoreFor(int side) => scoreLine(sets, side: side);

  Map<String, dynamic> toJson() => {
    'id': id,
    'playedAt': playedAt.toIso8601String(),
    'format': format.toJson(),
    'sideA': sideA.map((p) => p.toJson()).toList(),
    'sideB': sideB.map((p) => p.toJson()).toList(),
    'sets': sets.map((s) => s.toJson()).toList(),
    'winner': winnerSide,
    'completed': completed,
    if (stats != null) 'stats': stats!.map((s) => s.toJson()).toList(),
    if (durationMinutes != null) 'duration': durationMinutes,
    'notes': notes,
    'source': source.name,
    if (tournamentId != null) 'tournamentId': tournamentId,
  };

  factory MatchRecord.fromJson(Map<String, dynamic> json) => MatchRecord(
    id: json['id'] as String,
    playedAt: DateTime.parse(json['playedAt'] as String),
    format: MatchFormat.fromJson((json['format'] as Map).cast<String, dynamic>()),
    sideA: _participants(json['sideA']),
    sideB: _participants(json['sideB']),
    sets: (json['sets'] as List).map((s) => SetScore.fromJson((s as Map).cast<String, dynamic>())).toList(),
    winnerSide: json['winner'] as int?,
    completed: json['completed'] as bool? ?? true,
    stats: (json['stats'] as List?)?.map((s) => SideStats.fromJson((s as Map).cast<String, dynamic>())).toList(),
    durationMinutes: json['duration'] as int?,
    notes: json['notes'] as String? ?? '',
    source: MatchSource.values.asNameMap()[json['source']] ?? MatchSource.manual,
    tournamentId: json['tournamentId'] as String?,
  );

  static List<Participant> _participants(Object? raw) =>
      (raw as List).map((p) => Participant.fromJson((p as Map).cast<String, dynamic>())).toList();
}
