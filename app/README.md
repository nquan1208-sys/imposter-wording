# EscapeCall Mobile

Flutter mobile app with Signals state management, Riverpod DI, a Bumble-inspired theme (`lib/theme`) and VI/EN localization (default VI).

## Docs

- [Architecture](docs/architecture.md)
- [State Management](docs/state-management.md)
- [Routing](docs/routing.md)
- [How to Add a New Feature](docs/how-to-new-feature.md)

## Environments

Run these commands from `app/` on a new machine:

```sh
cp env/.env.local.example env/.env.local
cp env/.env.dev.example env/.env.dev
cp env/.env.prod.example env/.env.prod
flutter pub get
```

Create all three files, even if some credentials are not available yet: Flutter
registers all three as assets. Real env files are ignored by Git; examples are
committed. Each file contains `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY`.

| Environment | File | Backend |
| --- | --- | --- |
| Local | `env/.env.local` | Local Supabase, same public client values as `admin/.env.local` |
| Dev | `env/.env.dev` | Shared `imposter-word` Supabase project; fill in its publishable key |
| Prod | `env/.env.prod` | Fill in the production project URL and publishable key |

Copy the Admin `VITE_SUPABASE_URL` and `VITE_SUPABASE_PUBLISHABLE_KEY` values
without the `VITE_` prefix. Use only `sb_publishable_...` keys; never put secret,
service-role keys or passwords in these files. All three files are bundled into
every build and can be extracted, including the files not selected at startup.

### Run and debug

Open the repository root in VS Code/Cursor with the Flutter extension installed.
In **Run and Debug**, select **Flutter Local**, **Flutter Dev** or **Flutter Prod**,
select your device, then press F5. All three launch in debug mode with breakpoints
and hot reload, using the same app ID; they cannot be installed side by side.

Equivalent terminal commands:

```sh
flutter run --dart-define=APP_ENV=local
flutter run --dart-define=APP_ENV=dev
flutter run --dart-define=APP_ENV=prod
```

`APP_ENV` selects the file loaded by `flutter_dotenv` before `runApp`. It defaults
to `local`. Unknown environments, missing/empty files, invalid URLs and missing
or invalid publishable keys stop startup with a configuration error. There is no
fallback to another environment. Dev and Prod cannot start until configured.
After changing env values or environments, stop and run again.

Start the local Supabase stack from the repository root with `supabase start`.
Use `http://127.0.0.1:54321` for iOS Simulator. For Android Emulator, edit
`SUPABASE_URL` in `env/.env.local` to `http://10.0.2.2:54321`. For a physical
device, use the LAN IP of the computer running Supabase and ensure it is reachable.

Application code can read the validated config through `AppConfig.current`
from `package:untitled/config/app_config.dart`. Startup initializes Supabase with
the publishable key and no player session, then starts one shared background
content load. Dev and Prod require HTTPS. Local HTTP is enabled only in Android
debug and iOS Debug configuration; Release/Profile retain platform TLS protections.

### Word setup and offline content

Start opens setup: 3–100 players (default four), one fixed imposter, Word,
Classic/Family, and all or selected categories. Category selections commit on
Confirm; back discards picker edits. Both word and question games are playable.
UI language does not change content: phase 2 always uses published Vietnamese
translations and active categories. Family additionally requires family-friendly
words; categories without eligible words are hidden.

`data/content_repository.dart` loads every page in ascending original-ID order,
validates category links and translations, and replaces the snapshot only after
all three tables (categories, words, question pairs) succeed. It restores cached
content immediately while refreshing. Failed refreshes retain the previous cache;
a successful empty load replaces it. Images retain their Storage paths only.

Snapshots and committed setup use separate Hive CE boxes in Application Support,
scoped by environment, normalized backend URL, and content locale. Existing
versioned JSON files migrate after validation and are preserved. Setup writes
serialize, compute against the latest commit and publish only after successful
storage. Failed autosaves retain the attempted change for retry; dialogs/editors
retain their input. Unreadable records block writes until a successful retry.
Changing backend URLs creates a separate scope.

No backend schema changes or seed data are needed. Current Local content contains
one Classic word and zero Family words; populated Family and multi-page behavior
are covered with fixtures.

### Release builds

Fill in production config first:

```sh
flutter build appbundle --release --dart-define=APP_ENV=prod
flutter build ipa --release --dart-define=APP_ENV=prod
```

IPA builds require macOS/Xcode and signing configuration. Config validation runs
at application startup, including release; building alone does not validate keys.

### Checks

```sh
flutter analyze
flutter test
flutter test integration_test/setup_smoke_test.dart -d <ios-simulator-id> --dart-define=APP_ENV=local
```

The integration smoke test requires the current Local Supabase dataset. It reads
anonymously, checks counts and setup navigation, then recreates stores from real
Application Support files with a simulated offline source. Its files use a
temporary directory and do not replace the normal app settings.

### Question game (Phase 5)

Setup supports word/question and Classic/Family modes using the same content
repository and cache. Question games keep roles secret: every player opens an
identical hidden card, answers privately, then locks their answer on submission.
Unsent drafts stay in memory by player ID and require reopening that player's
card. Backgrounding hides both the question and answer field. After all answers,
the civilian question and answers become public; reveal shows every imposter and
the alternate question directly, without a scored vote. Replay returns to setup.
Answers, drafts and sessions are never saved to disk or uploaded.

### Player presets and imposter options (Phase 6)

The player editor can create, select and manage saved lists. Presets include only
ordered players, their next ID counter and the five imposter rule fields; selecting
one preserves game type, mode, categories and UI/content languages. Selection is a
draft until Confirm. Creating a list saves it immediately, so it survives discarding
the editor. Active lists autosave rule changes. Rename preserves identity; deletion
keeps current players/rules and stale drafts cannot recreate a deleted list.

Setup uses fixed/random imposter cards and a shared confirmation draft for count,
mode and never-start. For 3–4 players, a warning card explains that at least five
players are needed for multiple imposters. Both games offer “Imposters know each other” and “Show category
to imposters”. In question games, only revealed imposter cards can show teammates,
excluding the current player by ID; hiding the card removes that content from both
widgets and semantics. Imposters see the category only when enabled. Sessions retain
their original rule snapshot.

Phase 6 verification: localization generation, static analysis and all 146 automated
tests passed. Coverage includes real Hive close/reopen and legacy migration,
serialized/failing writes, preset management, small layouts/text scale 2/keyboard,
private question options and complete word/question games after preset loading.
No screenshot verification, real-device smoke or backend integration test was run.
