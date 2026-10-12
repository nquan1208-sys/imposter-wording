revoke delete on public.game_categories, public.word_prompts, public.question_prompts from anon, authenticated;

-- Keep timestamps and category identity consistent for all API callers.
create or replace function private.category_before_write()
returns trigger language plpgsql set search_path = '' as $$
begin
  if tg_op = 'UPDATE' and (new.game_type is distinct from old.game_type or new.locale is distinct from old.locale) then
    raise exception 'Không thể đổi loại trò chơi hoặc ngôn ngữ của danh mục.' using errcode = '23514';
  end if;
  new.name := btrim(new.name);
  new.slug := btrim(new.slug);
  new.description := nullif(btrim(new.description), '');
  if new.name = '' or new.slug !~ '^[a-z0-9]+(-[a-z0-9]+)*$' or new.sort_order < 0 then
    raise exception 'Tên, slug hoặc thứ tự danh mục không hợp lệ.' using errcode = '23514';
  end if;
  new.updated_at := now();
  return new;
end;
$$;
create trigger category_before_write before insert or update on public.game_categories
for each row execute function private.category_before_write();

create or replace function private.category_content_snapshot(p_id uuid)
returns jsonb language sql stable set search_path = '' as $$
  select jsonb_build_object(
    'counts', jsonb_build_object(
      'draft', count(*) filter (where status = 'draft'),
      'published', count(*) filter (where status = 'published'),
      'archived', count(*) filter (where status = 'archived')),
    'version', md5(coalesce(string_agg(kind || row_data, ',' order by kind, id), '')))
  from (
    select 'word' as kind, id, status, to_jsonb(w)::text as row_data from public.word_prompts w where category_id = p_id
    union all
    select 'question', id, status, to_jsonb(q)::text from public.question_prompts q where category_id = p_id
  ) content;
$$;
revoke all on function private.category_content_snapshot(uuid) from public;

create or replace function public.preview_category_delete(p_id uuid)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare result jsonb;
begin
  if not private.is_admin() then
    raise exception 'Bạn không có quyền quản trị.' using errcode = '42501';
  end if;
  select jsonb_build_object('category', to_jsonb(c)) || private.category_content_snapshot(c.id)
  into result from public.game_categories c where c.id = p_id;
  if result is null then raise exception 'Danh mục không còn tồn tại.' using errcode = 'P0002'; end if;
  return result;
end;
$$;
revoke all on function public.preview_category_delete(uuid) from public, anon;
grant execute on function public.preview_category_delete(uuid) to authenticated;

create or replace function public.delete_category(
  p_id uuid, p_mode text, p_target_id uuid default null,
  p_confirmation text default null, p_expected_version text default null
)
returns void language plpgsql security definer set search_path = '' as $$
declare
  source public.game_categories%rowtype;
  target public.game_categories%rowtype;
  snapshot jsonb;
begin
  -- Hold the admin grant until the transaction finishes.
  perform 1 from public.admin_users where user_id = auth.uid() and is_active and role = 'admin' for share;
  if not found then raise exception 'Bạn không có quyền quản trị.' using errcode = '42501'; end if;
  if p_mode is null or p_mode not in ('empty', 'transfer', 'purge') then
    raise exception 'Thao tác xóa không hợp lệ.' using errcode = '22023';
  end if;
  perform id from public.game_categories
  where id = p_id or (p_mode = 'transfer' and id = p_target_id) order by id for update;
  select * into source from public.game_categories where id = p_id;
  if not found then raise exception 'Danh mục không còn tồn tại.' using errcode = 'P0002'; end if;
  -- Parent locks block new FK references; row locks stabilize the confirmation snapshot.
  perform id from public.word_prompts where category_id = p_id order by id for update;
  perform id from public.question_prompts where category_id = p_id order by id for update;
  snapshot := private.category_content_snapshot(p_id);
  if p_mode = 'empty' then
    if exists(select 1 from public.word_prompts where category_id = p_id)
      or exists(select 1 from public.question_prompts where category_id = p_id) then
      raise exception 'Danh mục đã có content. Hãy chuyển content hoặc chọn xóa toàn bộ.' using errcode = '23503';
    end if;
  elsif p_mode = 'transfer' then
    select * into target from public.game_categories where id = p_target_id;
    if not found or p_target_id = p_id or not target.is_active
      or target.game_type <> source.game_type or target.locale <> source.locale then
      raise exception 'Danh mục nhận phải đang hoạt động, cùng loại và ngôn ngữ.' using errcode = '23514';
    end if;
    update public.word_prompts set category_id = p_target_id, updated_at = now() where category_id = p_id;
    update public.question_prompts set category_id = p_target_id, updated_at = now() where category_id = p_id;
  else
    if p_confirmation is distinct from source.name then
      raise exception 'Tên xác nhận chưa đúng.' using errcode = '22023';
    end if;
    if p_expected_version is distinct from (snapshot ->> 'version') then
      raise exception 'Content đã thay đổi. Hãy tải lại thống kê và xác nhận lại.' using errcode = '40001';
    end if;
    -- Storage assets are retained until the content upload lifecycle is implemented.
    delete from public.word_prompts where category_id = p_id;
    delete from public.question_prompts where category_id = p_id;
  end if;
  delete from public.game_categories where id = p_id;
end;
$$;
revoke all on function public.delete_category(uuid, text, uuid, text, text) from public, anon;
grant execute on function public.delete_category(uuid, text, uuid, text, text) to authenticated;
