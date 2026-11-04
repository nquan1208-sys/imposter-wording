# Application Implementation Plan

> Requirements: [Application Screen Layout](layout/screen-layout.md). Checked against repository code/migrations on 2026-10-24, including the new multilingual content schema. Status and evidence are recorded per phase below; Phases 1–5 have analyzer/tests and iOS Simulator smoke checks. Dev/Production backend acceptance is pending.

## 1. Goals and PR breakdown

Build a shared-device Flutter app with word and question games. Prioritize a complete Vietnamese game early, then add configuration, content management, and DB-driven content-language selection.

**One phase equals one PR.** Each PR delivers usable functionality, a UI entry point, and its own tests without requiring unfinished PRs to run. Phases may depend on **merged** PRs; independence does not mean identical baselines or arbitrary merge order.

- Each PR includes its feature's UI, stores, data/validation, routes, translations, and tests.
- Unimplemented features are hidden or clearly unavailable; no buttons leading to empty screens or missing routes.
- Phases 1–2 deliver foundations and usable setup; **Phase 3 is the first complete playable game**.
- Working features remain functional after every merge. Do not split features into mock-only UI and logic PRs that must merge together.
- Avoid whole-app architecture changes, admin rewrites, or new backend services in feature PRs before needed.

## 2. Verified baseline

| Area | Repository state | Planning consequence |
| --- | --- | --- |
| App | `LandingScreen` entry, `HowToPlayScreen`, light/dark themes; Start disabled | Phase 1 foundations exist; continue setup in Phase 2, no gameplay yet. |
| State/DI | `StoreBase`, `StoreProvider`, Signals, `AutoDisposeManager`, Riverpod | Reuse existing code; no additional state management. |
| Navigation | `RouterService`, `RouteName`, `RouteInput`, `RoutePage`, `RouteScreen`; landing/instructions/unknown routes | Use existing Navigator/service; product flow no longer has demo bottom navigation. |
| App docs | README and `app/docs/` describe Signals/Store, routing, VI/EN | Reuse and update for new features. |
| UI language | VI/EN ARB, default `vi`; `AppStore.setLocale` updates MaterialApp in memory only | Phase 12 now uses one shared UI/content language choice. |
| Backend config | `AppConfig` reads/validates URL/publishable key by `APP_ENV`; no client/API calls yet | Phase 2 reuses config, adds client/repository and anon reads without rebuilding environments. |
| Content backend | Three base tables, `content_languages`, three translation tables; public grants/RLS now translation-based | Mobile reads Data API as anon, never admin `admin_*`/`save_*` RPCs. |
| Current schema | Base records retain shared IDs/metadata; category names, words, question pairs, `locale`, status live in translations | Do not select `text`/`status`/`locale` from base prompts or `name` from base categories. Words share `image_path`; questions have no remote images yet. |
| Device data | No content repository, saved setup/lists, custom images, or game sessions yet | Add when used; do not assume these exist. |
| Tests | Onboarding/back/VI–EN/config/theme/auto-dispose tests; clean analyzer, 27/27 passed at Phase 1 acceptance | Preserve foundations and add per-PR data/game-rule tests; results do not validate unimplemented phases. |

Primary technical sources: [pubspec](../app/pubspec.yaml), [AppStore](../app/lib/store/app_store.dart), [routing](../app/lib/base/dependency/router/utils/route_page.dart), [AppConfig](../app/lib/config/app_config.dart), [schema](database-schema.dbml), [translation migration and current RLS/Storage](../supabase/migrations/20261024045640_content_translations.sql), [multilingual read-permission tests](../supabase/tests/content_translations.sql), [backend cutover procedure](plans/admin-content-translations/admin-content-translations-phase-6.md).

Backend statements here come from repository files. Cutover reports local tests, without cloud deployment; before Phase 2 verify the target has the new schema and anon reads. Do not assume Dev/Production matches local; the app does not support both old/new schemas.

## 3. Decisions required before related phases

These are **implementation proposals**, not automatic replacements for layout requirements. Final decisions update layout/tests in the same feature PR.

| Ambiguity | Smallest proposal | Decide before |
| --- | --- | --- |
| Section 3 has `Show hints`, but section 7 forbids hints and backend removed them | **Agreed Phase 4:** keep only `Show category to imposters`; no new hint source. Other hints require separate content/data specifications. | Phase 4 |
| No imposter-count formula; `1–4` is only an example | **Agreed Phase 4:** for N players use 1…floor((N−1)/2), preserving civilian majority; uniformly random in range. Never-start chooses starter first, then excludes them from roles. | Phase 4; Phase 3 uses one imposter |
| Layout refers both to first-player exclusion and selecting a starter | **Agreed Phase 4:** one `startingPlayerId` drives role assignment and displayed discussion starter. | Phase 4 |
| No voted-player UI, tie handling, or multiple-imposter win rules | Vote verbally; reveal opens selection/confirmation sheet. One imposter: correct selection means group victory, otherwise imposter victory. **Agreed Phase 4:** select exactly K players; group wins only if the complete imposter set matches. Ties require revoting before confirmation; no individual-ballot system. | Phase 3 agreed single selection/win rules; multiple-imposter rules finalized in Phase 4 |
| Unclear whether alternate-question recipients know their role | **Agreed Phase 5:** show private question only, no role; locked cards identical. **Phase 6 addition:** question `Imposters know each other`; with at least two imposters, only revealed imposter cards show teammates. Disabled/single-imposter cases retain Phase 5. Questions retain RAM-only drafts and direct reveal without voting/win calculation; `showCategory` also applies to questions per Phase 6. | Phase 5; extended in Phase 6 |
| Custom content is current-game-only but also locally saved across games; return mentions nonexistent `Classic` category tab | **Agreed Phase 8:** save with device setup across replay/restart; delete only after confirmed setup → landing navigation. Save retains picker tab and adds category to draft selection; `Confirm` applies, Back discards only selection, preserving saved categories. No permanent library. | Phase 8 |
| One `Question` field cannot provide different questions to two groups | Custom question forms require two different questions. Bulk entry pairs two multiline fields by line, requiring equal counts. | Phase 9 |
| No custom Family suitability field | **Agreed Phase 8:** Family-tab creation requires suitability confirmation and appears in both tabs; All-tab creation is not implicitly Family-friendly. Tab/game changes never delete categories. | Phases 8–9 |
| Saved-list details show `Show imposter count`, absent from setup | **Agreed Phase 6:** omit it; show only existing rules and fixed/random count. No new setting/rule. | Phase 6 |
| Section 16 has one Language row, while DB translations are independent | Agreed: one `Language` for UI/content, default `vi`; DB list restricted to existing UI ARB codes. Missing prompts are empty, without fallback. | Phases 11–12 |
| Not all state illustrations, store URLs, or feedback channels exist | Reuse theme; no pixel-match promise. Release URLs/IDs required before Phases 11/13. | Relevant phase |

Unresolved decisions leave related features unavailable and documented in PRs; do not claim complete specification delivery.

## 4. Shared data and lifecycle rules

### Game content

Read the new schema starting in Phase 2, initially only `vi`:

| Source | App fields | Rules |
| --- | --- | --- |
| `content_languages` | `code`, `display_name`, `sort_order` | Content language catalog; listed codes do not guarantee published prompts. Phase 12 picker uses it. |
| `game_categories` + `game_category_translations` | Base: `id`, `game_type`, `sort_order`, `is_active`, `is_family_friendly`; translation: `category_id`, `locale`, `name`, `description`, `status` | Join `category_id = id`; require published content-locale translation and active category. `slug` unique by `(game_type, slug)`, not locale; select/store by ID. |
| `word_prompts` + `word_prompt_translations` | Base: `id`, `category_id`, `difficulty`, `image_path`; translation: `prompt_id`, `locale`, `text`, `status` | One translation per `(prompt_id, locale)`; base images shared across locales. |
| `question_prompts` + `question_prompt_translations` | Base: `id`, `category_id`, `difficulty`; translation: `prompt_id`, `locale`, `civilian_question`, `imposter_question`, `status` | Both questions come from one translation row; never combine locales or invent missing questions. |

- One content repository drives pickers/counts/randomization; joined models retain base ID and `contentLocale`. UI must not apply a separate eligibility rule set.
- Eligible content matches game type, has **prompt/category translations in the same locale with `status = published`**, and category `is_active = true`. Family is word-only and requires `game_categories.is_family_friendly = true`, including all eligible words in those categories. Classic includes Family/non-Family. Base prompts no longer have `locale`/`status` or historical hint columns.
- RLS permits base reads with any public locale; a readable base does not establish selected-locale eligibility. Explicitly filter translation locale/status and join full parent/child data; missing translations in nested left joins are not eligible content.
- No categories means all eligible content; multiple categories mean their union. Every prompt has equal probability; do not randomize categories first and favor smaller ones.
- Pickers show only categories with eligible content and counts from the same start-game dataset. Fetch all needed pages in stable order from Phase 2; never count/randomize only the first page or count translations as separate prompts.
- Type/mode/content-locale changes or refresh remove invalid selections with notice; none remaining means `All categories`. No eligible content blocks start with recovery guidance. Retain eligible IDs and update translated names.
- Fetch through Supabase API from Phase 2; no DB seeds or bundled content/images. Scope cache by backend, format version, content locale; atomically replace only after complete fetch/validation, including valid empty results. Failures use latest good cache **for the same backend/locale**, otherwise error/retry. Draft/archived fixtures exist only in tests.
- Phase 7 completes setup refresh, Storage images, and sync recovery; Phase 12 adds content-language selection. No manifest, delta sync, random RPC, Realtime, or new release system yet.

### UI and content languages

- Since the Phase 12 revision, `GameSetup.contentLocale` drives ARB/MaterialApp and queries/cache/categories/prompts. One Language choice; legacy `ui_locale` remains only for storage compatibility.
- Phase 12 lists `content_languages` by `sort_order`, then `code`, restricted to matching UI ARB support. The list has no active/status flag or translation-completeness guarantee.
- Never automatically translate/copy/fallback VI↔EN content. Listed languages without eligible prompts are empty. Offline uses only selected-locale cache, showing language/staleness clearly.
- Persist one `GameSetup.contentLocale`, change only outside games, and preserve active snapshots. Custom content keeps its creation locale without automatic translation.

### Setup and sessions

- Setup includes stable player IDs, game type, mode, category IDs, `contentLocale` (initially `vi`), and options. Add fields only when used. UI locale is not a game rule and presets cannot overwrite it.
- Sessions snapshot setup, locale, translated category names/prompts, roles, starter, reveal/answer progress, and stage at start. Rebuild/back/refresh/resume never rerandomizes or changes translations.
- `Play again` ends sessions and returns to setup with settings/players retained for edits. Only setup start creates/rerandomizes from current eligible content. Repeats are allowed for small sets; no initial anti-repeat history.
- Sessions outlive individual game screens, not disposed with reveal routes. Confirmed exit/end destroys them; back cannot reopen completed secrets.
- Player names, roles, answers, and votes remain on-device, never sent to Supabase/logs. Setup/saved lists survive restart; ongoing sessions need not survive OS process termination.
- Backgrounding/handoffs conceal secrets before redisplay. No OS screenshot-blocking promise in scope.
- Settings/locale and content cache persist separately; read failures must not silently overwrite user data. Failed saves retain forms with retries.
- Phase 8 custom words persist in setup with creation locale, outside remote cache/presets. Launching on landing does not delete them; only confirmed setup → landing clears them atomically with matching category IDs. Failures retain content/setup.

### Planned code structure

- Keep `app/lib/features/<feature>/` screens/stores; group related screens sharing flows/sessions.
- Shared services/DI go in `base/dependency/`; use existing `base/store/` registration. Shared sessions have independent lifecycles, never registered per route.
- Add `app/lib/data/` for content/local storage and `app/lib/models/` for genuinely shared models only when needed. Do not precreate future-phase files.
- Reuse constants, Signals, Riverpod, l10n. Choose minimal file/image/link plugins at implementation time and commit lockfiles; do not preload every dependency.

## 5. Phase overview and dependencies

| Phase / PR | Demonstrable result after merge | Dependencies |
| --- | --- | --- |
| 1. App shell/instructions | Vietnamese startup, instructions, correct navigation/back; already in source | — |
| 2. Word setup/backend categories | Player count, mode, multiple `vi` API/cache categories with correct counts | 1; target translation schema |
| 3. Complete word game | Setup → private handoff/word/role → discussion → reveal → replay | 2 |
| 4. Players/advanced rules | Rename/reorder; fixed/random imposters, never-start, teammates | 3 |
| 5. Complete question game | Private answers → common question → discussion → reveal → replay | 4 |
| 6. Saved players/imposter options | Save/select/details/rename/delete presets; imposter modal; question teammates; retain mode/categories/language | 4, 5 |
| 7. Content/image sync | Setup refresh, Storage word images, sync/cache recovery | 5 |
| 8. Custom word text | Create categories/words, bulk entry, immediate gameplay | 4 |
| 9. Custom question text | Create pairs and play complete question games | 5, 8 |
| 10. Custom images | Choose/capture/replace/remove, visible only to eligible viewers | 9 |
| 11. Settings/support | Persist VI/EN UI, version/ID, rating/feedback | 5 |
| 12. Content languages | DB language selection, correctly translated games, locale-specific cache/offline | 6, 7, 10, 11 |
| 13. Release readiness | Both games/all selected features in Android/iOS release | 1–12 |

Default order: 1 → 13. Preserve Phases 1–11; new Phase 12 covers content languages, old release phase becomes 13. After Phase 4, Phase 8 may precede Phase 5 if priorities change; Phase 6 needs Phase 5 for question teammates. Phase 7 is not required for play: Phase 2 already fully reads/caches `vi`. Phase 12 extends the same repository across locales without separate game logic.

Layout scope mapping:

| Layout sections | Responsible phase |
| --- | --- |
| 1–2: start/instructions | 1; updated rules in 4–5 |
| 3–4: setup/picker/imposter sheet | 2, 4; questions in 5; modal/question teammates in 6; sync/images in 7; content locale in 12 |
| 5: custom creation | 8–10 |
| 6–9: word/results | 3–4 |
| 10–14: questions/results | 5; private teammates in 6 |
| 15: players/saved lists | 4, 6 |
| 16: settings | 11; unified language in 12 |
| 17–19: shared layout/navigation/missing images/states | Every PR; overall reconciliation in 13 |

## 6. Phase details

### Phase 1 — App shell and instructions

**Proposed PR:** `feat(app): replace demo entry with game onboarding`

**Acceptance status 2026-10-24:** landing, instructions, theme, VI/EN, routing, and onboarding tests exist since `c77108b`; README/docs describe Signals/Store. Retain code, extend tests, and accept the behavior below rather than rebuilding features.

- Scope: screens 1/2, shared section 17; basic theme, SafeArea, scrollable content, bottom primary actions.
- Set entry to landing; add How to Play returning to its caller. Remove demo bottom navigation, keep RouterService; delete demo code only after callers are gone.
- Add Vietnamese ARB, update English strings and Signals/Store guides in `app/README.md`, `app/docs/`. Never manually edit generated localization.
- Touchpoints: `main.dart`, `features/landing`, `features/how_to_play`, router/utils, ARB, constants/theme, existing onboarding tests.
- **Acceptance:** cold start opens correctly; instructions scroll; system/UI Back work. `Start` clearly unavailable in foundation PR, without fake setup pages.
- **Checks:** preserve entry → instructions → back widget tests, VI/EN switching, small screens/large text in `app/test/features/onboarding_test.dart`.

**Acceptance results:**

- `flutter analyze --no-pub`: no issues; `flutter test --no-pub`: 27/27 passed, including 5 onboarding tests. Checked `Coming soon` in both languages and disabled Start; English instructions scroll to tips then return; 320×568, text scale 2 scrolls the tips heading into view without overflow. Widget tests cover UI/system Back.
- Debug smoke on iPhone 17 Pro Simulator, iOS 26.5, `APP_ENV=local`: temporary external script calls real `main()`, inspects widget tree, invokes navigation callbacks. Local config → Vietnamese landing → disabled Start → instructions → scroll to tips → `Navigator.maybePop()` back all passed without framework errors. No dependencies/product-code changes; automated, not manual physical-device use.
- Agreed acceptance scope excludes image capture/verification and demo images/videos for Phase 1. Android, physical devices, Release, and API calls remain unchecked; no image-based design matching. Existing illustrations retained, dark theme uses light palette, locale remains memory-only.

### Phase 2 — Word setup and backend categories

**Implementation status 2026-10-24:** Word setup supports 3–100 players,
All categories/Family mode tabs with draft selections, shared background loading,
snapshots, and separate JSON setup in Application Support by backend/locale.
Refresh failures preserve cache; setup read failures block writes until retry or
confirmed reset. Game start remains unavailable until Phase 3.

**Phase 2 evidence:**

- `flutter gen-l10n`, `flutter analyze`: successful, no issues.
- `flutter test`: **63 tests passed**, including pagination, eligibility, translation
  validation, duplicate IDs, empty replacement, cache/settings failures, serialized
  writes, picker confirm/back, retry, 320×568 at text scale 2.
- `flutter build ios --simulator --debug --dart-define=APP_ENV=local`: successful.
- `flutter test integration_test/setup_smoke_test.dart -d <iPhone-17-Pro-simulator-id>
  --dart-define=APP_ENV=local`: **1 test passed**, iOS 26.5 Simulator.
  Reads Local Supabase with publishable key, verifies no auth session, opens setup,
  selects category/count, recreates repository/store from real files with simulated
  offline networking. Not process kill/relaunch or actual airplane-mode testing.
- Read-only `supabase db query --local`: Vietnamese Food has **1 Classic / 0 Family**;
  Fictional Characters has **0 / 0** and is hidden. UI matches **1 / 0**; Family/multipage
  coverage uses fixtures without seeding/modifying DB.
- `flutter build apk --debug --dart-define=APP_ENV=local`: successful,
  output `app/build/app/outputs/flutter-apk/app-debug.apk`. Updated Kotlin 2.3.0,
  AGP 8.13.2, Gradle 8.13 for new native plugins; first build with old
  Kotlin 1.8.10 failed in `shared_preferences_android`.
- Normal iOS Simulator `flutter run`: startup/background loading succeeded;
  setup opened with 4 default players and 1 eligible word.
- Dev/Production, physical devices, Android runtime, gameplay not accepted yet.
  No images, player renaming, advanced rules, or manual refresh in this phase.

**Proposed PR:** `feat(app): add word setup with remote content`

- Scope: word portions of screens 3–4; 3–100 default-named players, one fixed imposter, Classic/Family, all/multiple categories.
- Reuse `AppConfig.current`/`APP_ENV`; initialize clients with validated URL/publishable key and existing anon reads, without admin login/service-role keys. Verify target translation schema first.
- Add section 4 models/repository: active categories + published `vi` category translations, base prompts + published `vi` word/question translations; select gameplay fields only. Filter translations at API, validate links/locale, fetch all pages stably, then atomically replace cache. No admin RPCs/dropped columns. Include question pairs for Phase 5 without exposing question selection yet.
- Start background fetch at landing/instructions, before setup, for weak-network situations. One fetch at a time; setup reuses pending results.
- Network/API failures use same-backend/locale cache, otherwise error/retry; no bundled fallback. Mid-page failures cannot partially write cache; successful empty results replace old snapshots. Setup shows loading/error/empty and Vietnamese content until Phase 12.
- Enable landing Start to setup; picker drafts apply only on `Confirm`, Back discards. Persist basic setup with read/write error handling.
- Touchpoints: setup/categories, data/content, DI/config, cache/settings, router, ARB, Android internet permission, `pubspec.yaml`/lockfile if needed.
- **Acceptance:** `vi` category/prompt counts match new-schema backend filters across pages; mode changes remove invalid IDs; setup survives restart; offline after first fetch remains configurable. Game-start button clearly unavailable until Phase 3, other setup actions work.
- **Checks:** unit tests for type/mode/status/active categories, unions, pages, empty sets. Fixtures include shared base IDs with VI published/EN draft and reverse; VI-hidden/EN-public categories; missing translations; no duplicate IDs or EN leakage. Invalid/incompatible payloads and middle-page errors preserve cache; HTTP simulation covers network/no-cache errors; read-only local/dev checks verify anon base/translation access. Widget picker confirm/cancel/retry/setup restore.

### Local storage update — Hive CE (2026-10-25)

- Setup/players and content snapshots now use `settings` / `content_cache` boxes
  at `<ApplicationSupport>/hive/`. Each record is JSON with `version: 1`, `scope`,
  `data`; scope keys retain environment + normalized backend URL + content locale (`vi`).
  Signals owns state; Riverpod provides shared `HiveLocalStorage`; no adapters,
  generators, or box opening that blocks `runApp`.
- `SetupStore`/`ContentRepository` use `LocalJsonStore`. Storage lazily opens boxes,
  shares opening, retries failures, serializes operations, and awaits `put()`.
  Riverpod disposal hands setup writes to storage; storage drains before closing.
  Cache read errors can retry immediately offline.
- Missing Hive keys read legacy `content/<scope-base64>/setup.json` or
  `snapshot.json`, validate version/scope and `GameSetup.fromJson` /
  `ContentSnapshot.fromJson`, then write Hive. Only successful writes establish
  migration; no marker. Existing Hive always wins; corrupt Hive reports errors,
  without JSON fallback. Read/write failures never automatically delete/reset.
- Retain old JSON for manual recovery, without updating after migration. JSON-only
  app rollback sees migration-time data, missing newer Hive changes. No multiple
  rosters, saved games, UI locale, accounts, sync, or encryption added.
- Fakes now use interface-based `MemoryStorage`. Real temporary Hive tests cover
  restart/scopes/open retry, valid/missing/invalid version/scope/data/JSON migration,
  failed `put()` then restart, Hive priority over JSON, corruption, drain-on-close,
  and Riverpod lifecycle.
- Checks: clean `flutter analyze`; **110/110 unit/widget tests passed**. `word_game_smoke_test.dart`
  **2/2 passed** on iPhone 17 Pro Simulator iOS 26.5: import both old JSON files,
  close/reopen, restore players/rules, offline play, vote/replay/back for normal/advanced
  settings. No signal-after-disposal warnings in the final run.
- `setup_smoke_test.dart` now uses Hive with setup migration and close/reopen before
  offline restore; not rerun because local backend fixtures were unconfirmed
  (1 Classic word, 0 Family, fixed category name). No backend seeds/changes.
  Phase 2–4 JSON/smoke evidence below predates Hive.
- Retained existing merged Players tile changes. No UI images; physical devices,
  Android runtime, Release, process kill/relaunch, actual airplane mode unchecked.

### Phase 3 — First complete word game

**Implementation status 2026-10-24:** connected setup → player list → secret card
→ discussion → vote sheet → results → replay. Session lives in one route,
snapshots setup/content, assigns exactly one imposter and randomizes starter once
from all players. Imposter category display is disabled in this phase.

**Agreed decision:** group votes verbally; sheet records exactly one person.
Correct imposter means group wins, otherwise imposter wins; ties require revoting
before confirmation. Cancel reveals no roles. Layout/VI–EN instructions updated.

Card Back returns without completion; in-game Back confirms ending;
results Back returns to setup. Backgrounding conceals, return requires reveal.
`Play again` destroys session and retains setup; starting again uses current
eligible content. No disk sessions; word images remain Phase 7.

**Phase 3 evidence:**

- `flutter gen-l10n`, `flutter analyze`: successful, no issues.
- `flutter test`: **72 tests passed**: seeded roles, immutable snapshots,
  stage guards, correct/incorrect voting, sheet cancel, back/cancel, duplicate start,
  replay with empty content, lifecycle/semantics, VI/EN, 100 players,
  320×568 at text scale 2 through voting/results.
- `flutter test integration_test/word_game_smoke_test.dart -d <iPhone-17-Pro-simulator-id>
  --dart-define=APP_ENV=local`: **1 passed**, iOS 26.5 Simulator.
  Real JSON cache fixtures in a test directory, simulated offline source,
  full game → vote → results → replay/setup → start new game → exit/setup.
  No backend calls, seeds, actual airplane mode, or process kill/relaunch.
- `flutter build apk --debug --dart-define=APP_ENV=local` and
  `flutter build ios --simulator --debug --dart-define=APP_ENV=local`: successful.
- No UI image capture/verification per project rules. Physical-device gameplay,
  Android runtime, Release unchecked; multiple imposters/advanced rules remain Phase 4.

**Proposed PR:** `feat(app): ship playable word game loop`

- Scope: screens 6–9 using Phase 2 setup and one imposter. Enable real session creation.
- Randomize prompt/roles once; default player list → concealed card → word/role → `Got it!`. Only revealed civilians see word/category; hidden headings/semantics leak nothing. Images in Phase 7.
- Advance only when all complete; show starter. `Announce results` selects exactly one verbally voted person, confirms, then reveals roles/word/winner. No individual ballots; sheet/single-imposter rules finalized in layout per section 3.
- Replay destroys session, retaining setup; only setup start creates another. In-game Back safely returns to list or confirms ending, never reopening completed reveals. Backgrounding conceals.
- Touchpoints: word_game, shared session, content repository, routes, ARB; no backend game tables.
- **Acceptance:** 3+ players complete games, including airplane mode after successful content fetch; no reopened cards, rebuild randomization, rapid taps confirming two people/creating two games.
- **Checks:** seeded/fake random tests for one role, early-stage rejection, correct/incorrect wins; full widget/integration flow, canceled voting, back, pause/resume, replay retention. No flaky probabilistic distribution tests.

### Phase 4 — Player names and configurable rules

**Implementation status 2026-10-25:** roster editor supports trim, add/delete,
up/down ordering, drafts/discard confirmation, stable IDs, persistence, and
Phase 2–3 compatibility. Saved lists remain Phase 6.

**Agreed with user:** no separate hints; uniform fixed/random in
1…floor((N−1)/2); choose starter first and exclude under never-start; group wins
only by selecting all K imposters exactly. Category/teammate names appear only
on revealed imposter cards. VI/EN instructions/layout updated.

**Phase 4 evidence:**

- `flutter gen-l10n`, `flutter analyze`: successful, no issues.
- `flutter test`: **89 passed**: fixed/random boundaries 3/100, reduced N,
  legacy/corrupt data, duplicate names/trim/IDs/order, draft cancel/confirm,
  never-start, incomplete/correct/wrong sets, teammate privacy.
- Editor/settings sheet widget tests at 320×568, 844×390, 1024×768,
  text scale 2; one-imposter regression and full two-imposter game.
- `flutter test integration_test/word_game_smoke_test.dart -d <iPhone-17-Pro-simulator-id>
  --dart-define=APP_ENV=local`: **2 passed**, iOS 26.5 Simulator.
  One/two imposters (never-start, category display, teammates), full vote/results/
  replay/new game/exit. Real test JSON cache with simulated offline networking;
  no backend, seeds, process kill/relaunch, or actual airplane mode.
- No UI images. Physical devices, Android runtime, Release unchecked;
  no schema/plugin/native configuration changes in Phase 4.
- After merging player controls: clean `flutter analyze`, **90 tests passed**;
  setup integration now uses the roster editor but was not rerun on simulator.

**Proposed PR:** `feat(app): add roster editing and imposter options`

- Scope: current roster in screen 15 and remaining setup/sheet, excluding saved lists.
- Setup **Players** opens the roster editor directly; remove separate **Edit players** and count increment/decrement sheet. Display confirmed roster count; canceled drafts keep it unchanged. Reducing players clamps imposter count.
- Rename/add/delete/order 3–100 players; trim/reject empty names. Stable IDs prevent duplicate-name role/answer mixups; default new names depend on current roster.
- Fixed/random counts, N-dependent validation/clamping, never-start, category display, teammates. Teammates appear after reveal without words/images.
- Finalize hint/multiple-imposter rules before exposing UI; update instructions. Extend voting/results for K imposters without dropping Phase 3 win/loss behavior.
- Touchpoints: setup, player_names, assignment, local settings, word reveal, ARB, Phase 3 tests.
- **Acceptance:** configured full games, correct displayed starter never imposter under constraint, no invalid sessions.
- **Checks:** 3/100 boundaries, fixed/random/reduced N, duplicate names/order/never-start, correct/incorrect/incomplete vote sets; editor CRUD and timely teammate visibility widget tests.

### Phase 5 — Complete question game

**Implementation status 2026-10-27:** question setup/picker uses existing repository/
cache pairs, persists game type in Hive, and supports players → private questions/
answers → common question → discussion → reveal → replay. Phase 4 roster,
fixed/random counts, never-start are shared; word voting/wins remain unchanged.

**Agreed Phase 5 scope:** no role/teammate disclosure; identical locked cards.
Pre-submit Back retains ID-scoped RAM drafts visible only after that player's
reveal; submit trims/rejects empties and locks completion. Backgrounding conceals
question/input and dismisses focus. Questions directly reveal all imposters and
alternate questions, without vote sheets/winner calculation. No backend answers
or disk sessions/drafts. Old word settings preserved; default type is word.

**Planned Phase 6 extension:** question teammate option/revealed-card disclosure
under conditions below. Phase 5 evidence does not validate this extension.

**Phase 5 evidence:**

- `flutter gen-l10n`, `flutter analyze`: successful, no issues.
- `flutter test`: **118 passed**: game type/legacy setup, type/mode filtering/
  counts/categories, fixed/random 3/100 boundaries, IDs/duplicate names, snapshots,
  private drafts, trim/empty rejection, repeated submit, stage guards.
- Full Classic/Family question widgets, VI/EN, light/dark, 320×568/844×390,
  text scale 2; keyboard insets/semantics, pause concealment, per-player drafts,
  submission locks, multiple-imposter reveal, back/cancel/end, replay/word switch.
- iPhone 17 Pro, iOS 26.5 Simulator:
  `flutter test integration_test/question_game_smoke_test.dart -d <simulator-id>
  --dart-define=APP_ENV=local`: **2 passed**, both modes using real Hive after
  close/reopen and simulated offline source → answers → discussion → reveal →
  replay → new session → exit/setup.
- Same-simulator `integration_test/word_game_smoke_test.dart`: **2 passed**,
  one/multiple imposters, voting/wins/replay preserved.
- No UI images or schema/plugin/native changes. Dev/Production, physical devices,
  Android runtime, Release pending. Smoke offline is simulated, not airplane mode
  or process kill/relaunch. Target needs published Vietnamese questions for real-content acceptance.

**Proposed PR:** `feat(app): add private question game loop`

- Scope: screens 10–14; enable correct type/mode in setup/picker. Reuse roster/session/random/content layers.
- Choose one pair from the same selected-locale `question_prompt_translations` row joined through repository. Civilians get `civilian_question`, imposters `imposter_question`. Conceal first; current-player-only input; trim/reject empty/repeated submits.
- Submitted players lock, counter advances, no edits/review; common question appears only after all answers.
- Discussion reveals names/answers, hiding alternate question until results; reveal marks all imposters and their questions. Replay retains setup; new start regenerates roles/answers.
- Touchpoints: question_game, setup/category mapping, session stages, ARB, local fixtures; no backend answers.
- **Acceptance:** complete Classic/Family setup-to-replay; no early discussion; game switches retain no old answers/session.
- **Checks:** assignment/stage/answer validation units; multi-player handoff, pause concealment, double submit, pre-reveal privacy, replay reset widget/integration tests.

### Phase 6 — Saved player lists and imposter options

**Proposed PR:** `feat(app): manage player presets and imposter options`

**Implemented 2026-10-27; evidence below:** keep Phase 6, depending on Phases 4–5; no Phase 4.1 or renumbering. Scope: screen 15/preset management, imposter setup modal for both games, and question teammates. References supply structure/interactions; colors, typography, components, code follow current app rules.

#### Imposter modal and question options

- **App style rules:** references guide layout/interactions only. Colors, typography, spacing, radii, icons, selection, modal overlays, light/dark use `AppTheme`/`AppColors`, constants, existing components; no copied or separate reference styles.
- Setup `How many imposters?` opens `Choose imposters` bottom sheet with dim backdrop and icon/title as in `IMG_2987.PNG`. Reuse existing word/question entry without a separate route.
- Replace random switch with mutually exclusive radio cards: `Fixed` — `Choose the exact number of imposters`; `Random` — `Random imposter count each game`.
- Selected Fixed shows `−`, large count, `+`, range. Use 1…floor((N−1)/2), disable boundaries, never hardcode reference `1–3`. For 3–4 players, warn that 5+ are needed for multiple imposters. Mark `1` as `Recommended`, without another recommendation formula. Random collapses controls but retains fixed draft count; randomize once at game start.
- Move `Imposters never start` to modal bottom, removing setup duplicate. Reuse `imposterNotFirst`/Phase 4 `startingPlayerId`. Count/method/switch share a draft: Confirm saves together; Back/drag/outside dismiss discards. Active presets update only after successful confirmed persistence; errors retain drafts.
- Following `IMG_2986.PNG`, show `Imposters know each other` in category/options for **both word/question**, Classic/Family. Share `knowEachOther` across game switches/presets/replay, legacy default `false`. User update 2026-10-27: `Show category to imposters` also supports both games. Question civilians see category; imposters only with enabled option and revealed private card. Snapshot at game start.
- With question `knowEachOther` and 2+ imposters, only revealed imposters see other imposter names, excluding self by ID even for duplicate names. Civilians, locked cards, handoff lists, discussion expose no roles/teammates. Never expose opposing questions or others' private answers. Disabled/single-imposter retains Phase 5 no-disclosure behavior.
- Background, Back/player switch, submit conceal teammates with question/input; only the correct revealed card reopens them. Session snapshots `knowEachOther`, unaffected by later setup. VI/EN instructions explain private teammate disclosure; preserve question direct-reveal/no-vote/no-winner flow.

#### UI flow

- **Player editor:** top preset card before count/roster, folder icon, selected name or `Unsaved game`, sheet affordance; full card tappable. Keep Phase 4 rename/add/delete/up/down, 3–100, Confirm.
- **Preset sheet:** `Saved lists`, `Unsaved game` quick-play description, saved names/counts/checks reflecting draft. Bottom `Save as list…` / `Manage lists`. Selection loads draft and closes; dismiss keeps draft.
- **Save as list:** close sheet before `Save as new list…`; `List name`, `Enter list name`, Cancel/Save. Use draft roster/rules, not old setup. Trim/reject empty/case-insensitive duplicate names. Validate roster first, never save empty player names.
- **Management:** close sheet then route to `Manage lists`; Back retains editor draft. Cards show icon/name/count/`In use` from confirmed setup/vertical ellipsis. Empty guidance returns to editor to save the first preset; no dead-end buttons.
- **Ellipsis:** anchored popover with Details/Rename list/divider/error-colored Delete. Menu taps must not trigger cards; close before opening sheets/dialogs.
- **Details:** card tap or Details opens the same read-only sheet without switching. Summary name/count, ordered player chips, saved rules/autosave note. Show fixed count or Random, never session's sampled count.
- **Rename:** prefilled dialog, creation validation excluding itself. Cancel preserves data; successful persistence updates editor/selection/management/details names without changing ID/roster/rules.
- **Delete:** named confirmation, cancel/delete. Delete only after successful confirmation/persistence; retain other presets.
- Reuse `AppTheme`/`AppColors`, `AppContent`, constants, Material widgets; no reference purple/dark palette or separate hardcoded style. Scrollable, keyboard-safe, SafeArea, accessible icon labels; footer wraps when narrow. Selected/in-use uses text/checks, not color alone.

#### Data and application timing

- Presets store stable ID/name, roster IDs/names/order, next player-ID counter, `imposters`, `randomImposters`, `imposterNotFirst`, `showCategory`, `knowEachOther`. Reuse N-based validation/clamping after player reductions.
- Exclude game type/mode/category IDs/UI/content locale/custom content/session. Selection changes only roster/rules, preserving setup's remaining choices. Since Phase 6 both `knowEachOther` and `showCategory` apply to word/question.
- Details show fixed/random count, never-start, category display, teammates. Omit `Show imposter count`; no extra switch to match references.
- Editor drafts roster/rules/preset ID. Choosing presets only changes drafts, never setup/old presets. Confirm applies setup and updates selected preset if still present. Dirty Back asks to discard, preserving prior confirmed setup/preset.
- `Unsaved game` retains draft roster/rules, clears linkage only on Confirm, never deletes/overwrites the departed preset.
- Save as list immediately persists a new preset and selects it in draft without switching setup. Later discard leaves the new library entry and prior setup selection.
- Setup rule changes autosave to the confirmed active preset. Player changes update only on Confirm, never each keystroke/add/delete/reorder.
- Deleting active presets preserves setup roster/rules and switches to Unsaved game. Drafts retain content but clear deleted linkage; old confirmation cannot resurrect deleted presets. Renaming preserves drafts.
- Active sessions retain role/prompt/progress snapshots independently of library actions.

#### Storage, errors, integration

- Reuse Hive CE, `LocalJsonStore`, write queues, storage lifecycle; no new dependency/backend/state mechanism. Follow feature model/store structure, Signals/Riverpod DI, existing `RouterService` registry.
- Atomically persist setup/active-preset ID/library when related; restarts cannot show deleted active presets or mismatched rules. Serialize old/new writes; drain before closing storage.
- Phase 2–4 setups without library/link restore empty library/Unsaved game and original roster/rules. Keep JSON → Hive migration without deleting legacy files or resetting users.
- Explicit loading/read-error/retry; missing differs from corrupt. Read failures never silently reset/overwrite; block dependent writes until read/validation succeeds.
- Write failures retain forms/drafts/retry data; no success/closing before persistence. Prevent repeated submissions; failed rule autosaves report unsaved/retry, not durable memory-only changes.
- Touchpoints: player_names, preset feature, setup_screen/store/model, question_game snapshot/teammates, Hive/storage/migration, providers/routes, instructions, VI/EN ARB/tests/fixtures. Never manually edit generated localization; keep layout/instructions consistent.

#### Acceptance and checks

- **Acceptance:** editor create → confirm → edit rules → switch → details → rename/delete → close/reopen storage preserves correct data. Presets do not alter type/mode/categories/language; details do not switch; no loss of other presets or active-session changes.
- **Unit:** serialization/validation, trimmed/empty/case-insensitive duplicate preset names, duplicate player names with distinct IDs, order/counters/3–100 limits. Fixed/random/reduced N, draft selection/confirm/cancel, unsaved mode, create then discard, correct preset autosave.
- **Storage:** old setup/JSON → Hive; actual close/reopen with library/link/rules. Read/write failures/retry/duplicates/serialization/dispose; corrupt data preserved, deleted presets not restored by stale drafts.
- **Widgets:** preset card → sheet → create/select/unsaved → management → popover → details/rename/delete. Cancel, active deletion, rename with open draft, empty/error/loading, keyboard/labels/small screens/text scale 2. Menu must not also open details.
- **Modal:** both game entry points, Fixed/Random, count boundaries/reduced N/method retention, never-start, confirm/cancel/autosave. Small/large-text layouts scroll to Confirm with readable selection.
- **Question teammates:** on/off, one/multiple, fixed/random, duplicate names/distinct IDs, correct revealed card only, no civilian disclosure; pause/resume/back/submit/player changes conceal. Persist/load presets, game switches, snapshots/replay; full Classic/Family VI/EN without early alternate questions.
- Run `flutter gen-l10n`, `flutter analyze`, `flutter test`; regress both games after preset loads and replay retention. No screenshots/image verification required for Phase 6; evidence is code inspection/static analysis/automated tests.
- No login, cross-device sync, extra rules, or saved games. Implementation evidence below.

**Phase 6 verification (2026-10-27):**

- Added same-record preset library, stable IDs/counters, roster/rule/link drafts, management route/details/rename/delete, active-rule autosave.
- Queue derives operations from committed data and publishes only after successful writes; read errors allow retry without reset. Disposal drains queue; JSON migration preserves old files and validates library/link.
- Fixed/Random modal drafts count/never-start; teammates/category display support both games. Questions render ID-filtered teammates only on revealed imposter cards; background/back/submit conceal; snapshots/replay retained.
- `flutter gen-l10n`, `flutter analyze`, `flutter test` succeeded (current counts in `app/README.md`). Coverage: complete preset lifecycle, failures/retries/serialized writes/disposal, migration/real Hive reopen, small/large-text/keyboard, semantics/question privacy, both games after preset loading.
- No image checks, device smoke, or real-backend integration; automated tests do not establish physical-device behavior.

### Phase 7 — Complete content and image synchronization

**Proposed PR:** `feat(app): harden content sync and word images`

**Implementation/evidence 2026-10-27 (`app-phase-7`):**

- Added shared `load()` setup refresh, 15-second/page timeout, snapshots retained on failure, stale marking even after previous success. Valid empty replaces cache; cache-write failure warns about persistence only. Cache reread cannot replace newer memory content after a subsequent download failure.
- `WordImageCache` uses Application Support, normalized backend + path, independent of locale without stored signed URLs. Restore existing images before queueing missing downloads; 300-second signing, timeout, 5 MiB, MIME/decode, temp + rename, one expiry/unauthorized renewal. Individual failures wait for next startup/refresh.
- Hive read-only inventory covers all backend snapshots/legacy JSON. Cleanup serializes with downloads and rechecks inventory/current snapshot/session pins before deletion; inventory errors skip pruning. Pin before navigation, release on route failure too. No setup/preset/migration/RLS/schema changes.
- Revealed civilians/results show local word images, stable placeholders on errors, text-only without paths. Hidden/imposter/player-list/discussion expose no image semantics. Refresh never changes either game's prompt/locale/category/roles/progress.
- Successful `flutter gen-l10n`, clean `flutter analyze`, **175 tests passed**, 10 HTTP/live opt-in skips. Coverage: pages/middle failure/late responses/corrupt-empty cache/write failure/recovery, backend separation/locale sharing/restart/cleanup/pins, late/file/decode images/concealment, route failures, category removal, both themes/small/text scale 2.
- Postman local HTTP simulation: **8/8 cases, 57 requests** final run. Real client exercises REST offsets 0/2, JSON 500, HTML 502, malformed payloads, timeout/late response, 300-second signing, expired GET → resign → GET 200, Storage GET 500. Code/instructions: `postman/simulations/phase-7.context.md`; env `SUPABASE_SIMULATION_URL`, no hardcoded backend test address.
- Anonymous local read-only: **14 categories, 52 words, 52 question pairs**; valid `vi`, all returned translations published, nonexistent path signing rejected. Current data has no image paths, so eligible-image downloads/other-locale eligibility remain unverified on real backend. **Dev inaccessible/denied**, unverified; no backend writes.
- Remaining: physical devices/Release/screenshots not run. Valid image permissions and other-locale scenarios need available backend/data. Offline content may remain stale until successful sync.

- Scope: harden Phase 2 repository/API/cache without game UI/rule changes. Fetch gameplay fields only, no creator/admin information.
- Preserve base + same-locale published translation contract; regress complete pagination before counts/randomization. No old-schema queries or extra locales on sync.
- Network/timeout/mid-page/invalid-payload failures preserve good cache; latest cache fallback or error/retry, without bundled content. Valid empty results are empty, not network failures.
- Refresh at startup/setup; ongoing sessions retain locale/names/prompts. Archived/deleted translations/prompts, disabled categories, or unpublished category translations disappear from refreshed locale caches for future games. Other published locales do not keep hidden translations eligible. No immediate offline revocation promise.
- Word images: private `word-prompt-images`; public eligibility requires at least one published prompt translation with public category in that locale, not base status. Shared image access does not establish selected-locale gameplay eligibility.
- Never cache by signed URL. After valid content sync, sign/download to app storage using backend + `image_path`, changed on replacement. Skip existing files; delete only when no locale cache/current session references them. Renew expired URLs online; archiving cannot immediately revoke issued URLs/offline bytes.
- Download in background; image failures do not break content sync. Missing gameplay files show placeholders, without blocking game start until all images arrive.
- Touchpoints: data/content, cache, setup refresh/error/retry, word images. Do not change RLS when existing reads suffice.
- **Acceptance:** both games use real `vi` without drafts/archived/wrong-locale/mode/inactive-category leakage; offline cache works; updates never rerandomize active sessions.
- **Checks:** multipage/partial failure/corrupt-empty cache/hidden translation-prompt-category/image tests; pinned session images retained. HTTP simulations for errors plus read-only local/dev anon/filter checks, including images public through other locales. No production fixture writes.

### Phase 8 — Custom word text

**Proposed PR:** `feat(app): create local custom word categories`

**Implemented 2026-10-27:**

- Creation available from both word tabs without backend snapshots. Last grid tile matches dimensions/borders/spacing with light-blue action background. Name/add/delete/bulk form trims, ignores blanks, deduplicates case-insensitively retaining first spelling. Reject same-locale remote/custom word names including outside Family. No custom images/questions yet.
- Stable local category/prompt IDs, `contentLocale = vi`, no uploads. Atomically persist with setup through Hive/queue; legacy defaults empty, excluded from presets/remote cache. SetupStore combined catalog drives picker/count/random and word session name/text snapshots; refresh neither changes sessions nor deletes custom content.
- Saving only adds ID to current-tab picker draft while retaining selections. Confirm applies; picker Back discards selections but retains saved category. Dirty form exit confirms; failures retain for retry.
- Family creation requires checkbox, usable in both tabs; All-created categories stay outside Family. Game/tab switches preserve content across restart/replay; only confirmed setup → landing clears content/matching IDs. Clear failures retain screen/data; other players/presets/settings remain.
- Successful l10n, clean analyzer, **206 tests passed**, 10 opt-in skips. Added 20 tests: parse/validation/IDs/filter/selection/preset/save errors, Hive reopen, forms/dialog guards, picker drafts, suitability/tabs, custom-only offline full game/replay, setup-exit clearing, VI/EN layout/semantics at 320×568/text scale 2/keyboard/both themes. No screenshots, physical/Release checks, or new backend verification; no API/backend/dependency changes.

- Scope: screen 5 word text; enable `Create custom`. Record creation `contentLocale` (currently `vi`), never treat user input as translated for every language.
- Name/add/delete/bulk; trim/ignore blanks/deduplicate case-insensitively while preserving display. Reject duplicate names rather than overwrite; no saving without valid words.
- Drafts/discard confirmation; only successful saves add/select in picker. One/multiple/random rules combine remote/cache/custom without duplicate IDs.
- Apply finalized lifecycle/Family decisions in section 3; no backend input or image actions yet.
- Touchpoints: custom_content, picker, local repository/session content, ARB, word reveal/replay.
- **Acceptance:** create and immediately play words; replay follows lifecycle; canceled forms leave no partial categories.
- **Checks:** bulk/duplicates/trim/names/IDs/Family units; unsaved guard/save errors/post-save selection/single-word category widgets.

### Phase 9 — Custom question text

**Proposed PR:** `feat(app): create local custom question pairs`

**Implemented 2026-10-27:**

- Extend Phase 8 route/form by game type, including offline creation. Pair lists show both role labels/count/delete/single-pair/two-multiline import. Shared name/save/error/discard/layout; no question Family.
- Immutable `CustomQuestionEntry`/`CustomQuestionCategory`, JSON, `custom-question-N` IDs; old setup defaults empty/counter 1. Parser preserves blank rows, accepts LF/CRLF/trailing newline, identifies empty/identical/mismatched/ordered-duplicate lines, never partially imports.
- `SetupStore.eligibleQuestions` combines sources for picker/count/start/random; session resolves catalog names without remote snapshots. Recheck names by game/locale and allocate IDs in queue; failures preserve counter/draft. Exclude from presets/cache; clear both types atomically on confirmed setup exit.
- Evidence: `app/test/features/setup/custom_question_categories_test.dart` (parser, JSON/legacy, IDs, queues, name/game/locale, catalog/session, preset, atomic clear); `custom_word_screen_test.dart` (form/errors/discard/draft, offline full game/replay VI/EN, privacy/semantics/layout/keyboard, word regression); `app/test/data/hive_local_storage_test.dart` (reopen).
- Final: successful l10n, clean analyzer, **219 tests passed**, 10 opt-in skips (13 added since Phase 8). No images, new APIs/backend/dependencies, or screenshots; physical devices pending.


- Scope: extend Phase 8 forms with shared name/validation/draft, no images.
- Require two different trimmed, case-insensitive questions; never reuse one for both roles or invent the other.
- After section 3 UX agreement, bulk pairs by line index; mismatched/invalid rows show errors without silent partial saves.
- Same lifecycle/selections as Phase 8; standard question picker, Family confirmation/filter word-only. Connect existing question game/results.
- Touchpoints: custom_content, pair model, picker, assignment/reveal, ARB. No backend columns for local data.
- **Acceptance:** custom questions never appear in words; groups receive correct questions; alternate questions reveal only in results.
- **Checks:** empty/duplicate pairs, missing/blank/duplicate batch rows; form → save → complete game → replay widgets, custom-word regression.

### Phase 10 — Custom content images

**PR:** `feat(app): attach local images to custom prompts` — implemented, physical-device acceptance pending.

- Creation uses `image_picker: 1.2.4` via Riverpod: library/camera add/replace, source-sheet removal, canceled picks retain old images. Single word/pair dialogs have optional images; bulk is text-only with later per-item images. Thumbnails sit below content for narrow screens. Category tiles only say `Has images`, exposing no secrets.
- Preserve `CustomWordCategory.words`; add immutable `imageIds` map keyed by exact saved text, rejecting unknown keys. `CustomQuestionEntry.imageId` shares one image per pair; duplicates compare question text only. Local prompts use `localImageId`, separate from remote `imagePath`; legacy defaults empty/null without ID/counter/preset/cache changes.
- `LocalImageStore` copies decodable images ≤5 MiB into `Application Support/custom-images` via temp/rename. Random relative IDs reject absolute/traversal paths; never delete library source files. Canceled/failed picks/decode/write preserve old images. Category/image references persist in one setup record; failed saves retain full drafts.
- Import/setup writes/cleanup share queue. Inventory covers all Hive scopes/backends/locales and unsuperseded legacy JSON; unsafe inventory skips pruning. Retain open-draft/pending-save/session images until routes exit. Replace/delete/discard/successful category clear release references; failed clear retains files. Orphan-delete failure does not fail save; retry next startup/cleanup.
- Words honor session **Family + Show images**: revealed civilians/results only. Questions show shared images below revealed current-player questions; **results only** publicly show once below civilian question. Handoff/hidden/common-question/discussion have no image widgets/semantics. Conceal/background/submit/Back/player changes remove private content. Generic question-image labels reveal no role/opposing question. Missing/corrupt files show placeholders without blocking play.
- Lock editing/navigation during picker/import/save; post-disposal results cannot attach to other items and release orphan files. VI/EN errors distinguish denied/restricted permission with system Settings guidance, unavailable camera, unreadable/oversized images, storage writes. iOS Photos/Camera descriptions; Android plugin system picker, startup `retrieveLostData()` discards orphan results and reports lost drafts without attaching to new items.
- Drafts are RAM-only; Android process death does not restore them. Saved categories/images survive offline/replay/restart under Phases 8/9; no uploads/backend/schema changes.
- **Automated evidence (2026-10-27):** model legacy/round-trip/invalid IDs/immutable maps/image-independent pair duplicates; Hive reopen/multi-scope-locale-legacy inventory; file copy/replace/oversize/corruption/disk failures/cleanup races/draft-save-session pins/category clear failure-success. Word/question widgets include dialog images, replace/delete/cancel/permissions/save retry/late disposal; offline reveal/results/replay, three word Family/image configurations, question VI/EN stage/lifecycle privacy, 320×568/text scale 2/keyboard/light-dark through widgets/semantics without screenshots. l10n complete, analyzer clean, **237 passed / 10 existing skips**. Android debug/release APK and iOS release `--no-codesign` built successfully.
- **Incomplete acceptance:** real Android/iOS required for library/camera/permissions/cancel/restart persistence; Android also needs picker interruption by process death. Builds/simulators cannot replace these.
- Out of scope: editing saved categories, cropping, uploads, backend/schema, draft recovery, screenshots.

### Phase 11 — Settings, UI language, and support

**Proposed PR:** `feat(app): add settings and support actions`

**Implemented 2026-10-27; real store/feedback configuration pending:**

- Settings opens from setup; `AppStore` selects/persists/restores VI/EN without changing
  content locale `vi`. Existing instructions route returns to the correct caller.
- UI locale and anonymous installation ID use versioned records in separate Hive box;
  read failures preserve data, write failures retain values/retry. Generate local 128-bit
  ID once, abbreviate display/copy full. Version/build from `package_info_plus`.
- Missing URLs/app IDs/feedback channels leave both actions disabled with reasons;
  no fake URL/link launcher. Actual device link launching not accepted yet.
- l10n and `flutter analyze --no-pub` succeeded; `flutter test --no-pub`:
  **256 passed**, 10 opt-in skips. Android debug APK/iOS Simulator debug built.
  No backend/physical devices/screenshots; worktree builds use separate placeholder env.

- Scope: screen 16/language screen from setup; reuse instructions from landing/settings.
- Choose VI/EN from `AppLocalizations.supportedLocales`, update `AppStore.locale`/MaterialApp/strings immediately, persist/restore locally; no manual generated l10n edits. This is `UI language`; game stays `vi` until Phase 12 with clear setup label. Never use UI locale as API/cache filter.
- Actual version/build, one local anonymous ID with abbreviated display/full copy; no account/device identifier collection.
- Use supplied store URLs/app IDs/feedback, handling launch failure/no receiving app. Without config hide/explain; never fake URLs.
- Touchpoints: settings, i18n, `main.dart`, local settings, metadata, platform/link config, ARB. Active sessions unchanged.
- **Acceptance:** UI language survives restart, instructions return correctly, stable/full clipboard ID, correct platform links. English UI still plays labeled Vietnamese content.
- **Checks:** locale/restart/copy widgets with fakes; physical store/feedback launch; UI changes do not alter content queries/cache/sessions.

### Phase 12 — Shared UI and content language

**User-requested revision 2026-10-28:** merge UI/content into **one Language option**, superseding separate choices.

- English changes UI/categories/prompts to EN; Vietnamese changes both to VI. DB `content_languages` supplies names/codes/order, restricted to `AppLocalizations.supportedLocales`. DB locales without UI ARB remain hidden, preventing unusable UI choices.
- `GameSetup.contentLocale` is the persisted source for MaterialApp/repository. Legacy `ui_locale` stays with installation-ID data for storage compatibility but no longer controls UI. Change both only after successful setup write; errors retain old selection/retry.
- Remove separate UI-language row/screen. Language links in Settings/setup/picker. No in-game changes; sessions retain names/prompts/locale; replay uses persisted setup.
- Keep old setup key to retain players/presets/custom/images; presets never store/overwrite locale. Language cache by environment/backend, snapshots by environment/backend/locale. `SetupStore` survives switching; late responses cannot replace current-locale data.
- Await correct-locale snapshots before confirm/start. Offline uses same-locale cache, never fallback for missing/empty. Retain eligible IDs/update names; remove invalid IDs with notice, none means All categories. Picker drafts cancel even VI→EN→VI before a frame.
- Custom content/drafts keep creation/form locale. Images share backend/path caches; inventory all locales/session before cleanup. No dependencies/migrations/seeds/admin APIs added.
- Phase 12 read-only anon evidence: local `http://127.0.0.1:54321`: `vi` 13 categories/27 words (25 Family)/26 question pairs, `en` 13/25 (25 Family)/25. Dev `https://pxycsjwjakzehcuygngv.supabase.co` inaccessible/denied within 5 seconds; unaccepted. No DB test writes.
- Updated checks: one selection changes UI/game, failed saves change neither, picker discard, session/replay, cache/restart, small/large-text/semantics. Repository still tests a third DB locale via fixtures; picker hides unsupported UI locales. No screenshots.
- After revision: l10n successful, clean analyzer, **274 passed / 12 opt-in skipped**. Debug build/start on iPhone 17 Pro Simulator succeeded without screenshots. Physical devices pending.

### Phase 13 — Release preparation and verification

**Proposed PR:** `chore(app): prepare mobile release and verify game flows`

- Reconcile every agreed screen/state with layout; review consistent wording, SafeArea, scrolling, keyboard, focus, screen readers, text scaling, bottom actions. Earlier phases still need basic accessibility.
- Replace `untitled`/demo branding with approved name/assets; configure application/bundle IDs, version/build, release environments. Package-ID changes update Kotlin package/MainActivity, Gradle, related iOS settings together.
- Build Android/iOS Release; verify permissions/TLS against target backend, image/link plugins in Release, no accidental dev HTTP config.
- Verify no privileged source/bundle keys or role/answer logs; no bundled content and correct release backend. Preserve local data across upgrades, especially presets/setup.
- Touchpoints: actual integration bugs, native config/assets, test/integration_test, build/UAT guides. Do not defer missing earlier features into this PR.
- **Acceptance:** VI/EN and DB content languages; both games/modes, presets/custom/images/replay/offline/refresh pass Android/iOS checklists. Release backend has translation schema/eligible published data; no demo routes/buttons.
- **Checks:** analyzer/tests/integration smoke and installed Release on devices. Missing signing/accounts must be explicit; unsigned builds do not prove installation/distribution. Store upload/publication is an operational step after PR, never assumed complete.

## 7. Completion conditions for every PR

1. Identify phase, merged dependencies, UI entry, demo steps/data.
2. Small tests for new rules; input/save validation and data retention on errors. Focus regression on changes without recreating every suite in every phase.
3. Run `flutter analyze`/`flutter test` in `app/`; codegen/l10n after source changes. Native/plugin PRs need relevant platform builds/checks.
4. Every exposed flow has appropriate back/cancel/loading/empty/error/retry; unimplemented buttons cannot create dead ends.
5. No premature player information exposure; confirm destructive form/list actions or ending games.
6. Include demo images/video and actual check results in PRs; distinguish unit/widget, simulation, local/dev backends, physical devices.
7. Update docs when decisions differ from layout. Every merged PR works independently; code rollback does not require deleting local user data. Content readers preserve same-locale translations, backend/locale-scoped caches, and active-session snapshots.

## 8. Handoff milestones and excluded expansion

- **After Phase 3:** internal word game, Dev content, one imposter.
- **After Phase 5:** complete games with core players/configuration.
- **After Phase 7:** stable refresh, word images, offline cache; pagination mandatory since Phase 2.
- **After Phase 10:** agreed custom text/images complete.
- **After Phase 11:** persistent VI/EN UI and support actions.
- **After Phase 12:** DB content-language selection, correct translations, locale-safe offline/cache/custom data.
- **After Phase 13:** release candidate with evidence and remaining limits.

Do not add Premium, payments, ads, player login, online multiplayer, cross-device lists, leaderboards, timers, AI content, permanent custom libraries, individual-ballot systems, or multi-round elimination. Still record group selections and word-game winners. If voting/win rules or content lifecycles differ from proposals, adjust the related phase before implementation.

Analyzer/test, local read-only, and Simulator evidence are recorded per implemented phase. Dev/Production data and physical devices remain unverified; fixtures/simulated offline do not establish target backend or actual airplane-mode acceptance. No date estimates while section 3 design/decisions remain open.

Backend-phase reference: Data API requires grants and RLS per [Supabase API security guidance](https://supabase.com/docs/guides/api/securing-your-api). Before Phases 2/7/12 and release, recheck the [changelog](https://supabase.com/changelog) and target OS connectivity.
