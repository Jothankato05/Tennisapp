import 'match_format.dart';
import 'set_score.dart';

enum PointKind { rally, ace, doubleFault, winner, unforcedError }

/// One point as tapped by the scorer.
///
/// For [PointKind.rally] and [PointKind.winner], [side] won the point.
/// For [PointKind.unforcedError], [side] made the error (so the other side wins).
/// For aces and double faults [side] is ignored; the current server is used.
class PointEvent {
  const PointEvent(this.kind, [this.side = 0]);

  const PointEvent.to(int side) : this(PointKind.rally, side);

  final PointKind kind;
  final int side;

  Map<String, dynamic> toJson() => {'k': kind.index, 's': side};

  factory PointEvent.fromJson(Map<String, dynamic> json) =>
      PointEvent(PointKind.values[json['k'] as int], json['s'] as int? ?? 0);
}

class SideStats {
  int pointsWon = 0;
  int aces = 0;
  int doubleFaults = 0;
  int winners = 0;
  int unforcedErrors = 0;
  int servicePointsPlayed = 0;
  int servicePointsWon = 0;
  int breakPointChances = 0;
  int breakPointsWon = 0;

  SideStats();

  SideStats clone() => SideStats.fromJson(toJson());

  Map<String, dynamic> toJson() => {
    'pw': pointsWon,
    'ace': aces,
    'df': doubleFaults,
    'win': winners,
    'ue': unforcedErrors,
    'spp': servicePointsPlayed,
    'spw': servicePointsWon,
    'bpc': breakPointChances,
    'bpw': breakPointsWon,
  };

  factory SideStats.fromJson(Map<String, dynamic> json) => SideStats()
    ..pointsWon = json['pw'] as int? ?? 0
    ..aces = json['ace'] as int? ?? 0
    ..doubleFaults = json['df'] as int? ?? 0
    ..winners = json['win'] as int? ?? 0
    ..unforcedErrors = json['ue'] as int? ?? 0
    ..servicePointsPlayed = json['spp'] as int? ?? 0
    ..servicePointsWon = json['spw'] as int? ?? 0
    ..breakPointChances = json['bpc'] as int? ?? 0
    ..breakPointsWon = json['bpw'] as int? ?? 0;
}

/// What a single point changed, so the UI can announce it.
class PointOutcome {
  int? gameWonBy;
  int? setWonBy;
  int? matchWonBy;
  bool changeEnds = false;
  bool tiebreakStarted = false;
}

/// Pure tennis scoring state machine.
///
/// Sides are 0 (A) and 1 (B). The serve rotation has 2 slots in singles and
/// 4 in doubles ([A1, B1, A2, B2] relative to whoever serves first), so the
/// serving player alternates correctly inside each team.
class TennisScorer {
  TennisScorer(this.format, {this.firstServerSide = 0});

  final MatchFormat format;
  final int firstServerSide;

  final List<SetScore> sets = [];
  List<int> games = [0, 0];
  List<int> points = [0, 0];
  bool inTiebreak = false;
  int tiebreakTarget = 7;
  int _tiebreakStartSlot = 0;
  int _serverSlot = 0;
  int? winner;
  final List<SideStats> stats = [SideStats(), SideStats()];
  PointOutcome lastOutcome = PointOutcome();

  /// Builds the state reached after playing [events] from the start.
  factory TennisScorer.replay(MatchFormat format, int firstServerSide, Iterable<PointEvent> events) {
    final scorer = TennisScorer(format, firstServerSide: firstServerSide);
    for (final e in events) {
      scorer.play(e);
    }
    return scorer;
  }

  TennisScorer clone() {
    final c = TennisScorer(format, firstServerSide: firstServerSide)
      ..sets.addAll(sets)
      ..games = [...games]
      ..points = [...points]
      ..inTiebreak = inTiebreak
      ..tiebreakTarget = tiebreakTarget
      .._tiebreakStartSlot = _tiebreakStartSlot
      .._serverSlot = _serverSlot
      ..winner = winner;
    c.stats[0] = stats[0].clone();
    c.stats[1] = stats[1].clone();
    return c;
  }

  // ---- Serving --------------------------------------------------------------

  int get _rotation => format.doubles ? 4 : 2;

  int get _currentSlot {
    if (!inTiebreak) return _serverSlot;
    final n = points[0] + points[1];
    if (n == 0) return _tiebreakStartSlot;
    return (_tiebreakStartSlot + 1 + (n - 1) ~/ 2) % _rotation;
  }

  int _sideOfSlot(int slot) => slot.isEven ? firstServerSide : 1 - firstServerSide;

  /// Side currently serving.
  int get servingSide => _sideOfSlot(_currentSlot);

  /// Which player of the serving team is serving (0 = first listed, 1 = partner).
  int get servingPlayer => (_currentSlot ~/ 2) % 2;

  // ---- Queries ----------------------------------------------------------------

  bool get isOver => winner != null;

  int setsWon(int side) => sets.where((s) => s.winner == side).length;

  bool get isDecidingSet => setsWon(0) == format.setsToWin - 1 && setsWon(1) == format.setsToWin - 1;

  bool get isMatchTiebreak => inTiebreak && tiebreakTarget == 10;

  int get totalGamesInSet => games[0] + games[1];

  /// Score of the current game for [side]: "0", "15", "30", "40", "AD", or
  /// tiebreak points.
  String pointLabel(int side) {
    if (inTiebreak) return '${points[side]}';
    final mine = points[side], theirs = points[1 - side];
    if (!format.noAd && mine >= 3 && theirs >= 3) {
      if (mine == theirs) return '40';
      return mine > theirs ? 'AD' : '40';
    }
    return const ['0', '15', '30', '40'][mine.clamp(0, 3)];
  }

  /// Short description of the situation, e.g. "Deuce", "Break point", "Match point".
  String? get situation {
    if (isOver) return null;
    for (final side in [0, 1]) {
      final sim = clone()..play(PointEvent.to(side));
      final o = sim.lastOutcome;
      if (o.matchWonBy == side) return 'Match point';
      if (o.setWonBy == side) return 'Set point';
      if (o.gameWonBy == side && !inTiebreak && side != servingSide) {
        return 'Break point';
      }
    }
    if (inTiebreak) return isMatchTiebreak ? 'Match tiebreak' : 'Tiebreak';
    if (!format.noAd && points[0] >= 3 && points[0] == points[1]) return 'Deuce';
    if (format.noAd && points[0] == 3 && points[1] == 3) return 'Deciding point';
    if (!format.noAd && points[0] >= 3 && points[1] >= 3) return 'Advantage';
    return null;
  }

  // ---- Playing a point --------------------------------------------------------

  PointOutcome play(PointEvent event) {
    lastOutcome = PointOutcome();
    if (isOver) return lastOutcome;

    final server = servingSide;
    final receiver = 1 - server;
    final int scorer;
    switch (event.kind) {
      case PointKind.ace:
        scorer = server;
        stats[server].aces++;
      case PointKind.doubleFault:
        scorer = receiver;
        stats[server].doubleFaults++;
      case PointKind.winner:
        scorer = event.side;
        stats[scorer].winners++;
      case PointKind.unforcedError:
        scorer = 1 - event.side;
        stats[event.side].unforcedErrors++;
      case PointKind.rally:
        scorer = event.side;
    }

    if (!inTiebreak && _wouldWinGame(receiver)) {
      stats[receiver].breakPointChances++;
      if (scorer == receiver) stats[receiver].breakPointsWon++;
    }
    stats[scorer].pointsWon++;
    stats[server].servicePointsPlayed++;
    if (scorer == server) stats[server].servicePointsWon++;

    points[scorer]++;
    if (inTiebreak) {
      final other = 1 - scorer;
      if (points[scorer] >= tiebreakTarget && points[scorer] - points[other] >= 2) {
        _winTiebreak(scorer);
      } else if ((points[0] + points[1]) % 6 == 0) {
        lastOutcome.changeEnds = true;
      }
    } else if (_gameIsWon(scorer)) {
      _winGame(scorer);
    }
    return lastOutcome;
  }

  bool _gameIsWon(int side) {
    if (format.noAd) return points[side] >= 4;
    return points[side] >= 4 && points[side] - points[1 - side] >= 2;
  }

  bool _wouldWinGame(int side) {
    final next = points[side] + 1;
    if (format.noAd) return next >= 4;
    return next >= 4 && next - points[1 - side] >= 2;
  }

  void _winGame(int side) {
    games[side]++;
    points = [0, 0];
    _serverSlot = (_serverSlot + 1) % _rotation;
    lastOutcome.gameWonBy = side;

    final g = format.gamesPerSet;
    final other = 1 - side;
    if (games[side] >= g && games[side] - games[other] >= 2) {
      _winSet(side);
      return;
    }
    final playOn = isDecidingSet && format.finalSet == FinalSet.advantage;
    if (games[0] == g && games[1] == g && !playOn) {
      inTiebreak = true;
      tiebreakTarget = 7;
      _tiebreakStartSlot = _serverSlot;
      lastOutcome.tiebreakStarted = true;
    }
    if (totalGamesInSet.isOdd) lastOutcome.changeEnds = true;
  }

  void _winTiebreak(int side) {
    lastOutcome.gameWonBy = side;
    if (isMatchTiebreak && totalGamesInSet == 0) {
      sets.add(
        SetScore(side == 0 ? 1 : 0, side == 1 ? 1 : 0, tiebreakA: points[0], tiebreakB: points[1], matchTiebreak: true),
      );
    } else {
      games[side]++;
      sets.add(SetScore(games[0], games[1], tiebreakA: points[0], tiebreakB: points[1]));
    }
    // Whoever received first in the tiebreak serves first in the next set.
    _serverSlot = (_tiebreakStartSlot + 1) % _rotation;
    inTiebreak = false;
    points = [0, 0];
    games = [0, 0];
    lastOutcome.changeEnds = true;
    _afterSet(side);
  }

  void _winSet(int side) {
    sets.add(SetScore(games[0], games[1]));
    if (totalGamesInSet.isOdd) lastOutcome.changeEnds = true;
    games = [0, 0];
    _afterSet(side);
  }

  void _afterSet(int side) {
    lastOutcome.setWonBy = side;
    if (setsWon(side) == format.setsToWin) {
      winner = side;
      lastOutcome.matchWonBy = side;
      lastOutcome.changeEnds = false;
      return;
    }
    if (isDecidingSet && format.finalSet == FinalSet.matchTiebreak) {
      inTiebreak = true;
      tiebreakTarget = 10;
      _tiebreakStartSlot = _serverSlot;
      lastOutcome.tiebreakStarted = true;
    }
  }

  /// Completed sets plus the set in progress (if any games have been played).
  List<SetScore> setsIncludingCurrent() {
    if (isOver || (totalGamesInSet == 0 && !inTiebreak)) return List.of(sets);
    if (isMatchTiebreak && totalGamesInSet == 0) {
      return [...sets, SetScore(0, 0, tiebreakA: points[0], tiebreakB: points[1], matchTiebreak: true)];
    }
    return [...sets, SetScore(games[0], games[1])];
  }
}
