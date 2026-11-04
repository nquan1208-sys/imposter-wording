create schema if not exists private;

create type public.game_type as enum ('word', 'question');
create type public.content_status as enum ('draft', 'published', 'archived');
create type public.difficulty_level as enum ('easy', 'medium', 'hard');
create type public.admin_role as enum ('admin');

create table public.admin_users (
  user_id uuid primary key references auth.users (id) on delete cascade,
  role public.admin_role not null default 'admin',
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.game_categories (
  id uuid primary key default gen_random_uuid(),
  game_type public.game_type not null,
  slug text not null,
  name text not null,
  description text,
  locale text not null default 'vi',
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint game_categories_slug_locale_key unique (game_type, slug, locale)
);

create table public.word_prompts (
  id uuid primary key default gen_random_uuid(),
  category_id uuid not null references public.game_categories (id),
  civilian_text text not null,
  imposter_text text,
  imposter_hint text,
  image_path text,
  difficulty public.difficulty_level not null default 'medium',
  is_family_friendly boolean not null default false,
  status public.content_status not null default 'draft',
  locale text not null default 'vi',
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.question_prompts (
  id uuid primary key default gen_random_uuid(),
  category_id uuid not null references public.game_categories (id),
  civilian_question text not null,
  imposter_question text not null,
  imposter_hint text,
  difficulty public.difficulty_level not null default 'medium',
  is_family_friendly boolean not null default false,
  status public.content_status not null default 'draft',
  locale text not null default 'vi',
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index game_categories_active_sort_order_idx
  on public.game_categories (game_type, is_active, sort_order);

create index game_categories_created_by_idx
  on public.game_categories (created_by);

create index word_prompts_category_status_difficulty_idx
  on public.word_prompts (category_id, status, difficulty);

create index word_prompts_status_locale_idx
  on public.word_prompts (status, locale);

create index word_prompts_created_by_idx
  on public.word_prompts (created_by);

create index question_prompts_category_status_difficulty_idx
  on public.question_prompts (category_id, status, difficulty);

create index question_prompts_status_locale_idx
  on public.question_prompts (status, locale);

create index question_prompts_created_by_idx
  on public.question_prompts (created_by);

create or replace function private.validate_prompt_category_game_type()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  expected_game_type public.game_type;
begin
  expected_game_type := case tg_table_name
    when 'word_prompts' then 'word'::public.game_type
    when 'question_prompts' then 'question'::public.game_type
  end;

  if not exists (
    select 1
    from public.game_categories
    where id = new.category_id
      and game_type = expected_game_type
  ) then
    raise exception 'Category % does not match % game type', new.category_id, expected_game_type
      using errcode = '23514';
  end if;

  return new;
end;
$$;

create trigger validate_word_prompt_category_game_type
before insert or update of category_id on public.word_prompts
for each row execute function private.validate_prompt_category_game_type();

create trigger validate_question_prompt_category_game_type
before insert or update of category_id on public.question_prompts
for each row execute function private.validate_prompt_category_game_type();
