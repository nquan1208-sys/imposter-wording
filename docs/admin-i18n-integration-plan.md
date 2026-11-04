# Admin Language Integration Research

Date: 2026-10-12. Scope: Vue 3 + Vite + Nuxt UI 4 admin UI; proposal only, not implemented.

## 1. Approach

Use `vue-i18n@11` for application text and built-in `@nuxt/ui/locale` locales for Nuxt UI internal text. This follows Nuxt UI's Vue integration documentation.

Admin does not run Nuxt: `src/main.js` creates a Vue application using Vue Router and `@nuxt/ui/vue-plugin`. Follow the Vue guide without adding `@nuxtjs/i18n` or changing frameworks.

Two language files:

```text
admin/src/i18n/index.js
admin/src/i18n/locales/vn.json
admin/src/i18n/locales/en.json
```

- `vn.json`: complete Vietnamese text; all keys and placeholder names are English.
- `en.json`: initially valid `{}`, not a blank JSON file or keys with `""` values.
- Runtime locale codes: `vi` and `en`. Map `vn.json` to `messages.vi`; do not use `vn` as the Nuxt UI, HTML, or Intl language code.
- Default and fallback language: `vi`.
- When `en` lacks a key, application text falls back to Vietnamese. Nuxt UI internal text uses `en`, so the interface may mix languages until translations are complete.
- No language switcher is needed while `en.json` is empty. Test `en` through tests; add a selector only when needed.

Nuxt UI locales do not replace the application dictionary: the existing `UApp :locale="vi"` only provides locales to library components; it does not translate admin-supplied labels.

## 2. Consistent key rules

Keys are semantic paths: `<namespace>.<group>.<name>`. Shared groups may be shorter, such as `common.actions.save`. Use nested JSON objects, not flat dotted keys.

1. Each segment uses English `lowerCamelCase`, starting lowercase: `^[a-z][a-zA-Z0-9]*$`.
2. Do not use Vietnamese, spaces, hyphens, snake_case, or full display sentences as keys.
3. Do not embed locale codes: use `auth.login.title`, not `vn.login.title` or `loginTitleVi`.
4. Name by meaning and context rather than wording; changing translations must not change keys.
5. Both languages use identical key paths and placeholders. While EN is incomplete, its keys may be a subset of VN; no EN-only keys.
6. Use `common` only for shared meaning across screens. Do not merge different contexts merely because their Vietnamese wording matches.
7. Use complete sentences and `{name}`, `{count}`, `{page}`, `{pages}` placeholders; do not concatenate sentence fragments.
8. Error keys describe causes, such as `slugExists` or `sessionExpired`; do not use `error1` or full backend error sentences.
9. Keys must not contain data IDs or category names. Pass those through placeholders.

Agreed namespaces and groups:

| Namespace | Content |
| --- | --- |
| `common` | Shared `actions`, `fields`, `status`, `gameTypes`, `errors`, `confirmations` |
| `navigation` | `items`, `accessibility`, `account`, `contentManagement` |
| `auth` | `login`, `logout`, `errors` |
| `dashboard` | `title`, `description` |
| `categories` | `title`, `description`, `fields`, `help`, `actions`, `filters`, `table`, `pagination`, `form`, `deleteDialog`, `messages`, `errors`, `confirmations` |
| `wordPrompts` | `title`, `description`, screen-specific groups when implemented |
| `questionPrompts` | `title`, `description`, screen-specific groups when implemented |
| `placeholder` | `eyebrow`, `title`, `description` |

Example structure for part of `vn.json` (values shown in English here for readability; the actual VN dictionary uses Vietnamese):

```json
{
  "common": {
    "actions": {
      "save": "Save",
      "cancel": "Cancel",
      "retry": "Retry"
    },
    "gameTypes": {
      "word": "Words",
      "question": "Questions"
    }
  },
  "categories": {
    "title": "Categories",
    "fields": {
      "name": "Category name"
    },
    "pagination": {
      "summary": "{count} categories · Page {page} / {pages}"
    },
    "errors": {
      "slugExists": "This slug already exists for this game type and language."
    },
    "confirmations": {
      "deactivateNamed": "Disable category “{name}”? Its content will be preserved."
    }
  }
}
```

`en.json` initially contains only `{}`. When adding translations, `categories.fields.name` must remain `categories.fields.name`; do not change the key to translate the same content.

## 3. Proposed configuration

```js
// admin/src/i18n/index.js
import { createI18n } from 'vue-i18n'
import vn from './locales/vn.json'
import en from './locales/en.json'

export const i18n = createI18n({
  legacy: false,
  locale: 'vi',
  fallbackLocale: 'vi',
  messages: { vi: vn, en },
})
```

Register `.use(i18n)` in `main.js` before mounting. Components use `const { t, locale } = useI18n({ useScope: 'global' })` and `t('categories.fields.name')`.

In `App.vue`, explicitly import `{ vi, en }` from `@nuxt/ui/locale`, define `const uiLocales = { vi, en }`, and pass `<UApp :locale="uiLocales[locale]">`. Do not import every locale. Synchronize `<html lang>` through a Vue watch; initially default HTML to `vi`. Both languages are LTR; no head-management library is needed.

Keep missing-translation warnings in development to find incorrect keys. EN fallback tests may disable warnings on a dedicated test instance; do not disable application-wide warnings to hide missing VN keys.

## 4. Migration scope in existing code

| Location | Required work |
| --- | --- |
| `admin/package.json`, `admin/yarn.lock` | Add Vue I18n 11 and update the lockfile with Yarn |
| `src/main.js`, `src/App.vue`, `index.html` | Register the plugin, synchronize Nuxt UI locale and HTML `lang` |
| `src/router/index.js` | Replace literal `meta.title` / `description` with `titleKey` / `descriptionKey`; do not translate during route definition |
| `src/components/admin/AdminShell.vue` | Translate menus, breadcrumbs, titles, logout, account fallback, tooltips, and aria-labels |
| `src/views/login/LoginView.vue` | Translate titles, instructions, labels, placeholders, footer, and login errors |
| `src/views/shared/AdminPlaceholder.vue` | Translate placeholders and read `route.meta.descriptionKey` |
| `src/views/categories/*.vue` | Translate toolbars, loading, statuses, pagination, deactivation confirmations, detail errors, and success messages |
| `src/components/categories/*.vue` | Translate forms, filters, table headers, empty/caption text, badges, delete dialogs, data-loss warnings, and accessibility text |
| `src/utils/categories.js` | Replace Vietnamese labels/errors with keys; preserve validation and enum values |
| `src/utils/adminAuth.js`, `src/api/categories.js` | Use stable keys/causes for app-created errors; do not translate backend errors by modifying the entire error object |
| `src/utils/unsavedChanges.js` | Pass translated strings to `confirmDiscard(message)`; update AdminShell and CategoryFormView |
| `admin/tests/*.test.js` | Register i18n for SSR component rendering; change internal error assertions from Vietnamese sentences to stable keys/codes |
| `admin/README.md` | Describe dictionary structure, key rules, and fallback |

Implementation notes:

- Menus, table columns, select/radio options, and date formatters must use `computed` if locale-dependent. Calling `t()` once in a static array retains the old language after locale changes.
- Success/error refs should store keys with params or error objects; translate in computed/template so visible messages follow locale changes.
- `gameTypeLabels` also validates `game_type`. It can become a key map (`word: 'common.gameTypes.word'`, `question: 'common.gameTypes.question'`) while retaining `word`/`question` membership checks; update all callers.
- App validation errors may use `Error('categories.errors.nameRequired')`, or retain technical `message` with a `messageKey` if needed. Use and test one convention across auth/categories; do not call `useI18n` in JS helpers outside setup.
- Map `categoryError` and auth errors from stable codes to keys in the presentation layer. Do not pass arbitrary `error.message` to `t()` or identify errors by Vietnamese wording.
- Existing RPCs have Vietnamese errors and sometimes share codes (`23514`, `22023`). Initially map accurate general messages by code; detailed bilingual causes require stable backend identifiers in a separate change. Use translated generic messages for unknown errors and retain originals for diagnosis.
- CategoryTable currently uses `Intl.DateTimeFormat('vi-VN')`. Create locale-based formatters (`vi-VN` / `en-US`), preserving the current timezone; date formatting must not depend on translation fallback.
- Fully translate permanent deletion warnings, published-content warnings, and image-retention notices; preserve confirmation requirements and unsaved changes guards.
- `beforeunload` and native HTML validation text depend on the browser/OS. App-called `window.confirm` accepts translated text; Vue I18n cannot guarantee the language of every browser message.
- Database content (names, descriptions, slugs) remains data. Content `game_type`/`locale`, route URLs, filter queries, cache keys, and payloads do not change with UI language. In particular, do not replace `locale: 'vi'` in category creation payloads with the UI locale.
- Sample emails contain `@`; retain them as sample data or use valid Vue I18n literal interpolation in messages, and test rendering to avoid message compiler errors.

## 5. Implementation order and completion criteria

1. Add the plugin and two JSON files; collect complete Vietnamese translations following the rules above.
2. Migrate shell/login/router/placeholder, then all categories and related helpers.
3. Update existing tests, add dictionary contract/fallback checks, and update README.
4. Run `yarn test` and `yarn build:local` in `admin`; visually check screens and dialogs.

Required implementation checks:

- Each key segment matches the regex; VN leaves are nonempty strings. EN may omit keys but existing values cannot be empty.
- No EN-only keys; EN placeholders match VN.
- With `en.json = {}`, translating `categories.fields.name` in EN returns the Vietnamese category-name label rather than the key.
- Inspect literal keys in `t(...)`, route metadata, and enum/error maps for missing keys; regex cannot prove all dynamic keys, so test these separately or use explicit maps.
- Switching locale in component tests updates menus, options, columns, dates, and visible messages; use sample EN in a separate test instance without populating production `en.json`.
- Auth, payload validation, unsaved changes, and category deletion retain behavior; EN UI locale does not change content payload `vi`.
- Review labels, aria-labels, tooltips, placeholders, confirmations, and warnings for untranslated source text. Sample data, branding, and browser-generated messages do not count as missing translations.

This document adds no dependency, changes no runtime, and has not run tests/builds. Existing admin or migration changes are untouched.

## 6. Official documentation

- [Nuxt UI i18n — Nuxt, initial reference](https://ui.nuxt.com/docs/getting-started/integrations/i18n/nuxt): the Nuxt branch uses `@nuxtjs/i18n`.
- [Nuxt UI i18n — Vue, applicable to this admin](https://ui.nuxt.com/docs/getting-started/integrations/i18n/vue): Vue I18n 11, plugin registration, and locale binding with UApp.
- [Vue I18n — Composition API](https://vue-i18n.intlify.dev/guide/advanced/composition): `legacy: false`, `useI18n`, global scope, and computed translation.
- [Vue I18n — Fallback](https://vue-i18n.intlify.dev/guide/essentials/fallback): `fallbackLocale`, missing keys, and development warnings.
