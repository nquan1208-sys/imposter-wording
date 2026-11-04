begin;

alter table public.game_categories add column is_family_friendly boolean not null default false;

alter table public.game_categories add constraint family_word_categories_only check (not is_family_friendly or game_type = 'word');

drop function public.save_category(uuid,public.game_type,text,integer,boolean,text,text,text,public.content_status,timestamptz);

drop function public.save_word_prompt(uuid,uuid,public.difficulty_level,boolean,text,text,text,public.content_status,timestamptz);

drop function public.save_question_prompt(uuid,uuid,public.difficulty_level,boolean,text,text,text,public.content_status,timestamptz);

drop function public.admin_list_categories(text,text,public.game_type,boolean,text,integer);

drop function public.admin_list_word_prompts(text,text,uuid,public.difficulty_level,boolean,public.content_status,text,integer);

drop function public.admin_list_question_prompts(text,text,uuid,public.difficulty_level,boolean,public.content_status,text,integer);

create function public.save_category(
  p_id uuid, p_game_type public.game_type, p_slug text, p_sort_order integer, p_is_active boolean, p_is_family_friendly boolean,
  p_locale text, p_name text, p_description text, p_status public.content_status, p_expected_updated_at timestamptz
)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare original public.game_categories%rowtype;
begin
  perform private.require_content_admin();
  select * into original from public.game_categories where id = p_id for update;
  if found then
    if p_expected_updated_at is distinct from original.updated_at then
      raise exception 'Content changed; reload before saving' using errcode = 'PT409';
    end if;
    update public.game_categories set game_type = p_game_type, slug = p_slug,
      sort_order = p_sort_order, is_active = p_is_active, is_family_friendly = p_is_family_friendly where id = p_id;
  else
    if p_expected_updated_at is not null then raise exception 'Content not found' using errcode = 'P0002'; end if;
    insert into public.game_categories(id,game_type,slug,sort_order,is_active,is_family_friendly,created_by)
      values(p_id,p_game_type,p_slug,p_sort_order,p_is_active,p_is_family_friendly,auth.uid()) on conflict (id) do nothing;
    if not found then raise exception 'Content already exists; reload' using errcode = 'PT409'; end if;
  end if;
  insert into public.game_category_translations(category_id,locale,name,description,status,created_by)
    values(p_id,p_locale,p_name,p_description,p_status,auth.uid())
    on conflict (category_id,locale) do update set name = excluded.name, description = excluded.description, status = excluded.status;
  return jsonb_build_object('original', (select to_jsonb(c) from public.game_categories c where id = p_id),
    'translation', (select to_jsonb(t) from public.game_category_translations t where category_id = p_id and locale = p_locale));
end;
$$;

create function public.save_word_prompt(
  p_id uuid, p_category_id uuid, p_difficulty public.difficulty_level,
  p_image_path text, p_locale text, p_text text, p_status public.content_status, p_expected_updated_at timestamptz
)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare original public.word_prompts%rowtype; observed_category uuid;
begin
  perform private.require_content_admin();
  -- shortcut: sibling prompt edits serialize, use finer locks if admin contention is measured.
  select category_id into observed_category from public.word_prompts where id = p_id;
  perform id from public.game_categories where id in (observed_category, p_category_id) order by id for update;
  select * into original from public.word_prompts where id = p_id for update;
  if found then
    if p_expected_updated_at is distinct from original.updated_at or original.category_id is distinct from observed_category then
      raise exception 'Content changed; reload before saving' using errcode = 'PT409';
    end if;
    update public.word_prompts set category_id = p_category_id, difficulty = p_difficulty,
      image_path = p_image_path where id = p_id;
  else
    if p_expected_updated_at is not null then raise exception 'Content not found' using errcode = 'P0002'; end if;
    insert into public.word_prompts(id,category_id,difficulty,image_path,created_by)
      values(p_id,p_category_id,p_difficulty,p_image_path,auth.uid()) on conflict (id) do nothing;
    if not found then raise exception 'Content already exists; reload' using errcode = 'PT409'; end if;
  end if;
  insert into public.word_prompt_translations(prompt_id,locale,text,status,created_by)
    values(p_id,p_locale,p_text,p_status,auth.uid())
    on conflict (prompt_id,locale) do update set text = excluded.text, status = excluded.status;
  return jsonb_build_object('original', (select to_jsonb(w) from public.word_prompts w where id = p_id),
    'translation', (select to_jsonb(t) from public.word_prompt_translations t where prompt_id = p_id and locale = p_locale));
end;
$$;

create function public.save_question_prompt(
  p_id uuid, p_category_id uuid, p_difficulty public.difficulty_level,
  p_locale text, p_civilian_question text, p_imposter_question text, p_status public.content_status, p_expected_updated_at timestamptz
)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare original public.question_prompts%rowtype; observed_category uuid;
begin
  perform private.require_content_admin();
  select category_id into observed_category from public.question_prompts where id = p_id;
  perform id from public.game_categories where id in (observed_category, p_category_id) order by id for update;
  select * into original from public.question_prompts where id = p_id for update;
  if found then
    if p_expected_updated_at is distinct from original.updated_at or original.category_id is distinct from observed_category then
      raise exception 'Content changed; reload before saving' using errcode = 'PT409';
    end if;
    update public.question_prompts set category_id = p_category_id, difficulty = p_difficulty where id = p_id;
  else
    if p_expected_updated_at is not null then raise exception 'Content not found' using errcode = 'P0002'; end if;
    insert into public.question_prompts(id,category_id,difficulty,created_by)
      values(p_id,p_category_id,p_difficulty,auth.uid()) on conflict (id) do nothing;
    if not found then raise exception 'Content already exists; reload' using errcode = 'PT409'; end if;
  end if;
  insert into public.question_prompt_translations(prompt_id,locale,civilian_question,imposter_question,status,created_by)
    values(p_id,p_locale,p_civilian_question,p_imposter_question,p_status,auth.uid())
    on conflict (prompt_id,locale) do update set civilian_question = excluded.civilian_question,
      imposter_question = excluded.imposter_question, status = excluded.status;
  return jsonb_build_object('original', (select to_jsonb(q) from public.question_prompts q where id = p_id),
    'translation', (select to_jsonb(t) from public.question_prompt_translations t where prompt_id = p_id and locale = p_locale));
end;
$$;

create function public.admin_list_categories(
  p_locale text, p_search text, p_game_type public.game_type, p_is_active boolean, p_is_family_friendly boolean, p_sort text, p_page integer
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare result jsonb;
begin
  perform private.require_content_admin();
  if not exists(select 1 from public.content_languages where code = p_locale)
    or p_sort is null or p_sort not in ('name','sort_order','updated_at') or p_page is null or p_page < 1 then
    raise exception 'Invalid category filters' using errcode = '22023';
  end if;
  with filtered as (
    select c.*, t.name from public.game_categories c
    left join public.game_category_translations t on t.category_id = c.id and t.locale = p_locale
    where (p_game_type is null or c.game_type = p_game_type)
      and (p_is_active is null or c.is_active = p_is_active)
      and (p_is_family_friendly is null or c.is_family_friendly = p_is_family_friendly)
      and (coalesce(btrim(p_search),'') = '' or strpos(lower(c.slug),lower(btrim(p_search))) > 0
        or exists(select 1 from public.game_category_translations s where s.category_id = c.id
          and strpos(lower(s.name),lower(btrim(p_search))) > 0))
  ), ordered as (
    select f.*, row_number() over(order by
      case when p_sort = 'sort_order' then f.sort_order end,
      case when p_sort = 'updated_at' then f.updated_at end desc,
      f.name asc nulls last, f.id) as position from filtered f
  ), page as (
    select * from ordered order by position limit 20 offset ((p_page::bigint - 1) * 20)
  )
  select jsonb_build_object('total',(select count(*) from filtered),'rows',coalesce((select jsonb_agg(
    (to_jsonb(p) - 'position') || jsonb_build_object(
      'translations', (select coalesce(jsonb_agg(to_jsonb(t) order by t.locale),'[]') from public.game_category_translations t where t.category_id = p.id),
      'word_count', (select count(*) from public.word_prompts w where w.category_id = p.id),
      'question_count', (select count(*) from public.question_prompts q where q.category_id = p.id)
    ) order by position) from page p),'[]')) into result;
  return result;
end;
$$;

create function public.admin_list_word_prompts(
  p_locale text, p_search text, p_category_id uuid, p_difficulty public.difficulty_level,
  p_status public.content_status, p_sort text, p_page integer
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

create function public.admin_list_question_prompts(
  p_locale text, p_search text, p_category_id uuid, p_difficulty public.difficulty_level,
  p_status public.content_status, p_sort text, p_page integer
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

create or replace function public.admin_dashboard_summary(p_locale text default 'vi')
returns jsonb language plpgsql security definer set search_path = '' as $$
declare result jsonb;
begin
  perform private.require_content_admin();
  if p_locale is null or not exists (select 1 from public.content_languages where code = p_locale) then
    raise exception 'Unknown content language' using errcode = '22023';
  end if;
  with prompts as (
    select w.id, 'word'::text as game_type, t.text as title, c.name as category_name, t.status,
      greatest(w.updated_at, t.updated_at) as updated_at, t.locale, w.difficulty
    from public.word_prompts w join public.word_prompt_translations t on t.prompt_id = w.id and t.locale = p_locale
    left join public.game_category_translations c on c.category_id = w.category_id and c.locale = p_locale
    union all
    select q.id, 'question', t.civilian_question, c.name, t.status, greatest(q.updated_at,t.updated_at), t.locale, q.difficulty
    from public.question_prompts q join public.question_prompt_translations t on t.prompt_id = q.id and t.locale = p_locale
    left join public.game_category_translations c on c.category_id = q.category_id and c.locale = p_locale
  )
  select jsonb_build_object(
    'stats', jsonb_build_object(
      'published_word_prompts', (select count(*) from prompts where game_type = 'word' and status = 'published'),
      'published_question_prompts', (select count(*) from prompts where game_type = 'question' and status = 'published'),
      'active_categories', (select count(*) from public.game_categories c where c.is_active and exists (
        select 1 from public.game_category_translations t where t.category_id = c.id and t.locale = p_locale and t.status = 'published')),
      'drafts', (select count(*) from prompts where status = 'draft')),
    'recent', (select coalesce(jsonb_agg(to_jsonb(p) - 'difficulty' order by updated_at desc, game_type, id), '[]')
      from (select * from prompts order by updated_at desc, game_type, id limit 5) p),
    'drafts', (select coalesce(jsonb_agg(to_jsonb(p) - 'difficulty' order by updated_at desc, game_type, id), '[]')
      from (select * from prompts where status = 'draft' order by updated_at desc, game_type, id limit 5) p),
    'warnings', jsonb_build_object(
      'empty_categories', (select count(*) from public.game_categories c where exists (
          select 1 from public.game_category_translations t where t.category_id = c.id and t.locale = p_locale)
        and not exists (select 1 from public.word_prompts w join public.word_prompt_translations t on t.prompt_id = w.id
          where w.category_id = c.id and t.locale = p_locale)
        and not exists (select 1 from public.question_prompts q join public.question_prompt_translations t on t.prompt_id = q.id
          where q.category_id = c.id and t.locale = p_locale)),
      'duplicate_questions', (select count(*) from public.question_prompt_translations where locale = p_locale
        and lower(private.content_trim(civilian_question)) = lower(private.content_trim(imposter_question))))
  ) into result;
  return result;
end;
$$;

alter table public.word_prompts drop column is_family_friendly;

alter table public.question_prompts drop column is_family_friendly;

revoke all on function public.save_category(uuid,public.game_type,text,integer,boolean,boolean,text,text,text,public.content_status,timestamptz) from public, anon, authenticated;

grant execute on function public.save_category(uuid,public.game_type,text,integer,boolean,boolean,text,text,text,public.content_status,timestamptz) to authenticated;

revoke all on function public.save_word_prompt(uuid,uuid,public.difficulty_level,text,text,text,public.content_status,timestamptz) from public, anon, authenticated;

grant execute on function public.save_word_prompt(uuid,uuid,public.difficulty_level,text,text,text,public.content_status,timestamptz) to authenticated;

revoke all on function public.save_question_prompt(uuid,uuid,public.difficulty_level,text,text,text,public.content_status,timestamptz) from public, anon, authenticated;

grant execute on function public.save_question_prompt(uuid,uuid,public.difficulty_level,text,text,text,public.content_status,timestamptz) to authenticated;

revoke all on function public.admin_list_categories(text,text,public.game_type,boolean,boolean,text,integer) from public, anon, authenticated;

grant execute on function public.admin_list_categories(text,text,public.game_type,boolean,boolean,text,integer) to authenticated;

revoke all on function public.admin_list_word_prompts(text,text,uuid,public.difficulty_level,public.content_status,text,integer) from public, anon, authenticated;

grant execute on function public.admin_list_word_prompts(text,text,uuid,public.difficulty_level,public.content_status,text,integer) to authenticated;

revoke all on function public.admin_list_question_prompts(text,text,uuid,public.difficulty_level,public.content_status,text,integer) from public, anon, authenticated;

grant execute on function public.admin_list_question_prompts(text,text,uuid,public.difficulty_level,public.content_status,text,integer) to authenticated;

notify pgrst, 'reload schema';

commit;
