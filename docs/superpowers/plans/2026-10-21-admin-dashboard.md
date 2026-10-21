# Admin Dashboard Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:executing-plans` (or `superpowers:subagent-driven-development`) to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the admin dashboard placeholder with real content statistics, recent updates, drafts to handle, and data-quality warnings linked to existing management screens.

**Architecture:** An admin-only Postgres RPC returns a small, complete dashboard summary so counts and warnings are computed against all records without downloading full tables. A typed API wrapper and Vue Query power the existing dashboard route; the view uses existing Nuxt UI, routing, and localization patterns.

**Tech Stack:** PostgreSQL/Supabase RPC and migrations; Vue 3, TypeScript, TanStack Vue Query, Vue Router, vue-i18n, Nuxt UI; Node test runner and local Supabase SQL tests.

**Spec:** `docs/admin-screen-implementation-plan.md` (item 4) and `docs/layout/admin-screen-layout.md` (Admin overview).

## Global Constraints

- Keep the existing `/dashboard` route and admin shell; replace only the placeholder content.
- Do not add dependencies or download full content tables to the browser for aggregation.
- The RPC must reject callers that are not active admins; do not expose drafts or admin-only data through an unguarded function.
- Recent items include all statuses; draft items include only `draft`; show at most five items in each list.
- Warnings scan all statuses. A category is empty only when it has no associated prompt of its game type.
- Question-pair duplicate detection uses the same case-insensitive and Unicode-trim semantics as the question write trigger.
- Include loading, retryable error, and empty states. Add required UI copy to Vietnamese; English continues using the configured Vietnamese fallback.

## Review Focus

- Anonymous or inactive/non-admin callers must not receive summary data; SQL tests assert RPC execution is denied.
- Categories containing only draft or archived prompts are not empty; SQL fixtures exercise status-independent category checks.
- Whitespace and case variants of a question pair count as duplicates using the write trigger's trim behavior; SQL tests cover this normalization.
- Mixed word/question records sort deterministically by `updated_at` and stable tie-breakers, with the five-item limit applied after merging; SQL tests assert the returned list.
- An empty summary displays empty/clear states, while a failed fetch exposes retry instead of fabricated zero counts; dashboard component tests cover both.

---

### Task 1: Add the guarded dashboard summary RPC

**Files:**
- Create: `supabase/migrations/<generated-timestamp>_admin_dashboard_summary.sql` (create with `supabase migration new admin_dashboard_summary`)
- Create: `supabase/tests/admin_dashboard.sql`
- Modify: `admin/src/types/database.ts` (regenerate; do not hand-edit)

**Interface:**
- Produces `public.admin_dashboard_summary()` with no arguments and a JSONB result:
  - `stats`: `published_word_prompts`, `published_question_prompts`, `active_categories`, `drafts`.
  - `recent` and `drafts`: arrays of `{ id, game_type, title, category_name, status, updated_at }`.
  - `warnings`: `empty_categories`, `duplicate_questions`, `non_family_easy_prompts`.
- Each list item uses `id: string`, `game_type: 'word' | 'question'`, `title: string`, `category_name: string`, `status: 'draft' | 'published' | 'archived'`, and `updated_at: string`. Use `word_prompts.text` or `question_prompts.civilian_question` as `title`.
- `recent` includes all statuses; `drafts` includes only draft records. Both are merged across word and question prompts, ordered by `updated_at DESC, game_type ASC, id ASC`, then limited to five.
- `empty_categories` counts categories with no prompts in the corresponding word/question table. `duplicate_questions` counts question rows whose trimmed, lowercased civilian and imposter questions match. `non_family_easy_prompts` counts easy, non-family-friendly word and question prompts.

- [x] **Step 1: Write the SQL assertions first**

Create `supabase/tests/admin_dashboard.sql` as a transaction with rollback, following the existing management SQL tests. Add fixtures and assertions for summary counts, merged/limited ordering, drafts, all three warnings, and function privileges. Capture baseline values before inserting fixtures so assertions remain valid if the local database has seed data. Include a duplicate pair with case/Unicode whitespace differences; temporarily disable and re-enable the question validation trigger only for that malformed legacy-data fixture.

- [x] **Step 2: Run the SQL test and confirm it fails before the RPC exists**

Run: `psql <local-db-url> -v ON_ERROR_STOP=1 -f supabase/tests/admin_dashboard.sql`

Expected: FAIL because `public.admin_dashboard_summary()` is not yet defined.

- [x] **Step 3: Implement the migration**

Create the no-argument JSONB function as `SECURITY DEFINER` with an empty `search_path`. Check for an active `admin_users` row inside the function and raise SQLSTATE `42501` otherwise. Revoke execution from `PUBLIC` and `anon`; grant it to `authenticated`. Build counts and the two limited lists in SQL, without returning full prompt rows.

- [x] **Step 4: Apply the migration and verify SQL behavior and permissions**

Run: `supabase migration up --local`

Run: `psql <local-db-url> -v ON_ERROR_STOP=1 -f supabase/tests/admin_dashboard.sql`

Expected: migration applies without resetting data; all assertions pass and fixtures roll back.

- [x] **Step 5: Regenerate the committed Supabase types**

Run from `admin/`: `yarn types:database`

Expected: the generated `Database` function map contains `admin_dashboard_summary` with no arguments and a JSON return type.

- [x] **Step 6: Commit the RPC and its SQL coverage**

```sh
git add supabase/tests/admin_dashboard.sql admin/src/types/database.ts 'supabase/migrations/*_admin_dashboard_summary.sql'
git commit -m "feat: add admin dashboard summary RPC"
```

### Task 2: Add a typed dashboard API wrapper

**Files:**
- Create: `admin/src/api/dashboard.ts`
- Create: `admin/tests/dashboard.test.ts`

**Interfaces:**
- Produces `DashboardItem` with `id`, `game_type`, `title`, `category_name`, `status`, and `updated_at`.
- Produces `DashboardSummary` with `stats`, `recent`, `drafts`, and `warnings` matching the RPC JSON contract in Task 1.
- Produces `getDashboardSummary(client: AdminClient): Promise<DashboardSummary>`; it calls `client.rpc('admin_dashboard_summary')`, throws RPC errors unchanged, and returns the typed summary.

- [x] **Step 1: Write API tests**

In `admin/tests/dashboard.test.ts`, assert that `getDashboardSummary` calls the named RPC, returns its payload unchanged, and rejects when the RPC returns an error.

- [x] **Step 2: Run the focused API test and confirm it fails**

Run from `admin/`: `node --import tsx --test tests/dashboard.test.ts`

Expected: FAIL because the dashboard API module/function does not exist.

- [x] **Step 3: Implement `getDashboardSummary` and the response types**

Use the existing `AdminClient` type and the same error-propagation pattern as the other API modules. Keep the response types in `admin/src/api/dashboard.ts`; do not add a new shared type module for this one consumer.

- [x] **Step 4: Run the API test and full admin tests**

Run from `admin/`: `node --import tsx --test tests/dashboard.test.ts`

Expected: PASS.

Run from `admin/`: `yarn test`

Expected: all tests pass.

- [x] **Step 5: Commit the API wrapper and tests**

```sh
git add admin/src/api/dashboard.ts admin/tests/dashboard.test.ts
git commit -m "feat: add dashboard summary client"
```

### Task 3: Replace the dashboard placeholder

**Files:**
- Modify: `admin/src/views/dashboard/DashboardView.vue`
- Create: `admin/src/views/dashboard/DashboardView.css`
- Modify: `admin/src/styles/index.css`
- Modify: `admin/src/i18n/locales/vn.json`
- Create: `admin/tests/dashboardComponents.test.ts`

**Consumes:** `getDashboardSummary` and `DashboardSummary` from `admin/src/api/dashboard.ts`.

- [x] **Step 1: Add component tests for loaded, empty, and error states**

Use the existing in-memory Vue renderer and Vite SFC loading pattern from `admin/tests/questionPromptComponents.test.ts`. Assert that the pending query shows a loading status; loaded data renders all four statistic values, recent and draft rows, and relevant links; zero rows/warnings render clear empty states; and an RPC failure renders an alert with a retry action that refetches successfully.

- [x] **Step 2: Run the focused component test and confirm it fails**

Run from `admin/`: `node --import tsx --test tests/dashboardComponents.test.ts`

Expected: FAIL because the dashboard still renders the placeholder.

- [x] **Step 3: Implement the dashboard view**

Use `useQuery` with query key `['dashboard', 'summary']`, `retry: false`, and the API wrapper. Render the four specified statistics, up to five recent rows, up to five draft rows, and warning counts. Link recent/draft rows to the existing named edit routes; link empty categories to `categories`, duplicates to `question-prompts`, and easy/non-family warnings to both prompt lists filtered by `difficulty=easy&family=false`. Keep the existing `/dashboard` route unchanged.

Show a loading skeleton/status while pending, an error alert with a retry button on failure, empty messages for lists, and a no-warnings state when all warning counts are zero. Format dates with `Intl.DateTimeFormat` using the current locale. Use translated labels and accessible section headings/link names.

- [x] **Step 4: Add responsive styles and Vietnamese copy**

Create dashboard-specific styles using the existing CSS variables and import them from `admin/src/styles/index.css`. Add all new labels, empty/error messages, warning text, and retry copy under the existing `dashboard` dictionary in `vn.json`; rely on the configured Vietnamese fallback for untranslated English keys.

- [x] **Step 5: Run focused tests, the complete suite, and the production-like local build**

Run from `admin/`: `node --import tsx --test tests/dashboardComponents.test.ts`

Expected: PASS for loaded, empty, and retryable-error behavior.

Run from `admin/`: `yarn test`

Expected: all tests pass, including localization key checks.

Run from `admin/`: `yarn build:local`

Expected: typecheck and Vite build pass.

- [x] **Step 6: Commit the dashboard view and tests**

```sh
git add admin/src/views/dashboard/DashboardView.vue admin/src/views/dashboard/DashboardView.css admin/src/styles/index.css admin/src/i18n/locales/vn.json admin/tests/dashboardComponents.test.ts
git commit -m "feat: implement admin dashboard"
```

## Rollout

Apply the new database migration before deploying the matching frontend. Use `supabase migration up --local` and the SQL test above for local verification; do not reset local data or push a remote deployment as part of this plan.
