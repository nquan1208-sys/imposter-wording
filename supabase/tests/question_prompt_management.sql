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
  category_id uuid := gen_random_uuid(); word_id uuid := gen_random_uuid(); foreign_id uuid := gen_random_uuid();
  prompt_id uuid; version timestamptz; state public.content_status;
begin
  insert into auth.users(id) values(admin_id), (outsider_id);
  insert into public.admin_users(user_id) values(admin_id);
  insert into public.game_categories(id,game_type,name,slug,locale) values
    (category_id,'question','Question tests',category_id::text,'vi'),
    (word_id,'word','Word tests',word_id::text,'vi'),
    (foreign_id,'question','English tests',foreign_id::text,'en');
  perform pg_temp.assert_true(not exists(select 1 from information_schema.columns where table_schema = 'public' and table_name = 'question_prompts' and column_name = 'imposter_hint'), 'hint removed');
  perform pg_temp.assert_true(not has_table_privilege('authenticated','public.question_prompts','delete'), 'no direct authenticated delete');
  perform pg_temp.assert_true(not has_table_privilege('anon','public.question_prompts','delete'), 'no direct anonymous delete');
  perform pg_temp.assert_true(has_function_privilege('authenticated','public.delete_question_prompt(uuid,timestamptz)','execute'), 'authenticated can call guarded RPC');
  perform pg_temp.assert_true(not has_function_privilege('anon','public.delete_question_prompt(uuid,timestamptz)','execute'), 'anon cannot call RPC');
  perform set_config('request.jwt.claim.sub', admin_id::text, true);
  set local role authenticated;
  foreach state in array array['draft','published','archived']::public.content_status[] loop
    prompt_id := gen_random_uuid();
    insert into public.question_prompts(id,category_id,civilian_question,imposter_question,status,updated_at)
      values(prompt_id,category_id,E' \tFavourite?\n ',E'\nWorst?\t ',state,'2000-01-01');
    select updated_at into version from public.question_prompts where id = prompt_id;
    perform pg_temp.assert_true(version > '2000-01-01', 'server timestamp on insert');
    perform pg_temp.assert_true((select civilian_question = 'Favourite?' and imposter_question = 'Worst?' from public.question_prompts where id = prompt_id), 'questions trimmed');
    perform pg_temp.expect_error(format('update public.question_prompts set civilian_question = %L where id = %L',E' \t\n',prompt_id),'23514');
    perform pg_temp.expect_error(format('update public.question_prompts set imposter_question = %L where id = %L',E' \t\n',prompt_id),'23514');
    perform pg_temp.expect_error(format('update public.question_prompts set imposter_question = %L where id = %L',' FAVOURITE? ',prompt_id),'23514');
    perform pg_temp.expect_error(format('update public.question_prompts set civilian_question = null where id = %L',prompt_id),'23514');
    perform pg_temp.expect_error(format('update public.question_prompts set category_id = %L where id = %L',word_id,prompt_id),'23514');
    perform pg_temp.expect_error(format('update public.question_prompts set category_id = %L where id = %L',foreign_id,prompt_id),'23514');
    perform pg_temp.expect_error(format('update public.question_prompts set locale = %L where id = %L','en',prompt_id),'23514');
    perform pg_temp.expect_error(format('update public.question_prompts set imposter_question = %L where id = %L',chr(160)||chr(65279),prompt_id),'23514');
    reset role;
    set local role anon;
    perform pg_temp.assert_true((select count(*) from public.question_prompts where id = prompt_id) = case when state = 'published' then 1 else 0 end, 'anonymous published-only read');
    perform pg_temp.expect_error(format('select public.delete_question_prompt(%L,%L)',prompt_id,version),'42501');
    perform pg_temp.expect_error(format('insert into public.question_prompts(category_id,civilian_question,imposter_question) values(%L,%L,%L)',category_id,'A','B'),'42501');
    update public.question_prompts set civilian_question = 'Anonymous edit' where id = prompt_id;
    perform pg_temp.assert_true(not found, 'anonymous updates affect zero rows');
    reset role;
    perform set_config('request.jwt.claim.sub', outsider_id::text, true);
    set local role authenticated;
    perform pg_temp.assert_true((select count(*) from public.question_prompts where id = prompt_id) = case when state = 'published' then 1 else 0 end, 'non-admin published-only read');
    perform pg_temp.expect_error(format('insert into public.question_prompts(category_id,civilian_question,imposter_question) values(%L,%L,%L)',category_id,'A','B'),'42501');
    update public.question_prompts set civilian_question = 'Unauthorized edit' where id = prompt_id;
    perform pg_temp.expect_error(format('select public.delete_question_prompt(%L,%L)',prompt_id,version),'42501');
    reset role;
    perform set_config('request.jwt.claim.sub', admin_id::text, true);
    set local role authenticated;
    perform pg_temp.assert_true((select civilian_question = 'Favourite?' from public.question_prompts where id = prompt_id), 'non-admin update has no effect');
    perform pg_temp.expect_error(format('delete from public.question_prompts where id = %L',prompt_id),'42501');
    perform pg_temp.expect_error(format('select public.delete_question_prompt(%L,null)',prompt_id),'40001');
    update public.question_prompts set civilian_question = 'Other tab edit', updated_at = '2000-01-01' where id = prompt_id;
    perform pg_temp.assert_true((select updated_at > version from public.question_prompts where id = prompt_id), 'server timestamp advances');
    -- Same version predicate used by the admin API must never overwrite a newer row.
    update public.question_prompts set civilian_question = 'Stale edit' where id = prompt_id and updated_at = version;
    perform pg_temp.assert_true(not found, 'stale update affects zero rows');
    perform pg_temp.expect_error(format('select public.delete_question_prompt(%L,%L)',prompt_id,version),'40001');
    select updated_at into version from public.question_prompts where id = prompt_id;
    perform public.delete_question_prompt(prompt_id,version);
    perform pg_temp.assert_true(not exists(select 1 from public.question_prompts where id = prompt_id), 'delete works for every status');
    perform pg_temp.expect_error(format('select public.delete_question_prompt(%L,%L)',prompt_id,version),'P0002');
  end loop;
  -- Inactive categories remain editable as drafts/archived, but cannot publish.
  prompt_id := gen_random_uuid();
  insert into public.question_prompts(id,category_id,civilian_question,imposter_question,status) values(prompt_id,category_id,'A','B','published');
  update public.game_categories set is_active = false where id = category_id;
  perform pg_temp.assert_true(exists(select 1 from public.question_prompts where id = prompt_id), 'inactive-category content still opens for admin');
  perform pg_temp.expect_error(format('update public.question_prompts set civilian_question = %L where id = %L','C',prompt_id),'23514');
  update public.question_prompts set status = 'archived' where id = prompt_id;
  update public.question_prompts set status = 'draft', civilian_question = 'Draft edit' where id = prompt_id;
  perform pg_temp.expect_error(format('update public.question_prompts set status = %L where id = %L','published',prompt_id),'23514');
  select updated_at into version from public.question_prompts where id = prompt_id;
  reset role;
  update public.admin_users set is_active = false where user_id = admin_id;
  set local role authenticated;
  perform pg_temp.expect_error(format('select public.delete_question_prompt(%L,%L)',prompt_id,version),'42501');
  reset role;
  raise notice 'question prompt management assertions passed';
end; $$;
rollback;
