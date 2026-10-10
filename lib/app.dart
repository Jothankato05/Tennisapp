import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/app_store.dart';
import 'screens/events/events_screen.dart';
import 'screens/home_screen.dart';
import 'screens/ladder/ladder_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/play/live_match_screen.dart';
import 'screens/play/play_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/train/train_screen.dart';
import 'theme.dart';

class VeritasTennisApp extends StatefulWidget {
  const VeritasTennisApp({super.key, this.showSplash = true});

  /// Plays the opening animation over the first screen.
  final bool showSplash;

  @override
  State<VeritasTennisApp> createState() => _VeritasTennisAppState();
}

class _VeritasTennisAppState extends State<VeritasTennisApp> {
  late bool _splash = widget.showSplash;

  @override
  Widget build(BuildContext context) {
    final hasProfile = context.select<AppStore, bool>((s) => s.me != null);
    return MaterialApp(
      title: 'Veritas Tennis',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      home: hasProfile ? const HomeShell() : const OnboardingScreen(),
      builder: (context, child) => Stack(
        children: [
          child!,
          if (_splash) SplashScreen(onDone: () => setState(() => _splash = false)),
        ],
      ),
    );
  }
}

/// Lets any screen switch the bottom-navigation tab.
class TabSwitcher extends InheritedWidget {
  const TabSwitcher({super.key, required this.goTo, required super.child});

  final void Function(int index) goTo;

  static void of(BuildContext context, int index) =>
      context.dependOnInheritedWidgetOfExactType<TabSwitcher>()?.goTo(index);

  @override
  bool updateShouldNotify(TabSwitcher oldWidget) => false;
}

class AppTab {
  static const home = 0;
  static const play = 1;
  static const ladder = 2;
  static const events = 3;
  static const train = 4;
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _pages = [HomeScreen(), PlayScreen(), LadderScreen(), EventsScreen(), TrainScreen()];

  @override
  Widget build(BuildContext context) {
    final live = context.watch<AppStore>().liveMatch;
    return TabSwitcher(
      goTo: (i) => setState(() => _index = i),
      child: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: IndexedStack(index: _index, children: _pages),
            ),
            if (live != null)
              Material(
                color: VeritasColors.navy,
                child: InkWell(
                  onTap: () =>
                      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const LiveMatchScreen())),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
                    child: Row(
                      children: [
                        const Icon(Icons.circle, size: 10, color: VeritasColors.ball),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${live.sideName(0)} vs ${live.sideName(1)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const Text(
                          'Resume',
                          style: TextStyle(color: VeritasColors.ball, fontWeight: FontWeight.w800),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: VeritasColors.ball),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(
              icon: Icon(Icons.sports_tennis_outlined),
              selectedIcon: Icon(Icons.sports_tennis),
              label: 'Play',
            ),
            NavigationDestination(
              icon: Icon(Icons.leaderboard_outlined),
              selectedIcon: Icon(Icons.leaderboard),
              label: 'Ladder',
            ),
            NavigationDestination(
              icon: Icon(Icons.emoji_events_outlined),
              selectedIcon: Icon(Icons.emoji_events),
              label: 'Events',
            ),
            NavigationDestination(
              icon: Icon(Icons.fitness_center_outlined),
              selectedIcon: Icon(Icons.fitness_center),
              label: 'Train',
            ),
          ],
        ),
      ),
    );
  }
}
