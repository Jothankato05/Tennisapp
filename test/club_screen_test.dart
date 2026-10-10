import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veritas_tennis/data/app_store.dart';
import 'package:veritas_tennis/data/club_sync.dart';
import 'package:veritas_tennis/main.dart';
import 'package:veritas_tennis/models/player.dart';

import 'support/fake_club_api.dart';

void main() {
  testWidgets('join a club from the home screen cloud icon', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final server = FakeClubApi();
    final club = await server.createClub('Veritas Tennis Club');

    final store = await AppStore.load(await SharedPreferences.getInstance());
    store.setMe(Player(id: 'me', name: 'Ada Obi', createdAt: DateTime(2026)));
    final sync = ClubSync(store, server, debounce: const Duration(days: 1));
    addTearDown(sync.dispose);
    await tester.pumpWidget(AppRoot(store: store, sync: sync, showSplash: false));

    await tester.tap(find.byIcon(Icons.cloud_off_outlined));
    await tester.pumpAndSettle();
    expect(find.text('One ladder for the whole club'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Club code'), 'wrong-code');
    await tester.tap(find.text('Join club'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No club has that code'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Club code'), club.code.toLowerCase());
    await tester.tap(find.text('Join club'));
    await tester.pumpAndSettle();
    expect(store.club?.code, club.code);
    expect(find.text(club.code), findsOneWidget);
    expect(find.text('Invite players'), findsOneWidget);
    expect(server.rows.keys.any((k) => k.endsWith('|player|me')), isTrue, reason: 'profile shared with club');
  });
}
