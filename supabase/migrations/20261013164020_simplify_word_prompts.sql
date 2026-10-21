begin;

create or replace function private.word_prompt_before_write()
returns trigger language plpgsql security definer set search_path = '' as $$
declare category public.game_categories%rowtype;
begin
  new.civilian_text := btrim(new.civilian_text);
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

alter table public.word_prompts
  drop column imposter_text,
  drop column imposter_hint;

commit;
