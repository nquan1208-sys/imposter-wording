begin;

-- Confirmation belongs to the UI; remove the old RPC signatures entirely.
drop function public.delete_word_prompt(uuid, timestamptz, text);
drop function public.delete_category(uuid, text, uuid, text, text);

create function public.delete_word_prompt(
  p_id uuid, p_expected_updated_at timestamptz
)
returns void language plpgsql security definer set search_path = '' as $$
declare prompt public.word_prompts%rowtype;
begin
  -- Keep the admin grant valid for the whole deletion transaction.
  perform 1 from public.admin_users
  where user_id = auth.uid() and is_active and role = 'admin' for share;
  if not found then raise exception 'Bạn không có quyền quản trị.' using errcode = '42501'; end if;
  select * into prompt from public.word_prompts where id = p_id for update;
  if not found then raise exception 'Đề không còn tồn tại.' using errcode = 'P0002'; end if;
  if p_expected_updated_at is distinct from prompt.updated_at then
    raise exception 'Đề đã thay đổi. Hãy tải lại trước khi xác nhận.' using errcode = '40001';
  end if;
  -- Retain all Storage files, including the current image.
  delete from public.word_prompts where id = p_id;
end;
$$;
revoke all on function public.delete_word_prompt(uuid, timestamptz) from public, anon;
grant execute on function public.delete_word_prompt(uuid, timestamptz) to authenticated;

create function public.delete_category(
  p_id uuid, p_mode text, p_target_id uuid default null,
  p_expected_version text default null
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
revoke all on function public.delete_category(uuid, text, uuid, text) from public, anon;
grant execute on function public.delete_category(uuid, text, uuid, text) to authenticated;

notify pgrst, 'reload schema';

commit;
