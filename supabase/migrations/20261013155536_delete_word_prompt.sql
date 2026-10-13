revoke delete on public.word_prompts from public, anon, authenticated;

create function public.delete_word_prompt(
  p_id uuid, p_expected_updated_at timestamptz, p_confirmation text
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
  if p_confirmation is distinct from 'XÓA' then
    raise exception 'Nhập chính xác XÓA để xác nhận.' using errcode = '22023';
  end if;
  if p_expected_updated_at is distinct from prompt.updated_at then
    raise exception 'Đề đã thay đổi. Hãy tải lại trước khi xác nhận.' using errcode = '40001';
  end if;
  -- Retain all Storage files, including the current image.
  delete from public.word_prompts where id = p_id;
end;
$$;
revoke all on function public.delete_word_prompt(uuid, timestamptz, text) from public, anon;
grant execute on function public.delete_word_prompt(uuid, timestamptz, text) to authenticated;
