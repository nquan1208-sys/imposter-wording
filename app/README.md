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
a successful empty load replaces it. Each page has a 15-second timeout, and late
responses cannot replace newer content. Setup's refresh button shares the startup
and retry operation; retained content stays playable while it runs. A failed refresh
marks retained content as stale. Persistence failures warn separately while keeping
downloaded content playable.

Snapshots and committed setup use separate Hive CE boxes in Application Support,
scoped by environment, normalized backend URL, and content locale. Existing
versioned JSON files migrate after validation and are preserved. Setup writes
serialize, compute against the latest commit and publish only after successful
storage. Failed autosaves retain the attempted change for retry; dialogs/editors
retain their input. Unreadable records block writes until a successful retry.
Changing backend URLs creates a separate scope.

No backend schema changes or seed data are needed. The read-only Local check on
2026-10-27 returned 14 categories, 52 words and 52 question pairs. Dataset counts
can change; pagination and Family filtering are also covered with fixtures.

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

### Content refresh and word images (Phase 7)

Private `word-prompt-images` files are downloaded in a background queue using
five-minute signed URLs. Only backend identity and `image_path` identify local files;
signed URLs are never saved. Existing files restore before missing downloads run.
Signing and downloads have 15-second timeouts. Downloads enforce the bucket's
5 MiB limit and JPEG/PNG/WebP response types, decode before publishing, and use
atomic temporary-file renames. Expired/unauthorized downloads renew their URL once;
other failures retry on the next startup or setup refresh.

Opened civilian word cards and the final result show the local image below the word.
Missing, unreadable or undecodable images use a stable placeholder. Words without
images stay text-only. Covered/imposter cards, player selection and discussion
contain no image or image semantics. Lifecycle concealment removes private images.
Background completion updates visible images without changing the session.

Images live in a backend-scoped Application Support directory shared across locales.
Cleanup retains every validated persisted snapshot (including legacy JSON), current
content and pinned word sessions. Pins release when navigation ends or fails.
Unreadable/invalid snapshot inventory prevents deletion. Existing setup/presets and
legacy migration remain intact. Offline content can remain stale until sync succeeds.

#### HTTP verification

From the repository root, start the local Postman simulation:

```sh
postman simulation run postman/simulations/phase-7.sim.yaml --port 4937 --output ndjson --no-history
```

In another terminal, run from `app/`:

```sh
cp env/.env.test.example env/.env.test
flutter test test/data/backend_http_test.dart
PHASE7_LIVE_CHECKS=1 flutter test test/data/backend_http_test.dart --plain-name 'read-only anonymous'
```

`SUPABASE_SIMULATION_URL` comes from `env/.env.test` or the process environment.
`TEST_HTTP_HOST` is an optional process environment override for in-process test
servers; otherwise tests use the address their server actually bound. The application
continues to read its backend URL from `SUPABASE_URL` in the selected environment.
The live checks use only anonymous read/sign/download requests against local/dev.
HTTP and live checks skip in the default suite unless explicitly configured.

Evidence and remaining backend/device gaps are recorded in the Phase 7 section of
[the implementation plan](../docs/app-implementation-plan.md) and the
[simulation context](../postman/simulations/phase-7.context.md).

Phase 7 verification (2026-10-27): localization generation and static analysis passed;
175 automated tests passed (10 optional HTTP/live checks skipped in the default run).
All eight Postman HTTP cases passed separately, with 57 requests confirmed in its log.
Local anonymous reads passed; valid image downloads and cross-locale-only images were
unavailable in that dataset, and Dev was unreachable/rejected. Physical-device and
Release behavior remain unverified. No screenshot capture was performed.

### App settings (Phase 11)

Settings is available from setup. UI language (Vietnamese/English) and the
anonymous installation ID live in a versioned `app_preferences` Hive record,
independent of the backend/content cache. Game content remains Vietnamese until
Phase 12. Version/build comes from platform package metadata; the full local ID
is copied only when the user asks. Store review and feedback actions stay visibly
unavailable until real destinations are configured.


### Flutter UI refresh (2026-10-29)

The entire mobile interface now follows the Bumble reference through the shared
light theme, system font, Material icons and 640 logical-pixel content width.
Setup stats, game choices, categories and player cards prefer two columns on
ordinary phones. Cards share their row height and grow with content; narrow
screens and enlarged text fall back to one column. Category reveal remains a
persisted word-only option directly below the game choices, before content/network
notices. Know-each-other remains available in both games; hints remain hidden. Custom-content dialogs scroll their actions with the form when space
is limited by the keyboard.

See [design rules](DESIGN_RULES.md) and the
[phase checkpoint](../docs/plans/flutter-ui-refresh.md) for the component contract,
user amendments and verification evidence. Role assignment, scoring, route inputs, storage
formats and dependencies are unchanged.

Verification: analyzer clean; 294 unit/widget tests passed. Twelve existing
backend checks remain opt-in through their environment flags. The offline
setup/word/question integration suites passed on both iPhone 16 Pro (iOS 18.5
Simulator) and Android `Sm_Phone_test`: 5 cases on each platform, including live
anonymous Local Supabase reads and offline disk recovery. No screenshots or
golden tests were used; physical-device and opt-in backend test gaps are recorded
in the checkpoint.
