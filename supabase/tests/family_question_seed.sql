-- Run after seed_family_questions.sql on a fresh, unedited local seed.
begin;
set local role anon;

do $$
begin
  if (select count(*) from public.game_categories
      where id::text like '5eed0003-%' and game_type = 'question' and is_active
        and not is_family_friendly) <> 3 then
    raise exception 'Expected 3 visible family question categories';
  end if;
  if (select count(*) from public.game_category_translations
      where category_id::text like '5eed0003-%' and locale in ('vi', 'en')
        and status = 'published') <> 6 then
    raise exception 'Expected 6 visible category translations';
  end if;
  if (select count(*) from public.question_prompts
      where id::text like '5eed0013-%' and difficulty = 'easy') <> 15 then
    raise exception 'Expected 15 visible easy question pairs';
  end if;
  if exists (
    select c.id from public.game_categories c
    left join public.question_prompts q on q.category_id = c.id
    where c.id::text like '5eed0003-%'
    group by c.id having count(q.id) <> 5
  ) then
    raise exception 'Expected 5 pairs in every family category';
  end if;
  if (select count(*) from public.question_prompt_translations t
      join public.question_prompts q on q.id = t.prompt_id
      where q.id::text like '5eed0013-%' and q.category_id::text like '5eed0003-%'
        and t.locale in ('vi', 'en') and t.status = 'published'
        and btrim(t.civilian_question) <> '' and btrim(t.imposter_question) <> ''
        and lower(btrim(t.civilian_question)) <> lower(btrim(t.imposter_question))) <> 30 then
    raise exception 'Expected 30 visible, complete question translations';
  end if;
end;
$$;

rollback;
