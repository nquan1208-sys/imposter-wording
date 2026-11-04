# Word Content Management Completion Plan

Date: 2026-10-13

Status: Implemented in the workspace and automatically tested locally; not applied or verified on Dev cloud.

At implementation start, the workspace had partial image/save migrations and APIs, while the word screen was a placeholder; UI and Local/Dev verification were incomplete. Lists, create/edit forms, previews, uploads, publish/archive, and permanent deletion are now available. Image, prompt deletion, and Wording simplification migrations were applied locally without resetting data.

## 1. Goals and agreed choices

Complete **list → create draft → edit → assign category → manage images → preview → publish/archive → permanently delete** before implementing question content.

- Drafts require a civilian word and category; images are optional.
- Civilian previews show the word and image; Imposter previews show only the category name when hints are enabled, or only “You are the imposter” otherwise. The admin toggle only simulates this and is not saved in the prompt.
- Editing published content updates it directly after confirmation.
- Use a **private** bucket configured identically on Local and Dev.
- Reuse Nuxt UI, Vue Query, Zod, i18n, and existing unsaved changes warnings; add no dependencies.
- Admin is the only content source. Flutter fetches published categories/prompts through the API at runtime; do not seed the database or bundle content/images in app builds.

### Current state

- Word management has lists and create/edit forms with URL filters.
- `word_prompts` already contains content fields, `image_path`, and `draft`, `published`, `archived` statuses.
- Database RLS lets admins manage content and players read published content.
- Private bucket and Storage policies are configured in migrations/config; the local bucket exists.
- Category management provides reusable API, form, filter, pagination, and unsaved changes patterns.

## 2. Lists, forms, and statuses

### List

- Replace the placeholder with thumbnails, civilian words, categories, difficulty, status, and update dates.
- Search civilian words; filter category, difficulty, locale, and status.
- Use 20-row pagination; default to most recently updated with `id` for stable order. Allow sorting by civilian word or update date.
- Preserve URL filters when entering forms and returning.
- Include loading, empty, error, and retry states.

### Create/edit form

- Add `/word-prompts/new` and `/word-prompts/:id/edit` routes.
- Use existing fields: `text`, `category_id`, `difficulty`, `locale`, `image_path`.
- Defaults: `locale=vi`, difficulty `medium`.
- Select active `word` categories with the same locale.
- Existing prompts in disabled categories retain their current category for editing/saving; publishing requires an active category.
- Default locale is `vi`; changing it requires selecting a matching category. Do not automatically change category locales.
- Previews follow unsaved data with Civilian and Imposter cards. Category hint defaults off; enabling it shows only the selected category name, disabling it shows only “You are the imposter”; do not save this setting in the prompt.

### Actions by status

| Current status | Actions |
|---|---|
| Unsaved new prompt | Save draft; Publish; Cancel; no delete |
| Saved Draft | Save draft; Publish; Archive; Permanently delete |
| Published | Save update with confirmation; Revert to draft with confirmation; Archive with confirmation; Permanently delete |
| Archived | Save edits; Revert to draft; Republish; Permanently delete |

Each action saves form data and status in one database write. Prevent repeated clicks, warn before leaving/logging out, and preserve input on save errors.

### Permanent deletion

- Place **Permanently delete** on each list row and edit form, beside Archive when available.
- Dialogs use the saved civilian word, category, and status, with a warning and confirmation button; no word re-entry is required.
- Warn that deletion is irreversible, unsaved changes will be discarded, and all image files remain.
- Deletion is independent of saving: do not validate the form, save edits, or upload the selected file.
- While deleting, block repeated clicks, dialog dismissal, internal navigation, and logout; warn on browser reload/tab close. Browsers may still let users force navigation.
- Success closes the dialog, invalidates word list/detail and category statistics queries, and returns forms to the list with current URL filters. Lists move to the last valid page when the final row is removed.
- Failure preserves the form, selected file, and confirmation data; show the error without automatically retrying deletion.
- Conflicts require reload before reconfirmation. Discard form input only after the user selects reload and confirms discarding changes. Close the dialog after reload so fresh confirmation requires reopening it.

### API and database

- Add list, detail, target-status save, image upload, and preview URL APIs, following category API Supabase client injection.
- `deleteWordPrompt(client, { id, updatedAt })` calls only `delete_word_prompt(p_id uuid, p_expected_updated_at timestamptz)`.
- Delete RPC uses `SECURITY DEFINER`, `search_path = ''`; revoke execution from `PUBLIC`/`anon`, granting only `authenticated`. Keep direct `DELETE` revoked.
- Lock the active admin grant with `FOR SHARE`, the prompt with `FOR UPDATE`, check `updated_at`, then delete in the same transaction. Missing record: `P0002` (“Prompt no longer exists”); stale version: `40001`, requiring reload. Do not modify categories/questions or category transfer/purge RPCs.
- Add a migration normalizing text, converting empty optional fields to `null`, updating `updated_at`, and checking category type/locale and publishing conditions.
- Civilian text must remain nonempty after trimming in all statuses; images remain optional when publishing.
- Verify the referenced image belongs to the prompt's bucket/path and exists before writing `image_path`.
- On edits, check the loaded `updated_at` to prevent overwriting another tab; report conflicts and require reload.
- Refresh word list/detail queries and category statistics after successful saves.
- Preserve compatibility with existing content transfer/category deletion; do not change question content schema or behavior.

## 3. Bucket and image lifecycle

Fixed bucket name: `word-prompt-images`:

| Property | Value |
|---|---|
| Public | Disabled |
| File limit | 5 MiB, or 5,242,880 bytes |
| Allowed MIME | `image/jpeg`, `image/png`, `image/webp` |
| Path | `<prompt-id>/<file-uuid>.<extension>` |
| Database stores | `image_path`, not signed URLs |

Supabase supports bucket-level size and MIME limits. See [bucket creation documentation](https://supabase.com/docs/guides/storage/buckets/creating-buckets).

### Uploading, replacing, and removing images

- Selecting a file immediately creates a local preview; validate size, format, and image readability before uploading.
- Generate a stable UUID for a new prompt before upload and use it when inserting the prompt.
- On save, upload the new file with `upsert: false`, then write its `image_path` to the prompt.
- Upload failures prevent writes. Database failures preserve the old image and attempt new-file cleanup; cleanup errors must not hide the primary save error.
- Replacements always use a new path. Removing an image in the form only unlinks it after successful saving; do not delete the old file during that write.
- Retain all old images, images from permanently deleted prompts, and purged content images to avoid accidental deletion; no automatic cleanup job yet. Prompt deletion RPCs do not call Storage delete.
- Show uploading, success, and error states without fake percentages.
- Revoke local preview object URLs when replacing files or leaving the form.

### Read and write permissions

Policies on `storage.objects`, all restricted to the correct bucket:

- Active admins: `SELECT`, `INSERT`; `DELETE` only for files no longer referenced by any prompt, for failed-upload cleanup.
- `anon` and regular authenticated users: `SELECT` when a `word_prompts` row has matching `image_path = storage.objects.name` and `status = 'published'`.
- No `UPDATE`, since files are never overwritten.
- Reuse `private.is_admin()`; checking only `authenticated` is insufficient.
- Separate admin-read and published-read policies so `anon` does not need permission to call `private.is_admin()`.

See [Storage RLS documentation](https://supabase.com/docs/guides/storage/security/access-control).

Admin uses 5-minute signed URLs for thumbnails/previews, refreshed on expiry. Players may download or request URLs only for published images. See [signed URL documentation](https://supabase.com/docs/reference/javascript/storage-from-createsignedurl).

After prompt deletion, no published record references its image, so anon/regular users cannot download directly or obtain new signed URLs. Previously issued URLs remain usable until expiry; downloaded images cannot be revoked. Revoke local object URLs when replacing files, reloading, or leaving the form.

## App data contract

The app bundles no fallback data; all content comes from the Supabase API.

- Use `anon` with a publishable key; no admin login or embedded `service_role`. Existing RLS allows active `game_categories` and `word_prompts` with `status = 'published'`. No new app migration is needed.
- Select only gameplay fields: `id`, `category_id`, `text`, `image_path`, `difficulty`, `locale`, and category name/locale/type.
- Images: request signed URLs or download under published-image policies, then cache locally by `image_path` for offline use. Draft/archived/deleted prompt images cannot be fetched anew; cached files are removed at the next sync. Since the app keys images by `image_path`, replacements must always use new paths (section 3).
- Admin publishing, archiving, editing, or deletion takes effect at the next content fetch; ongoing games retain their selected prompts.
- Cache the latest successful fetch. Offline use may be stale until successful sync; the first launch without connectivity shows an error and retry.
- `word_prompts`/`game_categories` become contracts with released apps: prefer additive columns. Renaming/dropping columns (such as moving to `text` or removing `imposter_*`) requires coordination with app versions before applying to their environment.

## 4. Local + Dev setup guide

### Local

1. Start local Supabase and open Studio at `http://127.0.0.1:54323`.
2. Open **Storage → New bucket**, enter `word-prompt-images`, disable Public.
3. Set 5 MiB and MIME types `image/jpeg`, `image/png`, `image/webp`.
4. Apply the image-policy migration when implemented. Creating a bucket alone does not authorize admin uploads.
5. Record equivalent configuration in `supabase/config.toml` for local reproducibility:

```toml
[storage.buckets.word-prompt-images]
public = false
file_size_limit = "5MiB"
allowed_mime_types = ["image/jpeg", "image/png", "image/webp"]
```

No `objects_path` is needed because sample images are not seeded. Do not seed content in any environment; prompts and images are created only through admin. Do not reset an existing database just to add a bucket.

### Dev cloud

1. Open Dev project `imposter-word`, ref `pxycsjwjakzehcuygngv`.
2. Create the same bucket name, permissions, size, and MIME settings under **Storage → New bucket**.
3. Apply locally tested policy migrations. Do not add an “all authenticated users may upload” policy.
4. Run admin in Development, log in as admin, and test form uploads.
5. Verify anon cannot read draft images, can read after publishing, and cannot get new URLs after archiving.
6. Dev has no seeds, so content stays empty until entered through admin. UAT creates/publishes a prompt through admin and verifies app (`anon`) access to the prompt and image.

### Adding configuration to the repository

- Create a Supabase CLI migration containing bucket configuration and Storage policies for consistent application across environments.
- Handle manually created buckets by updating configuration by name instead of creating duplicates.
- Test locally first; dry-run pending migrations before applying to Dev.
- Review existing policies for broader permissions that could exceed requirements.
- Never put `service_role`, secret keys, or database passwords in `VITE_*`.

Existing environment guides: [admin-supabase-environment-guide.md](admin-supabase-environment-guide.md) and [supabase-local-manual-setup.md](supabase-local-manual-setup.md).

## 5. Implementation order and testing

### Order

1. Validation/timestamp migration and bucket/policies; test permissions through SQL and Storage API.
2. API, validation, and word list.
3. Create/edit form, category assignment, and unsaved changes warnings.
4. Upload/replace/remove images and role previews.
5. Publish, revert to draft, archive, permanently delete from list/form, and handle conflicts; deploy delete RPC after prompt/image management migration.
6. Check the complete Local flow, then Dev; update progress documentation.

### Tests

- Validation/API: text trimming, optional fields, special-character search, filters, pagination, statuses, and edit conflicts.
- SQL: admin/non-admin, incorrect category type/locale, publishing in disabled categories, timestamps, missing images/invalid paths, and content transfer during category deletion.
- Real local Storage API: admins upload; regular users cannot write; draft/archived images deny reads; published images allow reads; invalid MIME/oversized files are rejected.
- Test both anon and authenticated non-admin roles; disabling admins must revoke image/content management.
- Manual complete flow: draft with image → reload → edit/replace image → preview → publish → archive → republish.
- Also test image removal followed by cancellation, network loss during upload/save, simultaneous edits, no valid categories, and expired signed URLs.
- SQL deletion for `draft`, `published`, `archived`; reject anon, regular users, disabled admins, invalid/null confirmation, stale/null versions, and missing prompts; direct DELETE remains revoked.
- API/UI deletion: cancel dialog, confirm, prevent duplicates/navigation/logout, network errors preserving form/file, invalid-form deletion, concurrent edits/deletes, reload with discard confirmation, URL retention, and pagination adjustment. Invalidate category statistics too.
- Storage: files remain after deletion; anon/regular users cannot read or obtain new URLs; pre-deletion signed URLs work until expiry.
- Run admin tests, Local/Development builds, and desktop/tablet layout, accessibility label, and i18n checks.

### Completion criteria

- Data and image links survive reload correctly.
- Upload/save errors preserve old images and current input.
- Players cannot fetch draft/archived data or obtain new image URLs for it.
- Civilian/imposter previews match agreed behavior.
- All saved statuses can be deleted through confirmation/version-checked RPCs, without saving/uploading unsaved input; retain images, block new player access, and refresh lists/statistics correctly.
- Complete management works on Local and Dev before moving to question content.

### Workspace verification results

- `cd admin && yarn test`: 31 tests passed, including API, validation, i18n, and mounted Vue components testing network errors, conflicts, confirmations, busy guards, data retention, pagination, and sidebar navigation.
- `localdev` and `development` builds passed. Builds do not verify the Dev cloud environment.
- `supabase/tests/word_prompt_management.sql` and regression `category_management.sql` passed locally; SQL fixtures roll back.
- `node admin/tests/wordStorage.local.js` passed through real local Auth/Data/Storage APIs; dedicated fixtures are cleaned in `finally`.
- `supabase db advisors --local --type security`: no issues. Local migration history records both new migrations.
- Checked Chrome desktop navigation among Categories/Words/Questions and opening category filters before navigation. Fixed empty-valued “All” options causing Reka SelectItem errors and stale router views; now uses `all` following category filters, without putting the sentinel in URLs. Regression tests cover all four tabs, valid Select options, clearing filters, and unsaved changes warnings. Tablet sizes remain unchecked.
- No Dev cloud migration deployment or full Dev UAT. Do not mark the Local/Dev milestone complete before those steps.

## Known limits and risks

- Actual cloud project state and Dev migrations were not checked/applied in this implementation.
- Question screens, Flutter gameplay integration, image library, cropping, and automatic cleanup are not implemented.
- Prompt deletion is irreversible; no restore, bulk deletion, or cleanup job is added.
- Issued signed URLs remain usable until expiry after archiving/deletion; downloaded images cannot be revoked.
- Unlinked images still consume Storage, including replaced images, deleted/purged content images, and failed uploads whose cleanup failed.
- With no bundled content, first launch offline cannot play; cached offline devices may remain stale and miss recent archives/deletions.

## Simplifying Wording to match gameplay

- `simplify_word_prompts` drops `imposter_text` and `imposter_hint` from `word_prompts`, replacing the trigger function in the same transaction; historical migrations stay unchanged.
- Preserve `text`, `category_id`, and existing image/status/filter fields. Question schema stays unchanged.
- Flutter has no Wording gameplay yet; category display settings belong to the locally stored game, with category names resolved by `category_id` from downloaded API/cache data.
- For shared environments, export nonempty values from both columns; update admin before applying the migration. Old admin versions are incompatible after column removal.

### Wording simplification verification (2026-10-13)

- Before local migration: 0 word prompts, 0 records with imposter words/hints; no data required export.
- Applied `20261013164020_simplify_word_prompts.sql` locally without resetting; schema checks confirm both columns are removed.
- 31 admin tests passed, including payload removal of old fields and preview templates not exposing words/images; local build passed.
- `word_prompt_management.sql` and `category_management.sql` passed; local security advisor reported no warning/error issues.
- Local `wordStorage.local.js` integration passed: draft creation, edit/publish, archive/republish, literal comma/wildcard/quote search, image permissions, and prompt deletion. Fixtures were cleaned.
- Migration tested with old word/hint fixtures in a rolled-back transaction: remaining data stayed intact and triggers still trim/update.
- Replayed all migrations on a temporary empty local application DB retaining Supabase Auth/Storage foundations: both SQL suites passed; temporary DB removed.
- No manual UI checks because tools could not connect to the browser; Dev cloud not applied.


## Form and `text` field update (2026-10-21)

- Renamed `word_prompts.civilian_text` to `word_prompts.text` in `20261021032252_rename_word_prompt_text.sql`; in-place rename without table recreation or data reset. Historical migrations remain unchanged.
- Admin uses `text` in forms, lists, search, sorting, and deletion dialogs; the label is “Secret word”. Legacy `sort=civilian_text` URLs still resolve to `sort=text`.
- Clean forms accept query updates; dirty/busy forms retain data and files. Save conflicts persist until successful reload; further edits do not hide the reload button. Block saving/status changes while conflicted.
- Forms separate Content, Classification, Image, and Preview; two cards use light teal/yellow backgrounds, role icons, wrapped content, proportional images, and vertical stacking on narrow screens. Permanent deletion is separate from save actions.
- 32 admin tests passed, including clean/dirty/busy cache behavior, conflict persistence during further edits, canceled/failed/successful reload, preview toggles not marking forms dirty, and legacy sort URLs.
- Local/Development builds passed. SQL `word_prompt_management.sql`, `category_management.sql`, migration preservation with rollback fixtures, and local Auth/Data/Storage integration passed. Local security advisor found no issues.
- Migration applied locally only. Shared environments must deploy database and admin together because old admins use the old column; no data export/import is required.
- Checked Chrome desktop with an image prompt: balanced cards and proportional images; enabling hints shows only the category, disabling shows only the role. Refreshed Vite so Nuxt UI theme picks up the new toggle. Tablet/mobile visual checks remain pending.

### `text` appears last in Supabase Studio

Database order remains `id`, `category_id`, `text`, `image_path`, … (`text` is position 3). Studio stores its own browser column order; renamed columns may move to the end. No additional database migration is needed.

Run the JavaScript below in DevTools Console on **the word_prompts table tab in Local Studio**. It only resets column display order for the open table, preserving widths, filters, and other tables' settings. Do not run in SQL Editor.

```js
(() => {
  if (location.origin !== 'http://127.0.0.1:54323') {
    throw new Error('Run only on Supabase Studio Local.');
  }
  const match = location.pathname.match(/^\/project\/([^/]+)\/editor\/(\d+)$/);
  if (!match || !document.title.includes('word_prompts')) {
    throw new Error('Open the word_prompts table before running.');
  }
  const key = `supabase_grid_${match[1]}`;
  let changed = false;
  for (const storage of [localStorage, sessionStorage]) {
    const raw = storage.getItem(key);
    if (!raw) continue;
    const state = JSON.parse(raw);
    const table = state[match[2]];
    if (!Array.isArray(table?.gridColumns)) continue;
    const textColumn = table.gridColumns.find(c => c.key === 'text')
      || table.gridColumns.find(c => c.key === 'civilian_text')
      || { key: 'text', name: 'text', width: 250 };
    const columns = table.gridColumns.filter(c => !['text', 'civilian_text'].includes(c.key));
    const categoryIndex = columns.findIndex(c => c.key === 'category_id');
    if (categoryIndex < 0) throw new Error('The category_id column was not found in the configuration.');
    columns.splice(categoryIndex + 1, 0, { ...textColumn, key: 'text', name: 'text' });
    table.gridColumns = columns.map((column, idx) => ({ ...column, idx }));
    storage.setItem(key, JSON.stringify(state));
    changed = true;
  }
  if (changed) location.reload();
  else console.info('No saved column order exists for this table.');
})();
```

Configuration storage mechanism: [Supabase Studio source](https://github.com/supabase/supabase/blob/master/apps/studio/components/grid/SupabaseGrid.utils.ts).

The layout JavaScript was tested with mocked storage: it preserves widths, filters, and other tables' settings, supports old/new column names, and rejects other origins. It has not been applied to the real Studio tab's storage.
