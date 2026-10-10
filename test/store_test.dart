import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veritas_tennis/data/app_store.dart';
import 'package:veritas_tennis/models/live_match.dart';
import 'package:veritas_tennis/models/match_record.dart';
import 'package:veritas_tennis/models/player.dart';
import 'package:veritas_tennis/models/practice_session.dart';
import 'package:veritas_tennis/models/tournament.dart';
import 'package:veritas_tennis/scoring/match_format.dart';
import 'package:veritas_tennis/scoring/tennis_scorer.dart';

Player player(String id, String name) => Player(id: id, name: name, createdAt: DateTime(2026));

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('data survives a restart, including a match in progress', () async {
    final prefs = await SharedPreferences.getInstance();
    final store = await AppStore.load(prefs);
    store.setMe(player('me', 'Ada Obi'));
    store.savePlayer(player('p2', 'Chidi Okafor'));
    final live = LiveMatch(
      id: 'm1',
      format: const MatchFormat(),
      sideA: [const Participant(playerId: 'me', name: 'Ada Obi')],
      sideB: [const Participant(playerId: 'p2', name: 'Chidi Okafor')],
      firstServerSide: 0,
      startedAt: DateTime(2026, 10, 1, 7),
    );
    store.startLive(live);
    for (var i = 0; i < 6; i++) {
      live.play(const PointEvent.to(0));
    }
    store.touch();
    store.savePractice(PracticeSession(id: 's1', date: DateTime.now(), minutes: 45, focus: const ['Serve']));
    await Future<void>.delayed(Duration.zero);

    final reloaded = await AppStore.load(prefs);
    expect(reloaded.me?.name, 'Ada Obi');
    expect(reloaded.players.length, 2);
    expect(reloaded.liveMatch!.scorer.games, [1, 0]);
    expect(reloaded.liveMatch!.scorer.points, [2, 0]);
    expect(reloaded.practiceMinutesThisWeek(), 45);
  });

  test('ladder ranks players from saved matches; export/import round-trips', () async {
    final store = await AppStore.load(await SharedPreferences.getInstance());
    store.setMe(player('me', 'Ada'));
    store.savePlayer(player('b', 'Bola'));
    final live = LiveMatch(
      id: 'm1',
      format: const MatchFormat(bestOf: 1),
      sideA: [const Participant(playerId: 'me', name: 'Ada')],
      sideB: [const Participant(playerId: 'b', name: 'Bola')],
      firstServerSide: 0,
      startedAt: DateTime(2026, 10, 1),
    );
    for (var i = 0; i < 24; i++) {
      live.play(const PointEvent.to(0));
    }
    store.addMatch(live.toRecord(endedAt: DateTime(2026, 10, 1, 1)));
    expect(store.ladder.first.player.id, 'me');
    expect(store.ratingOf('me'), 1216);
    expect(store.rankOf('b'), 2);

    final backup = store.exportJson();
    final other = await AppStore.load(await SharedPreferences.getInstance());
    await other.resetAll();
    other.importJson(backup);
    expect(other.matches.single.sets.single.label(), '6-0');
    expect(() => other.importJson('not json'), throwsFormatException);
  });

  test('knockout tournament results feed the next round', () async {
    final store = await AppStore.load(await SharedPreferences.getInstance());
    for (final id in ['a', 'b', 'c', 'd']) {
      store.savePlayer(player(id, id.toUpperCase()));
    }
    final t = store.createTournament(
      id: 't',
      name: 'Hall cup',
      type: TournamentType.knockout,
      playerIds: ['a', 'b', 'c', 'd'],
      seedByRating: true,
    );
    final semi = t.rounds.first.first;
    store.setFixtureResult(t, semi, winnerId: semi.a, score: '6-2 6-2');
    expect(t.rounds.last.single.a, semi.a);
    store.setFixtureResult(t, semi, winnerId: null);
    expect(t.rounds.last.single.a, isNull);
  });
}
