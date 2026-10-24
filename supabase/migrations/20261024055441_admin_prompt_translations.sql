begin;

create function public.admin_list_word_prompts(
  p_locale text, p_search text, p_category_id uuid, p_difficulty public.difficulty_level,
  p_is_family_friendly boolean, p_status public.content_status, p_sort text, p_page integer
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare result jsonb;
begin
  perform private.require_content_admin();
  if not exists(select 1 from public.content_languages where code = p_locale)
    or p_sort is null or p_sort not in ('text','updated_at') or p_page is null or p_page < 1 then
    raise exception 'Invalid prompt filters' using errcode = '22023';
  end if;
  with filtered as (
    select p.*, t.text, t.status, p_locale as locale from public.word_prompts p
    left join public.word_prompt_translations t on t.prompt_id = p.id and t.locale = p_locale
    where (p_category_id is null or p.category_id = p_category_id)
      and (p_difficulty is null or p.difficulty = p_difficulty)
      and (p_is_family_friendly is null or p.is_family_friendly = p_is_family_friendly)
      and (p_status is null or t.status = p_status)
      and (coalesce(btrim(p_search),'') = '' or strpos(lower(t.text),lower(btrim(p_search))) > 0)
  ), ordered as (
    select f.*, row_number() over(order by
      case when p_sort = 'text' then f.text end asc nulls last,
      case when p_sort = 'updated_at' then f.updated_at end desc, f.id) as position from filtered f
  ), page as (
    select * from ordered order by position limit 20 offset ((p_page::bigint - 1) * 20)
  )
  select jsonb_build_object('total',(select count(*) from filtered),'rows',coalesce((select jsonb_agg(
    (to_jsonb(p) - 'position') || jsonb_build_object(
      'translations', (select coalesce(jsonb_agg(to_jsonb(t) order by t.locale),'[]') from public.word_prompt_translations t where t.prompt_id = p.id),
      'game_categories', (select to_jsonb(c) || jsonb_build_object('name',t.name,'locale',p_locale)
        from public.game_categories c left join public.game_category_translations t on t.category_id = c.id and t.locale = p_locale
        where c.id = p.category_id)
    ) order by position) from page p),'[]')) into result;
  return result;
end;
$$;
revoke all on function public.admin_list_word_prompts(text,text,uuid,public.difficulty_level,boolean,public.content_status,text,integer) from public,anon,authenticated;
grant execute on function public.admin_list_word_prompts(text,text,uuid,public.difficulty_level,boolean,public.content_status,text,integer) to authenticated;

create function public.admin_list_question_prompts(
  p_locale text, p_search text, p_category_id uuid, p_difficulty public.difficulty_level,
  p_is_family_friendly boolean, p_status public.content_status, p_sort text, p_page integer
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare result jsonb;
begin
  perform private.require_content_admin();
  if not exists(select 1 from public.content_languages where code = p_locale)
    or p_sort is null or p_sort not in ('civilian_question','updated_at') or p_page is null or p_page < 1 then
    raise exception 'Invalid prompt filters' using errcode = '22023';
  end if;
  with filtered as (
    select p.*, t.civilian_question, t.imposter_question, t.status, p_locale as locale from public.question_prompts p
    left join public.question_prompt_translations t on t.prompt_id = p.id and t.locale = p_locale
    where (p_category_id is null or p.category_id = p_category_id)
      and (p_difficulty is null or p.difficulty = p_difficulty)
      and (p_is_family_friendly is null or p.is_family_friendly = p_is_family_friendly)
      and (p_status is null or t.status = p_status)
      and (coalesce(btrim(p_search),'') = '' or strpos(lower(t.civilian_question),lower(btrim(p_search))) > 0 or strpos(lower(t.imposter_question),lower(btrim(p_search))) > 0)
  ), ordered as (
    select f.*, row_number() over(order by
      case when p_sort = 'civilian_question' then f.civilian_question end asc nulls last,
      case when p_sort = 'updated_at' then f.updated_at end desc, f.id) as position from filtered f
  ), page as (
    select * from ordered order by position limit 20 offset ((p_page::bigint - 1) * 20)
  )
  select jsonb_build_object('total',(select count(*) from filtered),'rows',coalesce((select jsonb_agg(
    (to_jsonb(p) - 'position') || jsonb_build_object(
      'translations', (select coalesce(jsonb_agg(to_jsonb(t) order by t.locale),'[]') from public.question_prompt_translations t where t.prompt_id = p.id),
      'game_categories', (select to_jsonb(c) || jsonb_build_object('name',t.name,'locale',p_locale)
        from public.game_categories c left join public.game_category_translations t on t.category_id = c.id and t.locale = p_locale
        where c.id = p.category_id)
    ) order by position) from page p),'[]')) into result;
  return result;
end;
$$;
revoke all on function public.admin_list_question_prompts(text,text,uuid,public.difficulty_level,boolean,public.content_status,text,integer) from public,anon,authenticated;
grant execute on function public.admin_list_question_prompts(text,text,uuid,public.difficulty_level,boolean,public.content_status,text,integer) to authenticated;

commit;
