# Admin Style Rules

The Word Prompt list is the reference for the Category list. When adding admin lists, use the rules below and shared classes in `admin/src/styles/admin-lists.css`.

## Tokens and layout

- Use tokens from `admin/src/styles/theme.css`; do not duplicate colors or spacing in each screen.
- Page background: `--color-gray-50`; primary text: `--color-charcoal`; secondary text: `--color-charcoal-soft`.
- Separate content blocks by `--space-4` (20px). Toolbars and pagination use flex, vertically centered, horizontally space-between, with `--space-3` (16px) gaps.
- Place toolbar descriptions on the left and the create button with a plus icon on the right. Keep titles in the admin shell.
- Table containers need `min-width: 0`; grids use `minmax(0, 1fr)` so tables do not widen the page.

## Filters

- Use `admin-filter-grid` without an additional card. Each input/select has a clearly labeled `UFormField` and 100% width.
- Desktop: 4 equal columns, gap `--space-3`. At 1000px and below: 2 columns; at 600px and below: 1 column.
- Keep search first, business filters in the middle, and sorting last. Preserve each screen's URL filter behavior.

## Tables

- Use `admin-table-scroll` on the wrapper: white background, 1px `--color-teal-border`, `--radius-md` (12px) corners, internal horizontal scrolling.
- Use `admin-table` on the table: 100% width, collapsed borders, `--space-3` cell padding, left-aligned and vertically centered.
- Header: `--color-teal-surface` background, 14px text, weight 600. Content uses body text size. Separate rows with teal borders; omit the bottom border on the last row.
- For `UTable`, put the wrapper class on the component and pass `base: 'admin-table …'` and `tbody: 'tw:divide-y-0'` through `ui`. Preserve component captions, empty messages, and loading states.
- Minimum width depends on column count: Categories 1100px, Word Prompt 1240px, Question Prompts 1400px. Do not shrink tables until buttons disappear or content is clipped.
- Wrap long primary names/content and category names with `overflow-wrap: anywhere`; limit text cells to 320px. Keep short details such as dates, statuses, and actions on one line.
- Editable names use neutral/link `UButton`, zero padding, left alignment. Show slugs as secondary text below. Category status continues using badges.
- Truncate each Question Prompts question to three lines; open the form to read it in full.
- Screen-specific rules such as 96×96px Word Prompt images and individual column widths belong in the screen's CSS.

## Buttons and states

- Create buttons use default primary styling. Table actions use neutral/outline; Delete uses error/outline.
- Table action groups stay on one line with `--space-1` (8px) gaps and non-shrinking buttons. Button groups outside tables may wrap.
- Preserve existing success/error `UAlert`, loading, and retry behavior. Empty states use each screen's translated messages.
- Preserve disabled/loading states during processing, confirmations, accessible labels, and keyboard focus; styling changes must not alter CRUD behavior.

## Responsive behavior and checks

- At ≤600px, stack toolbars and pagination; tables still scroll horizontally within their wrappers.
- Check desktop, tablet, and mobile with long names, empty tables, loading, and rows containing every action. Tables must not cause page-level horizontal scrolling.
- List rules do not apply directly to forms or dialogs. Category forms follow the rules below; other forms and dialogs retain their current styling.

## Category create/edit form

- Keep `UCard` at 100% width, maximum 850px: `--color-white` background, 1px `--color-teal-border`, `--radius-md` corners, no default shadow or ring. Content padding and block spacing use `--space-4`.
- Short fields use a 2-column `minmax(0, 1fr)` grid with `--space-3` gaps; switch to 1 column at ≤600px. Description spans the full width; input/select/textarea fill their cells without horizontal overflow.
- Labels use `--color-charcoal`, helper text uses `--color-charcoal-soft`. Preserve component validation errors and keyboard focus.
- Save uses default primary; Cancel uses neutral/outline. Button groups may wrap with `--space-1` gaps.
- Scope styles to `CategoryForm.vue` so screens sharing `category-form-*` classes remain unchanged. Preserve validation, pending/disabled states, and create/edit behavior.
