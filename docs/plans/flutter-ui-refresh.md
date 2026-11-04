# Flutter UI refresh — execution checkpoint

Reference: `docs/support.bumble.com-DESIGN.md` and `app/DESIGN_RULES.md`.

Decisions: redesign layouts while preserving game logic/routes/storage; light
theme only; system fonts and Material icons; centered 640 logical px content.
No new dependencies or screenshot/golden verification.

| Phase | Work | Status | Verification |
| --- | --- | --- | --- |
| 1 | Theme and shared presentation components | Complete | Analyzer clean; 6 theme/component tests passed |
| 2 | Landing, instructions, settings, language, fallback | Complete | 17 onboarding/settings tests passed |
| 3 | Setup, imposter sheet, category picker | Complete | Analyzer clean; 34 setup/locale tests passed |
| 4 | Player editor and saved lists | Complete | 33 roster/preset/setup tests passed |
| 5 | Custom content and images | Complete | 37 custom-content tests passed; keyboard dialog and recovery covered |
| 6 | Word game | Complete | 22 word-game tests passed, including privacy, voting and 100 players |
| 7 | Question game | Complete | 18 question-game tests passed, including drafts, lifecycle and role visibility |
| 8 | Cross-app regression and documentation | Complete | Analyzer clean; 294 tests passed; 5/5 iOS and 5/5 Android smoke cases passed |

## Invariants

- Private content is built only after reveal; conceal removes widgets/semantics.
- Preserve drafts, lifecycle handling, validation and persistence retries.
- No store/model/backend changes; update presentation tests with their screens.
- Each phase runs relevant tests and records results here before proceeding.

## Baseline

Previous planning checks: analyzer clean; 83 targeted tests passed.
Final automated and device results are recorded below.

## Resume

All eight phases are complete. For follow-ups, read the affected screens/tests
and shared components; preserve existing edits. Context cannot be programmatically
cleared by the assistant; this document records the handoff between phases.

## User amendments during phase 8

- Prefer two columns on ordinary phones for setup stats, game types, categories
  and player cards. Switch to one column below 280 content px or text scale >1.5.
- Keep category-reveal option easy to discover below game types, before content
  selection/network notices; add word-game toggle-to-reveal regression coverage.
- Final user decision: category option is word-only; keep know-each-other in both
  games. Hint option stays hidden; no hint model, storage flag or backend field.
  Preserve the saved word preference when switching to/from question mode.

## Final verification (2026-10-29)

- `flutter gen-l10n`: generated successfully; ARB strings exist in VI/EN.
- `flutter analyze --no-pub`: no issues.
- `flutter test --no-pub --reporter expanded`: 294 passed, 12 opt-in backend
  checks skipped; no failures or hit-test warnings.
- New regressions cover 360/375/430 px two-column setup/categories, equal row
  heights, the word-only category switch through imposter reveal, keyboard focus,
  Android tap targets/labels, text scale 2 and keyboard insets in landscape.
- iPhone 16 Pro, iOS 18.5 Simulator: combined setup/word/question suites 5/5 passed.
- Android `Sm_Phone_test`: combined setup/word/question suites 5/5 passed.
- `git diff --check`: clean.
- Live Local Supabase setup smoke passed on both iOS and Android, including
  save, disk restart and offline recovery. Replaced obsolete one-word seed
  assumptions with counts and category selection from the fetched live dataset.
  Backend data is unchanged. The final combined native rerun passed on both platforms.
- No screenshot/image verification, dependency changes, backend/schema changes,
  real dark palette or physical-device testing.

Temporary Android localhost forwarding and the headless test emulator were
removed/stopped after verification. Existing iOS simulators were left running.
