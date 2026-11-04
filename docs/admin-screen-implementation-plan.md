# Admin Screen Implementation Plan

> Layouts and data fields for each screen are described in [Admin Screen Layout](layout/admin-screen-layout.md).

## Implementation order after login/logout

**Next screen to implement: Overview.** Categories, Word Prompts, and Question Prompts already have content management flows.

Supabase integration, login/logout, the admin shell, and routes for four screens are in place. `Overview` still uses a placeholder; category, word, and question screens already have lists and management forms. Reuse the existing shell and routes.

| Order | Screen / scope | Expected outcome | Priority rationale |
| --- | --- | --- | --- |
| 1 | Categories: list → create/edit form | View, filter, create, edit, and enable/disable categories; save and reload backend data. | Foundation for both content types. |
| 2 | Word content: list → create/edit form → images and preview → publish/archive | Complete draft creation, editing, category assignment, image management, preview checks, and status changes. | Complete one content management flow end to end before implementing the other. |
| 3 | Question content: list → create/edit form and preview → publish/archive | Manage question pairs, reject empty/identical questions, and enforce category type. | Reuse filtering, pagination, and status display from word content. |
| 4 | Overview | Show statistics, recent content, pending drafts, and warnings from real data; link to the relevant management screens. | Management screens provide the data and workflows summarized by the dashboard. |

Implementation order differs from menu order: `Overview` remains the first screen after login but is completed after content management screens.

### Implemented scope: Categories

1. `/categories` list: backend name/slug search (300 ms debounce), game type/status filters, 20-row pagination, and sorting. Keep filters in the URL.
2. `/categories/new` and `/categories/:id/edit` forms: create in Vietnamese; preserve language and lock game type when editing.
3. Backend reads/writes through `admin/src/api/categories.js`; separate display components, utilities, and CSS. Vue Query refreshes data after actions.
4. Delete empty categories; transfer all content to an active category of the same type/locale and delete; or delete all content and the category. The RPC is atomic, checks admin permissions, locks data, and verifies the content version before purging.
5. Full deletion requires the exact name and shows content counts by status. Storage files are retained; image cleanup is not implemented.
6. Disabling a category requires confirmation; warn about unsaved changes on navigation, reload, or logout.

### Category testing and deployment

- `cd admin && yarn test` and `yarn build:local`.
- Apply new migrations with `supabase migration up --local`; do not reset data.
- Run `supabase/tests/category_management.sql` through psql with `ON_ERROR_STOP=1`; the script rolls back fixtures.
- Run `python3 supabase/tests/category_concurrency.py` to check concurrent content additions on the local container.
- Backend deployment must apply `20261012155821_category_management.sql` before releasing the frontend; this implementation does not automatically push to remote.

### Completion criteria for each screen

- Loading, empty list, load/save error, and retry states are available.
- Prevent duplicate submissions while saving; preserve entered data if saving fails.
- Forms include validation and warn before leaving or logging out with unsaved changes.
- Complete core actions with backend data before moving to the next screen.
- Check data permissions: expired sessions and non-admin accounts must not read/write admin data without authorization.

### Implemented Question Prompts

The list searches both questions (300 ms debounce), with URL filters and 20-row pagination. Create/edit forms include two textareas, role previews, draft/publish/archive/delete actions, version checks, and an unsaved changes guard. No hint is saved. See the [Question Prompts plan](admin-question-prompts-implementation-plan.md) for migrations, tests, and UI verification limits.
