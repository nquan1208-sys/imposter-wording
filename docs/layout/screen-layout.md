# Application Screen Layout

> Draft based on available reference images. Focuses on layout, content, and UI components; colors, fonts, and pixel specifications are not yet described.

## 1. Start screen

### Purpose

Introduce the game briefly and lead users into the main flow.

### Top-to-bottom layout

1. **Main illustration area**
   - Character/icon illustration themed around the “imposter”.
   - Centered near the top.

2. **Game name**
   - Large title: `Imposter`.

3. **Subtitle**
   - Short introduction: `Word game`.

4. **Game description**
   - Brief gameplay description, e.g. a party game with secret words and clues.
   - Centered below the title.

5. **Bottom action group**
   - Primary: `Start`.
   - Secondary: `How to play`.
   - Equal-width buttons stacked vertically.

### Navigation

- `Start` → game setup.
- `How to play` → instructions.

## 2. How to Play screen

### Purpose

Explain rules step by step before the first game.

### Screen structure

1. **Header**
   - Back button on the left.
   - Centered title: `How to play`.
   - Fixed at the top while content scrolls.

2. **Instruction steps**
   - Large vertically stacked cards.
   - Each card includes:
     - Illustration icon on the left.
     - Step title.
     - Brief description to the right or below the title.

### Existing step content

#### Step 1 — Set up the game

- Choose players and word categories.
- Choose fixed/random imposter count in 1…floor((N−1)/2); civilians always remain the majority.
- Icon: setup/settings.

#### Step 2 — Reveal words

- Each player privately views their information in turn.
- Civilians see the secret word.
- Imposters see their role; category name appears only if category display is enabled.
- Icon: eye.

#### Step 3 — Give clues

- Players take turns saying words related to the secret word.
- Clues should not be so obvious that they expose the word.
- Icon: message/conversation.

#### Step 4 — Find the imposter

- Discuss as a group.
- Vote for the person likely not to know the word.
- If the group votes incorrectly, the imposter wins.
- Icon: search.

3. **Pro tip card**
   - After the steps.
   - Lightbulb icon.
   - `Pro tip` title with short advice.
   - Example: imposters should listen carefully, blend in, and offer category-appropriate clues.

### Behavior

- Instructions scroll vertically.
- Back returns to the start screen.
- No final confirmation action in the current version.

## 3. Game Setup screen

### Purpose

Configure a game before starting.

### Screen structure

1. **Top navigation**
   - Back on the left.
   - Settings on the right.
   - Large title: `Game setup`.

2. **Player settings cards**
   - Two side-by-side cards:
     - `How many players?` — current player count.
     - `How many imposters?` — current imposter count.
   - Each has an icon, label, and large numeric value.
   - Tap to change values.

3. **Game type selection**
   - Group title: `Game mode`.
   - Two-column choice cards:
     - `Word game` — find who does not know the secret word.
     - `Question game` — find who received a different question.
   - Exactly one card is selected.

4. **Play mode**
   - Select in the word category screen through `All categories` / `Family mode` tabs.
   - `Show images` appears only in Family; setup has no mode selector or image switch.
   - Question games always use normal mode.

5. **Categories**
   - Group title: `Categories`.
   - One large settings card containing:
     - Current name: `All categories` when none is explicitly selected.
     - One or more category selections.
     - Arrow opening category selection.
     - With no selection, randomize across all content eligible for game type/mode.
     - With selections, randomize only within them.

6. **Game options**
   - `Show category to imposters`.
   - `Imposters know each other`.
   - Each has an icon, label, and switch.
   - Options share one card with dividers.
   - Words only reveal category names; no separate hint switch/data. `Show category to imposters` remains word-only.
   - **Planned Phase 6 addition, not implemented:** show `Imposters know each other` for word/question and Classic/Family, sharing its saved value across game switches, preset loads, and replay. With at least two imposters, only revealed imposter cards show teammates; locked cards/civilians do not.

7. **Start button**
   - Fixed near the bottom: `Start game`.
   - Remains visible while scrolling.

### Observed states

- `Word game` + `Classic`, with `All categories`.
- `Word game` + `Family`, showing only family-friendly content categories.
- `Question game` + `Family`, showing only family-friendly question-prompt categories.

### Behavior

- Vertically scroll to access all options.
- `Start game` remains at the bottom.
- Selected game type/mode determines eligible random content.
- Both games have `Classic` / `Family` modes.
- Categories are optional, defaulting to `All categories`.
- Multiple categories may be selected.
- No selection randomizes across all published content eligible for game type/mode.
- One or more selections restrict randomization to those categories.
- Words have no separate clue beyond the category name when enabled.
- Imposter count must be valid for player count.
- Back returns to the previous screen.

### Imposter selection sheet

- Tap imposter count in either game to open a bottom sheet titled `Choose imposters`.
- **Planned Phase 6 layout, not implemented:** follow `IMG_2987.PNG` structure: dim backdrop, icon/title header, `Fixed` / `Random` cards with mutually exclusive radios. Use existing app theme/components.
- **App style rules:** images guide layout/interactions only; colors, typography, spacing, radii, icons, selection, modal overlays, and light/dark styles use `AppTheme`/`AppColors`, constants, and existing components, without a separate image-derived style system.
- Two methods:
  - `Fixed`: exact imposter count per game.
    - `−` / `+` adjust count.
    - Large central value and range text; `1` is `Recommended`. Disable decrement/increment at limits.
    - Valid range 1…floor((N−1)/2), N from 3 to 100. Reducing N clamps fixed count to the new maximum.
  - `Random`: uniformly choose within the same range once at game start. Collapse count controls, retaining fixed count in draft for switching back.
- Phase 4 places `Imposters do not start` in setup; **Phase 6 moves it to the modal bottom**, labeled `Imposters never start`, without a duplicate in setup. Choose `startingPlayerId` first; when enabled, exclude this ID from role assignment. Discussion shows the same ID's name.
- Count, method, and never-start share one draft. Back/drag dismissal/outside tap discards; `Confirm` applies/saves, including active-preset updates. Write failures retain draft for retry. Sheet scrolls on small screens/large text with SafeArea and accessible labels.

## 4. Category Selection screen

### Purpose

Choose one or more categories or use all available categories.

### Screen structure

1. **Navigation**
   - Back on the left.
   - Large title: `Choose categories`.

2. **Game type/mode information**
   - Top badge, e.g.:
     - `Word game · Classic`.
     - `Question game · Family`.
   - Mode is selected in setup; this screen shows eligible categories.

3. **Category list**
   - Two-column grid.
   - Multiple selections allowed.
   - Each card contains:
     - Checkbox or selected state.
     - Category name.
     - Eligible content count for current game type/mode.
   - Word examples:
     - Animals.
     - Food.
     - Movies.
     - Places.
   - Question examples:
     - Life & society.
     - Love & relationships.
     - Money & fame.
     - Future & technology.

4. **All categories state**
   - `All categories` at the top.
   - Default state.
   - Selecting it deselects specific categories.
   - Randomize across published remote and eligible local custom content for current game type/locale/mode; every prompt has equal probability.

5. **Custom categories**
   - Phase 8 adds `Create custom category` as the last word-grid tile, matching existing tile width/borders/spacing; light-blue background and plus icon distinguish creation. It has no category checkbox. Phase 9 also shows it in question pickers, including offline.
   - **Phase 8:** custom words live with local setup across games/replay/restarts. Delete only after confirmed setup → landing navigation; launching on landing does not delete them. Phase 9 uses the same lifecycle for custom question pairs.

### Behavior

- Tap cards to select/deselect one or more categories.
- `All categories` deselects all specific categories.
- `Confirm` returns to setup with selected count.
- No explicit selection keeps `All categories`.
- Lists/counts are filtered by selected game type/mode.
- `All categories` includes regular/Family categories; `Family mode` includes only `game_categories.is_family_friendly = true` categories with valid words.
- Tab, categories, and images are drafts. `Confirm` saves all three together; back discards. Failed saves retain the screen for retry.
- Switching tabs retains eligible categories, removes others, and notifies. No specific selection means all in the tab.
- Empty Family tabs show a message; confirmation is allowed but games cannot start without words.
- Remember image choice; show only in Family word games. Old caches default missing category flags to false, ignoring old prompt flags.
- Premium categories are outside this draft's scope.

## 5. Custom Content Creation screen

### Purpose

Create custom word categories (Phase 8) or question pairs (Phase 9) for gameplay. Phase 10 added optional local images per word or question pair. Use current theme/components.

### Proposed layout

1. **Header**
   - Back on the left.
   - Title: `Create custom category`.

2. **Category name**
   - Required `Category name` input.
   - Placeholder: `Example: Office words`.

3. **Word list**
   - Group title: `Word list`.
   - Current word count.
   - One row/card per word:
     - Word above; thumbnail and add/replace image below for small-screen space.
     - Add/replace image button.
     - Delete on the right.
   - Empty state: `No words yet`.

4. **Add word**
   - `Add word` directly below the list.
   - Opens a form with:
     - `Word` — required in `Word game`.
     - `Civilian question` and `Imposter question` — required in `Question game`.
     - Optional `Image` selection/preview.
     - `Save word`.
   - Add one word and continue adding others.

5. **Bulk word entry**
   - Secondary `Enter multiple words` beside/below `Add word`.
   - Opens multiline input.
   - Each line is one word.
   - Confirmation adds valid lines.
   - Ignore blank lines and retain one instance of duplicates.

6. **Illustrations**
   - Each word has its own image; each **question pair shares one image**; optional.
   - Tapping an item's image area allows:
     - Photo library selection.
     - Taking a photo.
     - Removing the current image.
   - No image: icon + `Add image`. Existing image: thumbnail + `Replace image`. Sheet offers `Photo library`, `Camera`, `Remove image` when present, and `Cancel`.
   - Bulk entry creates text only; images are added individually afterward.

7. **Save button**
   - Fixed bottom `Save category`.
   - Enabled only with nonempty name and at least one word.

### States and behavior

- Confirm leaving with unsaved changes.
- Category names cannot be empty.
- Trim each word before saving.
- Compare trimmed words case-insensitively; ignore blanks and retain the first spelling of duplicates. Entirely duplicate batches require at least one new word.
- Names matching remote/custom word categories in the current locale (including outside Family) require renaming, never overwriting; compare trimmed/case-insensitive and recheck on save.
- Successful saves return to `Choose categories`, retain the current tab, add the new category to picker drafts, and preserve previous choices. Picker `Confirm` applies tab/categories/images; Back discards only draft selections, not saved categories.
- Family-tab creation requires a family-suitability checkbox. The category appears in both tabs; All-tab creation is not implicitly family-friendly. Tab/game changes hide unsuitable categories without deleting content.
- Save errors retain name/list/checkbox for retry, without partial categories; lock edits/navigation while saving. Inputs have labels/nearby errors, delete actions are labeled, forms scroll, save stays above keyboard.
- Content is local with setup across restart/replay, outside presets/backend. Setup → landing requires permanent custom-content deletion confirmation; leave only after successful deletion and selected-ID removal. Write errors keep setup for retry.
- Custom category cards show names, word counts, and image availability.

### Local images — Phase 10

- Single-item dialogs have optional image and confirmation; bulk remains text-only. Thumbnails sit below item content; category tiles show only `Has images`, without exposing images.
- Accept decodable images up to 5 MiB. Canceled selection/read/write errors preserve prior images; errors appear beside controls with VI/EN live regions. Denied/restricted permissions direct users to system Settings; unavailable cameras offer library selection. Missing/corrupt gameplay files use stable placeholders.
- Lock actions/Back during picker/import/save. Image changes participate in drafts/discard; failed saves retain images/text for retry. Dialogs scroll with inset 16 so buttons/images remain accessible at 320×568, text scale 2, with keyboard. Use current Material theme/buttons/touch targets.
- Words: show only with Family + Show images; revealed civilians and results may see images, imposters' private cards may not. Questions: shared image below the current player's revealed question; results show it once below the civilian question. No images on handoff, locked cards, common-question, or discussion screens; conceal/background/submit/Back/player changes remove private widgets/semantics. `Question image` labels reveal neither role nor opposing question.
- Saved images remain on-device throughout category lifetime, including replay/restart/offline; excluded from presets/backend. Unsaved drafts are lost on process termination. Android startup receives/discards picker lost-data and asks users to recreate drafts; never attach it to a new item.
- Unit/widget/semantics checks cover add/replace/delete/cancel, retry, disposal, lifecycle, question stages VI/EN, three word-image configurations, small/large-text/keyboard/light-dark layouts. No screenshots. Real-device library/camera/permissions/process-death checks remain acceptance requirements.

### Custom questions — Phase 9

- Reuse word creation screen, category name, save button/errors, and discard confirmation. Question picker keeps standard UI without Family tabs/checkboxes.
- `Question pairs` shows total; each item has civilian/imposter labels and accessible `Delete pair N`. Actions: `Add question pair` / `Enter multiple question pairs`.
- Add pairs through two labeled fields. Trim both; reject empty or case-insensitively identical questions.
- Bulk uses two multiline inputs paired by line number. Preserve blank lines while pairing; accept LF/CRLF and one trailing newline. Unequal counts, empty/identical questions, or duplicate pairs identify lines to fix; never partially add. Compare ordered civilian/imposter pairs after trim/lowercase against batch/draft. Reusing one question with a different counterpart is allowed.
- Compare category names only within the same game type/locale across remote/local; recheck in the write queue. Failures preserve draft/counter. Successful saves select only in picker draft; Back retains the saved category.
- Combined remote/local question catalogs drive counts, start eligibility, randomization, and session category names. `vi` content and `custom-question-N` IDs are stored in setup, outside presets/remote cache. Offline/refresh/game switches/restart/replay retain content; sessions snapshot pairs/names at start.
- Before public reveal, only the current phone recipient sees their role-specific question; discussion reveals civilian question only, results reveal imposter question. Setup → landing confirms and atomically deletes word/question content with selected IDs; failures keep setup open.

## 6. Player Selection screen

### Purpose

Let players privately open their secret information on one shared device.

### Layout

- Back at top left.
- Large title: `Players`.
- Instructions: `Tap your name to see your word, then pass the device to the next player.`
- Two-column player grid.
- Each card shows a circular initial and name.
- Unseen cards are tappable.
- Seen cards are dimmed and cannot reopen.

### Behavior

- Tap your name to open word reveal.
- Confirm completion to return and hand off.
- Advance to clues only after everyone views their information.

## 7. Word Reveal screen

### Before reveal

- Back at top left.
- Recipient name centered, e.g. `Word for Ha`.
- Hidden cards expose no category or secrets through headings/screen readers.
- Secret content is fully concealed in a card.
- Instructions below: `Tap to reveal`.

### After reveal

- Card shows the player's word, e.g. `Inception`.
- Centered word is most prominent. Civilians also see category name after reveal.
- Bottom action: `Got it!`.

### Behavior

- Tap toggles concealed → revealed.
- Civilians see the secret word.
- Imposters see role and selected category name only when `Show category to imposters` is enabled; otherwise role only. Never show secret word, hint, or image. This is a local game setting, not a per-prompt field.
- `Got it!` returns to `Players` and marks the current player complete.
- Completed players cannot reveal again.
- Phase 4 supports multiple imposters; with `Know each other`, only revealed imposters see other imposter names. No word/image for imposters. Phase 7 shows local images below revealed civilian words; missing/failed images retain a 180dp placeholder, no image path means text only. Late images update automatically and are removed from widgets/semantics on conceal.
- Back conceals and returns without completion. Backgrounding conceals; returning requires explicit reveal.

## 8. Voting Stage screen

### Purpose

Guide discussion and imposter voting after everyone has seen their word.

### Layout

- Back at top left.
- Large title: `Voting stage`.
- Description: `Time to discuss and vote for the imposter!`.
- Subtitle: `How to vote`.
- Vertically stacked instruction cards:
  1. `Starting player` — randomized once at session creation; never-start rules exclude this player from imposters.
  2. `Group discussion` — continue clockwise.
  3. `Voting time` — everyone says a related word; multiple rounds are allowed.
  4. `Reveal stage` — vote for suspects, then tap to see results.
- Bottom: `Announce results`.

### Behavior

- Available only after everyone confirms their card.
- Discussion/voting is verbal; the app does not collect individual ballots.
- `Announce results` opens a sheet selecting exactly K distinct voted player IDs, K being actual imposter count, including random mode. Initially none selected; enable confirmation only at exactly K.
- Ties require group revoting before confirmation. Cancel/back records no votes or secrets.
- Confirmation opens results. Civilians win only if all K voted IDs exactly match all imposters; any incorrect choice gives imposters victory.
- Back from player list/discussion asks to end the game; cancel preserves progress.

## 9. Results Reveal screen

### Layout

- Imposter announcement, e.g. `THE IMPOSTER IS`.
- All actual imposter names, voted players, and winning side.
- `SECRET WORD` label.
- Large centered word, e.g. `APPLE STRUDEL`.
- Bottom: `Play again`.

### Behavior

- Results appear only after voting is complete.
- `Play again` ends the session and returns to setup, retaining players/mode/categories for changes before the next game.
- Create/randomize a new session, word/roles/starter only when `Start game` is pressed in setup; repeats are allowed for small sets. Missing content blocks starting under shared rules.
- Back from results returns to setup and destroys the session. Sessions need not survive OS process termination.
- Incorrect voted sets still show actual results and imposter victory.

## 10. Player Selection — Question Game

### Layout

- Title: `Players`.
- Instructions: `Each player sees their question and submits a private answer.`
- Two-column player grid.
- Cards show initials and names.
- Unanswered cards open questions.
- Submitted cards are marked complete.

## 11. Answer Question screen

### Layout

- Top title: `Question for [Player name]`.
- Player name centered.
- Category below, e.g. `Category: Money & Fame`.
- Card shows the player's private question.
- Multiline input below: `Enter your answer here...`.
- `Submit answer` below input.
- Bottom counter: `0 / 5 answers submitted`.

### Secret question state

- All players have identical locked cards. Phase 5 reveals no role/teammates; **Phase 6 adds** other imposter names when `Imposters know each other` is enabled, at least two imposters exist, and the current imposter reveals their private card. Exclude self and compare IDs for duplicate names. Disabled/single-imposter cases retain no role/teammate disclosure.
- Lock icon and `Tap to reveal`.
- Questions appear only after tapping.
- Question, category, and input appear only after reveal for the current player. Teammates appear only in eligible private cards, never locked cards, handoff lists, or discussion. Do not expose opposing questions or other private answers.
- Backgrounding conceals question/input/teammates, dismisses keyboard focus, and requires reveal on return. Back/submission/player changes also conceal teammates. `knowEachOther` comes from the initial session snapshot.

### Behavior

- Enable `Submit answer` only for nonempty answers.
- Submission increments the counter and returns to `Players`.
- Submitted answers cannot be edited/reopened. Before submission, back retains an in-memory draft by stable player ID, visible only after revealing that player's card. Do not persist answers/drafts to disk/backend.
- Once everyone submits, advance to discussion and identify who received a different question.

## 12. Common Question screen

### Layout

- Title: `Everyone's answers`.
- One common question in a large centered card.
- Instructions: `Here is the question. Next you will see all answers and discuss who is lying about theirs.`
- Bottom: `Start round`.

### Behavior

- Opens only after all answers are submitted.
- `Start round` opens discussion.

## 13. Discussion Stage — Question Game

### Layout

- Title: `Discussion stage`.
- Common question in the top card.
- Numbered answer cards.
- Each shows number, player name, and answer.
- Bottom: `Find the imposter`.

### Behavior

- Discuss using public answers.
- Do not show the alternate private question before finding imposters.
- `Find the imposter` directly reveals all imposters; no vote sheet or winning-side calculation for questions. Word voting/win rules stay unchanged.

## 14. Results — Question Game

### Layout

- Keep `Discussion stage` title and common question at the top.
- Answers remain listed.
- Highlight every alternate-question recipient with `Imposter`.
- These cards also show their private question.
- Bottom: `Play again`.

### Behavior

- Reveal all imposter questions only after results. Reuse Phase 4 fixed/random counts and never-start rules; show starting player during discussion. Back before results asks to end the game.
- `Play again` ends the game and returns to setup with players/settings retained. Only pressing start in setup creates a new session.

## 15. Player Names screen

### Purpose

Enter, order, and manage players before playing.

Current roster editor belongs to Phase 4; saved-preset library to Phase 6. Phase 6 depends on Phases 4–5 because it adds question teammate visibility. Phase 6 specification was finalized on 2026-10-27 and is not implementation status. References guide layout/interactions; use current app theme/components/rules.

### Main layout

1. **Header**
   - Back on the left.
   - `Edit players`, aligned using the current AppBar.

2. **Selected list card**
   - Folder icon.
   - Top of content, before count/roster.
   - Selected draft preset name, e.g. `Activities Committee`; no preset shows `Unsaved game`.
   - Entire card opens `Saved lists` bottom sheet with a clear affordance.

3. **Player count**
   - Current count, e.g. `4 players` / `5 players`.
   - Allowed range: `3–100`.

4. **Player list**
   - One card per player.
   - Initial, name, sequence number, delete.
   - Additional players use defaults such as `Player 5`.

5. **Bottom actions**
   - Keep `Add` and per-player delete; no bulk deletion.
   - Keep bottom `Confirm` to apply drafts using current editor behavior.

### Current list behavior (Phase 4)

- Open from setup's `Players` tile. Phase 4 edits only the current roster; Phase 6 adds the preset card/library below.
- Trim names on confirmation; reject empty names. Duplicate names are allowed because roles use stable unique IDs.
- Add/delete within 3–100; use unused default-name numbers, never reuse IDs.
- Accessible up/down ordering, without requiring drag-and-drop.
- All actions affect drafts; `Confirm` applies/saves. Dirty Back asks to discard; cancel retains form.
- Phase 4 reports save errors in setup; Phase 6 editor confirmation must await persistence. Failures retain drafts with unsaved/retry feedback inside the editor.

### Saved lists

- Tap the top preset card to open.
- Bottom sheet titled `Saved lists`.
- `Unsaved game` option, description `Quick play without saving`.
- Saved presets show folder icon, name, count, and check matching draft selection.
- Two footer actions:
  - `Save as list…` creates a preset from draft roster/rules.
  - `Manage lists` opens management.
- Selecting a preset loads roster/rules into draft and closes the sheet without changing setup. `Unsaved game` retains draft roster/rules while clearing linkage. Dismissal without selection retains draft.
- Footer actions wrap when narrow; sheets scroll for many presets/large text.

### Save a new list

- Close selection sheet before opening `Save as new list…` dialog.
- `List name` input, placeholder `Enter list name`.
- `Cancel` / `Save`.
- Focusing input opens system keyboard.
- Trim preset names; reject empty/case-insensitive duplicates. Roster must contain 3–100 nonempty names; duplicate player names remain valid through IDs.
- `Save` persists draft roster/rules as a new preset. On success, close and select it in editor; setup changes only on `Confirm`.
- Cancel retains draft/library. A successfully created preset survives discarded editor drafts; setup keeps its previously confirmed selection.
- Block repeated submissions while saving; failures retain input with error/retry. Do not close/report success before persistence completes.

### Manage lists

- Close selection sheet before opening a separate screen; header has Back and `Manage lists`. Back returns to editor with draft retained.
- Each card shows folder icon, name, count, `In use` if confirmed in setup, and vertical ellipsis.
- Card tap opens details without switching presets. Ellipsis opens an anchored popover without triggering the card:
  - `Details`.
  - `Rename list`.
  - `Delete`.
- Divider before delete, using theme error color. Close menus before opening another sheet/dialog.
- Empty libraries explain returning to the editor for `Save as list…`. Explicit loading/read-error/retry; read failures are not empty libraries.

### Rename/delete presets

- `Rename list` opens prefilled dialog with `Cancel`/`Save`; same name validation, excluding itself from duplicates. Preserve ID/roster/rules; update names everywhere only after persistence.
- `Delete` confirms with preset name, cancel/delete. Cancel retains data; success deletes only that preset.
- Deleting the active preset preserves setup roster/rules and changes to `Unsaved game`. Open drafts retain content but clear deleted-preset linkage; later confirmation must not recreate it.
- Write failures retain dialog/content for retry; no premature close/success. Block repeated writes.

### List details

- Card tap or `Details` opens the same read-only bottom sheet, without selecting/loading into setup/draft.
- Summary card: list name and count.
- `Player names`: chips/cards in saved order, wrapping.
- `Game settings`:
  - Fixed imposter count or `Random`, never the sampled game count.
  - `Imposters never start` status.
  - `Show category to imposters` status.
  - `Imposters know each other` status.
- Omit `Show imposter count`; the app has no such setting. Do not invent rules to match images.
- Note: player edits save on `Confirm`; setup rule edits autosave to the active preset. Rules apply only to supporting game types.

### Data, drafts, persistence

- Presets store ID/name, stable player IDs/names/order, next-ID counter, and existing imposter rules: count, fixed/random, never-start, category display, teammate visibility.
- Exclude game type, mode, content categories, UI/content locale, custom content, and sessions. Preset selection retains those setup choices.
- Editors draft roster/rules/preset ID independently. Add/delete/edit/reorder/switch affects drafts only. `Confirm` applies setup and updates the selected preset if it still exists; dirty Back asks to discard. Discarding neither updates old presets nor deletes newly saved ones.
- `Unsaved game` clears linkage only after `Confirm`, without deleting/overwriting the previous preset. Reducing players still clamps imposters under Phase 4 rules.
- Setup rule edits autosave to the confirmed preset; player edits save only after `Confirm`. Management rename/delete persists independently of editor drafts.
- Use existing Hive/`LocalJsonStore`, serialized atomic setup/link/library updates. Old setup restores with empty library, `Unsaved game`, and original roster/rules; preserve JSON → Hive migration.
- Read failures never reset/overwrite automatically; allow retry and block dependent writes until read/validation succeeds. Write failures retain drafts/forms with unsaved/retry feedback; changed in-memory state alone is not success.
- Data remains on-device; do not send player names/rules to backend. Active sessions retain snapshots.

### UI rules and checks

- Reuse `AppTheme`/`AppColors`, `AppContent`, spacing, routing, Signals/Riverpod, and VI/EN ARB; do not copy reference purple/dark palettes.
- Sheets/modals support scrolling, SafeArea, keyboard, small screens, text scale 2; icon buttons have labels, selected/in-use states have text/checks.
- Unit/widget and real storage close/reopen checks: select/confirm/cancel drafts, create then discard, rule autosave, details, rename, active-preset deletion, no resurrection, errors/retries, legacy data. Regress word games after preset loading; run l10n/analyze/test during implementation.
- No screenshot/image-based verification required for Phase 6. Add no synchronization, login, or new game rules.

## 16. Settings screen

### Purpose

Change language, open instructions, rate/send feedback, and view app identification.

### Layout

1. **Header**
   - Back on the left.
   - Centered `Settings`.

2. **General options**
   - `Language`: one choice for UI/categories/prompts; names/codes from DB, showing only VI/EN supported by UI.
   - `How to play`: icon/arrow to instructions.
   - Both in one card with divider.

3. **Rating/feedback**
   - `Rate app`: opens configured platform store rating page.
   - `Send feedback`: opens configured developer feedback channel.
   - Missing URLs/app IDs/channels show unavailable with reasons; no fake URLs.
   - Both in one card with divider.

4. **App information**
   - Group title: `App information`.
   - `App version`: current version/build, e.g. `4.2.2 (158)`.
   - `Installation ID`: abbreviated, anonymous device-local ID with full-copy action.
   - Both in one card with divider.

### Behavior

- Language changes UI/game content together only after successful setup persistence. One saved value; write failures keep old language.
- `Language` uses Card/ListTile with DB name, locale code, icon, selected semantics. Keep screen open to show progress/save errors/retry; change content only after persistence.
- Paginated list ordered by `sort_order`, then `code`; loading/error/retry/cache notices. Do not derive it from ARB. Languages disappearing after successful refresh are unavailable; retain old selection and block starting.
- Setup/picker link to Language. New locales without snapshots block confirmation/start; empty snapshots explain no content and offer language changes. Locale changes discard picker drafts and retain category IDs eligible in the new snapshot.
- No language changes mid-game. Sessions retain prompt/category snapshots; replay returns to setup. Custom forms retain opening locale and are not deleted by language changes.
- `How to play` opens existing instructions.
- `Rate app` / `Send feedback` open appropriate apps when configured; otherwise disabled with reasons.
- Copy writes the entire installation ID to clipboard even when displayed abbreviated.
- Back returns to the previous screen.

## 17. Shared layout rules

- Vertical, mobile-first screens.
- Horizontally centered main content.
- Large content blocks use rounded cards.
- Primary actions sit near the start screen bottom.
- Instructions use short titles and readable descriptions.
- Long screens scroll vertically.
- Respect status/navigation bar safe areas.

## 18. Defined flows

```text
Start screen
├── Start
│   └── Game setup
│       ├── Settings
│       │   ├── Language
│       │   └── How to play
│       ├── Choose game type
│       │   ├── Word game
│       │   └── Question game
│       ├── Choose mode
│       │   ├── Classic
│       │   └── Family
│       ├── Choose categories
│       │   ├── All categories
│       │   ├── One or more specific categories
│       │   └── Create custom category
│       ├── Player names
│           ├── Saved lists
│           │   ├── Save as new list
│           │   └── Manage lists
│           │       └── List details
│       └── Start game
│           └── Players
│               └── Word reveal
│                   ├── Voting stage
│                   └── Results reveal
│           └── Question game
│               ├── Players
│               ├── Answer question
│               ├── Everyone's answers
│               ├── Discussion stage
│               └── Results + Play again
└── How to play
    └── Instructions + Pro tips
```

## 19. Screens awaiting additional images

- Role/secret-word reveal.
- Giving clues.
- Voting.
- Game results.
- Other supporting screens as needed.

## Related documents

- [Phase/PR application implementation plan](../app-implementation-plan.md)
- [Admin Screen Layout](admin-screen-layout.md)

### Phase 7 acceptance notes — 2026-10-27

- Setup app bar has `Refresh content`, tooltip/semantics, disabled while syncing. Retained content remains playable; successful empty refresh replaces snapshots and removes invalid category selections.
- Local word images appear below revealed civilian words and on results. No image widgets/semantics on hidden cards, imposters, player lists, or discussion. Results reuse the image widget and scroll area.
- Widget tests cover late images, missing/decode failures, placeholders, lifecycle/semantics, sessions unchanged by refresh, 320×568 at text scale 2 in both themes. Existing tests also check results/voting at 320×568, 844×390, 1024×768.
- No screenshots; real-device/Release checks remain pending.
