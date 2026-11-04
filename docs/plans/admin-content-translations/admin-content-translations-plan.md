# Multilingual Content Management — Admin and DB

Created: 2026-10-24

## Goals and agreed decisions

Move categories, word prompts, and question prompts to a **base record + translation tables** model. Admins open one item and add/edit language versions on the same screen.

- Initially support `vi`, `en`; add languages as data without adding DB columns.
- Each translation has its own `draft`, `published`, `archived` status.
- Images, difficulty, Family labels, and category belong to the base prompt and are shared.
- Vietnamese is not mandatory; do not replace missing content with another language.
- Scope is admin and DB; no Flutter prompt fetching, automatic translation, or UI language management yet.
- Develop/test phases sequentially; deploy DB and admin together when complete.

## Phase 1 — Inventory data and finalize migration

**Completed locally (2026-10-24):** [Inventory, dependencies, and migration contract](./admin-content-translations-phase-1.md). Read-only audit SQL and tests exist; target counts are projections. Actual backfill reconciliation belongs to Phase 2; rerun target DB audit before Phase 6.

### Tasks

- Inventory data by language, status, category, and images; inspect all queries, triggers, RLS, RPCs, and fixtures depending on fields being moved.
- Inspect actual language codes before creating the language list; preserve every existing code.
- Each current row becomes one base record and its corresponding translation. Preserve original IDs, category links, image paths, and creators.
- Do not merge Vietnamese–English rows into one prompt/category without reliable existing links.
- Old category translations receive `published`; preserve base `is_active`, including disabled categories.
- Slugs become shared category identifiers, unique per game type. If removing `locale` causes duplicates, the smallest ID keeps its slug; append full UUIDs to the others and record changes in the conversion report.

### Completion criteria

Before/after counts reconcile, with no skipped data or inferred translation merging.

## Phase 2 — Schema, security, and DB API

**Completed locally (2026-10-24):** [Migration, RPC contract, and testing report](./admin-content-translations-phase-2.md). Migration applied, all 5 source rows reconciled, database types regenerated; SQL suites, concurrency, DB lint, and advisors passed. As agreed, admin callers/UI and TypeScript fixtures migrate in Phases 3–5; admin is temporarily incompatible with the new schema and typecheck fails. No cloud deployment.

### New structure

| Table | Main data |
| --- | --- |
| `content_languages` | Language code, display name, order |
| `game_categories` | ID, game type, slug, order, enabled/disabled |
| `game_category_translations` | Category ID, locale, name, description, status |
| `word_prompts` | ID, category ID, difficulty, Family label, image |
| `word_prompt_translations` | Prompt ID, locale, word text, status |
| `question_prompts` | ID, category ID, difficulty, Family label |
| `question_prompt_translations` | Prompt ID, locale, both questions, status |

Preserve creation/update metadata on base records and translations; content–language pairs are unique and `locale` references `content_languages`.

### Behavior and API

- Add save RPCs per content type accepting shared data, the edited translation, and expected version; save everything in one transaction.
- Each translation change updates base `updated_at`. RPCs use this version to prevent cross-tab overwrites.
- Only active admins may write; clients cannot directly write content tables. RPCs fully check permissions and data.
- Saved translations must have valid content; question prompts still require different questions. Untouched tabs do not create empty records.
- Publishing prompts requires enabled categories and published category translations in the same language.
- Public readers see only published translations under enabled categories with published category translations in the same language. Base records are visible only with eligible public translations.
- Adjust Storage permissions so shared images are readable when a prompt has at least one eligible public translation; preserve format, size, path ownership, and cleanup checks.
- Update delete RPCs to delete translations too, preserving version checks and Storage file retention.
- Regenerate TypeScript database types once schema is stable.

### Completion criteria

Atomic saves, authorization, and overwrite prevention are tested directly in DB.

## Phase 3 — Admin category management

**Completed locally (2026-10-24):** [API, multilingual editor, and testing report](./admin-content-translations-phase-3.md). Lists default to `vi`, search all translated names/slugs, and paginate server-side; extra RPCs support lists, versioned activation, and valid transfer targets. Admin 48 tests, 5 DB rehearsal groups, and 8 races passed; Vite bundle passed. Full build/typecheck still has transitional Phase 4 errors in both prompt types. No cloud deployment.

- One editor with shared information and language tabs from `content_languages`.
- Each tab has its own name, description, status, and save/publish/archive actions. Missing tabs show “No translation”.
- Switching tabs retains unsaved content in memory; saving sends only shared fields and the current translation. Leaving still warns about unsaved changes.
- Lists have one row per category, language statuses, and base-prompt totals. Search translated names/slugs; paginate server-side.
- Enabling/disabling categories affects every language. Archiving a category translation hides prompts of that language publicly.
- Transferring prompts requires matching game types, enabled targets, and published target translations for every published prompt language.
- Delete previews distinguish base-prompt counts from translation counts by status. Snapshots include translation changes to reject stale confirmations; purge removes all related translations.

### Completion criteria

Category creation, translation, publication, transfer, and deletion work in both languages.

## Phase 4 — Admin management of both prompt types

**Implemented and automatically tested locally (2026-10-24):** [Editor, list RPCs, and testing report](./admin-content-translations-phase-4.md). Both editors use shared fields + language tabs, atomically saving one translation while retaining other drafts. Admin tests, full typecheck/build, SQL rehearsal, concurrency, and Storage integration passed. Direct keyboard/layout checks move to Phase 5 because tools could not access the browser window. No cloud deployment.

- Apply shared fields and translation tabs to word/question prompts using existing Nuxt UI components.
- Adding translations does not duplicate base prompts or automatically copy another language.
- Save/publish/archive affects only the selected translation. Deleting base prompts deletes all translations and must explicitly say so in confirmation.
- Lists have one row per base prompt, default language filter `vi`, and translation statuses.
- Missing selected-language translations still show a “No translation” row that opens for addition. Status filters exclude missing translations.
- Search/sort content in the selected language, missing values last. Count/paginate base prompts.
- Preserve image upload/error handling, repeated-click prevention, conflict reload, and unsaved changes warnings. Explain that shared edits affect all languages.
- Update APIs, form schemas, types, and fixtures; content locale is independent of admin UI locale.

### Completion criteria

Vietnamese can be published while English remains draft; editing one translation does not overwrite another.

## Phase 5 — Dashboard and integration testing

**Implemented and automatically tested locally (2026-10-24), manual verification incomplete:** [Dashboard, HTTP conflict fix, and testing report](./admin-content-translations-phase-5.md). Admin 57/57 tests, full typecheck/build, 6 migration rehearsal groups, 8 races, Storage HTTP integration, and DB lint/advisors passed. Added a forward migration changing explicit conflicts from `40001` to `PT409` to avoid PostgREST retries timing out. Directly checked dashboard, word draft retention, and question draft/save/publish/archive; 390px layout and listed UI flows remain due to unstable browser/capture tools. No cloud deployment.

- Dashboard language selector defaults to `vi`; published counts, drafts, and warnings use that language.
- `admin_dashboard_summary` accepts `p_locale`; returned items include locale to open the correct translation tab.
- Update cache keys/invalidation for categories, prompts, and dashboard after relevant changes.
- Update existing SQL/admin tests, Storage integration, and concurrency tests.

### Required scenarios

- Migration preserves content, statuses, IDs, and images on fresh DBs and legacy copies.
- Reject duplicate translations, unknown language codes, empty content, and identical questions.
- Outsiders cannot read drafts or write content; revoked admins cannot continue writing.
- Concurrent saves in two tabs report conflicts; failed saves cannot partially persist shared fields/translations.
- Category translation archiving/activation, transfer/purge, and post-preview translation edits preserve read eligibility and version checks.
- Images are accessible only when publicly eligible; upload/save failures preserve correct cleanup.
- Adding a test language creates tabs/translations without schema changes or separate forms.

### Completion criteria

SQL/admin tests, typecheck, local build, and Storage integration pass; directly check admin flows with keyboard and UI.

## Phase 6 — Conversion and deployment

**Local backup/restore, automated tests, and documentation complete (2026-10-24); manual UI verification and cloud deployment pending:** [Phase 6 report and cutover procedure](./admin-content-translations-phase-6.md). As agreed, do not resume Dev or deploy hosting. Backup restore matches 13 tables; admin 57 tests, 6 rehearsal groups / 8 races, Storage integration, and lint/advisors passed. Remaining UI checks stay unverified; cloud cutover below is guidance, not executed.

- Rehearse migrations on DB copies, reconcile data, and check permissions before deployment.
- Back up DB; pause admin, close old sessions, apply migrations, then deploy new admin.
- Remove old content columns only after successful transactional backfill reconciliation; update all dependencies before committing the migration.
- Smoke-test login, lists, save, publish, and public reads; reopen admin and require tab reloads.
- Migration failure rolls back its transaction. If post-deployment checks fail before writes reopen, restore backup and old admin.
- Update schema, language, test-command, and deployment documentation.

## Limits and risks

Local DB was reconciled in Phase 1; inactive Dev cloud and deployment DBs were not. The user confirmed no known external clients. Content schema/APIs will change; stop old admins during conversion and recheck consumers before deployment.
