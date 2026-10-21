begin;

alter table public.question_prompts drop column imposter_hint;

-- Definer lookup validates categories even when their RLS hides inactive rows.
create function private.question_prompt_before_write()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  category public.game_categories%rowtype;
  -- Match JavaScript String.trim(), including non-breaking and Unicode spaces.
  trim_chars text := E' \t\n\r\f\013' || U&'\00A0\1680\2000\2001\2002\2003\2004\2005\2006\2007\2008\2009\200A\2028\2029\202F\205F\3000\FEFF';
begin
  new.civilian_question := btrim(new.civilian_question, trim_chars);
  new.imposter_question := btrim(new.imposter_question, trim_chars);
  new.locale := btrim(new.locale, trim_chars);
  if new.civilian_question is null or new.civilian_question = ''
    or new.imposter_question is null or new.imposter_question = ''
    or new.locale is null or new.locale = ''
    or lower(new.civilian_question) = lower(new.imposter_question) then
    raise exception 'Two distinct questions and locale are required' using errcode = '23514';
  end if;
  select * into category from public.game_categories where id = new.category_id for share;
  if not found or category.game_type <> 'question' or category.locale <> new.locale then
    raise exception 'Category must match question type and locale' using errcode = '23514';
  end if;
  if new.status = 'published' and not category.is_active then
    raise exception 'Publishing requires an active category' using errcode = '23514';
  end if;
  new.updated_at := clock_timestamp();
  return new;
end;
$$;
revoke all on function private.question_prompt_before_write() from public, anon, authenticated;
create trigger question_prompt_before_write before insert or update on public.question_prompts
for each row execute function private.question_prompt_before_write();

create function public.delete_question_prompt(p_id uuid, p_expected_updated_at timestamptz)
returns void language plpgsql security definer set search_path = '' as $$
declare prompt public.question_prompts%rowtype;
begin
  perform 1 from public.admin_users
  where user_id = auth.uid() and is_active and role = 'admin' for share;
  if not found then raise exception 'Bạn không có quyền quản trị.' using errcode = '42501'; end if;
  select * into prompt from public.question_prompts where id = p_id for update;
  if not found then raise exception 'Đề không còn tồn tại.' using errcode = 'P0002'; end if;
  if p_expected_updated_at is distinct from prompt.updated_at then
    raise exception 'Đề đã thay đổi. Hãy tải lại trước khi xác nhận.' using errcode = '40001';
  end if;
  delete from public.question_prompts where id = p_id;
end;
$$;
revoke all on function public.delete_question_prompt(uuid, timestamptz) from public, anon;
grant execute on function public.delete_question_prompt(uuid, timestamptz) to authenticated;
revoke delete on public.question_prompts from anon, authenticated;

notify pgrst, 'reload schema';
commit;
