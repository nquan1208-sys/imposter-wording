begin;

create function public.admin_list_categories(
  p_locale text, p_search text, p_game_type public.game_type, p_is_active boolean, p_sort text, p_page integer
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

create function public.set_category_active(p_id uuid, p_is_active boolean, p_expected_updated_at timestamptz)
returns public.game_categories language plpgsql security definer set search_path = '' as $$
declare original public.game_categories%rowtype;
begin
  perform private.require_content_admin();
  select * into original from public.game_categories where id = p_id for update;
  if not found then raise exception 'Category not found' using errcode = 'P0002'; end if;
  if p_expected_updated_at is distinct from original.updated_at then
    raise exception 'Content changed; reload before saving' using errcode = '40001';
  end if;
  update public.game_categories set is_active = p_is_active where id = p_id returning * into original;
  return original;
end;
$$;

create function public.admin_category_transfer_targets(p_source_id uuid, p_locale text)
returns table(id uuid, slug text, name text)
language plpgsql security definer set search_path = '' as $$
declare source public.game_categories%rowtype;
begin
  perform private.require_content_admin();
  select * into source from public.game_categories where game_categories.id = p_source_id;
  if not found then raise exception 'Category not found' using errcode = 'P0002'; end if;
  if not exists(select 1 from public.content_languages where code = p_locale) then
    raise exception 'Invalid locale' using errcode = '22023';
  end if;
  return query select c.id,c.slug,t.name from public.game_categories c
    left join public.game_category_translations t on t.category_id = c.id and t.locale = p_locale
    where c.id <> source.id and c.is_active and c.game_type = source.game_type
      and not exists(select 1 from public.word_prompt_translations w
        join public.word_prompts p on p.id = w.prompt_id where p.category_id = source.id
        and w.status = 'published' and not private.category_is_public(c.id,w.locale))
      and not exists(select 1 from public.question_prompt_translations q
        join public.question_prompts p on p.id = q.prompt_id where p.category_id = source.id
        and q.status = 'published' and not private.category_is_public(c.id,q.locale))
    order by t.name nulls last,c.id;
end;
$$;

revoke all on function public.admin_list_categories(text,text,public.game_type,boolean,text,integer),
  public.set_category_active(uuid,boolean,timestamptz),public.admin_category_transfer_targets(uuid,text) from public,anon,authenticated;
grant execute on function public.admin_list_categories(text,text,public.game_type,boolean,text,integer),
  public.set_category_active(uuid,boolean,timestamptz),public.admin_category_transfer_targets(uuid,text) to authenticated;

commit;
