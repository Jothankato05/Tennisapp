import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../logic/bracket.dart';
import 'club_api.dart';
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
  static const syncKey = 'veritas_tennis_sync_v1';
  static const schemaVersion = 1;

  final SharedPreferences _prefs;

  final List<Player> players = [];
  final List<MatchRecord> matches = [];
  final List<Tournament> tournaments = [];
  final List<PracticeSession> sessions = [];
  String? meId;
  LiveMatch? liveMatch;

  Map<String, RatingInfo>? _ratings;

  // ---- Club sync state ----------------------------------------------------------

  /// The club this phone syncs with, if any.
  ClubInfo? club;

  /// Server timestamp of the newest club change already applied here.
  String? syncCursor;
  DateTime? lastSyncAt;

  /// Records changed on this phone and not yet sent to the club, as
  /// "kind/id" → change counter (so edits made during a push are not lost).
  final Map<String, int> _pending = {};
  int _changeCounter = 0;

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
    final sync = prefs.getString(syncKey);
    if (sync != null) {
      try {
        store._applySync(jsonDecode(sync) as Map<String, dynamic>);
      } catch (e) {
        debugPrint('Could not read sync state: $e');
      }
    }
    return store;
  }

  void _applySync(Map<String, dynamic> json) {
    club = json['club'] == null ? null : ClubInfo.fromJson((json['club'] as Map).cast<String, dynamic>());
    syncCursor = json['cursor'] as String?;
    lastSyncAt = DateTime.tryParse(json['lastSyncAt'] as String? ?? '');
    _pending
      ..clear()
      ..addAll((json['pending'] as Map? ?? const {}).cast<String, int>());
    _changeCounter = _pending.values.fold(0, (a, b) => a > b ? a : b);
  }

  Map<String, dynamic> _syncJson() => {
    'club': club?.toJson(),
    'cursor': syncCursor,
    'lastSyncAt': lastSyncAt?.toIso8601String(),
    'pending': _pending,
  };

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

  Future<void> _save() async {
    await _prefs.setString(storageKey, jsonEncode(toJson()));
    await _prefs.setString(syncKey, jsonEncode(_syncJson()));
  }

  void _changed() {
    _ratings = null;
    _sort();
    notifyListeners();
    _save();
  }

  /// Call after mutating the live match in place.
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
    if (club != null) _markAllPending();
    _changed();
  }

  Future<void> resetAll() async {
    players.clear();
    matches.clear();
    tournaments.clear();
    sessions.clear();
    meId = null;
    liveMatch = null;
    club = null;
    syncCursor = null;
    lastSyncAt = null;
    _pending.clear();
    _changed();
  }

  // ---- Club sync ----------------------------------------------------------------

  static const syncedKinds = ['player', 'match', 'tournament'];

  void _markPending(String kind, String id) {
    if (club == null) return;
    _pending['$kind/$id'] = ++_changeCounter;
  }

  void _markAllPending() {
    for (final p in players) {
      _markPending('player', p.id);
    }
    for (final m in matches) {
      _markPending('match', m.id);
    }
    for (final t in tournaments) {
      _markPending('tournament', t.id);
    }
  }

  int get pendingChanges => _pending.length;

  /// Changes waiting to be sent: key → (record, change counter). A null
  /// record means it was deleted on this phone.
  List<({String key, int counter, OutgoingRecord record})> pendingRecords() {
    final out = <({String key, int counter, OutgoingRecord record})>[];
    for (final e in _pending.entries) {
      final slash = e.key.indexOf('/');
      final kind = e.key.substring(0, slash), id = e.key.substring(slash + 1);
      final Map<String, dynamic>? data = switch (kind) {
        'player' => playerById(id)?.toJson(),
        'match' => matchById(id)?.toJson(),
        'tournament' => tournamentById(id)?.toJson(),
        _ => null,
      };
      out.add((key: e.key, counter: e.value, record: OutgoingRecord(kind: kind, id: id, data: data)));
    }
    return out;
  }

  /// Forgets pending changes that were sent, unless they changed again since.
  void markSent(Iterable<({String key, int counter})> sent) {
    for (final s in sent) {
      if (_pending[s.key] == s.counter) _pending.remove(s.key);
    }
    _save();
  }

  void recordSync({String? cursor}) {
    if (cursor != null) syncCursor = cursor;
    lastSyncAt = DateTime.now();
    notifyListeners();
    _save();
  }

  /// Applies changes made on other phones. Local changes not yet sent win.
  void applyRemote(Iterable<RemoteRecord> records) {
    var changed = false;
    for (final r in records) {
      if (_pending.containsKey(r.key)) continue;
      try {
        changed |= _applyRemoteRecord(r);
      } catch (e) {
        debugPrint('Skipped unreadable club record ${r.key}: $e');
      }
    }
    if (changed) {
      _ratings = null;
      _sort();
      notifyListeners();
      _save();
    }
  }

  bool _applyRemoteRecord(RemoteRecord r) {
    final data = r.data;
    final removed = r.deleted || data == null;
    switch (r.kind) {
      case 'player':
        if (removed) {
          if (r.id == meId) {
            _markPending('player', r.id); // Never lose your own profile; send it back.
            return false;
          }
          final before = players.length;
          players.removeWhere((p) => p.id == r.id);
          return players.length != before;
        }
        final player = Player.fromJson(data);
        players.removeWhere((p) => p.id == r.id);
        players.add(player);
        return true;
      case 'match':
        final before = matches.length;
        matches.removeWhere((m) => m.id == r.id);
        if (!removed) matches.add(MatchRecord.fromJson(data));
        return !removed || matches.length != before;
      case 'tournament':
        final before = tournaments.length;
        tournaments.removeWhere((t) => t.id == r.id);
        if (!removed) tournaments.add(Tournament.fromJson(data));
        return !removed || tournaments.length != before;
    }
    return false;
  }

  /// Starts syncing with [info]. [remote] is the club's current data: local
  /// players with the same name as a club player are merged into them, then
  /// everything else on this phone is queued to be shared with the club.
  void joinClub(ClubInfo info, List<RemoteRecord> remote, {String? cursor}) {
    final clubPlayers = <String, String>{}; // normalised name → id
    for (final r in remote) {
      if (r.kind == 'player' && !r.deleted && r.data?['name'] is String) {
        clubPlayers.putIfAbsent(_normalise(r.data!['name'] as String), () => r.id);
      }
    }
    club = info;
    syncCursor = cursor;
    _pending.clear();
    for (final p in [...players]) {
      final clubId = clubPlayers[_normalise(p.name)];
      if (clubId != null && clubId != p.id) _replacePlayerId(p.id, clubId, p.name);
    }
    _markAllPending();
    // Players merged into club players keep the club's version.
    for (final id in clubPlayers.values) {
      _pending.remove('player/$id');
    }
    _ratings = null;
    applyRemote(remote);
    _changed();
  }

  void leaveClub() {
    club = null;
    syncCursor = null;
    lastSyncAt = null;
    _pending.clear();
    _changed();
  }

  static String _normalise(String name) => name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  /// Treats [fromId] as the same person as [intoId]: their matches and
  /// tournament places move over and the duplicate is removed.
  void mergePlayers(String fromId, String intoId) {
    if (fromId == intoId) return;
    final into = playerById(intoId);
    if (into == null) return;
    _replacePlayerId(fromId, intoId, into.name);
    _changed();
  }

  void _replacePlayerId(String fromId, String toId, String toName) {
    for (var i = 0; i < matches.length; i++) {
      if (matches[i].involves(fromId)) {
        matches[i] = matches[i].withPlayerId(fromId, toId, toName);
        _markPending('match', matches[i].id);
      }
    }
    for (final t in tournaments) {
      if (t.playerIds.contains(fromId) && t.replacePlayer(fromId, toId)) _markPending('tournament', t.id);
    }
    if (meId == fromId) meId = toId;
    final live = liveMatch;
    if (live != null && [...live.sideA, ...live.sideB].any((p) => p.playerId == fromId)) {
      liveMatch = LiveMatch(
        id: live.id,
        format: live.format,
        sideA: [for (final p in live.sideA) p.playerId == fromId ? Participant(playerId: toId, name: toName) : p],
        sideB: [for (final p in live.sideB) p.playerId == fromId ? Participant(playerId: toId, name: toName) : p],
        firstServerSide: live.firstServerSide,
        startedAt: live.startedAt,
        events: live.events,
        tournamentId: live.tournamentId,
        fixtureId: live.fixtureId,
      );
    }
    players.removeWhere((p) => p.id == fromId);
    _markPending('player', fromId);
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
    _markPending('player', player.id);
    _changed();
  }

  void savePlayer(Player player) {
    final i = players.indexWhere((p) => p.id == player.id);
    if (i >= 0) {
      players[i] = player;
    } else {
      players.add(player);
    }
    _markPending('player', player.id);
    _changed();
  }

  /// Removes a player. Their past matches stay in history under their name.
  void deletePlayer(String id) {
    if (id == meId) return;
    players.removeWhere((p) => p.id == id);
    _markPending('player', id);
    _changed();
  }

  bool playerInTournament(String id) => tournaments.any((t) => t.playerIds.contains(id));

  // ---- Matches ----------------------------------------------------------------

  void addMatch(MatchRecord match) {
    matches.add(match);
    _markPending('match', match.id);
    _changed();
  }

  void deleteMatch(String id) {
    matches.removeWhere((m) => m.id == id);
    _markPending('match', id);
    for (final t in tournaments) {
      for (final f in t.fixtures) {
        if (f.matchId == id) {
          f.matchId = null;
          _markPending('tournament', t.id);
        }
      }
    }
    _changed();
  }

  /// A saved match that looks like the same result as [match], if any.
  MatchRecord? findDuplicate(MatchRecord match) {
    for (final m in matches) {
      if (m.id != match.id && m.sameResultAs(match)) return m;
    }
    return null;
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
    _markPending('tournament', t.id);
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
    _markPending('tournament', t.id);
    _changed();
  }

  /// Call after editing a tournament's details in place (e.g. renaming it).
  void updateTournament(Tournament t) {
    _markPending('tournament', t.id);
    _changed();
  }

  void deleteTournament(String id) {
    tournaments.removeWhere((t) => t.id == id);
    _markPending('tournament', id);
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
