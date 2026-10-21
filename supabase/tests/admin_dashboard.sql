-- Run against local Supabase; all fixtures roll back.
begin;
create function pg_temp.assert_true(ok boolean, message text) returns void language plpgsql as $$
begin if ok is not true then raise exception 'Assertion failed: %', message; end if; end; $$;
create function pg_temp.expect_error(statement text, expected_state text) returns void language plpgsql as $$
begin
  begin execute statement;
  exception when others then
    if sqlstate = expected_state then return; end if;
    raise exception 'Expected %, got %: %', expected_state, sqlstate, sqlerrm;
  end;
  raise exception 'Expected error %, statement succeeded: %', expected_state, statement;
end; $$;

do $$
declare
  admin_id uuid := gen_random_uuid(); outsider_id uuid := gen_random_uuid();
  empty_word uuid := gen_random_uuid(); empty_question uuid := gen_random_uuid();
  archived_word uuid := gen_random_uuid(); draft_question uuid := gen_random_uuid();
  recent_word uuid := gen_random_uuid(); recent_question uuid := gen_random_uuid();
  duplicate_id uuid := gen_random_uuid();
  baseline jsonb; summary jsonb; expected_recent jsonb; expected_drafts jsonb;
  fixture_categories uuid[];
begin
  insert into auth.users(id) values (admin_id), (outsider_id);
  insert into public.admin_users(user_id) values (admin_id);
  perform set_config('request.jwt.claim.sub', admin_id::text, true);
  set local role authenticated;
  baseline := public.admin_dashboard_summary();
  reset role;

  fixture_categories := array[empty_word, empty_question, archived_word, draft_question, recent_word, recent_question];
  insert into public.game_categories(id, game_type, name, slug, locale, is_active) values
    (empty_word, 'word', 'Dashboard empty word', empty_word::text, 'vi', true),
    (empty_question, 'question', 'Dashboard empty question', empty_question::text, 'vi', false),
    (archived_word, 'word', 'Dashboard archived word', archived_word::text, 'vi', true),
    (draft_question, 'question', 'Dashboard draft question', draft_question::text, 'vi', true),
    (recent_word, 'word', 'Dashboard recent word', recent_word::text, 'vi', true),
    (recent_question, 'question', 'Dashboard recent question', recent_question::text, 'vi', true);

  insert into public.word_prompts(id, category_id, text, difficulty, is_family_friendly, status)
    values (gen_random_uuid(), archived_word, 'Archived easy word', 'easy', false, 'archived');
  insert into public.question_prompts(id, category_id, civilian_question, imposter_question, difficulty, is_family_friendly, status)
    values (gen_random_uuid(), draft_question, 'Draft easy civilian', 'Draft easy imposter', 'easy', false, 'draft');

  insert into public.word_prompts(id, category_id, text, status) values
    (gen_random_uuid(), recent_word, 'Word draft 1', 'draft');
  insert into public.question_prompts(id, category_id, civilian_question, imposter_question, status) values
    (gen_random_uuid(), recent_question, 'Question draft 1', 'Question other 1', 'draft');
  insert into public.word_prompts(id, category_id, text, status) values
    (gen_random_uuid(), recent_word, 'Word draft 2', 'draft');
  insert into public.question_prompts(id, category_id, civilian_question, imposter_question, status) values
    (gen_random_uuid(), recent_question, 'Question draft 2', 'Question other 2', 'draft');
  insert into public.word_prompts(id, category_id, text, status) values
    (gen_random_uuid(), recent_word, 'Word draft 3', 'draft');
  insert into public.question_prompts(id, category_id, civilian_question, imposter_question, status) values
    (gen_random_uuid(), recent_question, 'Question published', 'Question other published', 'published');
  insert into public.word_prompts(id, category_id, text, status) values
    (gen_random_uuid(), recent_word, 'Word published', 'published');

  -- Model legacy data that predates the write-time duplicate validation.
  alter table public.question_prompts disable trigger question_prompt_before_write;
  insert into public.question_prompts(id, category_id, civilian_question, imposter_question, difficulty, is_family_friendly, status)
    values (duplicate_id, recent_question, E' \tFavourite?\n', U&'\3000fAVOURITE?\FEFF', 'hard', true, 'archived');
  alter table public.question_prompts enable trigger question_prompt_before_write;

  set local role authenticated;
  summary := public.admin_dashboard_summary();
  reset role;

  perform pg_temp.assert_true((summary->'stats'->>'published_word_prompts')::int = (baseline->'stats'->>'published_word_prompts')::int + 1, 'published word count');
  perform pg_temp.assert_true((summary->'stats'->>'published_question_prompts')::int = (baseline->'stats'->>'published_question_prompts')::int + 1, 'published question count');
  perform pg_temp.assert_true((summary->'stats'->>'active_categories')::int = (baseline->'stats'->>'active_categories')::int + 5, 'active category count');
  perform pg_temp.assert_true((summary->'stats'->>'drafts')::int = (baseline->'stats'->>'drafts')::int + 6, 'draft count across prompt types');
  perform pg_temp.assert_true((summary->'warnings'->>'empty_categories')::int = (baseline->'warnings'->>'empty_categories')::int + 2, 'empty categories include only categories with no prompt of their game type');
  perform pg_temp.assert_true((summary->'warnings'->>'duplicate_questions')::int = (baseline->'warnings'->>'duplicate_questions')::int + 1, 'duplicate questions use trigger trim and case semantics');
  perform pg_temp.assert_true((summary->'warnings'->>'non_family_easy_prompts')::int = (baseline->'warnings'->>'non_family_easy_prompts')::int + 2, 'easy non-family warning scans draft and archived prompts');

  with candidates(item) as (
    select item from jsonb_array_elements(baseline->'recent') as b(item)
    union all
    select jsonb_build_object('id', w.id, 'game_type', 'word', 'title', w.text, 'category_name', c.name, 'status', w.status, 'updated_at', w.updated_at)
      from public.word_prompts w join public.game_categories c on c.id = w.category_id where w.category_id = any(fixture_categories)
    union all
    select jsonb_build_object('id', q.id, 'game_type', 'question', 'title', q.civilian_question, 'category_name', c.name, 'status', q.status, 'updated_at', q.updated_at)
      from public.question_prompts q join public.game_categories c on c.id = q.category_id where q.category_id = any(fixture_categories)
  )
  select coalesce(jsonb_agg(item order by (item->>'updated_at')::timestamptz desc, item->>'game_type', item->>'id'), '[]'::jsonb) into expected_recent
  from (select item from candidates order by (item->>'updated_at')::timestamptz desc, item->>'game_type', item->>'id' limit 5) ordered;

  with candidates(item) as (
    select item from jsonb_array_elements(baseline->'drafts') as b(item)
    union all
    select jsonb_build_object('id', w.id, 'game_type', 'word', 'title', w.text, 'category_name', c.name, 'status', w.status, 'updated_at', w.updated_at)
      from public.word_prompts w join public.game_categories c on c.id = w.category_id where w.category_id = any(fixture_categories) and w.status = 'draft'
    union all
    select jsonb_build_object('id', q.id, 'game_type', 'question', 'title', q.civilian_question, 'category_name', c.name, 'status', q.status, 'updated_at', q.updated_at)
      from public.question_prompts q join public.game_categories c on c.id = q.category_id where q.category_id = any(fixture_categories) and q.status = 'draft'
  )
  select coalesce(jsonb_agg(item order by (item->>'updated_at')::timestamptz desc, item->>'game_type', item->>'id'), '[]'::jsonb) into expected_drafts
  from (select item from candidates order by (item->>'updated_at')::timestamptz desc, item->>'game_type', item->>'id' limit 5) ordered;

  perform pg_temp.assert_true(summary->'recent' = expected_recent and jsonb_array_length(summary->'recent') = 5, 'recent merges all statuses, orders deterministically, then limits to five');
  perform pg_temp.assert_true(summary->'drafts' = expected_drafts and jsonb_array_length(summary->'drafts') = 5, 'draft list merges both prompt types and limits to five');
  perform pg_temp.assert_true((select bool_and((select count(*) = 6 from jsonb_object_keys(item)) and item ?& array['id','game_type','title','category_name','status','updated_at']) from jsonb_array_elements(summary->'recent') as r(item)), 'recent items expose only summary fields');

  perform pg_temp.assert_true(has_function_privilege('authenticated', 'public.admin_dashboard_summary()', 'execute'), 'authenticated can call RPC');
  perform pg_temp.assert_true(not has_function_privilege('anon', 'public.admin_dashboard_summary()', 'execute'), 'anon cannot call RPC');
  perform pg_temp.assert_true((select prosecdef and proconfig @> array['search_path=""'] from pg_proc where oid = 'public.admin_dashboard_summary()'::regprocedure), 'RPC is security definer with empty search path');

  perform set_config('request.jwt.claim.sub', '', true);
  set local role anon;
  perform pg_temp.expect_error('select public.admin_dashboard_summary()', '42501');
  reset role;
  perform set_config('request.jwt.claim.sub', outsider_id::text, true);
  set local role authenticated;
  perform pg_temp.expect_error('select public.admin_dashboard_summary()', '42501');
  reset role;
  update public.admin_users set is_active = false where user_id = admin_id;
  perform set_config('request.jwt.claim.sub', admin_id::text, true);
  set local role authenticated;
  perform pg_temp.expect_error('select public.admin_dashboard_summary()', '42501');
  reset role;
  raise notice 'admin dashboard assertions passed';
end; $$;
rollback;
