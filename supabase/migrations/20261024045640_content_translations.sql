begin;

-- Keep the source and Storage inventory stable until reconciliation finishes.
lock table public.game_categories, public.word_prompts, public.question_prompts in access exclusive mode;
lock table storage.objects in share mode;
create temporary table ct_categories on commit drop as select * from public.game_categories;
create temporary table ct_words on commit drop as select * from public.word_prompts;
create temporary table ct_questions on commit drop as select * from public.question_prompts;
create temporary table ct_objects on commit drop as
  select to_jsonb(o) as row_data from storage.objects o where bucket_id = 'word-prompt-images';
create temporary table ct_slugs on commit drop as
  select id, game_type, slug as old_slug,
    case when row_number() over (partition by game_type, slug order by id) = 1
      then slug else slug || '-' || id::text end as new_slug
  from ct_categories;

create function private.content_trim(value text)
returns text language sql immutable parallel safe set search_path = '' as $$
  select btrim(value, E' \t\n\r\f\013' || U&'\00A0\1680\2000\2001\2002\2003\2004\2005\2006\2007\2008\2009\200A\2028\2029\202F\205F\3000\FEFF');
$$;
revoke all on function private.content_trim(text) from public, anon, authenticated;

do $$
begin
  if exists (
    select 1 from (
      select locale from ct_categories union select locale from ct_words union select locale from ct_questions
    ) l where locale is null or private.content_trim(locale) = '' or locale <> private.content_trim(locale)
  ) then raise exception 'Migration blocked: invalid or unreviewed locale'; end if;
  if exists (select 1 from ct_categories where private.content_trim(name) = '' or name is null
      or slug is null or slug !~ '^[a-z0-9]+(-[a-z0-9]+)*$' or sort_order < 0)
    or exists (select 1 from ct_words where text is null or private.content_trim(text) = '')
    or exists (select 1 from ct_questions where civilian_question is null or imposter_question is null
      or private.content_trim(civilian_question) = '' or private.content_trim(imposter_question) = ''
      or lower(private.content_trim(civilian_question)) = lower(private.content_trim(imposter_question)))
  then raise exception 'Migration blocked: invalid content'; end if;
  if exists (select 1 from ct_words w left join ct_categories c on c.id = w.category_id
      where c.id is null or c.game_type <> 'word' or c.locale is distinct from w.locale)
    or exists (select 1 from ct_questions q left join ct_categories c on c.id = q.category_id
      where c.id is null or c.game_type <> 'question' or c.locale is distinct from q.locale)
  then raise exception 'Migration blocked: invalid category link'; end if;
  if exists (select 1 from ct_words w where image_path is not null and (
      image_path !~ ('^' || id::text || '/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.(jpg|png|webp)$')
      or not exists (select 1 from storage.objects o where o.bucket_id = 'word-prompt-images' and o.name = w.image_path)))
  then raise exception 'Migration blocked: invalid or missing image'; end if;
  if exists (select 1 from ct_slugs group by game_type, new_slug having count(*) > 1)
  then raise exception 'Migration blocked: resulting_slug_collision'; end if;
end;
$$;

create table public.content_languages (
  code text primary key check (code <> '' and code = private.content_trim(code)),
  display_name text not null check (private.content_trim(display_name) <> ''),
  sort_order integer not null default 0 check (sort_order >= 0)
);
insert into public.content_languages values ('vi', 'Tiếng Việt', 0), ('en', 'English', 1);
insert into public.content_languages
  select locale, locale, 2 from (
    select locale from ct_categories union select locale from ct_words union select locale from ct_questions
  ) l where locale not in ('vi', 'en');

create table public.game_category_translations (
  category_id uuid not null references public.game_categories(id) on delete cascade,
  locale text not null references public.content_languages(code),
  name text not null check (private.content_trim(name) <> ''),
  description text,
  status public.content_status not null default 'draft',
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default clock_timestamp(),
  updated_at timestamptz not null default clock_timestamp(),
  primary key (category_id, locale)
);
create table public.word_prompt_translations (
  prompt_id uuid not null references public.word_prompts(id) on delete cascade,
  locale text not null references public.content_languages(code),
  text text not null check (private.content_trim(text) <> ''),
  status public.content_status not null default 'draft',
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default clock_timestamp(),
  updated_at timestamptz not null default clock_timestamp(),
  primary key (prompt_id, locale)
);
create table public.question_prompt_translations (
  prompt_id uuid not null references public.question_prompts(id) on delete cascade,
  locale text not null references public.content_languages(code),
  civilian_question text not null check (private.content_trim(civilian_question) <> ''),
  imposter_question text not null check (private.content_trim(imposter_question) <> ''),
  status public.content_status not null default 'draft',
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default clock_timestamp(),
  updated_at timestamptz not null default clock_timestamp(),
  primary key (prompt_id, locale),
  check (lower(private.content_trim(civilian_question)) <> lower(private.content_trim(imposter_question)))
);

insert into public.game_category_translations
  select id, locale, name, description, 'published', created_by, created_at, updated_at from ct_categories;
insert into public.word_prompt_translations
  select id, locale, text, status, created_by, created_at, updated_at from ct_words;
insert into public.question_prompt_translations
  select id, locale, civilian_question, imposter_question, status, created_by, created_at, updated_at from ct_questions;

drop trigger category_before_write on public.game_categories;
drop trigger word_prompt_before_write on public.word_prompts;
drop trigger question_prompt_before_write on public.question_prompts;
update public.game_categories c set slug = m.new_slug from ct_slugs m where c.id = m.id and c.slug <> m.new_slug;

-- Compare every legacy field, including metadata on both copies, before dropping columns.
do $$
declare changed_slugs jsonb;
begin
  if (select count(*) from ct_categories) <> (select count(*) from public.game_categories)
    or (select count(*) from ct_words) <> (select count(*) from public.word_prompts)
    or (select count(*) from ct_questions) <> (select count(*) from public.question_prompts)
    or (select count(*) from ct_categories) <> (select count(*) from public.game_category_translations)
    or (select count(*) from ct_words) <> (select count(*) from public.word_prompt_translations)
    or (select count(*) from ct_questions) <> (select count(*) from public.question_prompt_translations)
  then raise exception 'Migration reconciliation failed: counts'; end if;
  if exists (select 1 from ct_categories old full join public.game_categories c using (id)
    left join ct_slugs m on m.id = c.id
    left join public.game_category_translations t on t.category_id = c.id and t.locale = old.locale
    where to_jsonb(old) is distinct from (to_jsonb(c) || jsonb_build_object('slug', m.old_slug))
      or c.slug is distinct from m.new_slug or t.category_id is null
      or (to_jsonb(t) - 'category_id' - 'status') is distinct from
        (to_jsonb(old) - 'id' - 'game_type' - 'slug' - 'sort_order' - 'is_active') or t.status <> 'published')
    or exists (select 1 from ct_words old full join public.word_prompts w using (id)
      left join public.word_prompt_translations t on t.prompt_id = w.id and t.locale = old.locale
      where to_jsonb(old) is distinct from to_jsonb(w) or t.prompt_id is null
        or (to_jsonb(t) - 'prompt_id') is distinct from
          (to_jsonb(old) - 'id' - 'category_id' - 'difficulty' - 'is_family_friendly' - 'image_path'))
    or exists (select 1 from ct_questions old full join public.question_prompts q using (id)
      left join public.question_prompt_translations t on t.prompt_id = q.id and t.locale = old.locale
      where to_jsonb(old) is distinct from to_jsonb(q) or t.prompt_id is null
        or (to_jsonb(t) - 'prompt_id') is distinct from
          (to_jsonb(old) - 'id' - 'category_id' - 'difficulty' - 'is_family_friendly'))
  then raise exception 'Migration reconciliation failed: row identity, content or metadata'; end if;
  if exists (
    (select row_data from ct_objects except select to_jsonb(o) from storage.objects o where bucket_id = 'word-prompt-images')
    union all
    (select to_jsonb(o) from storage.objects o where bucket_id = 'word-prompt-images' except select row_data from ct_objects)
  ) then raise exception 'Migration reconciliation failed: Storage inventory'; end if;
  if exists (select locale from (
      select locale from ct_categories union select locale from ct_words union select locale from ct_questions
    ) l except select code from public.content_languages)
  then raise exception 'Migration reconciliation failed: languages'; end if;
  select coalesce(jsonb_agg(to_jsonb(m) order by id), '[]') into changed_slugs from ct_slugs m where old_slug <> new_slug;
  raise notice 'Content migration reconciled: categories=%, words=%, questions=%, slug_changes=%',
    (select count(*) from ct_categories), (select count(*) from ct_words), (select count(*) from ct_questions), changed_slugs;
end;
$$;

drop policy "Anonymous can read active categories" on public.game_categories;
drop policy "Authenticated users can read categories" on public.game_categories;
drop policy "Admins can create categories" on public.game_categories;
drop policy "Admins can update categories" on public.game_categories;
drop policy "Anonymous can read published word prompts" on public.word_prompts;
drop policy "Authenticated users can read word prompts" on public.word_prompts;
drop policy "Admins can create word prompts" on public.word_prompts;
drop policy "Admins can update word prompts" on public.word_prompts;
drop policy "Anonymous can read published question prompts" on public.question_prompts;
drop policy "Authenticated users can read question prompts" on public.question_prompts;
drop policy "Admins can create question prompts" on public.question_prompts;
drop policy "Admins can update question prompts" on public.question_prompts;
drop policy "Word image published read" on storage.objects;
drop index public.word_prompts_category_status_difficulty_idx;
drop index public.word_prompts_status_locale_idx;
drop index public.question_prompts_category_status_difficulty_idx;
drop index public.question_prompts_status_locale_idx;
alter table public.game_categories drop constraint game_categories_slug_locale_key;
alter table public.game_categories drop column name, drop column description, drop column locale,
  add constraint game_categories_game_type_slug_key unique (game_type, slug);
alter table public.word_prompts drop column text, drop column locale, drop column status;
alter table public.question_prompts drop column civilian_question, drop column imposter_question,
  drop column locale, drop column status;
create index word_prompts_category_difficulty_idx on public.word_prompts(category_id, difficulty);
create index question_prompts_category_difficulty_idx on public.question_prompts(category_id, difficulty);
create index game_category_translations_locale_status_idx on public.game_category_translations(locale, status);
create index word_prompt_translations_locale_status_idx on public.word_prompt_translations(locale, status);
create index question_prompt_translations_locale_status_idx on public.question_prompt_translations(locale, status);
create index game_category_translations_created_by_idx on public.game_category_translations(created_by);
create index word_prompt_translations_created_by_idx on public.word_prompt_translations(created_by);
create index question_prompt_translations_created_by_idx on public.question_prompt_translations(created_by);

-- Raw lookups avoid parent/translation RLS recursion; expose only eligibility booleans.
create function private.category_is_public(p_id uuid, p_locale text default null)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.game_categories c
    join public.game_category_translations t on t.category_id = c.id
    where c.id = p_id and c.is_active and t.status = 'published' and (p_locale is null or t.locale = p_locale));
$$;
create function private.word_is_public(p_id uuid, p_locale text default null)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.word_prompts w join public.word_prompt_translations t on t.prompt_id = w.id
    where w.id = p_id and t.status = 'published' and (p_locale is null or t.locale = p_locale)
      and private.category_is_public(w.category_id, t.locale));
$$;
create function private.question_is_public(p_id uuid, p_locale text default null)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.question_prompts q join public.question_prompt_translations t on t.prompt_id = q.id
    where q.id = p_id and t.status = 'published' and (p_locale is null or t.locale = p_locale)
      and private.category_is_public(q.category_id, t.locale));
$$;
revoke all on function private.category_is_public(uuid,text), private.word_is_public(uuid,text),
  private.question_is_public(uuid,text) from public, anon, authenticated;
grant execute on function private.category_is_public(uuid,text), private.word_is_public(uuid,text),
  private.question_is_public(uuid,text) to anon, authenticated;

alter table public.content_languages enable row level security;
alter table public.game_category_translations enable row level security;
alter table public.word_prompt_translations enable row level security;
alter table public.question_prompt_translations enable row level security;
revoke all on public.content_languages, public.game_categories, public.word_prompts, public.question_prompts,
  public.game_category_translations, public.word_prompt_translations, public.question_prompt_translations
  from public, anon, authenticated;
grant select on public.content_languages, public.game_categories, public.word_prompts, public.question_prompts,
  public.game_category_translations, public.word_prompt_translations, public.question_prompt_translations to anon, authenticated;
create policy "Content languages read" on public.content_languages for select to anon, authenticated using (true);
create policy "Public categories read" on public.game_categories for select to anon using (private.category_is_public(id));
create policy "Public words read" on public.word_prompts for select to anon using (private.word_is_public(id));
create policy "Public questions read" on public.question_prompts for select to anon using (private.question_is_public(id));
create policy "Public category translations read" on public.game_category_translations for select to anon
  using (status = 'published' and private.category_is_public(category_id, locale));
create policy "Public word translations read" on public.word_prompt_translations for select to anon
  using (status = 'published' and private.word_is_public(prompt_id, locale));
create policy "Public question translations read" on public.question_prompt_translations for select to anon
  using (status = 'published' and private.question_is_public(prompt_id, locale));
create policy "Authenticated categories read" on public.game_categories for select to authenticated
  using ((select private.is_admin()) or private.category_is_public(id));
create policy "Authenticated words read" on public.word_prompts for select to authenticated
  using ((select private.is_admin()) or private.word_is_public(id));
create policy "Authenticated questions read" on public.question_prompts for select to authenticated
  using ((select private.is_admin()) or private.question_is_public(id));
create policy "Authenticated category translations read" on public.game_category_translations for select to authenticated
  using ((select private.is_admin()) or (status = 'published' and private.category_is_public(category_id, locale)));
create policy "Authenticated word translations read" on public.word_prompt_translations for select to authenticated
  using ((select private.is_admin()) or (status = 'published' and private.word_is_public(prompt_id, locale)));
create policy "Authenticated question translations read" on public.question_prompt_translations for select to authenticated
  using ((select private.is_admin()) or (status = 'published' and private.question_is_public(prompt_id, locale)));
create policy "Word image published read" on storage.objects for select to anon, authenticated
  using (bucket_id = 'word-prompt-images' and exists (
    select 1 from public.word_prompts w where w.image_path = name and private.word_is_public(w.id)));

create function private.require_content_admin()
returns void language plpgsql security definer set search_path = '' as $$
begin
  perform 1 from public.admin_users where user_id = auth.uid() and is_active and role = 'admin' for share;
  if not found then raise exception 'Bạn không có quyền quản trị.' using errcode = '42501'; end if;
end;
$$;
revoke all on function private.require_content_admin() from public, anon, authenticated;

create or replace function private.category_before_write()
returns trigger language plpgsql set search_path = '' as $$
begin
  if tg_op = 'UPDATE' and new.game_type is distinct from old.game_type then
    raise exception 'Category game type is immutable' using errcode = '23514';
  end if;
  new.slug := private.content_trim(new.slug);
  if new.slug is null or new.slug !~ '^[a-z0-9]+(-[a-z0-9]+)*$' or new.sort_order < 0 then
    raise exception 'Invalid category slug or sort order' using errcode = '23514';
  end if;
  new.updated_at := case when tg_op = 'UPDATE' then greatest(clock_timestamp(), old.updated_at + interval '1 microsecond') else clock_timestamp() end;
  return new;
end;
$$;
create trigger category_before_write before insert or update on public.game_categories
  for each row execute function private.category_before_write();

create function private.prompt_before_write()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if tg_op = 'UPDATE' and new.category_id is distinct from old.category_id then
    if tg_table_name = 'word_prompts' then
      if exists (select 1 from public.word_prompt_translations t where t.prompt_id = new.id
        and t.status = 'published' and not private.category_is_public(new.category_id, t.locale)) then
        raise exception 'Destination category must publish every published prompt locale' using errcode = '23514';
      end if;
    else
      if exists (select 1 from public.question_prompt_translations t where t.prompt_id = new.id
        and t.status = 'published' and not private.category_is_public(new.category_id, t.locale)) then
        raise exception 'Destination category must publish every published prompt locale' using errcode = '23514';
      end if;
    end if;
  end if;
  if tg_table_name = 'word_prompts' then
    new.image_path := nullif(private.content_trim(new.image_path), '');
    if new.image_path is not null then
      if new.image_path !~ ('^' || new.id::text || '/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.(jpg|png|webp)$') then
        raise exception 'Image path must belong to this prompt' using errcode = '23514';
      end if;
      perform 1 from storage.objects where bucket_id = 'word-prompt-images' and name = new.image_path for share;
      if not found then raise exception 'Image does not exist' using errcode = '23514'; end if;
    end if;
  end if;
  new.updated_at := case when tg_op = 'UPDATE' then greatest(clock_timestamp(), old.updated_at + interval '1 microsecond') else clock_timestamp() end;
  return new;
end;
$$;
create trigger word_prompt_before_write before insert or update on public.word_prompts
  for each row execute function private.prompt_before_write();
create trigger question_prompt_before_write before insert or update on public.question_prompts
  for each row execute function private.prompt_before_write();
drop function private.word_prompt_before_write();
drop function private.question_prompt_before_write();

create function private.translation_before_write()
returns trigger language plpgsql security definer set search_path = '' as $$
declare category_id uuid;
begin
  if tg_op = 'UPDATE' then
    if new.locale is distinct from old.locale
      or (tg_table_name = 'game_category_translations' and to_jsonb(new)->>'category_id' is distinct from to_jsonb(old)->>'category_id')
      or (tg_table_name <> 'game_category_translations' and to_jsonb(new)->>'prompt_id' is distinct from to_jsonb(old)->>'prompt_id') then
      raise exception 'Translation identity is immutable' using errcode = '23514';
    end if;
    new.created_at := old.created_at;
    new.created_by := old.created_by;
  end if;
  if tg_table_name = 'game_category_translations' then
    new.name := private.content_trim(new.name);
    new.description := nullif(private.content_trim(new.description), '');
  elsif tg_table_name = 'word_prompt_translations' then
    new.text := private.content_trim(new.text);
    select w.category_id into category_id from public.word_prompts w where id = new.prompt_id;
  else
    new.civilian_question := private.content_trim(new.civilian_question);
    new.imposter_question := private.content_trim(new.imposter_question);
    select q.category_id into category_id from public.question_prompts q where id = new.prompt_id;
  end if;
  if tg_table_name <> 'game_category_translations' and new.status = 'published'
    and not private.category_is_public(category_id, new.locale) then
    raise exception 'Publishing requires an active category and published category translation' using errcode = '23514';
  end if;
  new.updated_at := case when tg_op = 'UPDATE' then greatest(clock_timestamp(), old.updated_at + interval '1 microsecond') else clock_timestamp() end;
  return new;
end;
$$;
create function private.translation_touch_original()
returns trigger language plpgsql security definer set search_path = '' as $$
declare row_data jsonb := case when tg_op = 'DELETE' then to_jsonb(old) else to_jsonb(new) end;
begin
  if tg_table_name = 'game_category_translations' then
    update public.game_categories set updated_at = clock_timestamp() where id = (row_data->>'category_id')::uuid;
  elsif tg_table_name = 'word_prompt_translations' then
    update public.word_prompts set updated_at = clock_timestamp() where id = (row_data->>'prompt_id')::uuid;
  else
    update public.question_prompts set updated_at = clock_timestamp() where id = (row_data->>'prompt_id')::uuid;
  end if;
  return null;
end;
$$;
create trigger category_translation_before_write before insert or update on public.game_category_translations
  for each row execute function private.translation_before_write();
create trigger word_translation_before_write before insert or update on public.word_prompt_translations
  for each row execute function private.translation_before_write();
create trigger question_translation_before_write before insert or update on public.question_prompt_translations
  for each row execute function private.translation_before_write();
create trigger category_translation_touch after insert or update or delete on public.game_category_translations
  for each row execute function private.translation_touch_original();
create trigger word_translation_touch after insert or update or delete on public.word_prompt_translations
  for each row execute function private.translation_touch_original();
create trigger question_translation_touch after insert or update or delete on public.question_prompt_translations
  for each row execute function private.translation_touch_original();
revoke all on function private.category_before_write(), private.prompt_before_write(),
  private.translation_before_write(), private.translation_touch_original(), private.validate_prompt_category_game_type()
  from public, anon, authenticated;

create function public.save_category(
  p_id uuid, p_game_type public.game_type, p_slug text, p_sort_order integer, p_is_active boolean,
  p_locale text, p_name text, p_description text, p_status public.content_status, p_expected_updated_at timestamptz
)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare original public.game_categories%rowtype;
begin
  perform private.require_content_admin();
  select * into original from public.game_categories where id = p_id for update;
  if found then
    if p_expected_updated_at is distinct from original.updated_at then
      raise exception 'Content changed; reload before saving' using errcode = '40001';
    end if;
    update public.game_categories set game_type = p_game_type, slug = p_slug,
      sort_order = p_sort_order, is_active = p_is_active where id = p_id;
  else
    if p_expected_updated_at is not null then raise exception 'Content not found' using errcode = 'P0002'; end if;
    insert into public.game_categories(id,game_type,slug,sort_order,is_active,created_by)
      values(p_id,p_game_type,p_slug,p_sort_order,p_is_active,auth.uid()) on conflict (id) do nothing;
    if not found then raise exception 'Content already exists; reload' using errcode = '40001'; end if;
  end if;
  insert into public.game_category_translations(category_id,locale,name,description,status,created_by)
    values(p_id,p_locale,p_name,p_description,p_status,auth.uid())
    on conflict (category_id,locale) do update set name = excluded.name, description = excluded.description, status = excluded.status;
  return jsonb_build_object('original', (select to_jsonb(c) from public.game_categories c where id = p_id),
    'translation', (select to_jsonb(t) from public.game_category_translations t where category_id = p_id and locale = p_locale));
end;
$$;

create function public.save_word_prompt(
  p_id uuid, p_category_id uuid, p_difficulty public.difficulty_level, p_is_family_friendly boolean,
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
      raise exception 'Content changed; reload before saving' using errcode = '40001';
    end if;
    update public.word_prompts set category_id = p_category_id, difficulty = p_difficulty,
      is_family_friendly = p_is_family_friendly, image_path = p_image_path where id = p_id;
  else
    if p_expected_updated_at is not null then raise exception 'Content not found' using errcode = 'P0002'; end if;
    insert into public.word_prompts(id,category_id,difficulty,is_family_friendly,image_path,created_by)
      values(p_id,p_category_id,p_difficulty,p_is_family_friendly,p_image_path,auth.uid()) on conflict (id) do nothing;
    if not found then raise exception 'Content already exists; reload' using errcode = '40001'; end if;
  end if;
  insert into public.word_prompt_translations(prompt_id,locale,text,status,created_by)
    values(p_id,p_locale,p_text,p_status,auth.uid())
    on conflict (prompt_id,locale) do update set text = excluded.text, status = excluded.status;
  return jsonb_build_object('original', (select to_jsonb(w) from public.word_prompts w where id = p_id),
    'translation', (select to_jsonb(t) from public.word_prompt_translations t where prompt_id = p_id and locale = p_locale));
end;
$$;

create function public.save_question_prompt(
  p_id uuid, p_category_id uuid, p_difficulty public.difficulty_level, p_is_family_friendly boolean,
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
      raise exception 'Content changed; reload before saving' using errcode = '40001';
    end if;
    update public.question_prompts set category_id = p_category_id, difficulty = p_difficulty,
      is_family_friendly = p_is_family_friendly where id = p_id;
  else
    if p_expected_updated_at is not null then raise exception 'Content not found' using errcode = 'P0002'; end if;
    insert into public.question_prompts(id,category_id,difficulty,is_family_friendly,created_by)
      values(p_id,p_category_id,p_difficulty,p_is_family_friendly,auth.uid()) on conflict (id) do nothing;
    if not found then raise exception 'Content already exists; reload' using errcode = '40001'; end if;
  end if;
  insert into public.question_prompt_translations(prompt_id,locale,civilian_question,imposter_question,status,created_by)
    values(p_id,p_locale,p_civilian_question,p_imposter_question,p_status,auth.uid())
    on conflict (prompt_id,locale) do update set civilian_question = excluded.civilian_question,
      imposter_question = excluded.imposter_question, status = excluded.status;
  return jsonb_build_object('original', (select to_jsonb(q) from public.question_prompts q where id = p_id),
    'translation', (select to_jsonb(t) from public.question_prompt_translations t where prompt_id = p_id and locale = p_locale));
end;
$$;

create or replace function public.delete_word_prompt(p_id uuid, p_expected_updated_at timestamptz)
returns void language plpgsql security definer set search_path = '' as $$
declare original public.word_prompts%rowtype; observed_category uuid;
begin
  perform private.require_content_admin();
  select category_id into observed_category from public.word_prompts where id = p_id;
  perform id from public.game_categories where id = observed_category for update;
  select * into original from public.word_prompts where id = p_id for update;
  if not found then raise exception 'Content not found' using errcode = 'P0002'; end if;
  if p_expected_updated_at is distinct from original.updated_at or original.category_id is distinct from observed_category then
    raise exception 'Content changed; reload before deleting' using errcode = '40001';
  end if;
  delete from public.word_prompts where id = p_id;
end;
$$;
create or replace function public.delete_question_prompt(p_id uuid, p_expected_updated_at timestamptz)
returns void language plpgsql security definer set search_path = '' as $$
declare original public.question_prompts%rowtype; observed_category uuid;
begin
  perform private.require_content_admin();
  select category_id into observed_category from public.question_prompts where id = p_id;
  perform id from public.game_categories where id = observed_category for update;
  select * into original from public.question_prompts where id = p_id for update;
  if not found then raise exception 'Content not found' using errcode = 'P0002'; end if;
  if p_expected_updated_at is distinct from original.updated_at or original.category_id is distinct from observed_category then
    raise exception 'Content changed; reload before deleting' using errcode = '40001';
  end if;
  delete from public.question_prompts where id = p_id;
end;
$$;

create or replace function private.category_content_snapshot(p_id uuid)
returns jsonb language sql stable set search_path = '' as $$
  with originals as (
    select 'word' as kind, id from public.word_prompts where category_id = p_id
    union all select 'question', id from public.question_prompts where category_id = p_id
  ), translations as (
    select t.status from public.word_prompt_translations t join public.word_prompts w on w.id = t.prompt_id where w.category_id = p_id
    union all
    select t.status from public.question_prompt_translations t join public.question_prompts q on q.id = t.prompt_id where q.category_id = p_id
  ), rows as (
    select 'category' as kind, to_jsonb(c)::text as data from public.game_categories c where id = p_id
    union all select 'category_translation', to_jsonb(t)::text from public.game_category_translations t where category_id = p_id
    union all select 'word', to_jsonb(w)::text from public.word_prompts w where category_id = p_id
    union all select 'question', to_jsonb(q)::text from public.question_prompts q where category_id = p_id
    union all select 'word_translation', to_jsonb(t)::text from public.word_prompt_translations t join public.word_prompts w on w.id = t.prompt_id where w.category_id = p_id
    union all select 'question_translation', to_jsonb(t)::text from public.question_prompt_translations t join public.question_prompts q on q.id = t.prompt_id where q.category_id = p_id
  )
  select jsonb_build_object(
    'counts', jsonb_build_object(
      'originals', (select jsonb_build_object('total', count(*), 'word', count(*) filter (where kind = 'word'), 'question', count(*) filter (where kind = 'question')) from originals),
      'translations', (select jsonb_build_object('draft', count(*) filter (where status = 'draft'), 'published', count(*) filter (where status = 'published'), 'archived', count(*) filter (where status = 'archived')) from translations)),
    'version', (select md5(coalesce(jsonb_agg(jsonb_build_array(kind, data) order by kind, data)::text, '[]')) from rows));
$$;

create or replace function public.preview_category_delete(p_id uuid)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare result jsonb;
begin
  perform private.require_content_admin();
  -- Saves and deletes take the same category lock before changing its children.
  perform id from public.game_categories where id = p_id for update;
  if not found then raise exception 'Category not found' using errcode = 'P0002'; end if;
  select jsonb_build_object('category', to_jsonb(c), 'category_translations', (
    select coalesce(jsonb_agg(to_jsonb(t) order by locale), '[]') from public.game_category_translations t where category_id = p_id))
    || private.category_content_snapshot(p_id) into result from public.game_categories c where id = p_id;
  return result;
end;
$$;

create or replace function public.delete_category(
  p_id uuid, p_mode text, p_target_id uuid default null, p_expected_version text default null
)
returns void language plpgsql security definer set search_path = '' as $$
declare source public.game_categories%rowtype; target public.game_categories%rowtype; snapshot jsonb;
begin
  perform private.require_content_admin();
  if p_mode is null or p_mode not in ('empty', 'transfer', 'purge') then
    raise exception 'Invalid delete mode' using errcode = '22023';
  end if;
  perform id from public.game_categories where id = p_id or (p_mode = 'transfer' and id = p_target_id) order by id for update;
  select * into source from public.game_categories where id = p_id;
  if not found then raise exception 'Category not found' using errcode = 'P0002'; end if;
  perform id from public.word_prompts where category_id = p_id order by id for update;
  perform id from public.question_prompts where category_id = p_id order by id for update;
  perform t.prompt_id from public.word_prompt_translations t join public.word_prompts w on w.id = t.prompt_id
    where w.category_id = p_id order by t.prompt_id, t.locale for update of t;
  perform t.prompt_id from public.question_prompt_translations t join public.question_prompts q on q.id = t.prompt_id
    where q.category_id = p_id order by t.prompt_id, t.locale for update of t;
  perform category_id from public.game_category_translations where category_id = p_id order by locale for update;
  snapshot := private.category_content_snapshot(p_id);
  if (p_mode <> 'empty' or p_expected_version is not null) and p_expected_version is distinct from snapshot->>'version' then
    raise exception 'Content changed; reload delete preview' using errcode = '40001';
  end if;
  if p_mode = 'empty' then
    if (snapshot#>>'{counts,originals,total}')::bigint <> 0 then
      raise exception 'Category contains prompts' using errcode = '23503';
    end if;
  elsif p_mode = 'transfer' then
    select * into target from public.game_categories where id = p_target_id;
    if not found or target.id = p_id or not target.is_active or target.game_type <> source.game_type then
      raise exception 'Destination must be active and have the same game type' using errcode = '23514';
    end if;
    if exists (select 1 from public.word_prompt_translations t join public.word_prompts w on w.id = t.prompt_id
        where w.category_id = p_id and t.status = 'published' and not private.category_is_public(p_target_id, t.locale))
      or exists (select 1 from public.question_prompt_translations t join public.question_prompts q on q.id = t.prompt_id
        where q.category_id = p_id and t.status = 'published' and not private.category_is_public(p_target_id, t.locale)) then
      raise exception 'Destination must publish every published prompt locale' using errcode = '23514';
    end if;
    update public.word_prompts set category_id = p_target_id where category_id = p_id;
    update public.question_prompts set category_id = p_target_id where category_id = p_id;
  else
    delete from public.word_prompts where category_id = p_id;
    delete from public.question_prompts where category_id = p_id;
  end if;
  delete from public.game_categories where id = p_id;
end;
$$;

drop function public.admin_dashboard_summary();
create function public.admin_dashboard_summary(p_locale text default 'vi')
returns jsonb language plpgsql security definer set search_path = '' as $$
declare result jsonb;
begin
  perform private.require_content_admin();
  if p_locale is null or not exists (select 1 from public.content_languages where code = p_locale) then
    raise exception 'Unknown content language' using errcode = '22023';
  end if;
  with prompts as (
    select w.id, 'word'::text as game_type, t.text as title, c.name as category_name, t.status,
      greatest(w.updated_at, t.updated_at) as updated_at, t.locale, w.difficulty, w.is_family_friendly
    from public.word_prompts w join public.word_prompt_translations t on t.prompt_id = w.id and t.locale = p_locale
    left join public.game_category_translations c on c.category_id = w.category_id and c.locale = p_locale
    union all
    select q.id, 'question', t.civilian_question, c.name, t.status, greatest(q.updated_at,t.updated_at), t.locale, q.difficulty, q.is_family_friendly
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
    'recent', (select coalesce(jsonb_agg(to_jsonb(p) - 'difficulty' - 'is_family_friendly' order by updated_at desc, game_type, id), '[]')
      from (select * from prompts order by updated_at desc, game_type, id limit 5) p),
    'drafts', (select coalesce(jsonb_agg(to_jsonb(p) - 'difficulty' - 'is_family_friendly' order by updated_at desc, game_type, id), '[]')
      from (select * from prompts where status = 'draft' order by updated_at desc, game_type, id limit 5) p),
    'warnings', jsonb_build_object(
      'empty_categories', (select count(*) from public.game_categories c where exists (
          select 1 from public.game_category_translations t where t.category_id = c.id and t.locale = p_locale)
        and not exists (select 1 from public.word_prompts w join public.word_prompt_translations t on t.prompt_id = w.id
          where w.category_id = c.id and t.locale = p_locale)
        and not exists (select 1 from public.question_prompts q join public.question_prompt_translations t on t.prompt_id = q.id
          where q.category_id = c.id and t.locale = p_locale)),
      'duplicate_questions', (select count(*) from public.question_prompt_translations where locale = p_locale
        and lower(private.content_trim(civilian_question)) = lower(private.content_trim(imposter_question))),
      'non_family_easy_prompts', (select count(*) from prompts where difficulty = 'easy' and not is_family_friendly))
  ) into result;
  return result;
end;
$$;

revoke all on function public.save_category(uuid,public.game_type,text,integer,boolean,text,text,text,public.content_status,timestamptz),
  public.save_word_prompt(uuid,uuid,public.difficulty_level,boolean,text,text,text,public.content_status,timestamptz),
  public.save_question_prompt(uuid,uuid,public.difficulty_level,boolean,text,text,text,public.content_status,timestamptz),
  public.delete_word_prompt(uuid,timestamptz), public.delete_question_prompt(uuid,timestamptz),
  public.preview_category_delete(uuid), public.delete_category(uuid,text,uuid,text), public.admin_dashboard_summary(text)
  from public, anon, authenticated;
grant execute on function public.save_category(uuid,public.game_type,text,integer,boolean,text,text,text,public.content_status,timestamptz),
  public.save_word_prompt(uuid,uuid,public.difficulty_level,boolean,text,text,text,public.content_status,timestamptz),
  public.save_question_prompt(uuid,uuid,public.difficulty_level,boolean,text,text,text,public.content_status,timestamptz),
  public.delete_word_prompt(uuid,timestamptz), public.delete_question_prompt(uuid,timestamptz),
  public.preview_category_delete(uuid), public.delete_category(uuid,text,uuid,text), public.admin_dashboard_summary(text)
  to authenticated;

notify pgrst, 'reload schema';
commit;
