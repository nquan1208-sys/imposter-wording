create schema if not exists private;

create or replace function private.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.admin_users
    where user_id = (select auth.uid())
      and role = 'admin'::public.admin_role
      and is_active = true
  );
$$;

revoke all on function private.is_admin() from public;
grant execute on function private.is_admin() to authenticated;

alter table public.admin_users enable row level security;
alter table public.game_categories enable row level security;
alter table public.word_prompts enable row level security;
alter table public.question_prompts enable row level security;

grant select on public.admin_users to authenticated;
grant select on public.game_categories to anon, authenticated;
grant insert, update on public.game_categories to authenticated;
grant select on public.word_prompts to anon, authenticated;
grant insert, update on public.word_prompts to authenticated;
grant select on public.question_prompts to anon, authenticated;
grant insert, update on public.question_prompts to authenticated;

create policy "Admins can read admin users"
on public.admin_users
for select
to authenticated
using ((select private.is_admin()));

create policy "Anonymous can read active categories"
on public.game_categories
for select
to anon
using (is_active = true);

create policy "Authenticated users can read categories"
on public.game_categories
for select
to authenticated
using (is_active = true or (select private.is_admin()));

create policy "Admins can create categories"
on public.game_categories
for insert
to authenticated
with check ((select private.is_admin()));

create policy "Admins can update categories"
on public.game_categories
for update
to authenticated
using ((select private.is_admin()))
with check ((select private.is_admin()));

create policy "Anonymous can read published word prompts"
on public.word_prompts
for select
to anon
using (status = 'published'::public.content_status);

create policy "Authenticated users can read word prompts"
on public.word_prompts
for select
to authenticated
using (status = 'published'::public.content_status or (select private.is_admin()));

create policy "Admins can create word prompts"
on public.word_prompts
for insert
to authenticated
with check ((select private.is_admin()));

create policy "Admins can update word prompts"
on public.word_prompts
for update
to authenticated
using ((select private.is_admin()))
with check ((select private.is_admin()));

create policy "Anonymous can read published question prompts"
on public.question_prompts
for select
to anon
using (status = 'published'::public.content_status);

create policy "Authenticated users can read question prompts"
on public.question_prompts
for select
to authenticated
using (status = 'published'::public.content_status or (select private.is_admin()));

create policy "Admins can create question prompts"
on public.question_prompts
for insert
to authenticated
with check ((select private.is_admin()));

create policy "Admins can update question prompts"
on public.question_prompts
for update
to authenticated
using ((select private.is_admin()))
with check ((select private.is_admin()));
