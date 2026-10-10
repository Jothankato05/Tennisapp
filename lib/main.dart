import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/app_store.dart';
import 'data/club_api.dart';
import 'data/club_sync.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final store = await AppStore.load(prefs);
  final sync = ClubSync(store, SupabaseClubApi())..start();
  runApp(AppRoot(store: store, sync: sync));
}

/// Provides app state and syncs with the club whenever the app comes back
/// to the foreground.
class AppRoot extends StatefulWidget {
  const AppRoot({super.key, required this.store, required this.sync, this.showSplash = true});

  final AppStore store;
  final ClubSync sync;
  final bool showSplash;

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) widget.sync.syncNow();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppStore>.value(value: widget.store),
        ChangeNotifierProvider<ClubSync>.value(value: widget.sync),
      ],
      child: VeritasTennisApp(showSplash: widget.showSplash),
    );
  }
}
