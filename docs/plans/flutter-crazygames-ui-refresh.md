# Flutter UX/UI Plan — CrazyGames Inspired

Created: 2026-11-02. Status: implemented; live setup smoke gap because the local backend was not running.

Design source: [CrazyGames](../www.crazygames.com-DESIGN.md).
Scope: all Flutter `app/`, excluding `admin/`.
This plan replaces the Bumble direction for the next redesign. Retain the
[previous checkpoint](flutter-ui-refresh.md) as history without changing recorded results.

## 1. Goals and design decisions

- Create a party-game feel: dark background, prominent headings, clearly grouped cards, lime CTAs.
- Let users scan settings quickly, understand the next step, and recognize completed states.
- Redesign information hierarchy and interactions, beyond changing colors.
- Preserve game rules, routes/inputs, storage, offline content, validation, and retries.
- Default to dark theme even on devices using light mode.
  No theme toggle or light-theme design in this iteration.
- Reuse existing components, Material icons, and bundled BeVietnamPro.
  Use available real weights 400/500/600; no new font or simulated 900.
- Add no packages, backend/schema, search, accounts, leaderboards,
  or portal-style game directories.

These are the plan's defaults; new user requirements take priority
during implementation.

## 2. Current state and required fixes

| Current code | Direction |
| --- | --- |
| `AppTheme.dark = light`; `main.dart` does not set `themeMode` | Create a real dark palette and use `ThemeMode.dark`; remove dark-equals-light test assumptions |
| `AppColors` uses Bumble color names, referenced directly by many screens | Migrate to role-based tokens and update every caller; do not turn `white` into a dark value to bypass migration |
| Theme, hero, selection, footer have separate gradients/shadows | Align palette/roles; reserve gradients for hero/sections and use solid lime CTAs |
| `app/DESIGN_RULES.md` still describes Bumble and bans gradients, unlike current code | Update the contract in the foundation phase for one rule source |
| `AppRadii.card = 24`, `hero = 28` | Cards 16, hero/sheets 22, pill buttons; moderate multiline-input corners |
| `AppContent` caps at 640; grids support large text and two columns | Keep responsive foundations; do not copy an eight-column web grid |
| Theme tests assert yellow, light, and white-background contrast | Replace with dark contract and actual surface/gradient contrast; retain behavioral tests |
| README describes old font/theme | Synchronize after implementation; historical test counts are not the new baseline |

## 3. Adapt references into a mobile contract

The source is an alpha extraction from one page with a blocked stylesheet and
missing states. These are app decisions, not all measured CrazyGames tokens.

| Role | Proposed value / rule |
| --- | --- |
| Canvas | `#0C0D14` |
| Surface / raised surface | `#1F2026` / `#2F3148`; layered cards, inputs, sheets |
| Primary / body / muted text | `#FFFFFF` / `#E5E6EE` / `#BDBFCE` |
| CTA / CTA text | `#C7FF5B` / `#0F1A00` |
| Accent / accent text | `#7361FF` / `#A48EFF`; light text on dark surfaces; check contrast before using purple behind text |
| Selection | Purple-tinted surface + clear border + check/radio + selected semantics |
| Secondary action | 10% alpha white surface, light text; measure on composited backgrounds |
| Border / focus | Neutral borders; bright 2 logical px focus, never remove focus rings |
| Error / warning / success | Dedicated dark tokens finalized through contrast tests; always labels/icons, retaining retry/explanations |
| Gradient | At most two source purple/teal gradients for hero/sections; place text in contrast-safe areas |
| Spacing | Reuse 4/8/12/16/24/32; gutter 16 on narrow screens, 24 when wider |
| Typography | Headings 24/28/32, titles 18/20, body 16, secondary 14; line-height 1.4–1.5, wrapping and text scaling |
| Controls | CTA minimum height 50, icon targets at least 48×48; height grows with content |
| Motion | Reuse `AppEffects` and reduced-motion; subtle press feedback, no 1.1–1.2× mobile card scaling |

Deliberate exceptions to the extraction:

- No 28px icon targets or 34–40px buttons for mobile actions.
- Do not use `outline: none`, `active opacity: 0`, or fade whole controls until illegible.
- Do not apply eight columns, zero gutters, or fixed text sizes to phones.
- Do not force APK Protocol/Artex without assets; retain Vietnamese-supporting fonts.
- Add semantic statuses for save/network failures and completion;
  missing source data is no reason to remove error feedback.
- Do not copy CrazyGames branding/logo or require hover to use the app.

## 4. UX by screen

| Group | Required changes | Preserve |
| --- | --- | --- |
| Landing, instructions | Compact gradient hero; app name → description → three steps; one lime “Start” CTA, secondary instructions action | Existing VI/EN content and navigation |
| Setup | Group players/imposters → game type/relevant rules → content/mode/categories → load status; fixed bottom start CTA | Two columns on typical phones; word-only category display immediately below game type; know-each-other for both; hint stays hidden |
| Imposter sheet | Clear fixed/random selection; count and never-start in one draft; constraints beside controls | Confirm commits; back/cancel discards; warnings for groups of 3–4 |
| Categories, Family/All | Clear selected cards/chips, wrapped labels, selection summary and confirmation | All versus explicit selection, eligibility filtering, back discards |
| Players, presets | Easily edited names, clear numbers, choose/save/manage hierarchy; deletion separate from primary actions | Drafts, autosave, rename/delete identity, discard warnings, retry |
| Custom content, images | Group category name/content/images; helpful empty states; field errors; dialogs scroll with keyboard | Word/question CRUD, local images, recovery, validation, drafts |
| Word game | Distinguish player selection → handoff → reveal → discussion → vote → results with titles, progress, one primary action, completion checks/labels | Reveal permissions, vote/scoring, image eligibility, replay, exit confirmation |
| Question game | Same card language as word; labeled answer input/submission state; readable completed public answers | Locked answers stay closed, ID-based drafts, result reveal, question-specific rules |
| Settings, language, fallback | Clear tile groups, consistent selection/focus, retry errors, not-found return path | Existing locale/content language, ID copied only on request, unconfigured actions disabled |

Do not merge/remove handoff or reveal steps to shorten flows. Hidden cards must
look identical across roles; public states must not reveal imposters early.

## 5. Implementation phases

Run sequentially. Each phase updates status and actual check results here;
never record “pass” for checks not run.

### Phase 1 — Contract, tokens, Material theme

Files: `app/DESIGN_RULES.md`, `app/lib/theme/{app_colors,app_theme,app_effects}.dart`,
`app/lib/constants/{app_radii,app_spacing,app_edge_insets}.dart`, `app/lib/main.dart`.

- Finalize semantic tokens/contrast; inventory all `AppColors` callers before renaming.
- Define dark `ColorScheme`, text, app bars, buttons, inputs, sheets/dialogs,
  chips, list tiles, switches/checks/radios, tabs, progress, snackbars, system bars.
- Explicitly select dark in `MaterialApp`; remove dark=light alias. Review callers/tests
  using `AppTheme.light`, keeping temporary compatibility if needed between phases.
- Preserve all language-selection flows; no out-of-scope locale changes.
- Complete when theme tests confirm real dark mode, sufficient text/CTA/error contrast,
  distinguishable focus/disabled states, and static analysis finds no broken token references.

### Phase 2 — Shared components

Files: `app/lib/widgets/{app_content,app_action_bar,app_hero_card,app_selection_card,
app_card_grid,app_notice,player_cards}.dart`.

- Align surfaces, spacing, radii, gradients, and states; preserve APIs where possible.
- Keep max-width 640, lazy player rows, two columns at content width ≥280
  and text scale ≤1.5; otherwise one column, with content-sized cards.
- Footers must not double-count keyboard/safe insets; notices have clear messages/actions.
- Complete when tests cover tap/focus/disabled/selected semantics,
  reduced-motion, text scale 2, and narrow layouts without overflow/hit-test warnings.

### Phase 3 — Landing, instructions, setup, categories

Files: `features/landing/`, `how_to_play/`, `setup/`, and related tests.

- Apply section 4 UX; reduce decoration so settings/CTAs remain primary.
- Preserve loading/disabled start prevention of duplicate games, read/save errors,
  and correct stale-content states/retries.
- Complete when navigation, mode/category selection, imposter drafts, word-only category display,
  offline/loading/empty/error states, and two columns at 360/375/430 remain correct.

### Phase 4 — Player editor, presets, custom content

Files: `features/player_names/`, `player_presets/`, `custom_content/`.

- Apply form groups, action hierarchy, selection, and dark dialogs.
- Keep fields/actions visible above keyboards; preserve back/cancel/delete behavior.
- Complete when roster/preset/custom word/custom question/local-image tests pass,
  including failed saves, retained drafts, landscape + keyboard, text scale 2.

### Phase 5 — Word and question games

Files: `features/word_game/`, `question_game/`, `widgets/player_cards.dart` if needed.

- Apply consistent cards/progress/actions to every stage and results.
- Conceal animations must not retain old secret widgets; do not build secrets
  then hide using opacity/offstage. Conceal removes widgets and semantics.
- Complete when both full flows pass, including lifecycle/background, unopened cards,
  teammate/category visibility, locked/draft answers, vote/results/replay,
  word images, and lists up to 100 players.

### Phase 6 — Settings, locale, fallback

Files: `features/settings/`, `unknown/`, `app/lib/l10n/arb/app_{vi,en}.arb` if copy changes.

- Align tiles, language picker, unavailable states; verify every new label's translation,
  without hardcoded Vietnamese widget copy.
- Complete when language selection, read/write errors/retries, ID copy, and navigation pass;
  long VI/EN text must retain all information needed for actions.

### Phase 7 — Regression and handoff documentation

- Review all `app/lib` and tests/fixtures/harnesses: remove remaining Bumble tokens,
  migrate theme fixtures to dark; never change expected behavior to hide regressions.
- Synchronize `app/README.md`, `app/DESIGN_RULES.md`, and test descriptions.
- Run section 6 checks, recording pass/skip counts and actual gaps.
- Complete when all app screens use the contract, analyzer/full suite pass,
  without dependency, route-contract, store/model, or saved-data changes.

## 6. Verification strategy

Record a fresh analyzer/test baseline before changes; old results are historical.
Run affected tests per phase and the full suite at the end.

From `app/` (environment assets must exist per README; do not print credentials):

```sh
rtk proxy flutter gen-l10n
rtk proxy flutter analyze --no-pub
rtk proxy flutter test --no-pub
```

From repository root: `rtk git diff --check`.

Widget matrix: 320/360/375/430 logical px, tablet 768, landscape with keyboard;
text scales 1/2; VI/EN; loading/empty/error/offline/selected/disabled; reduced motion.
Reuse tests and add missing cases instead of multiplying the entire suite by every
combination. Contrast tests check alpha compositing and text-bearing gradient regions;
essential controls have focus/labels and minimum 48×48 targets.

Review `app/integration_test/`; run setup/word/question offline smoke tests on
iOS Simulator and Android emulator when available. Explicitly record unavailable checks.
Existing HTTP/live checks stay opt-in; UI redesign needs no backend changes.
Do not add screenshots, goldens, or image-based verification.

## 7. Risks and limits

- Central palette changes do not fix inline colors: review all callers, including
  dialogs, image placeholders, lime foregrounds, and private-card semantics.
- Source lacks complete pressed/error/focus states: mobile contract/contrast
  tests justify additions; do not claim website pixel matching.
- Font weights stop at 600: establish hierarchy through size/spacing; another font
  requires a separate request and suitable assets.
- Widget tests do not prove real-device visual quality. Record device gaps
  at handoff without adding image verification automatically.

## 8. Tracking

| Phase | Status | Evidence |
| --- | --- | --- |
| 1. Contract/theme | Complete | 3 theme tests passed; surface/alpha/gradient contrast, focus, disabled, control sizes |
| 2. Components | Complete | 14 component tests passed: focus/keyboard/semantics/reduced-motion/text/keyboard layouts |
| 3. Onboarding/setup | Complete | 54 focused tests passed; final suite has no hit-test warnings; two columns at 360/375/430 |
| 4. Editors/content | Complete | 28 tests passed: presets, word/question forms, local images, draft/error, keyboard, text scale 2 |
| 5. Gameplay | Complete | Full suite passed: both flows, lifecycle/semantics, word images, question draft/locked, 100 players in both |
| 6. Settings/fallback | Complete | Settings/language tests pass; notice retry; dark on light devices and landing fallback pass |
| 7. Regression/docs | Complete, environment gap | Clean gen-l10n/analyzer/diff-check; 305 passed / 12 skipped; 4 offline smoke tests passed per platform, live setup fails due to backend |

### Actual baseline — 2026-11-02

- `flutter analyze --no-pub`: No issues found (2.9s).
- `flutter test --no-pub`: 298 passed, 12 skipped (backend opt-in).
- Clean working tree before implementation. Counter demo is absent;
  follow existing stores/providers/router and skill, without recreating it.

### Actual regression — 2026-11-02

- `flutter gen-l10n`: successful; only ARB edited, generated files produced by Flutter.
- `flutter analyze --no-pub`: No issues found (7.0s).
- `flutter test --no-pub`: **305 passed, 12 skipped** (28s final run).
  No overflow/hit-test warnings in full-suite logs.
- Added 7 widget cases: 5 adaptive-gutter widths 320/360/375/430/768,
  dark on light devices + fallback navigation, question lazy/private 100-player case.
  Theme assertions check alpha blending, 11-point gradient interpolation, focus,
  disabled, control sizes; form fixtures use dark for both system appearances.
- No packages, store/model, route names/arguments, backend/schema,
  or storage-format changes. Added typed `RouteInput.landing()` for an existing fallback route.
- Counter demo is absent from this checkout: follow current provider/router;
  retain store lifecycles without recreating demos or changing state management.
- No screenshot/golden/image verification. Physical devices and
  TalkBack/VoiceOver remain unchecked; widget semantics do not replace actual screen-reader checks.

### Simulator/emulator and handoff — 2026-11-02

Ran `flutter test --no-pub integration_test -d <device>
--dart-define=APP_ENV=local` on both platforms without image capture:

| Device | Offline question | Offline word | Setup with live backend step |
| --- | --- | --- | --- |
| iPhone 17 Pro, iOS 26.5 Simulator | 2 passed | 2 passed | 1 failed: repository loadFailed before UI |
| Android Sm_Phone_test, API 36 emulator | 2 passed | 2 passed | 1 failed with the same precondition |

- Each integration command reported **4 passed / 1 failed**; the full integration
  suite did not pass. Live setup fails at `setup_smoke_test.dart:60`; host TCP checks
  confirmed the configured local endpoint returns `ConnectionRefusedError`. Android
  retains existing loopback settings; no environment changes or assumed host routing readiness.
- Both offline suites include setup → start, offline disk/cache restoration,
  private steps, vote/reveal, replay, and return to setup.
- Did not start/change the backend or alter expectations to pass live setup. Reruns
  need a running local backend, populated dataset, and correct host mapping;
  12 HTTP/backend unit checks remain opt-in as in the baseline.
- Added system-bar annotation for landing without AppBar after the full suite;
  reran 9 onboarding tests: passed. Final analyzer: clean.
- `rtk git diff --check`: passed. README/design contract synchronized.
- Physical devices, TalkBack/VoiceOver, and image-based visual quality remain unchecked.
  These are verification gaps, not proof of CrazyGames pixel matching.
