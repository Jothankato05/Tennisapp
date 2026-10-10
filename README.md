# Veritas Tennis

A Flutter app for the tennis players of **Veritas University, Abuja**. It is the
thing you actually reach for on court: keep score, see your record, settle who
is top of the campus ladder, run hall and departmental tournaments, and train
with a plan.

Everything is stored on the phone. It needs no account, server or data
connection, so it works on campus Wi‑Fi, on mobile data, or with no signal at all.

## Features

| Tab | What it does |
| --- | --- |
| **Home** | Your rating, ladder rank, win–loss record and streak; this week's matches and practice time; recent results, running tournaments and a daily coaching tip. |
| **Play** | **Live scorekeeper**: tap a side to give them the point. Handles 15‑30‑40, deuce/advantage, no‑ad, 7‑point tiebreaks, 10‑point match tiebreaks, short sets and advantage final sets. Tracks who serves (including the four-player doubles rotation), deuce/ad court, change of ends, break, set and match points, aces, double faults, winners and errors. Undo any point. A match in progress survives the app being closed. You can also **log a result** you played earlier (e.g. `6-4 3-6 7-6(5)`), view full match stats, and copy a result to share on WhatsApp. |
| **Ladder** | Elo-style campus rankings from singles results between club players. Each player's profile has a rating history chart, win rate, streaks, sets, tiebreaks, break-point conversion, recent form and head‑to‑head records. |
| **Events** | **Knockout** draws with seeding by rating and byes for top seeds, or **round robins** with a standings table (wins, then set and game difference, then head‑to‑head). Score any fixture live or type the result, and winners move on automatically. Copy a summary to post in the group chat. |
| **Train** | 15 drills covering warm-up, groundstrokes, serve and return, net play, footwork and match play, with steps and coaching tips. Includes a practice log with weekly minutes and a day streak, plus a rules guide covering scoring, tiebreaks, serving, doubles, line calls, court etiquette and playing in the heat. |
| **Settings** | Edit your profile, copy a backup of all data as text (to keep it safe or share it with the club secretary), restore it on another phone, or erase everything. |

## Getting started

Requires the [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.47 or newer (Dart 3.13).

```bash
flutter pub get
flutter run            # on a connected phone or emulator
flutter test           # unit + widget tests
flutter analyze
```

Build for distribution:

```bash
flutter build apk --release          # Android APK to share or sideload
flutter build appbundle --release    # for the Google Play Store
flutter build ipa                    # iOS (needs a Mac with Xcode)
flutter build web --release          # optional web version
```

> Release builds are signed with the debug key for now. Before you publish to
> Google Play, create an upload keystore and set up signing in
> `android/app/build.gradle.kts` (see the [Flutter docs](https://docs.flutter.dev/deployment/android#signing-the-app)).

## Project layout

```
lib/
  main.dart, app.dart        App start-up, theme and the five-tab shell
  scoring/                   Tennis scoring engine (pure Dart, fully tested)
  models/                    Players, matches, live match, tournaments, practice
  logic/                     Elo ratings, player stats, knockout and round-robin draws
  data/                      AppStore (state + on-device storage), drills, rules guide
  screens/                   home, play/, ladder/, events/, train/, settings
  widgets/                   Shared UI: score table, rating chart, player picker…
test/                        Engine, logic, storage and end-to-end widget tests
```

### How scoring works internally

A live match is stored as a list of point events. The score is rebuilt by
replaying them through `TennisScorer`, so undo just drops the last event, and a
match restored after the app is killed is exactly the same as before.

### Ladder ratings

Everyone starts at 1200. A ranked match (singles, both players in the club
list, with a result) moves `32 × (1 − expected)` points from loser to winner,
so upsets earn more. Ratings are recalculated from the full history every time,
which means deleting or correcting a match always leaves the ladder consistent.

## Ideas for later

- Optional cloud sync (e.g. Firebase) so the ladder and tournaments are shared live across every player's phone.
- A court booking or queue board for the campus court.
- Push reminders for upcoming tournament fixtures.
