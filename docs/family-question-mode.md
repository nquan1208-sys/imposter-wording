# Research: Family Mode for Question Games

Research date: 2026-11-03. Implementation update: 2026-11-04.
Sample data, question Family filters, admin controls, and automated checks are implemented.
Game rules are unchanged; suitability and balance still await playtesting.

## References and chosen direction

| Official source | Relevant mechanism | Application to this project |
| --- | --- | --- |
| [Herd Mentality — Big Potato](https://bigpotato.co.uk/blogs/how-to-play/herd-mentality) | Write answers privately and compare with the majority; publisher lists ages 10+ | Use familiar preferences and situations requiring no specialist knowledge. Do not add majority scoring. |
| [Insider — Oink Games](https://oinkgames.com/en/games/analog/insider/) | Questions, discussion, and finding a hidden role; publisher lists ages 9+ | Retain deduction from answers and discussion. Do not add a moderator or a quiz round with a correct answer. |

App-specific proposal: keep secret question reveal → answer entry → shared question
reveal → discussion → role reveal. Initially test with people able to read and type
answers independently, around age 10 and up; this is a playtesting hypothesis, not a validated age rating.

## Authoring criteria

- Each question requests a short answer; both questions in a pair require the same
  answer type: food, activity, place, color, or object. Example: fruit for juice / ice cream.
- Use different contexts with overlapping possible answers; avoid pairs so distant
  that the imposter is immediately exposed, or nearly synonymous pairs offering no clues.
- Do not ask about income, romance, secrets, appearance, member rankings, or required
  experiences such as flying. Do not require knowledge of celebrities.
- Do not copy reference games' card sets. The 15 seed pairs are newly authored.
- `easy` is an initial editorial label; suitable content does not establish balanced
  deduction difficulty. Test with groups containing children and adults.

## Added data

| Category | Slug | Pairs |
| --- | --- | --- |
| Family · Happy Mealtimes | `family-mealtime` | 5 |
| Family · Everyday Together | `family-together` | 5 |
| Family · Playful Imagination | `family-imagination` | 5 |

Each pair and category has published Vietnamese/English translations sharing one ID.
In the question game, open Categories → Family mode → Confirm. Selecting no specific
category plays all Family-flagged categories; questions outside the filter are excluded.
The All categories tab still supports regular and custom content.
Connect to the local backend and refresh content; old caches missing the Family flag
produce empty Family results instead of using unreviewed content.

The seed is in `supabase/seed_family_questions.sql`, runs in one transaction,
and uses fixed IDs with `ON CONFLICT ... DO NOTHING` to preserve existing edits.
It is listed after `seed.sql` in `config.toml`, so new databases also receive it through
[Supabase seeding](https://supabase.com/docs/guides/local-development/seeding-your-database).

Load into the running local stack without resetting or reloading other seeds:

```bash
rtk proxy supabase migration up --local
rtk proxy sh -c 'docker exec -i supabase_db_imposter-wording psql -U postgres -d postgres -v ON_ERROR_STOP=1 < supabase/seed_family_questions.sql'
rtk proxy sh -c 'docker exec -i supabase_db_imposter-wording psql -U postgres -d postgres -v ON_ERROR_STOP=1 < supabase/tests/family_question_seed.sql'
```

SQL checks use the `anon` role: 3 categories, 5 easy pairs each, with published
translations in both languages. Rerunning the seed neither duplicates nor updates existing content.

## Implemented Family filtering

- DB: migration `20261104082852_question_family_mode.sql` removes CHECK
  `family_word_categories_only` and enables the flag for exactly the 3 seed IDs/slugs above if present.
  New seeds create flagged categories; reruns do not overwrite existing edits.
  RPCs, RLS, and type structures are unchanged because they already support category flags.
- Admin: forms allow Family for both word and question types and preserve it when switching game type;
  lists and filters reuse the existing column/RPC.
- App: both game types share All/Family tabs and the draft → confirm workflow.
  Approved categories govern counts, selections, and session creation throughout.
  Family is saved and preserved across game/language changes; invalid categories
  are removed from selections. Games cannot start without Family content.
- Custom questions are not automatically flagged; they appear and participate only
  in All mode. The question Family tab has no create-category button. Saved content remains intact.
  The Family image option remains exclusive to word games.

The migration was applied to the local DB without resetting data. For other environments,
release the app with the new model before enabling Family on questions: older apps reject
snapshots containing flagged question categories. No remote/production deployment has occurred.

Automated checks cover category filtering (ignoring old prompt flags), missing cache flags,
VI/EN, language changes, game switching, saving/restoring Family, empty categories, exclusion
of custom questions, discarding drafts, save failures, and retries; SQL checks anon/admin permissions and RPCs.

## Pending playtesting

Test the 15 pairs with groups containing children and adults: record confusing pairs, common
answers, and cases where the imposter is exposed solely by answer type. No playtest results
currently validate balance or age suitability; `easy` remains an editorial assessment.
Do not infer suitability for every family from the reference games' age labels.
