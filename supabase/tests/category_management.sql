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
  admin_id uuid := gen_random_uuid();
  outsider_id uuid := gen_random_uuid();
  empty_id uuid := gen_random_uuid();
  source_id uuid := gen_random_uuid();
  target_id uuid := gen_random_uuid();
  wrong_id uuid := gen_random_uuid();
  inactive_id uuid := gen_random_uuid();
  foreign_id uuid := gen_random_uuid();
  question_id uuid := gen_random_uuid();
  question_target uuid := gen_random_uuid();
  version text;
begin
  insert into auth.users(id) values(admin_id), (outsider_id);
  insert into public.admin_users(user_id) values(admin_id);
  insert into public.game_categories(id,game_type,name,slug,locale,is_active) values
    (empty_id,'word','Empty',empty_id::text,'vi',true),
    (source_id,'word','Source',source_id::text,'vi',true),
    (target_id,'word','Target',target_id::text,'vi',true),
    (wrong_id,'question','Wrong',wrong_id::text,'vi',true),
    (inactive_id,'word','Inactive',inactive_id::text,'vi',false),
    (foreign_id,'word','Foreign',foreign_id::text,'en',true),
    (question_id,'question','Questions',question_id::text,'vi',true),
    (question_target,'question','Question target',question_target::text,'vi',true);
  insert into public.word_prompts(category_id,text,status) values
    (source_id,'a','draft'), (source_id,'b','published'), (source_id,'c','archived');
  insert into public.question_prompts(category_id,civilian_question,imposter_question,status) values
    (question_id,'q','other','published');
  perform pg_temp.assert_true(not has_function_privilege('anon','public.delete_category(uuid,text,uuid,text,text)','execute'), 'anon cannot execute delete');
  perform pg_temp.assert_true(not has_function_privilege('anon','public.preview_category_delete(uuid)','execute'), 'anon cannot execute preview');
  perform set_config('request.jwt.claim.sub', outsider_id::text, true);
  set local role authenticated;
  perform pg_temp.expect_error(format('select public.preview_category_delete(%L)',source_id), '42501');
  perform pg_temp.expect_error(format('select public.delete_category(%L,%L)',source_id,'empty'), '42501');
  reset role;
  perform set_config('request.jwt.claim.sub', admin_id::text, true);
  set local role authenticated;
  perform pg_temp.assert_true((public.preview_category_delete(source_id)->'counts') = '{"draft":1,"published":1,"archived":1}'::jsonb, 'preview includes all statuses');
  perform pg_temp.expect_error(format('select public.delete_category(%L,%L)',source_id,'empty'), '23503');
  perform pg_temp.assert_true((select count(*) = 3 from public.word_prompts where category_id = source_id), 'blocked delete keeps content');
  perform pg_temp.expect_error(format('select public.delete_category(%L,%L)',source_id,'bogus'), '22023');
  perform public.delete_category(empty_id,'empty');
  perform pg_temp.assert_true(not exists(select 1 from public.game_categories where id = empty_id), 'empty category removed');
  perform pg_temp.expect_error(format('select public.preview_category_delete(%L)',empty_id), 'P0002');
  perform pg_temp.expect_error(format('select public.delete_category(%L,%L,%L)',source_id,'transfer',source_id), '23514');
  perform pg_temp.expect_error(format('select public.delete_category(%L,%L,%L)',source_id,'transfer',wrong_id), '23514');
  perform pg_temp.expect_error(format('select public.delete_category(%L,%L,%L)',source_id,'transfer',inactive_id), '23514');
  perform pg_temp.expect_error(format('select public.delete_category(%L,%L,%L)',source_id,'transfer',foreign_id), '23514');
  perform pg_temp.expect_error(format('select public.delete_category(%L,%L,%L)',source_id,'transfer',gen_random_uuid()), '23514');
  perform pg_temp.expect_error(format('update public.game_categories set name = %L where id = %L',' ',source_id),'23514');
  perform pg_temp.expect_error(format('update public.game_categories set slug = %L where id = %L','bad slug',source_id),'23514');
  perform pg_temp.expect_error(format('update public.game_categories set sort_order = -1 where id = %L',source_id),'23514');
  perform pg_temp.expect_error(format('update public.game_categories set game_type = %L where id = %L','question',source_id),'23514');
  perform pg_temp.expect_error(format('update public.game_categories set locale = %L where id = %L','en',source_id),'23514');
  perform pg_temp.expect_error(format('delete from public.game_categories where id = %L',source_id),'42501');
  -- Timestamp is set by the database, even if the client sends an old value.
  update public.game_categories set name = 'Renamed', updated_at = '2000-01-01' where id = source_id;
  perform pg_temp.assert_true((select updated_at = now() from public.game_categories where id = source_id), 'backend timestamp');
  perform public.delete_category(source_id,'transfer',target_id);
  perform pg_temp.assert_true(not exists(select 1 from public.game_categories where id = source_id), 'source removed after transfer');
  perform pg_temp.assert_true((select count(*) = 3 from public.word_prompts where category_id = target_id), 'all statuses transferred');
  perform pg_temp.assert_true((select count(distinct status) = 3 from public.word_prompts where category_id = target_id), 'states preserved');
  version := public.preview_category_delete(target_id)->>'version';
  perform pg_temp.expect_error(format('select public.delete_category(%L,%L,null,%L,%L)',target_id,'purge','wrong',version), '22023');
  insert into public.word_prompts(category_id,text) values(target_id,'new after preview');
  perform pg_temp.expect_error(format('select public.delete_category(%L,%L,null,%L,%L)',target_id,'purge','Target',version), '40001');
  perform pg_temp.assert_true((select count(*) = 4 from public.word_prompts where category_id = target_id), 'stale confirmation rolls back');
  version := public.preview_category_delete(target_id)->>'version';
  update public.word_prompts set text = 'edited without timestamp' where category_id = target_id;
  perform pg_temp.expect_error(format('select public.delete_category(%L,%L,null,%L,%L)',target_id,'purge','Target',version), '40001');
  version := public.preview_category_delete(target_id)->>'version';
  perform public.delete_category(target_id,'purge',null,'Target',version);
  perform pg_temp.assert_true(not exists(select 1 from public.game_categories where id = target_id), 'purged category removed');
  perform pg_temp.assert_true(not exists(select 1 from public.word_prompts where category_id = target_id), 'purged word content removed');
  perform public.delete_category(question_id,'transfer',question_target);
  perform pg_temp.assert_true((select count(*) = 1 from public.question_prompts where category_id = question_target), 'question transfer');
  version := public.preview_category_delete(question_target)->>'version';
  perform public.delete_category(question_target,'purge',null,'Question target',version);
  perform pg_temp.assert_true(not exists(select 1 from public.question_prompts where category_id = question_target), 'question purge');
  reset role;
  update public.admin_users set is_active = false where user_id = admin_id;
  set local role authenticated;
  perform pg_temp.expect_error(format('select public.delete_category(%L,%L)',inactive_id,'empty'),'42501');
  reset role;
  raise notice 'category management assertions passed';
end; $$;
rollback;
