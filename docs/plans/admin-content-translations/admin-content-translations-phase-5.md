# Phase 5 — Dashboard and Integration Testing

Implemented and automatically tested locally on 2026-10-24. Direct keyboard checks partly passed; the phase remains open pending 390px viewport and some UI flow checks. No cloud deployment.

## Dashboard and cache

- Selector uses `content_languages`, defaults to `vi`, and stores URL query `locale`; unknown codes normalize to `vi` after discovery. Content language is independent of UI language, with no content fallback.
- `getDashboardSummary(client, locale = 'vi')` sends `p_locale` to the Phase 2 RPC. `DashboardItem` includes `locale` and `category_name: string | null`, matching actual JSON.
- Load summaries only after locale validation; cache key: `['dashboard', 'summary', locale]`. Switching languages never shows old-language results under the new choice. Both language-discovery and summary errors allow retry.
- Recent/draft links open the item's locale tab. List/warning links carry selected locale and preserve existing draft/difficulty/family filters.
- Preserve RPC statistics semantics: count translation statuses in the selected locale. `published` prompts still count when categories are disabled/archived; public-read eligibility remains separate.
- Keep existing prefix invalidation. Tests confirm shared/translation saves, category activation, transfer/purge, archive, and deletion of both prompt types invalidate category, both prompt-type, and dashboard caches for `vi`, `en`, and a third language.

## HTTP-discovered conflict fix

Storage integration deliberately submitted a stale version after upload and reproduced request timeouts instead of conflict errors. The RPC used SQLSTATE `40001` for application-detected version conflicts; PostgREST retries it. This is a [Supabase-documented issue](https://supabase.com/kb/troubleshooting/high-cpu-and-infinite-transaction-retries-when-using-custom-error-codes-in-rpc-functions).

- Forward migration [20261024093556_admin_content_conflict_errors.sql](../../../supabase/migrations/20261024093556_admin_content_conflict_errors.sql) changes explicit conflict literals to `PT409` in seven RPCs: three saves, three deletes, and category activation.
- Migration uses `CREATE OR REPLACE` from current definitions, changing only SQLSTATE literals; preserve signatures, locks, validation, security attributes, and grants. No historical migration or database type edits.
- Admin recognizes `PT409` as conflict and still supports `40001`. Editor tests use the new code while preserving save/delete blocking until explicit reload.
- New `admin_content_conflicts.sql` requires exact `PT409` from all seven RPCs and verifies no partial shared/translation writes. Helpers/concurrency suites accept both codes to rehearse earlier migration stages.
- Applied through local psql and recorded with `supabase migration repair --local --status applied 20261024093556`. No reset.

## Automated testing

From `admin`:

```bash
rtk proxy yarn test
rtk proxy yarn build:local
rtk proxy yarn test:storage
```

From the repository root:

```bash
rtk proxy python3 supabase/tests/content_translations.py
rtk proxy psql postgresql://postgres:postgres@127.0.0.1:54322/postgres -X -v ON_ERROR_STOP=1 -f supabase/tests/admin_dashboard.sql
rtk proxy psql postgresql://postgres:postgres@127.0.0.1:54322/postgres -X -v ON_ERROR_STOP=1 -f supabase/tests/admin_content_conflicts.sql
rtk proxy supabase db lint --local --schema public,private --level warning --fail-on warning
rtk proxy supabase db advisors --local --type all --level warn --fail-on warn
rtk proxy supabase migration list --local
```

- Admin **57/57 tests passed**: dashboard API, locale URL/cache, missing category names, correct-tab links, loading/error/retry, language discovery failures, UI-locale independence, third language, invalidation, and conflict/reload.
- Full app/node/test typecheck and local Vite build passed. The admin bundle still warns above 500 kB; no dependency or bundle restructuring in this phase.
- Migration rehearsal **6 unittest groups passed**, replaying empty/legacy DBs, reconciling content/metadata/IDs/statuses/Storage, running SQL suites through all forward migrations and **8 concurrency races**. Disposable copies were cleaned.
- Expanded dashboard SQL confirms a third language, independent statistics/warnings, draft links, five-item panel limits, and nullable category names. Existing suites still cover validation, permissions, revoked admins, atomic saves, stale previews, transfer/purge, and cross-tab conflicts.
- Storage HTTP integration passed: Vietnamese published/English draft; archiving Vietnamese blocks images; publishing English restores reads; archiving category translation or disabling category blocks images; restoring re-enables reads. Save conflicts clean newly uploaded images, unauthorized uploads leave no files, and shared old images remain readable. Prompt deletion retains bytes, blocks new access, and preserves issued signed URLs.
- Pre-fix Storage testing timed out and failed; after migration, the suite passed in about 2 seconds.
- DB lint/advisors have no warnings/errors; local ledger matches. Cleanup left **3 categories, 1 word prompt, 1 question prompt**, without Storage test accounts or rehearsal DBs.

## Direct checks and remaining work

Native Chrome was accessible in this session despite no browser surface in inventory:

- Default Vietnamese dashboard shows statistics; switching to English by keyboard updates URL, counts, and links. Tabbing to list links shows clear focus; Enter opens the English list with missing-translation labels.
- Opened the missing English word-prompt tab, entered a temporary draft, switched to Vietnamese and returned with Right arrow; draft remained. Leaving warned; Cancel retained content. Discarded the temporary draft without changing original prompt data.
- Created a temporary question prompt through UI, saved draft with create → edit transition, published by keyboard, then archived through confirmation. DB confirmed archived status; cleaned the fixture by exact ID.
- **390px** viewport remains unverified: DevTools toggle did not expose responsive controls, coordinate clicks/drags returned `noWindowsAvailable`; one capture returned `SCStreamErrorDomain -3811`, and images sometimes showed stale content despite updated AX. These captures are not evidence of completed visual QA.
- Still need direct 390px layout checks for dashboard/categories/both editors, category lifecycle, and full upload/save failure flows in the word editor. Related data behavior has automated tests, which do not replace actual UI checks.

Phase 5 remains **implemented, manual verification incomplete**. Backup, cutover, and cloud deployment remain Phase 6.
