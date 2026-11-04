# App design rules — CrazyGames inspired

Reference: [`../docs/www.crazygames.com-DESIGN.md`](../docs/www.crazygames.com-DESIGN.md).
Implementation: [`../docs/plans/flutter-crazygames-ui-refresh.md`](../docs/plans/flutter-crazygames-ui-refresh.md).
Mobile decisions in the plan take precedence over incomplete website extraction
and UI/UX skill palette suggestions. No copied logos or portal features.

## Tokens and typography

Use semantic `AppColors`, Material `AppTheme.dark`, `AppRadii` and `AppSpacing`.
No per-screen hex colors. Explicit `ThemeMode.dark`, even on light devices;
no theme toggle or light palette.

| Role | Value |
| --- | --- |
| Canvas | `#0C0D14` |
| Surface / raised | `#1F2026` / `#2F3148` |
| Primary / body / muted text | `#FFFFFF` / `#E5E6EE` / `#BDBFCE` |
| Primary action / foreground | `#C7FF5B` / `#0F1A00` |
| Accent / readable accent | `#7361FF` / `#A48EFF` |
| Selection / border | `#302A49` / `#A48EFF` |
| Secondary action | White at 10%, measured after blending |
| Neutral border / focus | `#85879E` / white, 2 px focus |
| Error / background | `#FFB4A9` / `#45231F` |
| Warning / background | `#FFDB85` / `#3B301B` |
| Success / background | `#83E0BE` / `#16382E` |

Normal text requires 4.5:1 contrast, controls/focus 3:1. Primary buttons use
a dark inset focus border against lime. Error/warning/completion include labels
or icons. Disabled controls retain readable labels and disabled semantics.
Use bundled BeVietnamPro, real weights 400/500/600. Headings 24/28/32,
titles 18/20, body 16, supporting text 14; line height 1.4–1.5.
Allow wrapping and text scaling; no new fonts or packages.

## Layout and interaction

- `AppContent`: safe area and centered maximum width 640. Page gutters 16 on
  narrow phones, 24 when width allows; spacing scale 4/8/12/16/24/32.
- Cards radius 16; heroes/sheets/dialogs 22; buttons pill; multiline inputs 16.
  Primary buttons solid lime, minimum height 50; icon hit areas ≥48×48.
- Reserve two dark purple/teal `AppEffects` gradients for introductions/sections.
  Selection is solid tint + border/check/radio + selected semantics.
- `AppActionBar` owns keyboard inset and safe area once. Content scrolls
  independently; one primary action, subordinate secondary actions.
- `AppCardGrid`: two columns at content width ≥280 and text scale ≤1.5,
  otherwise one; rows grow to the tallest card. Labels always wrap.
- `PlayerCards`: lazy rows for up to 100 players; completion check + label,
  cannot reopen. `AppSelectionCard`: keyboard activation and visible focus.
- `AppEffects.duration` respects reduced motion; press scale .98. No animations
  retaining old secret widgets. No decorative overlays behind hero text.
- `AppNotice`: explanatory copy and retry. Forms retain inline errors, validation
  and drafts; dialogs scroll with keyboard/large text. Preset deletion remains
  separate from selecting/saving, with existing discard/confirmation behavior.

## Hierarchy and privacy

Landing: name → description → three numbered steps → start; help is secondary.
Setup: players/imposters → game type/rules → content/categories → load status.
Show-category remains immediately below game choice, word-only;
know-each-other applies to both games; hints hidden; no duplicate game start.
Gameplay preserves selection → handoff → reveal → discussion → vote/result with
contextual titles, progress and one primary action; distinct game rules remain.
Conceal removes private widgets and semantics immediately on background/back.
Never build hidden secrets behind opacity/offstage or retain them in transitions.
Hidden cards remain identical for all roles; images obey reveal permissions.
Settings retain grouped tiles, language selection, explicit ID copy, disabled
unavailable actions, retry and VI/EN labels; fallback provides navigation home.

## Verification

Use analyzer, contrast assertions and behavioral widget/integration tests.
Cover narrow/360/375/430 phones, tablet/landscape, keyboard, large text,
reduced motion, errors/retry and secret semantics. No screenshots or goldens
by default, following AGENTS.md.
