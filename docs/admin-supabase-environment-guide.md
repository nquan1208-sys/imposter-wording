# Admin and Supabase Environment Guide

Current Family Mode contract and local upgrade procedure: [Category-Based Family Mode](family-mode.md).
> Update 2026-10-24: local has the base + translation schema, dashboard, and private Storage
> `word-prompt-images`; Dev cloud is INACTIVE, with no cutover yet. For the current contract, see
> [schema and API permissions](./admin-supabase-new-device-guide.md#8-what-current-migrations-create),
> [DBML](./database-schema.dbml) and [Phase 6 / cutover](./plans/admin-content-translations/admin-content-translations-phase-6.md).
> Do not push translation migrations using the quickstart; back up and rehearse first.


> If setting up a new device, read
> [`admin-supabase-new-device-guide.md`](./admin-supabase-new-device-guide.md).
> This document is a quick reference for switching environments.

This guide runs Vue Admin with three environments:

- Local: Supabase running on your machine.
- Development: Shared Supabase cloud project for Dev.
- Production: the live Supabase cloud project, not configured yet.

## 1. Environment files

Files are located in `admin/`:

```text
admin/.env.local                  # Supabase local
admin/.env.development.local      # Supabase cloud Dev
admin/.env.production.local       # Supabase cloud Production
admin/.env.production             # guard file, currently empty
admin/.env.example                # example file
```

`*.local` files are machine-specific and Git-ignored. The `.local` suffix
does not mean local Supabase; for example, `.env.development.local` stores
Dev cloud credentials on your personal machine.

Each file needs:

```env
VITE_SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
VITE_SUPABASE_PUBLISHABLE_KEY=sb_publishable_xxx
```

Use only the `Project URL` and `Publishable key` from Supabase Dashboard →
Connect. Never use the following in the Vue frontend:

```text
service_role key
secret key
database password
JWT secret
```

`VITE_*` values are bundled into the browser, so publishable keys require RLS and
correct Data API permissions.

### Current values

- Local URL: `http://127.0.0.1:54321`.
- Dev project: `imposter-word`.
- Dev project ref: `pxycsjwjakzehcuygngv`.
- Production: no project/credentials yet.

## 2. Run Admin with Local Supabase

Open the first terminal at the repository root:

```bash
cd /path/to/imposter-wording
supabase start
```

Check whether the local stack is running:

```bash
supabase status
```

If `API URL: http://127.0.0.1:54321` appears, the local stack is running.

Open a second terminal:

```bash
cd /path/to/imposter-wording/admin
yarn dev:local
```

Admin uses `admin/.env.local`.

## 3. Stop Local Supabase

From the repository root:

```bash
supabase stop
```

This stops the local stack while preserving local data. To restart:

```bash
supabase start
```

## 4. Run Admin with Development cloud

No `supabase start` is needed. Simply run:

```bash
cd /path/to/imposter-wording/admin
yarn dev:development
```

Admin uses `admin/.env.development.local` to connect to the Dev cloud project.

## 5. Link Supabase CLI to the Dev project

Run once per machine:

```bash
cd /path/to/imposter-wording

supabase login
supabase link --project-ref pxycsjwjakzehcuygngv
```

`supabase link` may request the Dev project's database password. This is the
database password, not the publishable key, and must not be stored in Git.

## 6. Push migrations to Development cloud

`supabase db push` only pushes database migrations; it does not deploy the Vue app.

### When are repeated pushes needed?

Multiple pushes may be needed during development, but only for database
or Supabase permission changes, such as:

- Creating tables, enums, or columns.
- Updating RLS policies.
- Adding functions, triggers, or Storage policies.
- Creating the initial schema migration.

No `supabase db push` is needed for changes only to Vue components, CSS, frontend logic,
the login screen, or `admin/.env.development.local`. Check those changes
with:

```bash
cd /path/to/imposter-wording/admin
yarn dev:development
```

### Local → Dev cloud workflow

For translation migrations, push only during the [Phase 6](./plans/admin-content-translations/admin-content-translations-phase-6.md) cutover window, after backup/restore rehearsal and blocking writes.

After each meaningful database change tested locally:

```bash
cd /path/to/imposter-wording

# Test on a copy, preserving the local DB
rtk proxy python3 supabase/tests/content_translations.py

# Preview migrations to be applied on Dev
supabase db push --linked --dry-run

# Apply migrations to Dev cloud
supabase db push --linked
```

Do not push after every file save. Group a complete database change into
one migration and push when needed for Dev use or testing.

### Do not edit pushed migrations

After a migration is applied on Dev, do not change its file.
Create a new migration for subsequent changes:

```text
supabase/migrations/
├── 202610030001_initial_schema.sql
├── 202610040001_add_categories.sql
└── 202610050001_update_rls.sql
```

### Git commits and database pushes differ

- `git commit`: stores code and migrations in the repository.
- `supabase db push`: applies migrations to the Dev database.

Normally commit migrations to preserve history, then push them
when you want to update the Dev database.

After creating migration files in `supabase/migrations/`, check first:

```bash
cd /path/to/imposter-wording
supabase db push --linked --dry-run
```

If the migration list is correct, apply it:

```bash
supabase db push --linked
```

Check cloud migration history:

```bash
supabase migration list --linked
```

Test migrations on a local copy before pushing:

```bash
rtk proxy python3 supabase/tests/content_translations.py
```

`db reset --local` deletes and recreates the local database; do not use it
when local data must be preserved.

The repository already has `supabase/config.toml` and schema migrations in
`supabase/migrations/`. After local checks, use `supabase db push
--linked --dry-run` to inspect pending migrations on Dev
before applying them.

## 7. Development versus build

### Run during development

```bash
yarn dev:local
yarn dev:development
```

These commands start the Vite development server with hot reload.

### Build for deployment

```bash
yarn build:local
yarn build:development
yarn build:production
```

These commands create `admin/dist/`. They only bundle the frontend;
they do not automatically deploy to hosting.

Preview the generated build:

```bash
yarn preview
```

## 8. Daily workflow

### Working locally

```bash
cd /path/to/imposter-wording
supabase status
supabase start                 # only if the stack is not already running

cd admin
yarn dev:local
```

### Working with Dev cloud

```bash
cd /path/to/imposter-wording/admin
yarn dev:development
```

### After changing database schema

```bash
cd /path/to/imposter-wording
supabase db push --linked --dry-run
supabase db push --linked
```

## References

- [Vite env variables and modes](https://vite.dev/guide/env-and-mode)
- [Supabase Vue quickstart](https://supabase.com/docs/guides/getting-started/quickstarts/vue)
- [Supabase local development workflow](https://supabase.com/docs/guides/local-development/cli-workflows)
- [Supabase data security](https://supabase.com/docs/guides/database/secure-data)
