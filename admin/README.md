# Admin

Admin dashboard built with Vue 3 and Vite.

## UI components

Use Nuxt UI 4 components for forms, inputs, selects, tables, pagination,
dialogs, buttons, alerts, cards, skeletons, avatars and breadcrumbs.
Vue Router still owns navigation and route guards; Nuxt is not required.

Nuxt UI is configured in `vite.config.js` and registered in `src/main.js`.
`UApp` follows the global Vue I18n locale. Tailwind uses the `tw:` prefix to
coexist with the existing CSS tokens. Brand yellow comes from
`src/styles/theme.css`; global component overrides live in `vite.config.js`.
Keep page CSS for layout, and avoid styling native inputs/buttons inside
Nuxt UI components.

Categories retain server filtering, ordering and pagination with Vue Query.
Keep payload validation, unsaved-change guards and the delete confirmation dialog
when editing UI components. Confirmation is a UI action; deletion RPCs accept no
confirmation text. The table renders the rows returned by the API,
without adding another client pagination layer.

References: [Vue setup](https://ui.nuxt.com/docs/getting-started/installation/vue),
[Form](https://ui.nuxt.com/docs/components/form),
[Table](https://ui.nuxt.com/docs/components/table),
[Modal](https://ui.nuxt.com/docs/components/modal).

For setting up the project on a new device, see
[`docs/admin-supabase-new-device-guide.md`](../docs/admin-supabase-new-device-guide.md).
The shorter environment reference is available at
[`docs/admin-supabase-environment-guide.md`](../docs/admin-supabase-environment-guide.md).

## Environments

The admin app uses Vite modes and Supabase projects as follows:

| Environment | Vite mode | Env file | Supabase target |
| --- | --- | --- | --- |
| Local | `localdev` | `.env.local` | Local Supabase CLI stack |
| Dev | `development` | `.env.development.local` | `imposter-word` cloud project |
| Prod | `production` | `.env.production.local` | Production cloud project (not configured yet) |

The `*.local` files are ignored by Git. Copy `.env.example` to create one.
`.env.production` is a tracked empty guard so a production build cannot
silently fall back to the local Supabase project.
`VITE_*` values are bundled into the browser; use only the Supabase publishable
key in this Vue app. Never use `service_role` or a Supabase secret key here.

## Development

```sh
yarn install

# Local Supabase stack
yarn dev:local

# Shared dev Supabase project
yarn dev:development
```

## Production build

```sh
# Production Supabase project
yarn build:production

# Other explicit modes
yarn build:local
yarn build:development
```

## Translations

Vue I18n 11 is registered in `src/main.js`; `src/i18n/index.js` uses `vi`
as the default and fallback locale. `locales/vn.json` contains Vietnamese
messages under runtime locale `vi`. `locales/en.json` is intentionally `{}`:
English falls back to Vietnamese for app text while Nuxt UI uses its English
locale and dates use `en-US`. There is no language selector yet.

Use nested semantic English lowerCamelCase keys (`categories.fields.name`),
with English named placeholders (`{name}`, `{count}`). English keys must be a
subset of Vietnamese keys with matching placeholders and nonempty strings.
Keep translations in computed values or templates so changing locale updates
menus, options, columns and visible messages. Route metadata stores `titleKey`
and `descriptionKey`; shared helpers return stable error keys and preserve
backend errors. Translate only known keys at the UI boundary.

UI locale never changes database content, enum values, URLs, filters or the
`vi` locale in category creation payloads. Browser validation and beforeunload
messages follow the browser/OS language. Run `yarn test` for dictionary,
fallback, locale switching and existing category/auth behavior checks.

## Deletion RPCs

- `delete_word_prompt(p_id uuid, p_expected_updated_at timestamptz)`
- `delete_category(p_id uuid, p_mode text, p_target_id uuid default null, p_expected_version text default null)`

Both RPCs require an active admin. Word deletion requires the saved timestamp;
category `purge` requires the preview snapshot version. Missing or stale versions
are rejected. Category `empty` and `transfer` retain their existing validation.
Storage files are retained.

The migration removing confirmation changes the RPC signatures. Deploy it and
the matching admin build together, pause delete operations during rollout, and
reload open admin tabs afterward. Old RPC signatures are not retained.
