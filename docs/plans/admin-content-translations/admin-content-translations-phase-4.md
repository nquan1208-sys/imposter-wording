# Phase 4 — Admin Management of Both Prompt Types

Implemented locally on 2026-10-24. Additional migration: [20261024055441_admin_prompt_translations.sql](../../../supabase/migrations/20261024055441_admin_prompt_translations.sql). No cloud deployment.

## Behavior

- Word/question prompts have shared fields and tabs from `content_languages`. Category, difficulty, Family flag, and word images are shared; UI explains their effect across languages. New tabs are blank, without copied content or empty rows.
- Each tab retains an in-memory draft. Save/publish/archive sends shared fields and exactly one translation. Successful saves clean only shared fields and that tab, staying in the editor; first save switches create → edit URL without remounting or losing other drafts.
- Always use `original.updated_at`, never translation timestamps. Background refetch preserves dirty/busy drafts. Conflicts block saving until explicit reload; canceling reload retains content. Upload/save/delete block repeated clicks, leaving, and logout.
- Preserve image validation, object URL previews, signed URLs, cleanup after failed saves, and file retention on deletion. Confirmation explicitly deletes the base prompt and all translations, using saved content and base version.
- Lists have one row per base prompt, default locale `vi`, independent of UI language and stored in URL/cache. Unknown locales normalize to `vi`. Show per-language statuses and missing-translation labels, allowing missing tabs to be opened and filled.
- Search only selected-locale content; questions search both fields. Content sorts ascending with missing values last; updates sort descending, with ID for stability. Status filters exclude missing translations. DB counts/paginates base prompts, 20 rows/page.
- List archive affects only the selected translation. Conflicts block archive until successful list reload. Delete still removes the entire prompt. Mutations invalidate both prompt-type, category, and dashboard caches.
- Fully paginate category options for the right game type; labels use selected-locale translations or slugs. Editors retain current categories, allow enabled choices, and preserve selection across language changes. DB still checks publishing and all published locales on category transfer.

## API contract

- Preserve Phase 2 `save_word_prompt`, `save_question_prompt`, both delete RPCs, and security rules. Save APIs return `{ original, translation }`; detail reads base records, all translations, and category translations. No direct table writes.
- Add `admin_list_word_prompts` and `admin_list_question_prompts`: accept `p_locale`, `p_search`, `p_category_id`, `p_difficulty`, `p_is_family_friendly`, `p_status`, `p_sort`, `p_page`; return JSON `{ rows, total }`.
- Rows contain base information, nullable selected-locale content/status, `locale`, `translations`, and `game_categories` with nullable name and slug. Out-of-range pages return empty rows and accurate totals. Search is literal substring, without `%`/`_` wildcards.
- List RPCs require active admins, empty search paths, EXECUTE restricted to authenticated, and `private.require_content_admin()` as in Phase 3. Do not enable direct writes or change RLS/Storage policies.
- Regenerate `database.ts` from local schema; adjust nullable RPC arguments only in `AdminDatabase`.
- Applied migration through local psql and recorded ledger with `supabase migration repair --local --status applied 20261024055441`. No local reset.

## Testing

From `admin`:

```bash
rtk proxy yarn test
rtk proxy yarn build:local
rtk proxy yarn test:storage
```

From the repository root:

```bash
rtk proxy python3 supabase/tests/content_translations.py
rtk proxy psql postgresql://postgres:postgres@127.0.0.1:54322/postgres -X -v ON_ERROR_STOP=1 -f supabase/tests/admin_prompt_translations.sql
rtk proxy supabase db lint --local --schema public,private --level warning --fail-on warning
rtk proxy supabase db advisors --local --type all --level warn --fail-on warn
rtk proxy supabase migration list --local
```

- Admin: **52/52 tests passed**. Coverage includes API/schema, UI-locale independence, one-translation saves, other-draft retention, third language, returned versions, errors/retries, conflict/reload, background refetch, repeated-click prevention, and delete/leave/logout guards.
- Navigation tests compile real templates: both editors retain Vietnamese drafts through first English save and create → edit routing in AdminShell.
- Full typecheck covers app and node/test config; local Vite build passes. Phase 3 transitional errors are resolved.
- Migration rehearsal: **6 unittest groups passed** on disposable copies, including Phase 4 replay on empty/legacy DBs, SQL suites, and **8 concurrency races**. No reset or changes to original local data.
- New SQL suite checks both prompt types: base counts, sort/pagination/empty pages, missing translations, independent statuses, selected-locale/two-question/literal special-character search, filters, and rejection of anon/outsiders/revoked admins.
- DB lint/advisors have no warnings/errors; local ledger matches.
- Storage HTTP integration passed: drafts blocked, published reads allowed, archive/republish, deletion retains bytes but blocks new access, old signed URLs stay valid, outsiders cannot upload, revoked admins cannot read. Fixtures now use RPCs/base versions; cleanup locks categories before deletion.
- The first Storage run timed out due to an incorrect fixture version; fixed it, reran successfully, and cleaned only temporary data. DB returned to **3 categories, 1 word prompt, 1 question prompt**, without Storage test users.

## Remaining work

Could not check the UI directly with keyboard or 390px viewport: tool inventory had no browser surface; native Chrome returned `cgWindowNotFound`. Template/navigation tests do not replace actual visual/accessibility checks; carry these to Phase 5.

Dashboard locale/statistics and expanded integration testing remain Phase 5; cloud deployment/backup/cutover remain Phase 6. No dependencies or shared editor framework added.
