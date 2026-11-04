-- Run as postgres (not through RLS). psql -X -qAt -v ON_ERROR_STOP=1 -f this_file
-- Two JSON lines: data/mapping first, live database dependencies second.
begin transaction isolation level repeatable read read only;

with
categories as (select * from public.game_categories),
words as (select * from public.word_prompts),
questions as (select * from public.question_prompts),
objects as (select name from storage.objects where bucket_id = 'word-prompt-images'),
trim_chars as (
  select E' \t\n\r\f\013' || U&'\00A0\1680\2000\2001\2002\2003\2004\2005\2006\2007\2008\2009\200A\2028\2029\202F\205F\3000\FEFF' as chars
),
slug_mapping as (
  select id, game_type, slug as old_slug,
    case when row_number() over (partition by game_type, slug order by id) = 1
      then slug else slug || '-' || id::text end as new_slug
  from categories
),
source_rows as (
  select 'category' as kind, c.id, c.locale, 'published'::text as status,
    c.id as category_id, to_jsonb(c) as row_data from categories c
  union all
  select 'word', w.id, w.locale, w.status::text, w.category_id, to_jsonb(w) from words w
  union all
  select 'question', q.id, q.locale, q.status::text, q.category_id, to_jsonb(q) from questions q
),
issues as (
  select 'invalid_locale' as issue, kind, id, jsonb_build_object('locale', locale) as detail
  from source_rows cross join trim_chars where locale is null or btrim(locale, chars) = ''
  union all
  select 'locale_needs_review', kind, id, jsonb_build_object('locale', locale)
  from source_rows cross join trim_chars where locale <> btrim(locale, chars)
  union all
  select 'invalid_category', 'category', id, '{}'::jsonb
  from categories cross join trim_chars
  where name is null or btrim(name, chars) = '' or slug is null
    or slug !~ '^[a-z0-9]+(-[a-z0-9]+)*$' or sort_order < 0
  union all
  select 'invalid_word', 'word', id, '{}'::jsonb
  from words cross join trim_chars where text is null or btrim(text, chars) = ''
  union all
  select 'invalid_questions', 'question', id, '{}'::jsonb
  from questions cross join trim_chars
  where civilian_question is null or imposter_question is null
    or btrim(civilian_question, chars) = '' or btrim(imposter_question, chars) = ''
    or lower(btrim(civilian_question, chars)) = lower(btrim(imposter_question, chars))
  union all
  select 'category_link_mismatch', r.kind, r.id,
    jsonb_build_object('category_id', r.category_id, 'locale', r.locale)
  from source_rows r left join categories c on c.id = r.category_id
  where r.kind <> 'category' and (c.id is null or c.game_type::text <> r.kind or c.locale is distinct from r.locale)
  union all
  select 'missing_image', 'word', w.id, jsonb_build_object('image_path', w.image_path)
  from words w where w.image_path is not null and not exists(select 1 from objects o where o.name = w.image_path)
  union all
  select 'invalid_image_path', 'word', id, jsonb_build_object('image_path', image_path)
  from words where image_path is not null and image_path !~
    ('^' || id::text || '/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.(jpg|png|webp)$')
  union all
  select 'resulting_slug_collision', 'category', m.id,
    jsonb_build_object('game_type', m.game_type, 'slug', m.new_slug)
  from slug_mapping m where exists (
    select 1 from slug_mapping other where other.game_type = m.game_type
      and other.new_slug = m.new_slug and other.id <> m.id
  )
)
select jsonb_build_object(
  'database', current_database(),
  'role', current_user,
  'read_only', current_setting('transaction_read_only'),
  'isolation', current_setting('transaction_isolation'),
  'rls_bypassed', (select rolsuper or rolbypassrls from pg_roles where rolname = current_user),
  'migrations', (select coalesce(jsonb_agg(version order by version), '[]') from supabase_migrations.schema_migrations),
  'counts', (select jsonb_object_agg(kind, jsonb_build_object(
    'source', n, 'expected_originals', n, 'expected_translations', n))
    from (select k.kind, count(r.id) as n from (values ('category'), ('word'), ('question')) k(kind)
      left join source_rows r using (kind) group by k.kind) totals),
  'groups', (select coalesce(jsonb_agg(to_jsonb(g) order by kind, locale, status, category_id), '[]')
    from (select kind, locale, status, category_id, count(*) as count
      from source_rows group by kind, locale, status, category_id) g),
  'languages', (select jsonb_agg(locale order by locale) from (
    select locale from source_rows union select 'vi' union select 'en') languages),
  'category_activity', (select coalesce(jsonb_agg(to_jsonb(g) order by game_type, locale, is_active), '[]')
    from (select game_type, locale, is_active, count(*) as count
      from categories group by game_type, locale, is_active) g),
  'images', jsonb_build_object(
    'references', (select count(*) from words where image_path is not null),
    'distinct_paths', (select count(distinct image_path) from words),
    'storage_objects', (select count(*) from objects),
    'unreferenced_objects', (select count(*) from objects o where not exists(select 1 from words w where w.image_path = o.name)),
    'by_group', (select coalesce(jsonb_agg(to_jsonb(g) order by locale, status, category_id), '[]') from (
      select locale, status, category_id, count(*) as prompts, count(image_path) as image_references
      from words group by locale, status, category_id) g)),
  'slug_changes', (select coalesce(jsonb_agg(to_jsonb(m) order by game_type, old_slug, id), '[]')
    from slug_mapping m where old_slug <> new_slug),
  'blockers', (select coalesce(jsonb_agg(to_jsonb(i) order by issue, kind, id), '[]') from issues i),
  -- Full-row hashes include metadata and shared fields without exporting prompt text or creator IDs.
  'source_manifest', (select coalesce(jsonb_agg(jsonb_build_object(
    'kind', kind, 'id', id, 'locale', locale, 'category_id', category_id,
    'status', status, 'source_md5', md5(row_data::text)) order by kind, id), '[]') from source_rows)
);

with targets as (
  select unnest(array['public.game_categories'::regclass, 'public.word_prompts'::regclass,
    'public.question_prompts'::regclass, 'storage.objects'::regclass]) as oid
),
functions as (
  select p.oid, n.nspname as schema, p.proname as name,
    pg_get_function_identity_arguments(p.oid) as arguments,
    p.prosecdef as security_definer, p.proacl::text as acl, pg_get_functiondef(p.oid) as definition
  from pg_proc p join pg_namespace n on n.oid = p.pronamespace
  where p.prokind = 'f' and (n.nspname in ('public', 'private')
    or p.oid in (select tgfoid from pg_trigger where tgrelid in (select oid from targets) and not tgisinternal))
)
select jsonb_build_object(
  'columns', (select coalesce(jsonb_agg(to_jsonb(c) order by table_schema, table_name, ordinal_position), '[]')
    from information_schema.columns c where table_schema = 'public'
      and table_name in ('game_categories', 'word_prompts', 'question_prompts')),
  'constraints', (select coalesce(jsonb_agg(jsonb_build_object('table', conrelid::regclass::text,
    'name', conname, 'definition', pg_get_constraintdef(oid)) order by conrelid, conname), '[]')
    from pg_constraint where conrelid in (select oid from targets) or confrelid in (select oid from targets)),
  'indexes', (select coalesce(jsonb_agg(to_jsonb(i) order by schemaname, tablename, indexname), '[]')
    from pg_indexes i where (schemaname = 'public' and tablename in ('game_categories', 'word_prompts', 'question_prompts'))
      or (schemaname = 'storage' and tablename = 'objects')),
  'triggers', (select coalesce(jsonb_agg(jsonb_build_object('table', tgrelid::regclass::text,
    'name', tgname, 'definition', pg_get_triggerdef(oid), 'enabled', tgenabled) order by tgrelid, tgname), '[]')
    from pg_trigger where tgrelid in (select oid from targets) and not tgisinternal),
  'rls', (select jsonb_agg(jsonb_build_object('table', oid::regclass::text,
    'enabled', relrowsecurity, 'forced', relforcerowsecurity) order by oid)
    from pg_class where oid in (select oid from targets)),
  'policies', (select coalesce(jsonb_agg(to_jsonb(p) order by schemaname, tablename, policyname), '[]')
    from pg_policies p where (schemaname = 'public' and tablename in ('game_categories', 'word_prompts', 'question_prompts'))
      or (schemaname = 'storage' and tablename = 'objects')),
  -- Include all public/private routines: PL/pgSQL body dependencies are not fully recorded by pg_depend.
  'functions', (select coalesce(jsonb_agg(to_jsonb(f) - 'oid' order by schema, name, arguments), '[]') from functions f),
  'grants', (select coalesce(jsonb_agg(to_jsonb(g) order by table_schema, table_name, grantee, privilege_type), '[]')
    from information_schema.table_privileges g where (table_schema = 'public'
      and table_name in ('game_categories', 'word_prompts', 'question_prompts'))
      or (table_schema = 'storage' and table_name = 'objects')),
  'column_grants', (select coalesce(jsonb_agg(to_jsonb(g) order by table_schema, table_name, column_name, grantee, privilege_type), '[]')
    from information_schema.column_privileges g where (table_schema = 'public'
      and table_name in ('game_categories', 'word_prompts', 'question_prompts'))
      or (table_schema = 'storage' and table_name = 'objects')),
  'catalog_dependencies', (select coalesce(jsonb_agg(jsonb_build_object(
    'object', pg_describe_object(classid, objid, objsubid),
    'referenced', pg_describe_object(refclassid, refobjid, refobjsubid), 'type', deptype)
    order by classid, objid, objsubid, refobjid, refobjsubid), '[]') from pg_depend
    where refclassid = 'pg_class'::regclass and refobjid in (select oid from targets)),
  'views', (select coalesce(jsonb_agg(to_jsonb(v) order by schemaname, viewname), '[]') from pg_views v
    where schemaname not in ('pg_catalog', 'information_schema')
      and definition ~ '(game_categories|word_prompts|question_prompts)'),
  'materialized_views', (select coalesce(jsonb_agg(to_jsonb(v) order by schemaname, matviewname), '[]') from pg_matviews v
    where definition ~ '(game_categories|word_prompts|question_prompts)'),
  'bucket', (select to_jsonb(b) - 'owner' - 'owner_id' from storage.buckets b where id = 'word-prompt-images')
);

rollback;
