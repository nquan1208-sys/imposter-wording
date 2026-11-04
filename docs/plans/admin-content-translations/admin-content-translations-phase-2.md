# Phase 2 — Schema, Security, and DB API

Completed locally on 2026-10-24. Migration: [20261024045640_content_translations.sql](../../../supabase/migrations/20261024045640_content_translations.sql).

## Conversion results

| Type | Source rows | Actual base records | Actual translations |
| --- | ---: | ---: | ---: |
| Categories | 3 | 3 | 3 |
| Word prompts | 1 | 1 | 1 |
| Question prompts | 1 | 1 | 1 |

- `content_languages` includes `vi` and `en`; current data has only `vi` translations. No empty translations, merged IDs, or changed category links.
- All three category translations are `published`; both prompt translations retain `published`. No slug changes in the local baseline.
- Preserved three Storage objects: one referenced image and two unreferenced images. No image bytes uploaded, deleted, or moved.
- Reconstructed all five source rows from base records and translations: every JSON MD5 matches the Phase 1 manifest. Before dropping old columns, the migration separately checks metadata on both sides, counts, ID/locale, slug mapping, and Storage objects.
- Migration uses a transaction and source-data locks; blockers or reconciliation failures roll back. No historical migrations modified or `DROP ... CASCADE` used.
- Created a local pre-migration backup at `/tmp/imposter-wording-phase2-before.dump`, file permissions `0600`. This temporary backup is outside the repo; deployment backup/rollback procedures remain in Phase 6.

## Schema and read permissions

`content_languages(code, display_name, sort_order)` supplies languages, ordered by `sort_order, code`. Operators with DB permissions add languages as data.

The three translation tables use composite keys `(category_id, locale)` or `(prompt_id, locale)`, language-list FKs, and cascade on base-record deletion. Base records retain shared fields; both sides have `created_by`, `created_at`, `updated_at`.

- `anon` and `authenticated` have explicit SELECT, with no direct INSERT/UPDATE/DELETE/TRUNCATE on the seven content tables. Active admins read all content through RLS.
- Public prompt translations require `published`, an enabled category, and a `published` category translation in the same locale. Base records appear only with at least one eligible translation. No locale fallback.
- `private` helpers return only boolean eligibility and avoid RLS recursion between base/translation tables. Write RPCs use `SECURITY DEFINER`, empty search paths, and checked/locked admin grants from `admin_users`, ignoring stale JWT privileges.
- Images are publicly readable when a prompt has at least one eligible translation. Preserve the private bucket, 5 MiB limit, JPEG/PNG/WebP, paths, uploads, and cleanup. Issued signed URLs may remain valid until expiry.

## RPC contract for Phases 3–5

### Saving

All three RPCs accept caller-provided UUID `p_id`, `p_locale`, `p_status`, `p_expected_updated_at`, and these fields:

| RPC | Shared fields | Translation fields |
| --- | --- | --- |
| `save_category` | `p_game_type`, `p_slug`, `p_sort_order`, `p_is_active` | `p_name`, `p_description` |
| `save_word_prompt` | `p_category_id`, `p_difficulty`, `p_is_family_friendly`, `p_image_path` | `p_text` |
| `save_question_prompt` | `p_category_id`, `p_difficulty`, `p_is_family_friendly` | `p_civilian_question`, `p_imposter_question` |

- Supply every argument. `p_expected_updated_at = null` is creation-only; updates require the exact base-record version. `p_description` and `p_image_path` accept null.
- JSON response is `{ original, translation }`, containing saved rows; use returned `original.updated_at` for subsequent saves, never a browser-generated timestamp.
- Save shared fields and exactly one translation transactionally. Every translation change advances the base version without changing other translations' content/metadata. Do not create records for untouched tabs.
- RPCs set metadata server-side and preserve creation metadata on edits; category game type is immutable. Trim Unicode whitespace and reject empty content, identical questions after trim/lowercase, unknown locales, incorrect image ownership/path, and missing objects.
- Saving a `published` prompt translation requires an enabled category and published category translation in the same locale. Changing a prompt's category checks every `published` locale.
- Lock order: admin grant → categories by UUID → base record → translation. Changes in the same category are serialized for stable publication conditions and delete previews; reduce lock scope only after measuring admin contention.
- SQLSTATE: `42501` unauthorized; `40001` stale version or duplicate creation ID; `P0002` missing record; `23514` invalid conditions/content; `23503` invalid FK; `23502` missing required field; `23505` duplicate key/slug. Publication conditions may reject unknown locales before the FK does.

TypeScript types were regenerated using the existing script. CLI types do not express RPC argument nullability; extend nullable arguments in `AdminDatabase` during admin phases following the existing `delete_category` pattern, without editing generated types or converting null to strings.

### Deletion, preview, and dashboard

- Keep `delete_word_prompt(uuid,timestamptz)` and `delete_question_prompt(uuid,timestamptz)`: require the base version, cascade all translations, retain Storage files.
- `preview_category_delete(p_id)` returns `{ category, category_translations, counts, version }`. `counts.originals` has `total`, `word`, `question`; `counts.translations` counts **prompt translations** by `draft`, `published`, `archived`.
- Preview versions include complete category rows, category translations, base prompts, and prompt translations. Any change invalidates an old preview.
- Keep `delete_category(p_id,p_mode,p_target_id default null,p_expected_version default null)`. `transfer`/`purge` require preview versions; `empty` may omit one, but supplied versions must match. Transfer targets must differ from the source, be enabled, have the same game type, and publish every published prompt locale. Purge cascades translations and retains images.
- Replace dashboard SQL in Phase 2 because the old routine depends on removed columns: `admin_dashboard_summary(p_locale text default 'vi')`. Count only selected-locale translations; items include `locale`, with no category-name fallback and nullable names when missing. Active-category counts require enabled categories with published locale translations; empty-category warnings cover categories with that locale but no prompt translations in it. Unknown locales return `22023`. Dashboard UI/cache remains Phase 5.

## Tests run

Rehearsed on independent DB copies in the local container without resetting the active DB:

```bash
rtk proxy python3 supabase/tests/content_translations.py
```

Passed 4 unittest groups: historical replay on an empty content DB; backfill across locales/statuses/metadata and duplicate slugs; six blocker types rolling back schema/data; local data copy and concurrency. The runner creates/removes copies and runs SQL suites on migrated copies.

SQL suites use rollback fixtures: `category_management.sql`, `word_prompt_management.sql`, `question_prompt_management.sql`, `admin_dashboard.sql`, `content_translations.sql`. Run separately from the repository root with a local connection in `DB_URL`:

```bash
rtk proxy psql "$DB_URL" -X -v ON_ERROR_STOP=1 -f supabase/tests/content_translations.sql
rtk proxy python3 supabase/tests/category_concurrency.py
rtk proxy supabase db lint --local --schema public,private --level warning --fail-on warning
rtk proxy supabase db advisors --local --type all --level warn --fail-on warn
rtk proxy supabase migration list --local
```

- Five SQL suites passed on copies and the migrated local DB. Coverage includes atomic saves, validation, uniqueness, direct/RPC permissions, multilingual RLS, admin revocation with stale JWTs, image eligibility, previews, transfer/purge, and adding languages as data.
- Seven races passed: category deletion/prompt creation; different-locale saves with the same version for each prompt type; translation edit/stale purge preview; publish/archive category translation; transfer/archive target; admin revocation/waiting save. No deadlocks.
- DB lint had no errors; advisors had no warnings/errors. Local migration ledger matches the new file.
- Reran six Phase 1 audit tests before migration. The old audit script requires the old schema and must not run directly on Phase 2 schema.
- Ran `yarn types:database`; generated types reflect new tables and RPCs.

## Transitional work

As agreed, Phase 2 completes only the DB contract. Admin APIs/forms/derived types and old TypeScript fixtures migrate in Phases 3–5. `yarn typecheck` exited 2 with 90 diagnostics from old callers/types referencing removed columns. Admin build/browser UAT and Storage HTTP integration were not run; Storage policies were checked directly in DB. No cloud changes/deployment.

Do not write to the new schema using old admin versions. Deploy the completed DB and admin together in Phase 6; repeat audit/rehearsal against target data first.
