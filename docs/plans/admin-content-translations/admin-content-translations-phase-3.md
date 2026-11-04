# Phase 3 — Admin Category Management

Completed locally on 2026-10-24. Additional migration: [20261024053232_admin_category_translations.sql](../../../supabase/migrations/20261024053232_admin_category_translations.sql). No cloud deployment.

## Implemented behavior

- Forms separate shared information and translations. Tabs come from `content_languages`, ordered by `sort_order, code`; missing tabs show “No translation”, without creating empty rows or copying other languages.
- Name, description, and status belong to each tab. Saving sends shared fields and exactly one translation; publish/archive affects only the selected translation. Confirm category deactivation and archiving published translations.
- Switching tabs retains each draft in memory. Successful saves clean only shared fields and the saved tab; other dirty tabs still trigger leave/close/logout warnings.
- First save creates one UUID, switches to the edit URL, and preserves editor/drafts. The shell retains the category component across create/edit routes; real-template navigation tests cover this.
- Subsequent saves use RPC-returned `original.updated_at`. Errors preserve data; conflicts block saving until explicit reload with draft-discard confirmation. Background refetch does not overwrite dirty/busy editors.
- Lists have a content-language selector defaulting to `vi`, stored in URL/cache keys independently of UI locale. Unknown locales normalize to `vi`, even with a cached language list.
- One row per category: selected-language name or missing-translation label, slug, all language statuses, and base-prompt total. Search all translated names and slugs; sort names by selected language, missing names last. Pagination/counts remain server-side.
- Enable/disable uses base versions without changing translation metadata. Category mutations invalidate category, both prompt-type, and dashboard caches.
- Delete previews separate base-prompt counts from prompt-translation counts by status. Prompts without translations still make a category nonempty.
- Transfer targets must be enabled, match game type, and publish every published prompt locale. Snapshot conflicts block confirmation until successful refresh; invalid targets are deselected. Purge explicitly deletes all translations while retaining Storage files.

## Additional API

| RPC | Input | Result |
| --- | --- | --- |
| `admin_list_categories` | `p_locale`, `p_search`, nullable `p_game_type`, nullable `p_is_active`, `p_sort`, `p_page` | JSON `{ rows, total }`; rows include base information, nullable `name`, `translations`, `word_count`, `question_count` |
| `set_category_active` | `p_id`, `p_is_active`, `p_expected_updated_at` | Updated category row |
| `admin_category_transfer_targets` | `p_source_id`, `p_locale` | `{ id, slug, name }` rows; names may be null |

- New RPCs allow only authenticated calls and check active admin grants; use `SECURITY DEFINER`, empty search paths, and grant locking from Phase 2. Reject `anon`, outsiders, and revoked admins.
- Literal substring search does not interpret `%`/`_` as wildcards; `EXISTS` prevents duplicate counts for multiple matching translations. Pages contain 20 base categories with ID as final sort key. Out-of-range pages still return accurate totals for UI correction.
- Activation locks the category, checks version, returns `40001` for stale versions and `P0002` for missing rows. Existing triggers advance versions and preserve public-read rules.
- Target discovery is advisory; `delete_category` transactionally rechecks snapshots and transfer conditions before writing. Clients fetch all 100-candidate pages without truncating at API limits.
- Preserve Phase 2 `save_category`, `preview_category_delete`, `delete_category` contracts. Do not restore direct table writes.
- Regenerate database types using the existing script; extend nullable args only in `AdminDatabase`, without editing generated files.
- Additional SQL ran through local-container `psql`; recorded application with `supabase migration repair --local --status applied 20261024053232`. Local ledger matches migrations. No local DB reset.

## Testing and reconciliation

From the repository root:

```bash
rtk proxy python3 supabase/tests/content_translations.py
rtk proxy supabase db lint --local --schema public,private --level warning --fail-on warning
rtk proxy supabase db advisors --local --type all --level warn --fail-on warn
rtk proxy supabase migration list --local
```

From `admin`:

```bash
rtk proxy yarn test
rtk proxy yarn types:database
rtk proxy yarn build:local
rtk proxy yarn vite build --mode localdev
```

- Admin: **48/48 tests passed**, covering API, schema, i18n, SSR, editor state, delete dialogs, and real-template navigation. Checks include draft retention, one-locale saving, returned versions, failures/retries, conflict/reload, duplicate prevention, data-driven new tabs, and first-save routing.
- DB rehearsal: **5 unittest groups passed** on disposable copies. Phase 3 replays empty/legacy DBs through Phase 2 and the new migration, rerunning five existing SQL suites and `admin_category_translations.sql`.
- Concurrency: **8 races passed**, including translation edit versus activation with a stale version. No deadlocks. Preview/purge, publish/archive, transfer/archive, and admin revocation races still pass.
- DB lint had no errors; advisors had no warnings/errors. New SQL also ran directly on local DB with rollback fixtures.
- Local Vite bundle passed. `yarn build:local` still stops at typecheck with **70 diagnostics in APIs/components/views for both prompt types**, transitional Phase 4 work. No category-code diagnostics. Separate node/test config checks still show legacy prompt/Storage fixture errors; the full admin build is not passing yet.
- Local browser: created a published English translation while Vietnamese was unsaved, retained Vietnamese through first save/new route, then saved it as draft; list showed `vi: Draft`, `en: Published`. Checked arrow-key tab switching, 390px editor layout, preview counts, and valid transfer targets.
- Browser testing created two temporary categories without prompts; deleted exactly those records and temporary preview files afterward. DB returned to **3 categories, 1 word prompt, 1 question prompt**. Existing content and Storage files were unchanged.

## Transitional work

No cloud deployment, Storage HTTP integration rerun, or multilingual prompt editors/dashboard yet. These remain Phases 4–6. Deploy the completed DB/admin together; do not use old prompt editors to write to the new schema.
