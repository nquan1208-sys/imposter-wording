insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('word-prompt-images', 'word-prompt-images', false, 5242880, array['image/jpeg','image/png','image/webp'])
on conflict (id) do update set public = false, file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create policy "Word image admin read" on storage.objects for select to authenticated
using (bucket_id = 'word-prompt-images' and (select private.is_admin()));
create policy "Word image admin upload" on storage.objects for insert to authenticated
with check (bucket_id = 'word-prompt-images' and (select private.is_admin())
  and name ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.(jpg|png|webp)$');
create policy "Word image admin cleanup" on storage.objects for delete to authenticated
using (bucket_id = 'word-prompt-images' and (select private.is_admin())
  and not exists (select 1 from public.word_prompts w where w.image_path = name));
create policy "Word image published read" on storage.objects for select to anon, authenticated
using (bucket_id = 'word-prompt-images' and exists (
  select 1 from public.word_prompts w where w.image_path = name and w.status = 'published'));

-- Definer lookup avoids Storage RLS hiding objects or recursing through word_prompts.
create function private.word_prompt_before_write()
returns trigger language plpgsql security definer set search_path = '' as $$
declare category public.game_categories%rowtype;
begin
  new.civilian_text := btrim(new.civilian_text);
  new.imposter_text := nullif(btrim(new.imposter_text), '');
  new.imposter_hint := nullif(btrim(new.imposter_hint), '');
  new.image_path := nullif(btrim(new.image_path), '');
  new.locale := btrim(new.locale);
  if new.civilian_text = '' or new.locale = '' then
    raise exception 'Civilian text and locale are required' using errcode = '23514';
  end if;
  select * into category from public.game_categories where id = new.category_id for share;
  if not found or category.game_type <> 'word' or category.locale <> new.locale then
    raise exception 'Category must match word type and locale' using errcode = '23514';
  end if;
  if new.status = 'published' and not category.is_active then
    raise exception 'Publishing requires an active category' using errcode = '23514';
  end if;
  if new.image_path is not null then
    if new.image_path !~ ('^' || new.id::text || '/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.(jpg|png|webp)$') then
      raise exception 'Image path must belong to this prompt' using errcode = '23514';
    end if;
    perform 1 from storage.objects where bucket_id = 'word-prompt-images' and name = new.image_path for share;
    if not found then raise exception 'Image does not exist' using errcode = '23514'; end if;
  end if;
  new.updated_at := clock_timestamp();
  return new;
end;
$$;
revoke all on function private.word_prompt_before_write() from public, anon, authenticated;
create trigger word_prompt_before_write before insert or update on public.word_prompts
for each row execute function private.word_prompt_before_write();
create index word_prompts_image_path_idx on public.word_prompts (image_path) where image_path is not null;
