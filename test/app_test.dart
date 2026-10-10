import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veritas_tennis/data/app_store.dart';
import 'package:veritas_tennis/data/club_api.dart';
import 'package:veritas_tennis/data/club_sync.dart';
import 'package:veritas_tennis/main.dart';

void main() {
  testWidgets('onboarding, then score a whole one-set match live', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final store = await AppStore.load(await SharedPreferences.getInstance());
    final sync = ClubSync(store, SupabaseClubApi());
    addTearDown(sync.dispose);
    await tester.pumpWidget(AppRoot(store: store, sync: sync));

    expect(find.text('Create your player profile'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Ada Obi');
    await tester.tap(find.text("Let's play"));
    await tester.pumpAndSettle();
    expect(find.text('Ada'), findsOneWidget);

    // Start a match against a guest.
    await tester.tap(find.text('Score match'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Player B'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Emeka');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use "Emeka" as a guest'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1 set'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Start match'), 200);
    await tester.tap(find.text('Start match'));
    await tester.pumpAndSettle();

    expect(find.text('TAP FOR POINT'), findsNWidgets(2));
    for (var i = 0; i < 24; i++) {
      await tester.tap(find.text('TAP FOR POINT').first);
      await tester.pump();
    }
    await tester.pumpAndSettle(const Duration(seconds: 4));
    expect(find.text('Ada Obi won'), findsOneWidget);
    await tester.tap(find.text('Save match'));
    await tester.pumpAndSettle();
    expect(find.text('Match saved'), findsOneWidget);
    expect(store.matches.single.winnerSide, 0);
    expect(store.liveMatch, isNull);
  });
}
