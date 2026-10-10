import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veritas_tennis/data/app_store.dart';
import 'package:veritas_tennis/data/club_api.dart';
import 'package:veritas_tennis/data/club_sync.dart';
import 'package:veritas_tennis/models/match_record.dart';
import 'package:veritas_tennis/models/player.dart';
import 'package:veritas_tennis/models/tournament.dart';
import 'package:veritas_tennis/scoring/match_format.dart';
import 'package:veritas_tennis/scoring/set_score.dart';

import 'support/fake_club_api.dart';

Player player(String id, String name) => Player(id: id, name: name, createdAt: DateTime(2026));

MatchRecord singles(String id, Player a, Player b, String score, {int winner = 0, DateTime? at}) => MatchRecord(
  id: id,
  playedAt: at ?? DateTime(2026, 10, 1, 9),
  format: const MatchFormat(),
  sideA: [Participant(playerId: a.id, name: a.name)],
  sideB: [Participant(playerId: b.id, name: b.name)],
  sets: parseSetScores(score)!,
  winnerSide: winner,
);

void main() {
  late FakeClubApi server;

  Future<(AppStore, ClubSync)> phone(String prefix) async {
    SharedPreferences.setMockInitialValues({});
    final store = await AppStore.load(await SharedPreferences.getInstance());
    return (store, ClubSync(store, server, debounce: const Duration(days: 1)));
  }

  setUp(() => server = FakeClubApi());

  test('two phones share players, matches, deletions and tournaments', () async {
    final (a, syncA) = await phone('a');
    final ada = player('ada', 'Ada Obi');
    final chidi = player('chidi', 'Chidi Okafor');
    a.setMe(ada);
    a.savePlayer(chidi);
    a.addMatch(singles('m1', ada, chidi, '6-4 6-4'));
    final club = await syncA.createClub('Veritas Tennis Club');
    expect(a.pendingChanges, 0);
    expect(syncA.status, SyncStatus.idle);

    // Chidi installs the app, creates his own profile, then joins the club.
    final (b, syncB) = await phone('b');
    b.setMe(player('chidi-phone', 'chidi  okafor'));
    await syncB.joinClub(club.code.toLowerCase());
    expect(b.meId, 'chidi', reason: 'same name → merged into the club player');
    expect(b.players.map((p) => p.name), containsAll(['Ada Obi', 'Chidi Okafor']));
    expect(b.players.length, 2);
    expect(b.matches.single.id, 'm1');
    expect(b.ladder.first.player.id, 'ada');

    // Chidi records a win and starts a tournament; Ada sees both.
    b.addMatch(singles('m2', b.playerById('chidi')!, b.playerById('ada')!, '7-5 6-3', at: DateTime(2026, 10, 2)));
    b.createTournament(
      id: 't1',
      name: 'Freshers Cup',
      type: TournamentType.knockout,
      playerIds: ['ada', 'chidi'],
      seedByRating: true,
    );
    await syncB.syncNow();
    await syncA.syncNow();
    expect(a.matches.length, 2);
    expect(a.tournamentById('t1')?.name, 'Freshers Cup');
    expect(a.ratingOf('ada'), b.ratingOf('ada'));

    // Ada deletes the first match; Chidi's phone follows.
    a.deleteMatch('m1');
    await syncA.syncNow();
    await syncB.syncNow();
    expect(b.matchById('m1'), isNull);
    expect(b.matches.length, 1);
  });

  test('offline edits are kept and sent later; unsent edits are never overwritten', () async {
    final (a, syncA) = await phone('a');
    a.setMe(player('ada', 'Ada'));
    final club = await syncA.createClub('Club');
    final (b, syncB) = await phone('b');
    b.setMe(player('bola', 'Bola'));
    await syncB.joinClub(club.code);
    await syncA.syncNow();

    server.offline = true;
    a.savePlayer(player('bola', 'Bola Tinubu-Ade'));
    await syncA.syncNow();
    expect(syncA.status, SyncStatus.error);
    expect(a.pendingChanges, 1);

    // Meanwhile Bola renames himself; Ada's pending edit must not be lost on pull.
    server.offline = false;
    b.savePlayer(player('bola', 'Bola A.'));
    await syncB.syncNow();
    await syncA.syncNow();
    expect(syncA.status, SyncStatus.idle);
    expect(a.pendingChanges, 0);
    await syncB.syncNow();
    expect(b.playerById('bola')!.name, 'Bola Tinubu-Ade', reason: 'last write (Ada, sent last) wins');
  });

  test('wrong club code is reported', () async {
    final (_, sync) = await phone('a');
    expect(() => sync.joinClub('NOPE'), throwsA(isA<ClubNotFoundException>()));
  });

  test('merging duplicate players moves their matches and tournament places', () async {
    final (s, _) = await phone('a');
    final ada = player('ada', 'Ada');
    final dup = player('dup', 'Ada O.');
    final emeka = player('emeka', 'Emeka');
    s.setMe(ada);
    s.savePlayer(dup);
    s.savePlayer(emeka);
    s.addMatch(singles('m1', dup, emeka, '6-1 6-1'));
    s.createTournament(
      id: 't',
      name: 'Cup',
      type: TournamentType.roundRobin,
      playerIds: ['dup', 'emeka'],
      seedByRating: false,
    );
    s.mergePlayers('dup', 'ada');
    expect(s.playerById('dup'), isNull);
    expect(s.matches.single.sideA.single.playerId, 'ada');
    expect(s.tournamentById('t')!.playerIds, containsAll(['ada', 'emeka']));
    expect(s.tournamentById('t')!.fixtures.single.isReady, isTrue);
    expect(s.statsOf('ada').wins, 1);
  });

  test('duplicate results are detected from either side', () {
    final a = player('a', 'A'), b = player('b', 'B');
    final m1 = singles('1', a, b, '6-4 3-6 6-2');
    final m2 = MatchRecord(
      id: '2',
      playedAt: DateTime(2026, 10, 1, 18),
      format: const MatchFormat(),
      sideA: m1.sideB,
      sideB: m1.sideA,
      sets: parseSetScores('4-6 6-3 2-6')!,
      winnerSide: 1,
    );
    expect(m1.sameResultAs(m2), isTrue);
    expect(m1.sameResultAs(singles('3', a, b, '6-4 6-4')), isFalse);
  });
}
