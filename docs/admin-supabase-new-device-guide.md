# Guide to Running the Project on a New Machine

Current Family Mode contract and local upgrade procedure: [Category-Based Family Mode](family-mode.md).
This guide sets up the `imposter-wording` repository on a new machine,
including:

- Vue/Vite Admin in `admin/`.
- Supabase database, Auth, RLS, and migrations in `supabase/`.
- Two Supabase connections: Dev cloud or local Supabase.

Based on `docs/admin-supabase-setup-plan.md` and the repository's
actual state.

> **Status 2026-10-24:** local includes login, route guards, multilingual CRUD,
> dashboard, and private `word-prompt-images` bucket. Dev cloud is INACTIVE and
> translation migrations are not deployed. Use local first; do not push cloud
> through the quickstart before following the [cutover procedure](./plans/admin-content-translations/admin-content-translations-phase-6.md).

## 1. Choose how to run

### Option A — Dev cloud, after cutover

Choose this to run Admin on a new machine using the existing shared
Dev database.

- No Docker required.
- No `supabase start` required.
- Requires Dev project access and Publishable key.
- Cloud data is shared; do not use it to test destructive migrations
  or data operations.

### Option B — Local Supabase, more complete and safer

Choose this to test migrations/RLS or experiment with independent local
data.

- Requires Docker Desktop, OrbStack, or a Docker-compatible runtime.
- Requires Supabase CLI.
- Local data is independent of Dev cloud.

Currently use **Option B** to open Admin. Option A is available only when Dev is running with a compatible schema.

### Dev cloud path — only after cutover

After installing Git, Node.js, and Yarn, the main commands are:

```bash
git clone <REPOSITORY_URL>
cd imposter-wording

cd admin
yarn install --frozen-lockfile
cp .env.example .env.development.local
# Open .env.development.local and enter Project URL + Publishable key

cd ..
supabase login
supabase link --project-ref pxycsjwjakzehcuygngv
supabase migration list --linked
# If migrations are pending, follow the cutover procedure; do not push directly.

cd admin
yarn dev:development
```

Run `yarn dev:development` only when Dev is active and its ledger matches the new admin schema.

## 2. Prerequisites

### 2.1. Required tools

Check installed tools:

```bash
git --version
node --version
npm --version
yarn --version
```

Recommended:

- Node.js 20 or later.
- Yarn `1.22.22`, matching `packageManager` in `admin/package.json`.
- Git.

If Yarn 1.22.22 is missing, install through Corepack:

```bash
corepack enable
corepack prepare yarn@1.22.22 --activate
yarn --version
```

If `corepack` is unavailable, use npm:

```bash
npm install --global yarn@1.22.22
yarn --version
```

### 2.2. Tools needed only for local Supabase

`supabase start` runs multiple services in containers. Install and open one
of these:

- macOS: OrbStack or Docker Desktop.
- Windows/Linux: Docker Desktop, Rancher Desktop, or Podman compatible with
  Docker API.

Check Docker daemon:

```bash
docker --version
docker info
```

If `docker info` cannot connect to the daemon, open Docker Desktop or
OrbStack and rerun it.

Install Supabase CLI on macOS with Homebrew:

```bash
brew install supabase/tap/supabase
supabase --version
```

Without global installation, use `npx` with Node.js 20 or later:

```bash
npx supabase --version
```

Remaining examples use `supabase`. For `npx`, adapt commands,
for example:

```bash
npx supabase start
npx supabase db push
```

## 3. Clone the repository on a new machine

Replace `<REPOSITORY_URL>` with the actual repository Git URL:

```bash
git clone <REPOSITORY_URL>
cd imposter-wording
git status
```

If SSH is required and no key is configured, inspect the remote:

```bash
git remote -v
```

Check essential files exist:

```bash
test -f admin/package.json && echo "admin/package.json: OK"
test -f supabase/config.toml && echo "supabase/config.toml: OK"
test -d supabase/migrations && echo "supabase/migrations: OK"
```

Do not run `supabase init` on the new machine. `supabase/` and
`config.toml` are committed; rerunning `supabase init` may
change existing configuration.

## 4. Install Admin dependencies

From the repository root:

```bash
cd admin
yarn install --frozen-lockfile
```

This installs exact packages from `admin/yarn.lock`, including Vue, Vite,
and `@supabase/supabase-js`.

Check installation:

```bash
yarn --version
test -d node_modules && echo "node_modules: OK"
```

Return to the root for Supabase commands:

```bash
cd ..
pwd
```

## 5. Create Admin environment files

Do not commit `*.local`. Each Vite mode uses its own file:

| Purpose | Vite mode | File | Supabase target |
| --- | --- | --- | --- |
| Local | `localdev` | `admin/.env.local` | Local Supabase |
| Development | `development` | `admin/.env.development.local` | Dev cloud project |
| Production | `production` | `admin/.env.production.local` | Not configured |

Frontend may use only these two variables:

```env
VITE_SUPABASE_URL=...
VITE_SUPABASE_PUBLISHABLE_KEY=...
```

Never put these values in `VITE_*` files:

- `service_role key`.
- Secret key.
- Database password.
- JWT secret.

`VITE_*` values are browser-bundled. RLS is the primary protection for
frontend requests.

### 5.1. Configure Dev cloud

Copy the example:

```bash
cd admin
cp .env.example .env.development.local
```

Open in any editor:

```bash
nano .env.development.local
```

Enter:

```env
VITE_SUPABASE_URL=https://pxycsjwjakzehcuygngv.supabase.co
VITE_SUPABASE_PUBLISHABLE_KEY=<PUBLISHABLE_KEY_FROM_SUPABASE_DASHBOARD>
```

Get the key from the `imposter-word` Supabase Dashboard:

1. Open project `imposter-word`.
2. Open **Project Settings → API** or **Connect**.
3. Copy **Publishable key**.
4. Paste into `VITE_SUPABASE_PUBLISHABLE_KEY`.

Do not copy `service_role` or Secret keys.

Check the file exists without printing the key:

```bash
test -s .env.development.local && echo "Dev env file: OK"
```

### 5.2. Configure local Supabase

This file is not needed before `supabase start`; CLI prints the local key
after startup. Return to the root and start the local stack per
section 6, then get `API URL` and `anon key` from `supabase status`.

Create:

```bash
cd admin
cp .env.example .env.local
nano .env.local
```

Enter local URL:

```env
VITE_SUPABASE_URL=http://127.0.0.1:54321
VITE_SUPABASE_PUBLISHABLE_KEY=<ANON_KEY_FROM_SUPABASE_STATUS>
```

For local stacks, CLI usually calls the frontend key `anon key`. Use
it in `VITE_SUPABASE_PUBLISHABLE_KEY`, never `service_role key`.

## 6. Option B — Set up local Supabase

Run from the `imposter-wording` root.

### 6.1. Start the stack

```bash
cd /path/to/imposter-wording
supabase start
```

First startup may take minutes while CLI downloads Docker images. On success,
check status:

```bash
supabase status
```

Important values:

- API URL: usually `http://127.0.0.1:54321`.
- Studio URL: usually `http://127.0.0.1:54323`.
- Mailpit URL: usually `http://127.0.0.1:54324`.
- `anon key`: for `admin/.env.local`.

Open local Supabase Studio:

```text
http://127.0.0.1:54323
```

Supabase uses repository migrations from
`supabase/migrations/`. Check local history:

```bash
supabase migration list
```

### 6.2. Reset local database from migrations

Run only if you accept deleting the entire local database:

```bash
supabase db reset --local
```

This deletes the local DB, replays migrations chronologically, and
runs seeds if present. Do not run against a cloud project.

Check tables after reset in Studio or SQL Editor:

```sql
select table_name
from information_schema.tables
where table_schema = 'public'
  and table_name in (
    'admin_users',
    'game_categories',
    'word_prompts',
    'question_prompts',
    'content_languages',
    'game_category_translations',
    'word_prompt_translations',
    'question_prompt_translations'
  )
order by table_name;
```

Check RLS:

```sql
select schemaname, tablename, rowsecurity
from pg_tables
where schemaname = 'public'
  and tablename in (
    'admin_users',
    'game_categories',
    'word_prompts',
    'question_prompts',
    'content_languages',
    'game_category_translations',
    'word_prompt_translations',
    'question_prompt_translations'
  )
order by tablename;
```

`rowsecurity` must be `true` for all eight tables.

### 6.3. Create a local admin user for testing

Local users exist only in local Supabase and cannot log into
Dev cloud.

Open local Studio:

```text
http://127.0.0.1:54323
```

Then:

1. Open **Authentication → Users**.
2. Choose **Add user**.
3. Enter test email/password.
4. Enable **Auto Confirm** for immediate login if desired.
5. Record the user's email.

Run in local SQL Editor:

```sql
insert into public.admin_users (user_id, role, is_active)
select id, 'admin', true
from auth.users
where email = 'admin.local@example.com'
on conflict (user_id) do update
set role = 'admin',
    is_active = true;
```

Replace `admin.local@example.com` with the newly created email. Check:

```sql
select au.user_id, u.email, au.role, au.is_active
from public.admin_users au
join auth.users u on u.id = au.user_id;
```

### 6.4. Run Admin with the local stack

Open a second terminal, leaving the `supabase start` terminal active:

```bash
cd /path/to/imposter-wording/admin
yarn dev:local
```

Open the URL printed by Vite, usually:

```text
http://localhost:5173
```

For missing environment variables, verify mode and filename:

- `yarn dev:local` reads `.env.local`.
- `yarn dev:development` reads `.env.development.local`.

### 6.5. Stop and restart local stack

Stop while retaining local data:

```bash
cd /path/to/imposter-wording
supabase stop
```

Restart:

```bash
supabase start
```

To delete local data and rebuild from migrations:

```bash
supabase db reset --local
```

## 7. Option A — Connect to Dev cloud

### 7.1. Log into Supabase CLI

From the root:

```bash
cd /path/to/imposter-wording
supabase login
```

CLI opens a browser or requests an access token. Use an account with
access to `imposter-word`.

Check visible projects:

```bash
supabase projects list
```

### 7.2. Link repository to Dev

Current project ref: `pxycsjwjakzehcuygngv`:

```bash
supabase link --project-ref pxycsjwjakzehcuygngv
```

CLI may request the project's database password. This is the Supabase
project database password, not the Publishable key. Do not store it in Git
or `VITE_*` files.

Check local/cloud migrations:

```bash
supabase migration list --linked
```

### 7.3. Apply migrations to Dev

Run only in the cutover window after backup/rehearsal per [Phase 6](./plans/admin-content-translations/admin-content-translations-phase-6.md). A correct dry-run does not replace backups or blocking writes.

Preview changes first:

```bash
supabase db push --linked --dry-run
```

If the migration list is correct, apply:

```bash
supabase db push --linked
```

Recheck:

```bash
supabase migration list --linked
```

Open Dashboard → **Table Editor** to verify eight tables:

- `admin_users`
- `game_categories`
- `word_prompts`
- `question_prompts`
- `content_languages`
- `game_category_translations`
- `word_prompt_translations`
- `question_prompt_translations`

No `supabase start` is needed for Dev cloud.

### 7.4. Create a Dev cloud admin user

In the Dev project's Supabase Dashboard:

1. Open **Authentication → Users**.
2. Choose **Add user**.
3. Enter admin email/password.
4. Enable **Auto Confirm** if email confirmation is not configured.
5. Create the user.

Then open **SQL Editor** and run the following, replacing the sample email
with the actual admin email:

```sql
insert into public.admin_users (user_id, role, is_active)
select id, 'admin', true
from auth.users
where email = 'admin@example.com'
on conflict (user_id) do update
set role = 'admin',
    is_active = true;
```

Check the admin record:

```sql
select au.user_id, u.email, au.role, au.is_active
from public.admin_users au
join auth.users u on u.id = au.user_id
where u.email = 'admin@example.com';
```

You can use `supabase/scripts/grant_admin.sql`, but it contains only
a placeholder email. Never put passwords/secrets in it.

### 7.5. Run Admin with Dev cloud

Ensure `admin/.env.development.local` exists, then:

```bash
cd /path/to/imposter-wording/admin
yarn dev:development
```

Open the URL printed by Vite. Admin calls:

```text
https://pxycsjwjakzehcuygngv.supabase.co
```

To test a build:

```bash
yarn build:development
```

Output is in `admin/dist/`. This is only a frontend bundle; building
does not deploy the website or push the database.

## 8. What current migrations create

Repository migrations create enums:

- `game_type`: `word`, `question`.
- `content_status`: `draft`, `published`, `archived`.
- `difficulty_level`: `easy`, `medium`, `hard`.
- `admin_role`: `admin`.

Main tables:

- `admin_users`: Auth-user admin permissions.
- `content_languages`: language code, name, order; initially `vi`, `en`.
- `game_categories`, `word_prompts`, `question_prompts`: base-record shared information.
- `game_category_translations`, `word_prompt_translations`, `question_prompt_translations`: per-locale content/status; composite base ID + locale keys.

Category slugs stay unique by `game_type`; images, difficulty, and Family labels belong to base prompts.
No cross-locale content fallback. Content language is independent of UI locale.
Add languages as `content_languages` data with DB admin permissions; no language-management UI yet.

RLS and API permissions:

- Public reads only `published` translations; prompts also require enabled categories with published same-locale category translations.
- Base records are public only with at least one eligible translation.
- Active admins read all content; write through permission/version-checked save/delete/toggle/transfer RPCs, never directly from clients.
- Saves update shared fields and the selected translation in one transaction. Stale versions return `PT409`; reload before writing again.
- Logged-in users without active-admin access cannot write.

Migrations do not create `auth_users`; Supabase manages `auth.users`.

## 9. Daily workflow

### 9.1. Working locally

Terminal 1:

```bash
cd /path/to/imposter-wording
supabase start
```

Terminal 2:

```bash
cd /path/to/imposter-wording/admin
yarn dev:local
```

### 9.2. Working with Dev cloud

Without running the local stack:

```bash
cd /path/to/imposter-wording/admin
yarn dev:development
```

### 9.3. Database changes

Create a new migration from the root:

```bash
cd /path/to/imposter-wording
supabase migration new change_name
```

After writing SQL, rehearse on a disposable copy; do not reset DBs containing data to preserve:

```bash
rtk proxy python3 supabase/tests/content_translations.py
```

Preview and push to Dev:

```bash
supabase migration list --linked
# If migrations are pending, follow the cutover procedure; do not push directly.
```

After pushing a migration to Dev, never edit that file. Create new migrations
for subsequent changes so local/cloud histories stay aligned.

### 9.4. Check code before handoff

```bash
cd /path/to/imposter-wording/admin
yarn build:development
```

Frontend-only changes do not need `supabase db push`. Push only for deployment
of migrations, RLS, functions, triggers, or database configuration.

## 10. Production

Production is not configured in this plan. Do not repurpose the Dev
project as production without authorization.

When a production project exists, create a local, uncommitted file:

```bash
cd /path/to/imposter-wording/admin
cp .env.example .env.production.local
nano .env.production.local
```

Enter its URL and Publishable key, then build:

```bash
yarn build:production
```

Minimum production requirements:

- Production Supabase project.
- Appropriate Auth provider/policies.
- Tested migrations pushed to the correct project.
- Production admin user.
- Private `word-prompt-images` bucket and migration policies.
- Hosting for `admin/dist/`.

`admin/.env.production` is intentionally empty to prevent production
builds from accidentally using `.env.local`.

## 11. Word image Storage

Private `word-prompt-images` bucket is created by migration. Images are shared across translations;
paths are `<prompt-uuid>/<file-uuid>.jpg|png|webp`, maximum 5 MiB.
Active admins upload/clean per policy; do not substitute a public bucket.
New image reads require at least one publicly eligible prompt translation.
Issued signed URLs stay valid until expiry. Deleting prompts retains bytes and blocks new access;
failed upload/save cleans new images through the editor workflow.

Run `cd admin && yarn test:storage` with the local stack for Storage HTTP checks.
DB dumps contain Storage metadata, not image bytes; see Phase 6 backup procedures.

## 12. Run Flutter app (optional)

The Supabase Admin setup above does not install Flutter. To run the mobile
app in `app/`, check Flutter/Dart:

```bash
flutter --version
dart --version
```

Then:

```bash
cd /path/to/imposter-wording/app
flutter pub get
flutter test
flutter run
```

The current Flutter app is a separate repository area, and `pubspec.yaml` does not yet
include `supabase_flutter`; this Admin/Supabase setup plan does not connect it
to Supabase.

## 13. New-machine completion checklist

- [ ] `git clone` succeeds.
- [ ] Node.js and Yarn work.
- [ ] `cd admin && yarn install --frozen-lockfile` succeeds.
- [ ] Correct mode chosen: `localdev` or `development`.
- [ ] Correct `.env.*.local` file created.
- [ ] Frontend uses only Project URL and Publishable/anon key.
- [ ] Local: Docker/OrbStack running and `supabase status` succeeds.
- [ ] Cloud: `supabase login` and `supabase link` succeed.
- [ ] Migrations checked with `supabase migration list`.
- [ ] Dev cloud: `supabase db push --linked` run when needed.
- [ ] Admin Auth user created.
- [ ] Admin has a `public.admin_users` record.
- [ ] `yarn dev:local` or `yarn dev:development` opens Vite.
- [ ] `yarn build:development` succeeds.
- [ ] No secrets/passwords committed.

## 14. Troubleshooting common errors

### `yarn: command not found`

Install Yarn 1.22.22:

```bash
corepack enable
corepack prepare yarn@1.22.22 --activate
yarn --version
```

### `Missing VITE_SUPABASE_URL...`

Check:

```bash
cd /path/to/imposter-wording/admin
ls -la .env*
```

Ensure:

- `yarn dev:local` has `.env.local`.
- `yarn dev:development` has `.env.development.local`.
- Variable names are spelled correctly.
- Stop/restart Vite after environment changes.

### `supabase start` fails

Check Docker daemon:

```bash
docker info
supabase status
```

If Docker runs but ports conflict, check `supabase/config.toml`, especially
`54320`, `54321`, `54322`, `54323`, `54324`.
Do not change ports without updating `admin/.env.local` URLs.

### `supabase link` requests a database password

Use the Dev project's database password, not Publishable, anon,
or service keys. If unavailable, a project administrator must
retrieve/reset it in Supabase Dashboard.

### Login succeeds but admin access is denied

Check the Auth user and mapping record:

```sql
select au.user_id, u.email, au.role, au.is_active
from public.admin_users au
join auth.users u on u.id = au.user_id
where u.email = 'admin@example.com';
```

Required result:

- `role = 'admin'`.
- `is_active = true`.

If absent, rerun `insert into public.admin_users` from admin-user
creation. Local and cloud users are separate identities.

### `db push` reports no pending migrations

Usually correct: all local migrations already exist on cloud. Check:

```bash
supabase migration list --linked
```

Create migrations only for actual database changes.

### Admin runs but schema/RPC errors occur

Check environment and migration ledger. New admin needs all translation migrations,
including conflict migration `20261024093556`; do not use old admin with new schema.
Do not reset a DB containing data to preserve.

## 15. References

- [Supabase CLI: installation and local development](https://supabase.com/docs/guides/local-development/cli/getting-started)
- [Supabase local development workflow](https://supabase.com/docs/guides/local-development/cli-workflows)
- [Supabase database migrations](https://supabase.com/docs/guides/local-development/database-migrations)
- [Vite env variables and modes](https://vite.dev/guide/env-and-mode)
