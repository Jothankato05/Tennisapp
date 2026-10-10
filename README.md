# Veritas Tennis

A Flutter app for the tennis players of **Veritas University, Abuja**. It is the
thing you actually reach for on court: keep score, see your record, settle who
is top of the campus ladder, run hall and departmental tournaments, and train
with a plan.

Everything works offline on the phone with no account needed. Students who
**join their club** with a shared code also get one ladder, one set of results
and the same tournaments on every member's phone, synced in the background
whenever there is a connection.

## Features

| Tab | What it does |
| --- | --- |
| **Home** | Your rating, ladder rank, win–loss record and streak; this week's matches and practice time; recent results, running tournaments and a daily coaching tip. |
| **Play** | **Live scorekeeper**: tap a side to give them the point. Handles 15‑30‑40, deuce/advantage, no‑ad, 7‑point tiebreaks, 10‑point match tiebreaks, short sets and advantage final sets. Tracks who serves (including the four-player doubles rotation), deuce/ad court, change of ends, break, set and match points, aces, double faults, winners and errors. Undo any point. The screen stays on while scoring, and a match in progress survives the app being closed. You can also **log a result** you played earlier (e.g. `6-4 3-6 7-6(5)`), view full match stats, and share a result straight to WhatsApp. |
| **Ladder** | Elo-style campus rankings from singles results between club players. Each player's profile has Call and WhatsApp buttons, a rating history chart, win rate, streaks, sets, tiebreaks, break-point conversion, recent form and head‑to‑head records. |
| **Events** | **Knockout** draws with seeding by rating and byes for top seeds, or **round robins** with a standings table (wins, then set and game difference, then head‑to‑head). Score any fixture live or type the result, and winners move on automatically. Share the draw and results to the group chat in one tap. |
| **Train** | 15 drills covering warm-up, groundstrokes, serve and return, net play, footwork and match play, with steps and coaching tips. Includes a practice log with weekly minutes and a day streak, plus a rules guide covering scoring, tiebreaks, serving, doubles, line calls, court etiquette and playing in the heat. |
| **Club sync** | A captain creates the club once and shares its code (e.g. `KQ7MZ-3HXPA`) in the WhatsApp group. Members join with the code; players, results, the ladder and tournaments sync across everyone's phones, while practice logs stay private. Players with the same name are merged when you join, any other duplicates can be merged from a profile, and logging a result that is already saved triggers a warning so the ladder doesn't count it twice. Pull down on Play, Ladder or Events to sync now. |
| **Settings** | Edit your profile, save a backup file of all data (to Google Drive, WhatsApp, email…), restore a backup on another phone, or erase everything. |

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

### Automatic builds (GitHub Actions)

Every push runs the analyzer and tests, then builds the APKs and a Play Store
bundle (`.github/workflows/build.yml`). Download them from the run's
**Artifacts** on the Actions tab. Pushing a tag such as `v1.0.0` also publishes
a GitHub Release with the APKs attached, so students can download from one link.

### Signing for the Google Play Store

**Publishing step by step:** see [PLAY_STORE.md](PLAY_STORE.md) for the store listing, graphics, privacy policy
and every Play Console form answer.

Without a key, release builds are signed with the debug key. That is fine for
sending the APK to students directly, but Google Play needs your own upload key:

```bash
keytool -genkeypair -v -keystore ~/veritas-upload.jks -keyalg RSA -keysize 2048 \
  -validity 10000 -alias upload
```

Then create `android/key.properties` (it is git-ignored, so never commit it):

```properties
storeFile=/home/you/veritas-upload.jks
storePassword=…
keyAlias=upload
keyPassword=…
```

To have GitHub Actions sign builds, add these repository secrets:
`ANDROID_KEYSTORE_BASE64` (output of `base64 -w0 veritas-upload.jks`),
`ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS` and `ANDROID_KEY_PASSWORD`.
Keep the keystore and passwords safe: you need the same key for every update.

## Project layout

```
lib/
  main.dart, app.dart        App start-up, theme and the five-tab shell
  scoring/                   Tennis scoring engine (pure Dart, fully tested)
  models/                    Players, matches, live match, tournaments, practice
  logic/                     Elo ratings, player stats, knockout and round-robin draws
  data/                      AppStore (state + storage), club sync (API + engine), drills, rules guide
  screens/                   home, play/, ladder/, events/, train/, settings
  widgets/                   Shared UI: score table, rating chart, player picker…
test/                        Engine, logic, storage, sync and end-to-end widget tests
supabase/migrations/         Club sync database schema and functions
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

## Club sync backend

Sync runs on a Supabase project (`veritas-tennis`, London region). The schema is
in `supabase/migrations/`. Clients talk only to four Postgres functions
(`create_club`, `get_club`, `sync_push`, `sync_pull`). The tables themselves are
locked to the public API, so the **club code is the credential**: anyone with
it can read and edit that club's results, and nothing else.

- Records (players, matches, tournaments) are stored as JSON, one row each,
  last write wins. Deletions are kept as tombstones so they reach every phone.
- Phones push their unsent changes first, then pull everything changed since
  their last sync (with a short overlap, so nothing committed out of order is
  missed). Changes made on a phone that are not yet sent are never overwritten.
- The app ships with the project URL and publishable key, which are meant to
  be public. To use another backend, apply the migration there and build with
  `--dart-define=SUPABASE_URL=… --dart-define=SUPABASE_KEY=…`.
- Free Supabase projects pause after a week with no activity. If the club takes
  a long break, restore the project from the Supabase dashboard.

## Ideas for later

- A court booking or queue board for the campus court.
- Push reminders for upcoming tournament fixtures.
