# Manual Local Supabase Setup on a New Machine

Current Family Mode contract and local upgrade procedure: [Category-Based Family Mode](family-mode.md).
macOS guide for running Supabase and Vue Admin from the
`imposter-wording` repository. Run all Supabase commands at the **repository root**;
run Yarn commands in **`admin/`**.

## 1. Prepare tools

Requires Git, Node.js 22.12 or later, Yarn 1.22.22, Supabase CLI, and a running Docker
runtime. The Homebrew commands below require Homebrew to be installed.

Check first:

```bash
git --version
node --version
yarn --version
supabase --version
docker --version
docker info
```

Install only missing tools:

```bash
# Node.js, if a suitable version is not installed
brew install node

# Yarn, if missing
npm install --global yarn@1.22.22

# Supabase CLI, if missing
brew install supabase/tap/supabase
```

If no Docker runtime is installed, you can install OrbStack:

```bash
brew install --cask orbstack
open -a OrbStack
```

If Docker Desktop is installed, open it. Wait for the runtime to start and
check `docker info` again before continuing.

## 2. Get the repository

If not yet cloned, replace `<REPOSITORY_URL>` with the project's Git URL:

```bash
git clone <REPOSITORY_URL>
cd imposter-wording
```

If already cloned:

```bash
cd /path/to/imposter-wording
```

The repository includes `supabase/config.toml` and migrations; no
`supabase init` is needed. Local use requires no `supabase login`, `supabase link`, or
cloud migration pushes.

## 3. Start local Supabase

```bash
supabase start
supabase status
supabase migration list --local
```

The first run downloads Docker images and may take a few minutes. When creating a new database,
Supabase applies repository migrations. `supabase start` finishes when
the stack is ready; containers continue running in the background.

Default addresses:

| Service | URL |
| --- | --- |
| API | http://127.0.0.1:54321 |
| Studio | http://127.0.0.1:54323 |
| Mailpit, xem email test | http://127.0.0.1:54324 |

## 4. Install Admin and configure the environment

```bash
cd admin
yarn install --frozen-lockfile
```

If `admin/.env.local` does not exist, create it from the example:

```bash
cp .env.example .env.local
```

Open it for editing:

```bash
nano .env.local
```

Fill in the URL and **Publishable key** from `supabase status`. If the CLI only
shows an `anon key`, use that:

```env
VITE_SUPABASE_URL=http://127.0.0.1:54321
VITE_SUPABASE_PUBLISHABLE_KEY=<LOCAL_PUBLISHABLE_KEY_OR_ANON_KEY>
```

Replace the entire placeholder with the actual key. Do not use `service_role`, Secret
keys, or database passwords in `VITE_*`. `.env.local` is
Git-ignored. To rerun `supabase status`, return to the root with `cd ..`.

## 5. Create a local admin account

Open http://127.0.0.1:54323:

1. Open **Authentication → Users → Add user**.
2. Create `admin.local@example.com` with a test password of your choice.
3. Enable **Auto Confirm** for immediate login.
4. Open **SQL Editor** and run the following.

```sql
insert into public.admin_users (user_id, role, is_active)
select id, 'admin', true
from auth.users
where email = 'admin.local@example.com'
on conflict (user_id) do update
set role = 'admin', is_active = true;

select u.email, au.role, au.is_active
from public.admin_users au
join auth.users u on u.id = au.user_id
where u.email = 'admin.local@example.com';
```

If using another email, replace it in both SQL statements. The result must contain one
row with `role = admin` and `is_active = true`. This account exists only in
the local stack on the machine being configured.

## 6. Run and check Admin

```bash
cd /path/to/imposter-wording/admin
yarn dev:local
```

Open the URL printed by Vite, usually http://localhost:5173. Log in with the
new account and open category management to verify connectivity.

You can check builds and existing tests in another terminal after creating
`.env.local`:

```bash
cd /path/to/imposter-wording/admin
yarn build:local
yarn test
```

## 7. Daily commands

Start the backend:

```bash
cd /path/to/imposter-wording
supabase start
```

Run the frontend:

```bash
cd /path/to/imposter-wording/admin
yarn dev:local
```

Stop the frontend with `Ctrl+C`. Stop the backend while preserving data:

```bash
cd /path/to/imposter-wording
supabase stop
```

Dependencies and accounts do not need to be recreated on every run.

## 8. Applying new migrations or rebuilding the database

If the database exists and new migrations are available, inspect and apply them locally:

```bash
cd /path/to/imposter-wording
supabase migration list --local
supabase db push --local --dry-run
supabase db push --local
```

Only when you intend to **delete local data and rebuild from migrations**, run:

```bash
supabase db reset --local
```

After resetting, recreate the admin account using step 5. Resetting is not
a required step when opening the project.

### Sample data and word images

Added [3 Family categories with 15 Vietnamese–English question pairs](family-question-mode.md).
See that guide to load them separately into a running local DB without resetting.
New databases automatically load both seed files listed in `config.toml`.

After applying migrations, load 5 categories per game type, each containing
5 prompts with published Vietnamese and English translations, plus 25 word illustrations:

```bash
python3 supabase/scripts/seed_local_images.py
```

The script runs only against the default local stack, preserves existing data, and checks player
read access to prompts/images. Reruns do not duplicate records. During resets,
`supabase/seed.sql` loads automatically; rerun the script to upload and link
images. Image sources and licenses: [seed-images](../supabase/seed-images/README.md).

## 9. Common errors

- **Cannot connect to Docker daemon:** open Docker Desktop/OrbStack and rerun
  `docker info`.
- **Ports in use:** check `docker ps` and stop the stack occupying
  ports `54321`–`54324`; avoid changing ports without updating the environment.
- **Missing `VITE_SUPABASE_*`:** check `admin/.env.local`, use
  `yarn dev:local`, and restart Vite after environment changes.
- **Login works but admin access is denied:** check the SQL result from
  step 5 and ensure the frontend points to the local API.

References: [Supabase CLI and local development](https://supabase.com/docs/guides/local-development/cli/getting-started),
[full project guide](./admin-supabase-new-device-guide.md).
