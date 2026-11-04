# Plan: Set Up Admin with Supabase

> Update 2026-10-24: local has the base + translation schema, dashboard, and private Storage
> `word-prompt-images`; Dev cloud is INACTIVE, with no cutover yet. For the current contract, see
> [schema and API permissions](./admin-supabase-new-device-guide.md#8-what-current-migrations-create),
> [DBML](./database-schema.dbml) and [Phase 6 / cutover](./plans/admin-content-translations/admin-content-translations-phase-6.md).
> Do not push translation migrations using the quickstart; back up and rehearse first.
> Phases below retain the original setup plan; old content fields and write permissions are superseded by the translation contract above.


## Goals

Build Vue Admin to:

- Log in through Supabase Auth.
- Manage categories.
- Manage word-game content.
- Manage question-game content.
- Publish, archive, and classify word categories for Family Mode.
- Upload word-content images.
- Use Supabase Data REST API through `@supabase/supabase-js`.

## Current scope

- Players do not log in.
- Player names, answers, votes, and game state are stored locally in the app.
- Admins are the only users of Supabase Auth.
- MVP has no `Admin users` or `Settings` sidebar items.
- Admin sidebar:
  - Overview.
  - Categories.
  - Word content.
  - Question content.
  - Log out.

## Related documents

- Database diagram: `docs/database-schema.dbml`
- App screen layout: `docs/layout/screen-layout.md`
- Admin screen layout: `docs/layout/admin-screen-layout.md`
- Admin app: `admin/`
- Environment guide: `docs/admin-supabase-environment-guide.md`

---

## Phase 0 — Configure Admin environments (local/dev/prod)

Admin is Vue 3 running on Vite, reading environment variables through
`import.meta.env`. Vite loads files by mode; `localdev` is custom,
while `development` and `production` are standard modes.

### Environment conventions

| Environment | Vite mode | Local file | Supabase target | Status |
| --- | --- | --- | --- | --- |
| Local | `localdev` | `admin/.env.local` | Supabase CLI local stack | Populated |
| Dev | `development` | `admin/.env.development.local` | Project `imposter-word`, ref `pxycsjwjakzehcuygngv` | Populated |
| Prod | `production` | `admin/.env.production.local` | Production project | Not configured |

Do not commit `*.local` files. The committed example is
`admin/.env.example`. `admin/.env.production` is a committed empty guard
preventing production builds from accidentally falling back to `.env.local`
while no production project exists.

### Allowed frontend variables

```env
VITE_SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
VITE_SUPABASE_PUBLISHABLE_KEY=sb_publishable_xxx
```

Vite bundles `VITE_*` into the browser. Publishable keys are safe for frontend
use with correct RLS and Data API permissions. Never put
`service_role`, Supabase secret keys, database passwords, or JWT secrets
in any `VITE_*` file.

### Run/build commands

```bash
cd admin
yarn dev:local           # local, mode localdev
yarn dev:development     # dev cloud, mode development
yarn build:production    # prod, mode production
```

- [x] Create `admin/.env.local` with local URL and publishable key.
- [x] Create `admin/.env.development.local` with Dev URL and publishable key.
- [x] Add Vite scripts for three modes.
- [x] Add `admin/.env.example`.
- [ ] Create/populate `admin/.env.production.local` once a production project exists.

---

## Phase 1 — Create Supabase project

### In Supabase Dashboard

- [x] Create a Supabase project.
- [x] Save Project URL.
- [x] Obtain Publishable key.
- [x] Do not use `service_role` or Secret keys in the frontend.
- [x] Enable Email/Password under `Authentication → Providers`.
- [x] Decide whether to enable email confirmation.

### Required output

```text
SUPABASE_URL
SUPABASE_PUBLISHABLE_KEY
```

Current Development project: `imposter-word`, ref
`pxycsjwjakzehcuygngv`. Credentials are stored in
`admin/.env.development.local` and excluded from Git.

---

## Phase 2 — Initialize Supabase in the repository

### In code

- [x] Install Supabase CLI if missing.
- [x] Run `supabase init` at the repository root.
- [x] Run `supabase migration new initial_schema`.
- [x] Check `supabase/migrations/`.

Expected structure:

```text
supabase/
├── config.toml
└── migrations/
    ├── 20261003072606_initial_schema.sql
    └── 20261003072909_rls_and_policies.sql
```

Both migrations were created with Supabase CLI: the first contains schema,
the second RLS and policies.

### Notes

- DBML is for diagrams, not direct execution.
- Do not create an actual `auth_users` table.
- Supabase already manages `auth.users`.

---

## Phase 3 — Write database schema migration

### Required enums

- [x] `game_type`: `word`, `question`.
- [x] `content_status`: `draft`, `published`, `archived`.
- [x] `difficulty_level`: `easy`, `medium`, `hard`.

### Required tables

- [x] `public.admin_users`.
- [x] `public.game_categories`.
- [x] `public.word_prompts`.
- [x] `public.question_prompts`.
- [x] `public.content_languages` and three translation tables (local).

### Current fields after translations

- `admin_users`: Auth user, role, `is_active`.
- `content_languages`: `code`, `display_name`, `sort_order`.
- `game_categories`: `game_type`, slug unique per game type, `sort_order`, `is_active`, `is_family_friendly` (word categories only).
- `word_prompts`: `category_id`, `image_path`, `difficulty`.
- `question_prompts`: `category_id`, `difficulty`.
- `game_category_translations`: `category_id`, `locale`, `name`, `description`, `status`.
- `word_prompt_translations`: `prompt_id`, `locale`, `text`, `status`.
- `question_prompt_translations`: `prompt_id`, `locale`, `civilian_question`, `imposter_question`, `status`.

Base records/translations have creation/update metadata; translations use base ID + locale
composite keys, with locale referencing `content_languages`. `imposter_hint` was removed.
Full schema is in [DBML](./database-schema.dbml); historical migrations are the deployment source and must not be edited.

---

## Phase 4 — Configure RLS and access permissions

### Admin check function

- [x] Create `private.is_admin()`.
- [x] Check `auth.uid()` against `public.admin_users`.
- [x] Use safe `SECURITY DEFINER` and `search_path = ''`.
- [x] Do not expose this function as a public API.

### Enable RLS

- [x] Enable RLS on `admin_users`.
- [x] Enable RLS on `game_categories`.
- [x] Enable RLS on `word_prompts`.
- [x] Enable RLS on `question_prompts` and four language/translation tables.

### Public app policies

- [x] Public reads only published translations under active categories; prompts need published category translations in the same locale.
- [x] Base records are public only with eligible translations; no locale fallback.
- [x] `anon` cannot insert, update, or delete.

### Admin policies

- [x] Admins can read all content.
- [x] Active admins create/update/archive through transactional, version-checked RPCs; clients cannot directly write content tables.
- [x] Logged-in users absent from `admin_users` cannot perform these actions.

Initial RLS is in `20261003072909_rls_and_policies.sql`; current permissions were updated by translation migrations on 2026-10-24.
`private.is_admin()` is revoked from `public`, with execute granted only to
`authenticated`; `private` is also excluded from Data API schemas.

---

## Phase 5 — Test migrations locally

> Do not use Phase 5 as a gate for the current workflow. Local migrations were
> reset/applied to check SQL, but local behavior checks were skipped;
> the workflow continued directly on Dev in Phase 6.

```bash
supabase start
supabase db reset
```

- [x] Migrations run successfully from scratch with `supabase db reset --local`.
- [x] All tables created.
- [x] RLS enabled.
- [x] No foreign-key errors.
- [x] No policy/function errors.

### Smoke checks

- [ ] Anonymous reads only published content.
- [ ] Anonymous cannot write content.
- [ ] Admin reads drafts.
- [ ] Admin creates/edits content.
- [ ] Authenticated non-admin users are rejected.

---

## Phase 6 — Push schema to Supabase Cloud

Checkmarks below cover only the two initial setup migrations. Dev is currently INACTIVE; translation migrations are not deployed. The next cutover must follow the [translation Phase 6 runbook](./plans/admin-content-translations/admin-content-translations-phase-6.md), rather than independently running the push command below.

```bash
supabase login
supabase link --project-ref pxycsjwjakzehcuygngv
supabase db push --linked
```

- [x] Link repository to Dev project `pxycsjwjakzehcuygngv`.
- [x] Check dry-run before pushing.
- [x] Push both migrations to Dev.
- [x] Verify applied migrations on the actual project.
- [x] Check four Dev database tables.
- [x] Check RLS policies with Supabase CLI.
- [ ] Enable Leaked Password Protection in Dev Auth settings.

---

## Phase 7 — Create the first admin

### Create a local Auth user for initial testing (temporarily skipped)

Local steps are temporarily skipped in favor of direct Dev testing. Any local user
created later exists only in local Supabase and cannot log into
the Dev project.

```bash
supabase start
```

- [ ] Open local Supabase Studio at `http://127.0.0.1:54323`.
- [ ] Open `Authentication → Users` → `Add user`.
- [ ] Create test email/password, e.g. `admin.local@example.com`.
- [ ] Enable `Auto Confirm` for immediate login.
- [ ] Copy the local user's UUID.
- [ ] Run the following in local SQL Editor to grant admin:

```sql
insert into public.admin_users (user_id, role, is_active)
select id, 'admin', true
from auth.users
where email = 'admin.local@example.com'
on conflict (user_id) do update
set role = 'admin',
    is_active = true;
```

Run Admin with `yarn dev:local`, then test login, route guards, and RLS using
local email/password. Do not put test passwords or local UUIDs
in migrations/repository.

### Create an Auth user in Dashboard

- [ ] Open `Authentication → Users`.
- [ ] Choose `Add user`.
- [ ] Create admin email/password.
- [ ] Enable Auto Confirm if immediate login is needed.
- [ ] Copy the user's email or UUID.

### Grant admin access

Create:

```text
supabase/scripts/grant_admin.sql
```

- [x] Create a script with placeholder email, without passwords/secrets.

Contents:

```sql
-- Run after the Auth user exists.
insert into public.admin_users (user_id, role, is_active)
select id, 'admin', true
from auth.users
where email = 'admin@example.com'
on conflict (user_id) do update
set role = 'admin',
    is_active = true;
```

- [ ] Replace the email with the actual admin email.
- [ ] Run once in Supabase SQL Editor.
- [ ] Verify role `admin` and `is_active = true`.

### Do not

- [ ] Do not store passwords in the repository.
- [ ] Do not insert passwords directly into `auth.users`.
- [ ] Do not put service keys in frontend scripts.
- [ ] Do not put admin grants in schema migrations.

---

## Phase 8 — Connect Vue Admin

### Install package

```bash
cd admin
yarn add @supabase/supabase-js
```

- [x] Install `@supabase/supabase-js`.

### Configure environment variables

Three environments were configured in Phase 0. Use the same variables
in Supabase clients for all three modes:

```env
VITE_SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
VITE_SUPABASE_PUBLISHABLE_KEY=sb_publishable_xxx
```

- [x] `*.local` files are excluded by `admin/.gitignore`.
- [x] No secret/service keys in the frontend.

### Create Supabase client

Create:

```text
admin/src/lib/supabase.js
```

- [x] Initialize `createClient()`.
- [x] Read URL and publishable key from `import.meta.env`.

---

## Phase 9 — Authentication and route guards

### Login

- [ ] Create `/login` screen.
- [ ] Log in with `supabase.auth.signInWithPassword()`.
- [ ] Show invalid email/password errors.
- [ ] Query `admin_users` after login.
- [ ] Sign out and show an error for non-admins.

### Route guards

Protect:

```text
/dashboard
/categories
/word-prompts
/question-prompts
```

- [ ] Unauthenticated → redirect to `/login`.
- [ ] Non-admin → deny admin pages.
- [ ] Page refresh retains valid sessions.
- [ ] Log out calls `supabase.auth.signOut()`.

---

## Phase 10 — Build Admin screens

### Dashboard

- [ ] Total published word prompts.
- [ ] Total published question prompts.
- [ ] Total active categories.
- [ ] Total draft content.

### Categories

- [ ] Category list.
- [ ] Create categories.
- [ ] Edit categories.
- [ ] Enable/disable categories.
- [ ] Show Classic/Family content counts.

### Word prompts

- [ ] Word prompt list.
- [ ] Filter category, difficulty, status. Family Mode filters belong only to category lists.
- [ ] Create/edit prompts.
- [ ] Upload images.
- [ ] Preview images.
- [ ] Save drafts.
- [ ] Publish.
- [ ] Archive.

### Question prompts

- [ ] Question prompt list.
- [ ] Filter category, difficulty, status. Family Mode filters belong only to category lists.
- [ ] Enter civilian question.
- [ ] Enter imposter question.
- [ ] Validate questions differ.
- [ ] Save drafts.
- [ ] Publish.
- [ ] Archive.

---

## Phase 11 — Storage for word images

- [x] Create private `word-prompt-images` bucket through migration; images are shared across translations.
- [x] Private bucket with signed URLs; issued URLs remain valid until expiry.
- [x] Active-admin upload/cleanup policies; JPEG/PNG/WebP, 5 MiB limits.
- [x] Read images when a prompt has an eligible public translation; issued URLs last until expiry.
- [x] Store shared paths in `word_prompts.image_path`.
- [x] No service keys in frontend. Flutter integration is out of scope.

---

## Phase 12 — Data API queries

Public reads fetch translations by locale and join shared fields; RLS excludes ineligible rows:

```js
supabase
  .from('word_prompt_translations')
  .select('*, word_prompts!inner(*)')
  .eq('locale', locale)
  .eq('status', 'published')
```

Likewise for `question_prompt_translations` and `game_category_translations`.
Admin uses existing list/save RPCs instead of this public query.
For the translation query above, shared-field filters must use relation names:

Family Mode:

```js
query = query.eq('game_categories.is_family_friendly', true)
```

Category filter:

```js
query = query.in('word_prompts.category_id', selectedCategoryIds)
```

- [ ] No selected category → random from all eligible content.
- [ ] Selected categories → random only within those categories.
- [ ] Word Family Mode → filter `game_categories.is_family_friendly = true`.
- [ ] App receives only published content.

---

## Phase 13 — Verification checklist

- [ ] Admin login succeeds.
- [ ] Non-admins are blocked.
- [ ] Admin logout succeeds.
- [ ] Anonymous cannot modify content.
- [ ] Anonymous reads only published content.
- [ ] Admin creates categories.
- [ ] Admin creates word prompts.
- [ ] Admin uploads images.
- [ ] Admin creates question prompts.
- [ ] Drafts do not appear in the player app.
- [ ] Archived content does not appear in the player app.
- [ ] Family Mode includes only words under `game_categories.is_family_friendly = true` categories.
- [ ] Multiple categories filter content correctly.
- [ ] No category selection randomizes across the entire content set.
- [ ] `service_role` appears in neither frontend nor Git.

## Definition of Done

- [ ] Migrations are in `supabase/migrations/` and run from scratch.
- [ ] Cloud schema matches repository migrations.
- [ ] RLS is enabled and tested.
- [ ] Admin Auth user has a corresponding `admin_users` record.
- [ ] Vue Admin login/logout works.
- [ ] Admin CRUD works for categories and both content types.
- [ ] Player app reads only published content.
- [ ] Family Mode and category filtering work correctly.
- [ ] Word prompt images upload and display.
