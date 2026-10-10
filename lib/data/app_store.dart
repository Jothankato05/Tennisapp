import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../logic/bracket.dart';
import '../logic/ratings.dart';
import '../logic/stats.dart';
import '../models/live_match.dart';
import '../models/match_record.dart';
import '../models/player.dart';
import '../models/practice_session.dart';
import '../models/tournament.dart';

class LadderEntry {
  const LadderEntry(this.rank, this.player, this.info);
  final int rank;
  final Player player;
  final RatingInfo info;
}

/// All app data, kept on the device and saved after every change.
class AppStore extends ChangeNotifier {
  AppStore(this._prefs);

  static const storageKey = 'veritas_tennis_v1';
  static const schemaVersion = 1;

  final SharedPreferences _prefs;

  final List<Player> players = [];
  final List<MatchRecord> matches = [];
  final List<Tournament> tournaments = [];
  final List<PracticeSession> sessions = [];
  String? meId;
  LiveMatch? liveMatch;

  Map<String, RatingInfo>? _ratings;

  static Future<AppStore> load(SharedPreferences prefs) async {
    final store = AppStore(prefs);
    final raw = prefs.getString(storageKey);
    if (raw != null) {
      try {
        store._apply(jsonDecode(raw) as Map<String, dynamic>);
      } catch (e) {
        debugPrint('Could not read saved data: $e');
      }
    }
    return store;
  }

  // ---- Persistence ------------------------------------------------------------

  Map<String, dynamic> toJson() => {
    'version': schemaVersion,
    'meId': meId,
    'players': players.map((p) => p.toJson()).toList(),
    'matches': matches.map((m) => m.toJson()).toList(),
    'tournaments': tournaments.map((t) => t.toJson()).toList(),
    'sessions': sessions.map((s) => s.toJson()).toList(),
    if (liveMatch != null) 'liveMatch': liveMatch!.toJson(),
  };

  void _apply(Map<String, dynamic> json) {
    List<T> list<T>(String key, T Function(Map<String, dynamic>) parse) =>
        (json[key] as List? ?? const []).map((e) => parse((e as Map).cast<String, dynamic>())).toList();

    final newPlayers = list('players', Player.fromJson);
    final newMatches = list('matches', MatchRecord.fromJson);
    final newTournaments = list('tournaments', Tournament.fromJson);
    final newSessions = list('sessions', PracticeSession.fromJson);
    final live = json['liveMatch'] == null
        ? null
        : LiveMatch.fromJson((json['liveMatch'] as Map).cast<String, dynamic>());

    players
      ..clear()
      ..addAll(newPlayers);
    matches
      ..clear()
      ..addAll(newMatches);
    tournaments
      ..clear()
      ..addAll(newTournaments);
    sessions
      ..clear()
      ..addAll(newSessions);
    meId = json['meId'] as String?;
    liveMatch = live;
    _sort();
    _ratings = null;
  }

  void _sort() {
    matches.sort((a, b) => b.playedAt.compareTo(a.playedAt));
    sessions.sort((a, b) => b.date.compareTo(a.date));
    tournaments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    players.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  Future<void> _save() => _prefs.setString(storageKey, jsonEncode(toJson()));

  void _changed() {
    _ratings = null;
    _sort();
    notifyListeners();
    _save();
  }

  /// Call after mutating a tournament or the live match in place.
  void touch() => _changed();

  String exportJson() => const JsonEncoder.withIndent('  ').convert(toJson());

  /// Replaces all data with a previously exported backup. Throws [FormatException] if invalid.
  void importJson(String raw) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      throw const FormatException('That is not a valid Veritas Tennis backup.');
    }
    if (decoded is! Map<String, dynamic> || decoded['players'] is! List) {
      throw const FormatException('That is not a valid Veritas Tennis backup.');
    }
    try {
      _apply(decoded);
    } catch (_) {
      throw const FormatException('The backup is damaged and could not be imported.');
    }
    _changed();
  }

  Future<void> resetAll() async {
    players.clear();
    matches.clear();
    tournaments.clear();
    sessions.clear();
    meId = null;
    liveMatch = null;
    _changed();
  }

  // ---- Players ----------------------------------------------------------------

  Player? get me => meId == null ? null : playerById(meId!);

  Player? playerById(String id) {
    for (final p in players) {
      if (p.id == id) return p;
    }
    return null;
  }

  String nameOf(String? id) => id == null ? 'TBD' : (playerById(id)?.name ?? 'Former player');

  void setMe(Player player) {
    if (playerById(player.id) == null) players.add(player);
    meId = player.id;
    _changed();
  }

  void savePlayer(Player player) {
    final i = players.indexWhere((p) => p.id == player.id);
    if (i >= 0) {
      players[i] = player;
    } else {
      players.add(player);
    }
    _changed();
  }

  /// Removes a player. Their past matches stay in history under their name.
  void deletePlayer(String id) {
    if (id == meId) return;
    players.removeWhere((p) => p.id == id);
    _changed();
  }

  bool playerInTournament(String id) => tournaments.any((t) => t.playerIds.contains(id));

  // ---- Matches ----------------------------------------------------------------

  void addMatch(MatchRecord match) {
    matches.add(match);
    _changed();
  }

  void deleteMatch(String id) {
    matches.removeWhere((m) => m.id == id);
    for (final t in tournaments) {
      for (final f in t.fixtures) {
        if (f.matchId == id) f.matchId = null;
      }
    }
    _changed();
  }

  MatchRecord? matchById(String id) {
    for (final m in matches) {
      if (m.id == id) return m;
    }
    return null;
  }

  List<MatchRecord> matchesFor(String playerId) => matches.where((m) => m.involves(playerId)).toList();

  PlayerStats statsOf(String playerId) => statsFor(playerId, matches);

  // ---- Ladder -----------------------------------------------------------------

  Map<String, RatingInfo> get ratings => _ratings ??= computeRatings(matches);

  int ratingOf(String playerId) => ratings[playerId]?.rating ?? startingRating;

  List<LadderEntry> get ladder {
    final entries = <({Player player, RatingInfo info})>[];
    for (final p in players) {
      final info = ratings[p.id];
      if (info != null && info.played > 0) entries.add((player: p, info: info));
    }
    entries.sort((a, b) {
      final c = b.info.rating.compareTo(a.info.rating);
      return c != 0 ? c : b.info.wins.compareTo(a.info.wins);
    });
    return [for (var i = 0; i < entries.length; i++) LadderEntry(i + 1, entries[i].player, entries[i].info)];
  }

  int? rankOf(String playerId) {
    for (final e in ladder) {
      if (e.player.id == playerId) return e.rank;
    }
    return null;
  }

  // ---- Tournaments ------------------------------------------------------------

  Tournament createTournament({
    required String id,
    required String name,
    required TournamentType type,
    required List<String> playerIds,
    required bool seedByRating,
  }) {
    final ordered = [...playerIds];
    if (seedByRating) {
      ordered.sort((a, b) => ratingOf(b).compareTo(ratingOf(a)));
    } else {
      ordered.shuffle();
    }
    final t = Tournament(
      id: id,
      name: name,
      type: type,
      playerIds: ordered,
      rounds: type == TournamentType.knockout ? createKnockout(ordered) : createRoundRobin(ordered),
      createdAt: DateTime.now(),
    );
    tournaments.add(t);
    _changed();
    return t;
  }

  Tournament? tournamentById(String id) {
    for (final t in tournaments) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// Records (or clears, when [winnerId] is null) a fixture result.
  void setFixtureResult(Tournament t, Fixture f, {String? winnerId, String score = '', String? matchId}) {
    f
      ..winner = winnerId
      ..score = winnerId == null ? '' : score
      ..matchId = winnerId == null ? null : matchId;
    if (t.type == TournamentType.knockout) propagateKnockout(t.rounds);
    _changed();
  }

  void deleteTournament(String id) {
    tournaments.removeWhere((t) => t.id == id);
    _changed();
  }

  // ---- Practice ---------------------------------------------------------------

  void savePractice(PracticeSession session) {
    sessions.removeWhere((s) => s.id == session.id);
    sessions.add(session);
    _changed();
  }

  void deletePractice(String id) {
    sessions.removeWhere((s) => s.id == id);
    _changed();
  }

  /// Minutes practised in the 7 days ending today.
  int practiceMinutesThisWeek([DateTime? now]) {
    final today = _day(now ?? DateTime.now());
    final from = today.subtract(const Duration(days: 6));
    return sessions.where((s) => !_day(s.date).isBefore(from)).fold(0, (sum, s) => sum + s.minutes);
  }

  /// Consecutive days (ending today or yesterday) with at least one practice or match.
  int activeDayStreak([DateTime? now]) {
    final days = <DateTime>{
      for (final s in sessions) _day(s.date),
      if (meId != null)
        for (final m in matches.where((m) => m.involves(meId!))) _day(m.playedAt),
    };
    var day = _day(now ?? DateTime.now());
    if (!days.contains(day)) day = day.subtract(const Duration(days: 1));
    var streak = 0;
    while (days.contains(day)) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  // ---- Live scoring -----------------------------------------------------------

  void startLive(LiveMatch match) {
    liveMatch = match;
    _changed();
  }

  void clearLive() {
    liveMatch = null;
    _changed();
  }

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
}
