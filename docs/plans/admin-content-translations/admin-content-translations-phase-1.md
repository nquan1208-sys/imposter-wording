# Phase 1 — Inventory and Finalize Multilingual Content Migration

Inventory date: 2026-10-24. Scope: this `imposter-wording` repository's local Supabase.

## Results and rerun instructions

Ran the [audit SQL](../../../supabase/scripts/audit_content_translations.sql) as `postgres` in a `REPEATABLE READ READ ONLY` transaction ending in `ROLLBACK`. No schema, content, permission, or Storage changes. Audit returns two JSON rows: data/projected mappings and catalog dependencies. Run from the repository root:

```bash
# Local: enter the local DB password when psql prompts.
rtk proxy psql -X -qAt -h 127.0.0.1 -p 54322 -U postgres -d postgres \
  -v ON_ERROR_STOP=1 -f supabase/scripts/audit_content_translations.sql

# Read the local connection from supabase status without printing credentials.
rtk proxy python3 supabase/tests/audit_content_translations.py
```

For other DBs, use a separately configured `DB_URL` connection:

```bash
rtk proxy psql "$DB_URL" -X -qAt -v ON_ERROR_STOP=1 \
  -f supabase/scripts/audit_content_translations.sql
# Tests also accept DB_URL; fixtures exist only in CTEs and do not write to the DB.
rtk proxy python3 supabase/tests/audit_content_translations.py
```

Accept audit results only with `rls_bypassed = true`, `read_only = on`, `isolation = repeatable read`, and `blockers = []`. Blockers stop migration finalization; do not exclude invalid rows from backfill. Audit requires the old schema through migration `20261021163720`; do not reuse unchanged after Phase 2 removes old columns. SQL/PLpgSQL catalogs do not capture every function-body dependency, so audit exports all `public`/`private` routines plus trigger routines for inventoried tables.

### Source and projected target counts

| Type | Current source | Projected base records | Projected translations | Source locale | Projected translation status |
| --- | ---: | ---: | ---: | --- | --- |
| Categories | 3 | 3 | 3 | `vi` | 3 `published` (new backfill rule) |
| Word prompts | 1 | 1 | 1 | `vi` | 1 `published` (preserved) |
| Question prompts | 1 | 1 | 1 | `vi` | 1 `published` (preserved) |

These are **projected target counts**, not migration results. All three categories are enabled: two `word`, one `question`. The baseline has no draft/archived rows; CTE fixtures test those statuses.

| Category ID | Type | Word prompts | Question prompts | Image references |
| --- | --- | ---: | ---: | ---: |
| `05e3818b-1a72-45d2-94e0-b2ab68d14512` | question | 0 | 1 | 0 |
| `55660f48-084b-4a10-9fcc-383858bd73ec` | word | 1 | 0 | 1 |
| `78abddb8-12a6-4da2-b49a-a24515336446` | word | 0 | 0 | 0 |

- Actual locale: only `vi`; target language list: `vi`, `en`. No empty `en` translations created.
- No duplicate slugs after removing locale; no baseline slug changes needed.
- No empty content, identical questions, incorrect type/locale links, or missing/invalid image paths found.
- `word-prompt-images` contains 3 objects: one referenced and **2 without current references**. Preserve all three; do not assume the others are garbage.
- Bucket is private, 5 MiB, JPEG/PNG/WebP. Audit checks object metadata/paths without downloading/decoding image bytes.
- Local history includes all 10 migrations from `20261003072606` through `20261021163720`. This reconciles current ledger/catalog, without proving every migration was applied byte-for-byte as its file.

### Source manifest

`source_md5` is `md5(to_jsonb(row)::text)`, including all source fields and metadata; it checks integrity, not security. Reports omit prompt contents and creator IDs.

| Type | Source ID = target base ID | source_md5 |
| --- | --- | --- |
| category | `05e3818b-1a72-45d2-94e0-b2ab68d14512` | `530c3f4e712561449d30d6bc38e4b992` |
| category | `55660f48-084b-4a10-9fcc-383858bd73ec` | `e435410e60f74a95d49ca39b6172cee9` |
| category | `78abddb8-12a6-4da2-b49a-a24515336446` | `6fc6bda12f0aec377d514be9ff9bf4c3` |
| question | `0adbb3fb-1498-48dd-972f-a6baf26a6a36` | `cd307a4814867d2ccd40af8f98e500b0` |
| word | `fa776d42-af60-437f-b488-2fe0f70b84c1` | `f2959d0d605d63f22e71b1de1d0e3754` |

The question belongs to category `05e3818b-1a72-45d2-94e0-b2ab68d14512`; the word belongs to `55660f48-084b-4a10-9fcc-383858bd73ec`. Audit returns full `(kind, id, locale, category_id, status)` mappings for reruns on other data.

## Phase 2 backfill contract

| Source | Keep on base | Move to translation |
| --- | --- | --- |
| `game_categories` | `id`, `game_type`, mapped slug, `sort_order`, `is_active` | `name`, `description`, `locale`; add `status = published` |
| `word_prompts` | `id`, `category_id`, `difficulty`, `is_family_friendly`, `image_path` | `text`, `locale`, `status` |
| `question_prompts` | `id`, `category_id`, `difficulty`, `is_family_friendly` | `civilian_question`, `imposter_question`, `locale`, `status` |

- Each source row becomes one base record and exactly one translation. Different IDs remain independent even with identical text or different locales.
- Preserve base `created_by`, `created_at`, `updated_at`; copy them to the initial translation, including `created_by = null`. Finish backfill before enabling new timestamp-changing triggers.
- Do not move/rename/reupload images, change category links or difficulty/Family flags, or restore previously dropped columns (`imposter_text`, `imposter_hint`, `civilian_text`).
- Old categories lack status: **every category translation gets `published`**, including base `is_active = false`. Re-enabling later remains subject to new public-read rules.
- Seed `vi`/`en` with display names meaning Vietnamese/English (the `vi` name remains localized); union all actual locales from the three tables. Preserve other codes and initially use codes as display names; do not convert `vn` to `vi`, lowercase, or trim automatically. Empty/surrounding-whitespace locales are blockers requiring deliberate resolution.
- Slugs are unique by `(game_type, slug)`. Sort UUIDs ascending within duplicate groups: first retains slug, others get `<slug>-<full UUID>`. Audit returns every rename in `slug_changes`. Recheck all resulting slugs; suffix collisions with existing slugs raise `resulting_slug_collision` and stop, without inventing more suffixes.
- Do not edit old migrations. Phase 1 does not change public APIs/types; Phase 2 changes schema, RPCs, and permissions together, with admin migration in later phases.

## Dependencies and later-phase actions

### Current database

Local catalog exports 11 constraints, 21 indexes (13 content, 8 Storage), 7 user triggers, 16 policies, and 13 routines. No content-dependent views/materialized views found. Audit also exports table/column grants, RLS flags, columns/defaults, and `pg_depend`; recheck the deployment DB.

| Dependency | Current state and required action |
| --- | --- |
| `game_categories_slug_locale_key` | Unique `(game_type, slug, locale)`; replace with `(game_type, slug)` after mapping. |
| PK, `*_created_by_fkey`, `*_category_id_fkey` | Preserve base IDs/FKs and creator `ON DELETE SET NULL`; add translation FKs/uniques with cascade on base deletion. Do not change Storage FKs. |
| `game_categories_active_sort_order_idx`, `*_created_by_idx`, PK indexes, `word_prompts_image_path_idx` | Preserve shared-field indexes; add translation metadata indexes as needed. |
| `*_category_status_difficulty_idx`, `*_status_locale_idx` | Depend on base status/locale; replace with suitable shared/translation indexes before dropping columns. Preserve Supabase-managed Storage indexes. |
| `private.category_before_write` / same-name trigger | Trims name/description, checks slug/sort_order, forbids game type/locale changes, sets timestamp. Separate base/translation validation; preserve immutable game type, move content/locale checks to translations. |
| `private.word_prompt_before_write`, `private.question_prompt_before_write` / same-name triggers | Check category type/locale and publication. Move content/status checks to translations; retain base image/ownership/path/object checks, Unicode trim, and different-question validation. |
| `private.validate_prompt_category_game_type` / `validate_word_prompt_category_game_type`, `validate_question_prompt_category_game_type` | Retain game-type checks on base FKs without old category locale. |
| `private.category_content_snapshot(uuid)` | Counts statuses and hashes base prompt JSON. Include category/prompt content/translations; separate base-prompt counts from translation statuses. |
| `public.preview_category_delete(uuid)` | Returns old category + snapshot; change shape together with callers/types/fixtures. |
| `public.delete_category(uuid,text,uuid,text)` | Remove base-category locale comparison; transfer checks every published prompt locale in target; purge all translations. Preserve admin/parent/child locks and snapshot checks; add translation locks. |
| `public.delete_word_prompt(uuid,timestamptz)`, `public.delete_question_prompt(uuid,timestamptz)` | Preserve active-admin/version/row-lock checks; delete translations with bases. Retain Storage files. |
| `public.admin_dashboard_summary()` | Counts/titles/category names come from old tables. Add `p_locale` and returned item locales in Phase 5. |
| `private.is_admin()` | Keep active `admin_users` lookup rather than stale JWT roles. New save RPCs must lock admin grants like existing delete RPCs. |
| `storage.protect_delete`, `storage.update_updated_at_column` / both Storage triggers | Preserve unchanged; do not modify Supabase system code. |

### Permissions and Storage

- All three content tables have RLS. Each has four policies: public/authenticated read and admin insert/update. Authenticated clients currently have direct insert/update; delete is revoked. Phase 2 revokes direct writes in favor of save RPCs checking admin, version, validation, and transactions.
- Current category reads check `is_active`; prompt reads only check `status = published`, without category activation. New schema deliberately tightens eligibility: published prompt translation + enabled category + published same-locale category translation. This is not data loss.
- `Word image admin read`, `Word image admin upload`: preserve admin/path/bucket/MIME/size checks. `Word image admin cleanup`: preserve prohibition on deleting files referenced by base prompts. `Word image published read`: replace old status checks with existence of at least one publicly eligible translation.
- Bucket stays private; retain 300-second signed URLs and cleanup after upload/save failures. Issued URLs remain valid until expiry; policy changes do not revoke them.
- Audit exports routine ACLs: five current public RPCs grant only authenticated/service_role/postgres; `private.is_admin` grants authenticated/postgres. Two old trigger functions have default ACLs (`category_before_write`, `validate_prompt_category_game_type`); explicitly review execution grants when replacing them. Do not grant default public access to new save RPCs.

### Admin, tests, and documentation

| Group | Locations to update |
| --- | --- |
| Queries / mutations | `admin/src/api/{categories,wordPrompts,questionPrompts,dashboard}.ts`: direct writes, category-name joins, search/sort/filter/count, category options/transfer targets, versions, upload/cleanup, delete preview. Use translations/save RPCs; paginate/count base records. |
| Forms / UI | List/form views in `admin/src/views/{categories,word-prompts,question-prompts}`; category table/form/delete components and both prompt delete dialogs. Add DB language tabs, retain per-tab drafts, explain shared edits/deleting all translations. Dashboard locale in Phase 5. |
| Validation / types | `admin/src/utils/{categories,wordPrompts,questionPrompts}.ts`, `admin/src/types/{admin,database}.ts`: separate shared/translation fields; categories currently hardcode `vi`. Regenerate DB types with existing script after schema stabilizes. Keep shared unsaved changes helper. |
| Cache | Existing keys: `categories` list/detail/delete-preview/transfer-targets/word-options/question-options; `word-prompts`, `question-prompts` list/detail; `dashboard/summary`; path-based `word-images`. Add locale to language-dependent queries; invalidate related groups after category/shared/translation edits, including dashboard/delete preview. |
| SQL / concurrency fixtures | `supabase/tests/{category_management,word_prompt_management,question_prompt_management,admin_dashboard}.sql`, `category_concurrency.py`: old direct-column inserts/queries need translation/RPC fixtures, new permission expectations, translation locks. Do not edit historical migrations to satisfy fixtures. |
| Admin fixtures | `admin/tests/{categories,wordPrompts,questionPrompts,dashboard}.test.ts`, `*Components.test.ts`, `navigation.test.ts`, `wordStorage.local.ts`: update query mocks, payloads, joins, cache keys, preview counts, Storage lifecycle assertions. i18n tests check new message keys after UI changes. |
| Config / docs | `supabase/config.toml` points to `./seed.sql`, absent from the repo; fixtures currently live in tests. Add no runtime seeds in Phase 1. Phase 6 updates DBML/environment/setup/deployment docs without changing admin credentials/environment. |
| Flutter / external | No content/RPC queries found in `app/lib`; Flutter is out of scope. User confirmed no known external clients. Admin UI locale (`vi`/`en`, Vietnamese file `vn.json`) is independent of content locale; do not change data codes to match filenames. |

## Required migration reconciliation

Within the migration transaction, after stopping writes and before dropping old columns:

1. Snapshot all old rows before backfill. Compare counts by type, locale, status, category; base count = old row count, translation count = old row count for each type.
2. Bidirectional anti-join by base ID and translation `(ID, locale)`: no missing/extra/duplicate/automatically merged records; totals alone are insufficient.
3. Join bases/translations and reconstruct exact old JSON keys/types, comparing every field with `IS NOT DISTINCT FROM`. Reconstruct category slugs with mapped `old_slug`; independently require new category status `published`. Check metadata on **both** sides, retaining nulls and consistent timezones for manifest hashes.
4. Separately verify target slug mapping/uniqueness, every language code, all FKs/category links, image paths, and unchanged object sets. Do not apply timestamp-update triggers to backfilled metadata.
5. Any mismatch/blocker raises an error and rolls back. Replace dependencies/drop old columns only after all assertions pass; do not use `DROP ... CASCADE` for unreviewed dependencies.

## Testing and remaining work

**6 tests** passed in `supabase/tests/audit_content_translations.py`: empty data; all statuses/multiple locales/UUID ordering; resulting slug collision; invalid content/locale/link/image; retained images/missing FKs; two live audit runs confirming unchanged data/catalog, read-only, and snapshot isolation. Fixtures use typed JSON recordsets in CTEs, without DB inserts or schema changes.

Local Phase 1 inventory and migration contract are complete. Real migration/backfill has not run, so actual target counts remain unconfirmed until Phase 2. No admin build, Storage integration, or concurrency suite because runtime/schema is unchanged.

Dev cloud `imposter-word` (`pxycsjwjakzehcuygngv`) was inactive in project inventory during planning; do not resume or query cloud data. Before deployment, rerun audit on the current target DB/copy, inventory added dependencies, and rehearse per Phase 6. The small local baseline does not represent cloud data.
