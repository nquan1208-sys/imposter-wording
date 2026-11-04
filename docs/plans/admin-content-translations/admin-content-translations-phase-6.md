# Phase 6 — Local Verification and Cutover Procedure

Execution date: 2026-10-24.

**Local backup/restore, automated tests, and documentation are complete; manual UI verification and cloud deployment are incomplete.** Agreed scope is local work + documentation. Do not resume Dev, change credentials, deploy hosting, or deploy Flutter. Phase 5 still has UI checks; do not mark the entire roadmap deployed.

## Local results

- Local ledger matches all **14 migrations**, ending with `20261024093556_admin_content_conflict_errors.sql`. No active DB reset, historical migration edits, or replay on this DB.
- Admin **57/57 tests**, full typecheck, and `build:local` passed. Vite still warns that the 511.40 kB admin chunk exceeds 500 kB; bundle optimization is outside scope.
- Migration rehearsal **6/6 tests**, including empty/populated legacy replay, backfill reconciliation, blocker rollback, and all forward migrations. **8 concurrency races** passed.
- Storage HTTP integration passed: multilingual public visibility, category changes, image cleanup on failed saves, byte retention after deletion, and unexpired signed URLs.
- Local DB lint/advisors have no warnings/errors. Temporary rehearsal/restore DBs were removed.
- Checked relative links in these documents and related guides/READMEs; all eight public DBML tables match local schema columns. `git diff --check` passed.
- Local content retains **3 categories / 5 category translations, 1 word prompt / 1 translation, 1 question prompt / 1 translation**, 2 languages, and 3 Storage objects. Storage fixtures were cleaned.

### Verified backup

Backup is outside Git at:

```text
~/.local/state/imposter-wording/backups/20261024-171412-phase6/local.dump
~/.local/state/imposter-wording/backups/20261024-171412-phase6/verification.json
```

Backup directory permissions are `0700`; dump and manifest are `0600`. Dump SHA-256:

```text
a83322155c6d38a4ec73f9276d50038fa54b742101fed925979539a18cda9ed2
```

Used `pg_dump -Fc` as `supabase_admin`, restoring with `pg_restore --exit-on-error --no-publications --no-subscriptions` into a temporary local-container DB. Compared row counts and MD5 of complete row JSON with stable ordering for 13 tables: eight public tables, `auth.users`, `auth.sessions`, `storage.buckets`, `storage.objects`, and `supabase_migrations.schema_migrations`. Restored/source results matched before tests. The dump includes schema/functions/policies; permissions are tested separately in rehearsal.

This dump contains sensitive Auth data; do not commit/share it. It is a **post-conversion local** snapshot, not an old-schema backup for cloud rollback. DB dumps contain Storage metadata, **not image bytes**. It cannot replace a complete target-environment backup.

### Remaining UI checks

Native Chrome could read category lists and creation forms. DevTools opened through the menu and Width confirmed `390`; however, click/focus sometimes went to the Network filter, and captures were occasionally blank or abnormally zoomed. No UI test content was created/saved in this session; captures do not prove layout acceptance. Left the unsaved form, disabled responsive/DevTools, and returned to the category list.

These items are **not directly verified** and must be completed before cutover:

- 390px dashboard, category, word editor, and question editor layouts; menus, scrolling, save buttons, and confirmations must be accessible.
- Keyboard category lifecycle: create, add translations, publish/archive, enable/disable, transfer, and purge using dedicated fixtures.
- Word editor upload/save failures: retain drafts, show errors, retry, and clean the correct new image.
- Login smoke test with valid admins and rejection of unauthorized users on the actual target environment.

Data behavior has automated coverage; unit/SQL results do not replace incomplete UI verification.

## Rerun tests

From the repository root with the local stack running:

```bash
rtk proxy python3 supabase/tests/content_translations.py
rtk proxy supabase db lint --local --schema public,private --level warning --fail-on warning
rtk proxy supabase db advisors --local --type all --level warn --fail-on warn
rtk proxy supabase migration list --local
```

Rehearsal creates DB copies, runs SQL/concurrency suites, and removes copies without resetting the source. `supabase/scripts/audit_content_translations.sql` and the Phase 1 audit suite require the **old schema**; do not run directly on local DBs after old columns are removed. Audit a legacy copy before migration.

From `admin/`:

```bash
rtk proxy yarn test
rtk proxy yarn build:local
rtk proxy yarn test:storage
```

Storage tests create and clean dedicated fixtures; do not run while capturing backup manifests requiring stable state.

### Create and test a local DB backup restore

From the repository root, without other writes or tests:

```bash
umask 077
backup_dir="$HOME/.local/state/imposter-wording/backups/$(date +%Y%m%d-%H%M%S)"
rtk proxy mkdir -p "$backup_dir"
rtk proxy docker exec supabase_db_imposter-wording pg_dump -U supabase_admin -d postgres -Fc > "$backup_dir/local.dump"
rtk proxy shasum -a 256 "$backup_dir/local.dump"
rtk proxy docker exec supabase_db_imposter-wording createdb -U supabase_admin -O postgres ct_restore_check
rtk proxy docker exec -i supabase_db_imposter-wording pg_restore -U supabase_admin -d ct_restore_check --exit-on-error --no-publications --no-subscriptions < "$backup_dir/local.dump"
```

Stop if any command fails. If `ct_restore_check` exists, do not overwrite it; choose another temporary DB name consistently. For each of the 13 listed tables, run the following on both `postgres` and `ct_restore_check`, then compare outputs:

```sql
-- Replace public.game_categories with each table in the checklist.
select count(*) as rows,
       md5(coalesce(string_agg(row_data, E'\n' order by row_data), '')) as digest
from (select to_jsonb(t)::text as row_data from public.game_categories t) s;
```

Run SQL as `supabase_admin`, without reporting individual row contents. After comparison, delete only the temporary DB just created:

```bash
rtk proxy docker exec supabase_db_imposter-wording dropdb -U supabase_admin --force ct_restore_check
```

## Dev/cloud cutover procedure — not executed

Inventory confirmed Dev `imposter-word` (`pxycsjwjakzehcuygngv`) INACTIVE during planning. No admin hosting or production target is configured. Local results do not establish cloud data safety.

1. Complete remaining UI checks. Identify the correct project, consumers, and old admin artifact for recovery; resume Dev only when cloud deployment is requested. Check CLI `--help`, target ledger, and `db push --linked --dry-run`. Do not repair ledgers to hide migration drift.
2. Back up a target copy for rehearsal: schema, data, required roles, migration history, custom Auth/Storage policies, and image bytes separately. Verify isolated restore before cutover. For legacy DBs, run Phase 1 audit and resolve blockers/dependencies absent from the repo; apply pending migrations on the copy and reconcile IDs, content, metadata, statuses, slug mappings, locales, and images.
3. Prepare `yarn build:development` for the correct project, keeping the old admin artifact outside the repo. Choose a maintenance window. Pause admin; record `admin_users` and statuses, deactivate active admins to block DB writes from old sessions/tokens. Wait for ongoing writes to finish; close old tabs. Hiding UI or browser logout alone is insufficient. Block privileged external writers found by audit.
4. Once writes stop, create a **fresh cutover backup**, verifying checksum/restorability, and separately retain pre-maintenance admin states. Back up Storage bytes in the same stable window; DB dumps omit bytes. Do not migrate before backup/rehearsal passes.
5. Apply the correct pending migrations through CLI without editing history. Translation migration reconciles backfill before dropping columns in the same transaction. Apply subsequent forward migrations, including `PT409`. Check ledger, schema, grants/RLS, and public reads. Multiple migrations do not share one transaction.
6. Serve the new admin at the selected endpoint, verify target API URL, and reload. Enable only test admins while others remain blocked; use dedicated fixtures to smoke-test login, lists, save, publish/archive, same-locale public/image reads, stale-version HTTP 409, and revoked-user write rejection. Clean fixtures before reopening writes.
7. If successful, restore exact pre-maintenance admin statuses and require everyone to reload tabs. Record time, ledger, backup, artifact, and smoke results; monitor Auth/RPC/Storage/conflict errors after reopening. Only then mark cloud deployment complete.

### Failure handling

- Migration failure: that migration's transaction rolls back. Earlier migrations in the batch may have committed; keep admins blocked, inspect ledger/state, and do not continue or use old admin against new schema.
- Smoke failure before reopening writes: retain maintenance, restore DB from the tested cutover backup with ledger/policies and old admin artifact; restore Storage bytes if changed. Verify old schema, permissions, and data before restoring original admin states.
- If writes have reopened, do not overwrite new data with a restore. Block writes, take an incident backup, and reconcile new changes before choosing a forward fix or data-preserving recovery.

Official references: [CLI backup and restore](https://supabase.com/docs/guides/platform/migrating-within-supabase/backup-restore), [Database backups and Storage limits](https://supabase.com/docs/guides/platform/backups).

## Related documents

- [Main plan and phase status](./admin-content-translations-plan.md).
- [Phase 5 and remaining manual verification](./admin-content-translations-phase-5.md).
- [DBML schema](../../database-schema.dbml).
- [New-machine setup / current schema / permissions](../../admin-supabase-new-device-guide.md).
- [Admin environments](../../admin-supabase-environment-guide.md).
