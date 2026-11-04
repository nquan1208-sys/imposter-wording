# Category-Based Family Mode for Words

Current contract from migration `20261027050239_category_family_mode.sql`.

Research on extending question games and local sample data:
[Family Mode for Question Games](family-question-mode.md).

- `game_categories.is_family_friendly`: boolean, NOT NULL, default false; CHECK permits the flag only for `game_type = 'word'`. The flag is shared across translations.
- The migration preserves categories, prompts, translations, and images. Family is disabled on all existing categories for admin review; prompt flags are not transferred to categories.
- `word_prompts` and `question_prompts` no longer have `is_family_friendly`.
- Admin manages the Family flag, column, and filter on categories. Prompts and the dashboard no longer have Family fields/filters/warnings.

## RPC

Keep RPC names, change signatures; do not retain old overloads:

```sql
save_category(p_id uuid, p_game_type game_type, p_slug text,
  p_sort_order integer, p_is_active boolean, p_is_family_friendly boolean,
  p_locale text, p_name text, p_description text, p_status content_status,
  p_expected_updated_at timestamptz)

admin_list_categories(p_locale text, p_search text, p_game_type game_type,
  p_is_active boolean, p_is_family_friendly boolean, p_sort text, p_page integer)

save_word_prompt(p_id uuid, p_category_id uuid, p_difficulty difficulty_level,
  p_image_path text, p_locale text, p_text text, p_status content_status,
  p_expected_updated_at timestamptz)

save_question_prompt(p_id uuid, p_category_id uuid, p_difficulty difficulty_level,
  p_locale text, p_civilian_question text, p_imposter_question text,
  p_status content_status, p_expected_updated_at timestamptz)

admin_list_word_prompts(p_locale text, p_search text, p_category_id uuid,
  p_difficulty difficulty_level, p_status content_status, p_sort text, p_page integer)

admin_list_question_prompts(p_locale text, p_search text, p_category_id uuid,
  p_difficulty difficulty_level, p_status content_status, p_sort text, p_page integer)
```

Nullable filters mean all. Preserve 20-row pagination, active-admin checks, transaction locks, independent translations, and `PT409` when the base version changes. Admin RPCs grant EXECUTE only to authenticated users and still check admin permissions internally.

## App

The word category screen has two tabs: **All categories** (including Family) and **Family mode** (only flagged categories with valid words). Family includes all valid words in a category without difficulty or prompt-flag filtering. Card counts use the same rule.

Tab, categories, and **Show images** are draft selections saved together on **Confirm**. Going back discards the draft; write errors preserve the previous settings and selection screen for retry. Switching tabs removes invalid categories and notifies the user; no specific selection means all categories in the tab. An empty Family tab shows a message and cannot start a game without words.

Remember the image preference but display images only in Family word games. Question games have no Family tab or filter; switching to questions or restoring old question settings resets the mode to normal. Old caches without category flags default to false, ignore old prompt flags, and remain playable offline in the All tab.

## Local application and verification

1. Back up the entire DB with `pg_dump -Fc` before migration; store the backup outside Git.
2. Run `supabase migration up --local` without resetting. Generate types with `cd admin && yarn types:database`.
3. Run `python3 supabase/tests/content_translations.py`: rehearse on a disposable database copy, checking backfill, data, SQL, and lock contention.
4. Run `supabase db lint --local` and `supabase db advisors --local --type security`.
5. Admin: `yarn test`, `yarn build:local` (includes typecheck). App: `flutter analyze`, `flutter test`.
6. Run HTTP checks from `postman/simulations/phase-7.context.md` when verifying the Supabase client through mock HTTP.

This change is local only. Cloud deployment must align DB, admin, and app contracts: old clients fail because old columns and RPC signatures were removed. The Family tab stays empty until an admin enables categories.
