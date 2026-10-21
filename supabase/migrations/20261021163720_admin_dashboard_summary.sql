create function public.admin_dashboard_summary()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  result jsonb;
  trim_chars text := E' \t\n\r\f\013' || U&'\00A0\1680\2000\2001\2002\2003\2004\2005\2006\2007\2008\2009\200A\2028\2029\202F\205F\3000\FEFF';
begin
  perform 1 from public.admin_users
  where user_id = auth.uid() and is_active and role = 'admin' for share;
  if not found then
    raise exception 'Bạn không có quyền quản trị.' using errcode = '42501';
  end if;

  with prompts as (
    select w.id, 'word'::text as game_type, w.text as title, c.name as category_name, w.status, w.updated_at
    from public.word_prompts w join public.game_categories c on c.id = w.category_id
    union all
    select q.id, 'question', q.civilian_question, c.name, q.status, q.updated_at
    from public.question_prompts q join public.game_categories c on c.id = q.category_id
  )
  select jsonb_build_object(
    'stats', jsonb_build_object(
      'published_word_prompts', (select count(*) from public.word_prompts where status = 'published'),
      'published_question_prompts', (select count(*) from public.question_prompts where status = 'published'),
      'active_categories', (select count(*) from public.game_categories where is_active),
      'drafts', (select count(*) from public.word_prompts where status = 'draft') + (select count(*) from public.question_prompts where status = 'draft')
    ),
    'recent', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'id', p.id, 'game_type', p.game_type, 'title', p.title,
        'category_name', p.category_name, 'status', p.status, 'updated_at', p.updated_at
      ) order by p.updated_at desc, p.game_type asc, p.id asc), '[]'::jsonb)
      from (select * from prompts order by updated_at desc, game_type asc, id asc limit 5) p
    ),
    'drafts', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'id', p.id, 'game_type', p.game_type, 'title', p.title,
        'category_name', p.category_name, 'status', p.status, 'updated_at', p.updated_at
      ) order by p.updated_at desc, p.game_type asc, p.id asc), '[]'::jsonb)
      from (select * from prompts where status = 'draft' order by updated_at desc, game_type asc, id asc limit 5) p
    ),
    'warnings', jsonb_build_object(
      'empty_categories', (
        select count(*) from public.game_categories c
        where (c.game_type = 'word' and not exists (select 1 from public.word_prompts w where w.category_id = c.id))
          or (c.game_type = 'question' and not exists (select 1 from public.question_prompts q where q.category_id = c.id))
      ),
      'duplicate_questions', (
        select count(*) from public.question_prompts q
        where lower(btrim(q.civilian_question, trim_chars)) = lower(btrim(q.imposter_question, trim_chars))
      ),
      'non_family_easy_prompts',
        (select count(*) from public.word_prompts where difficulty = 'easy' and not is_family_friendly)
        + (select count(*) from public.question_prompts where difficulty = 'easy' and not is_family_friendly)
    )
  ) into result;

  return result;
end;
$$;

revoke all on function public.admin_dashboard_summary() from public, anon;
grant execute on function public.admin_dashboard_summary() to authenticated;

notify pgrst, 'reload schema';
