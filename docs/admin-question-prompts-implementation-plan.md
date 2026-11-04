# Question Prompts Implementation Plan

## Goal

Complete listing, creation/editing, preview, and question status management following the [Admin Screen Implementation Plan](admin-screen-implementation-plan.md). Match the current Word Prompts interface. Remove `imposter_hint` entirely; the app handles category display when hints are enabled.

## References

- [Admin List Style Rules](layout/admin-style-rules.md): applies to the Question Prompts list, including tokens, shared CSS classes, filters, tables, buttons, and responsive behavior. Create/edit forms and dialogs continue using the current Word Prompts style.

## Interface and workflows

- Keep the Word Prompts shell, spacing, typography, cards, filters, tables, buttons, and responsive behavior; reuse suitable CSS without redesigning the word screen.
- List both questions, category, difficulty, status, and update date. Truncate long content; open the form to view it in full.
- Search both questions on the backend with a 300 ms debounce; filter by category, difficulty, language, and status. Use 20-row pagination; sort by update date descending or civilian question ascending, with ID as a secondary sort. Preserve URL filters when creating/editing and returning.
- Add `/question-prompts/new` and `/question-prompts/:id/edit` routes.
- Use two side-by-side textareas on desktop, stacked on small screens. Follow Word Prompts for classification and the action bar.
- Show civilian/imposter preview cards with their respective questions. Do not store a hint field or hint configuration in the prompt.
- Support save draft, publish, revert to draft, archive, and delete with the same confirmations as Word Prompts. Preserve data on errors, prevent duplicate actions, and warn about unsaved changes before leaving or logging out.
- Include loading, empty, load/save error, and retry states. After saving or deleting, update question caches and category content counts.

## API and database

- Separate API, validation, and components following Word Prompts; use Vue Query and the existing translation system without adding dependencies.
- Payload fields: `civilian_question`, `imposter_question`, `category_id`, `difficulty`, `locale`, and `status`. New prompt defaults: `vi`, `medium`, and `draft`.
- Trim before saving; both questions are required and must differ after trimming, case-insensitively. Apply the same frontend/backend rule for every status. Do not check duplicates across separate prompts.
- Backend checks that the category has type `question` and the same locale; publishing requires an active category. Existing prompts in disabled categories remain editable/archivable. Preserve the existing category selection when it is absent from active options.
- Use `updated_at` to detect concurrent edits; report conflicts and require reload instead of silently overwriting. Confirm discarding changes before reloading a dirty form.
- Add `delete_question_prompt(p_id uuid, p_expected_updated_at timestamptz)` following Word Prompts deletion: check admin, lock the record, and compare versions. Do not grant direct DELETE access to clients.
- Create a new migration dropping `question_prompts.imposter_hint`, adding backend validation, and updating timestamps on writes. Do not modify historical migrations.
- Preserve existing published-read and admin-write permissions; test grants and RLS following the [Supabase guide](https://supabase.com/docs/guides/database/postgres/row-level-security).
- Update deployment documentation, layout, schema, and old assertions requiring hints. Historical documents describing this field must clearly note the current schema change.

## Testing and deployment

- Unit/API: question validation, hint-free payloads, two-field search, filtering/pagination, permission errors, and version conflicts.
- Components: loading/empty/error/retry, create/edit, previews, status changes, deletion, duplicate submission prevention, and unsaved changes warnings.
- SQL: hint column removed; reject empty/identical questions, incorrect type/locale, and publishing in disabled categories; verify admin permissions, published reads, and version-checked deletion. Test scripts roll back fixtures.
- Rerun category and Word Prompts tests to check content transfer/deletion and updated hint assertions.
- Run `yarn test` and `yarn build:local` in `admin`; visually compare with Word Prompts on desktop and small screens.
- Apply migrations locally without resetting data. Deploy migrations before the frontend; do not automatically push remote.

## Assumptions and limits

- Dropping the column deletes old hint data as agreed.
- Scope covers admin and the related backend; do not modify the app or add hint logic to admin.
- API/validation, list, form, previews, status management, and delete RPC are implemented; the app is unchanged.

## Current implementation and verification

- Applied `20261021045906_question_prompt_management.sql` locally through `supabase migration up --local`, without resetting data. It removes `imposter_hint`, trims and validates both questions for every status, checks category type/locale/status, updates server-side `updated_at`, and adds version-checked deletion.
- Deploy this migration before the frontend. Not pushed remote.
- `cd admin && yarn test`: 40 tests passed. `yarn build:local`: successful.
- Ran three SQL scripts through `psql` with `ON_ERROR_STOP=1`: `supabase/tests/question_prompt_management.sql`, `category_management.sql`, and `word_prompt_management.sql`. Each rolls back all fixtures. Used psql because `supabase db query --file` currently cannot execute multiple commands in one prepared statement.
- `python3 supabase/tests/category_concurrency.py` passed; fixtures were cleaned up.
- `supabase db advisors --local --type security --level warn`: no issues.
- Opened the local list and verified its empty state in the browser. Render tests cover loading/empty/error states, both table questions, debounce, both previews, and the form navigation guard. Full desktop/mobile visual checks remain pending: the Chrome control tool returned `cgWindowNotFound` during screenshot capture. UI fixtures were cleaned up.
