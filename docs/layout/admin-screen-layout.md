# Admin Screen Layout

> This document describes the layout, content, and UI components of the Vue admin.

Shared list styles are defined in [Admin List Style Rules](admin-style-rules.md), using Word Prompt as the reference.

## Purpose

Admin manages backend categories and content. Players do not log in; player names, answers, votes, and game state are stored locally on the device within R1 scope.

Implementation order and completion criteria are described in the [Admin Screen Implementation Plan](../admin-screen-implementation-plan.md).

## Admin shell

Admin uses a desktop-first layout responsive to tablets. The MVP UI focuses on content management without additional administration screens.

1. **Fixed left sidebar**
   - App logo/name: `Imposter Admin`.
   - `Overview`.
   - `Categories`.
   - `Word content`.
   - `Question content`.
   - Sidebar bottom: admin email and `Log out` button.

2. **Page header**
   - Current screen breadcrumb.
   - Current screen title.

3. **Main content area**
   - Screen title.
   - Short description if needed.
   - Primary action at the top right.

## Admin Overview screen

### Purpose

Give admins a quick view of content health and pending work.

### Layout

- Statistics card row:
  - `Published word prompts`.
  - `Published question prompts`.
  - `Active categories`.
  - `Draft content`.
- `Recently updated content` section.
- `Drafts needing attention` section.
- Warnings section:
  - Categories without content.
  - Identical civilian and imposter questions.

## Categories screen

### Layout

- Primary button: `+ Add category`.
- Filters:
  - Game type: `Words` or `Questions`.
  - Table display language; new entries are fixed to Vietnamese.
  - Active/inactive status.
- Category table:
  - Category name.
  - Game type.
  - Content count.
  - Language.
  - Status.
  - Update time.
  - Actions menu.

### Category form

- Category name.
- Slug.
- Game type.
- Description.
- Language.
- Display order.
- Active/inactive.
- Family Mode checkbox in shared information for word categories; hide and set false for questions. Category lists have a Family Mode column and filter.

Game type and language are fixed when editing. To change type, admins must create a new category.

### Category deletion

- Empty category: confirm, then permanently delete.
- Category with content: transfer all content to an active category of the same type/language and delete, or delete both the category and all content.
- Full deletion shows draft/published/archived counts and requires the exact category name. If content changes after opening the dialog, reload statistics for reconfirmation.
- Backend processing uses one transaction without automatic cascading. Deleting records does not remove Storage image files.


## Word Content screen

### List

- Primary button: `+ Add word prompt`.
- Filters:
  - Category.
  - Difficulty.
  - Language.
  - Status: `Draft`, `Published`, `Archived`.
- Table:
  - Thumbnail.
  - Civilian word.
  - Category.
  - Difficulty.
  - Status.
  - Update date.

### Word prompt create/edit form

- Civilian word.
- Image upload.
- Image preview.
- Replace or remove image.
- Category.
- Difficulty: `Easy`, `Medium`, `Hard`.
- Checkbox: `Suitable for Family mode`.
- Language.

The preview should simulate two states:

- `Civilian sees`: image and secret word.
- `Imposter sees`: role and category name if category display is enabled; otherwise role only. Preview both cases without saving this setting in the prompt.

Form footer buttons:

- `Save draft`.
- `Publish`.
- `Archive`.

## Question Content screen

### List

- Primary button: `+ Add question prompt`.
- Same filters as Word Content.
- Table:
  - Civilian question.
  - Imposter question.
  - Category.
  - Difficulty.
  - Status.
  - Update date.

### Question prompt create/edit form

Two-column form:

```text
┌────────────────────────┬────────────────────────┐
│ Civilian question      │ Imposter question      │
│ [textarea]             │ [textarea]             │
└────────────────────────┴────────────────────────┘
```

- Civilian question.
- Imposter question.
- No stored hint; the app handles category display.
- Question category.
- Difficulty.
- `Suitable for Family mode` checkbox.
- Language.
- Preview the question shown to each role.

Validation:

- Neither question may be empty.
- Questions must differ after trimming, case-insensitively; applies to all statuses.
- Questions must belong to a `question` category with the same locale; publishing requires an active category.
- Incomplete content cannot be published.

## UI and state rules

- `Draft`: yellow badge.
- `Published`: green badge.
- `Archived`: gray badge.
- `Publish` must be more prominent than `Save draft`.
- Archiving or deactivation requires a confirmation dialog.
- Tables support pagination, search, and sorting.
- Long primary names/content and category names wrap in tables; click the name to edit. Dates, statuses, and action groups stay on one line.
- Image uploads show progress, preview, and format/size errors.
- Family Mode is shared on word categories (`game_categories.is_family_friendly`), independent of difficulty and language. Question games do not have Family Mode.
- `Log out` is fixed at the bottom of the sidebar, separated from content items.
- Clicking `Log out` briefly shows loading before returning to the admin login screen.
- Warn before logging out if the admin has unsaved form changes.

## Admin navigation flow

```text
Admin login
└── Overview
    ├── Categories
    │   ├── Create category
    │   └── Edit category
    ├── Word content
    │   ├── List
    │   ├── Create/edit word prompt
    │   └── Upload image
    ├── Question content
    │   ├── List
    │   └── Create/edit question prompt
    └── Log out
```
