-- All fixtures and destructive operations roll back.
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
  category_id uuid := gen_random_uuid(); other_id uuid := gen_random_uuid();
  prompt_id uuid; version timestamptz; image text; state public.content_status;
begin
  insert into auth.users(id) values(admin_id), (outsider_id);
  insert into public.admin_users(user_id) values(admin_id);
  insert into public.game_categories(id,game_type,name,slug,locale) values
    (category_id,'word','Word tests',category_id::text,'vi'), (other_id,'question','Question tests',other_id::text,'vi');
  perform pg_temp.assert_true(not exists(select 1 from information_schema.columns where table_schema = 'public' and table_name = 'word_prompts' and column_name in ('imposter_text','imposter_hint')), 'no imposter word or hint columns');
  perform pg_temp.assert_true(exists(select 1 from information_schema.columns where table_schema = 'public' and table_name = 'question_prompts' and column_name = 'imposter_hint'), 'question hint retained');
  perform pg_temp.assert_true(not has_table_privilege('authenticated','public.word_prompts','delete'), 'no direct delete');
  perform pg_temp.assert_true(not has_function_privilege('anon','public.delete_word_prompt(uuid,timestamptz,text)','execute'), 'anon cannot execute');
  prompt_id := gen_random_uuid();
  insert into public.word_prompts(id,category_id,civilian_text) values(prompt_id,category_id,'  Saved word  ');
  select updated_at into version from public.word_prompts where id = prompt_id;
  perform pg_temp.assert_true((select civilian_text = 'Saved word' from public.word_prompts where id = prompt_id), 'trim text');
  set local role anon;
  perform pg_temp.expect_error(format('select public.delete_word_prompt(%L,%L,%L)',prompt_id,version,'XÓA'), '42501');
  reset role;
  perform set_config('request.jwt.claim.sub', outsider_id::text, true);
  set local role authenticated;
  perform pg_temp.expect_error(format('select public.delete_word_prompt(%L,%L,%L)',prompt_id,version,'XÓA'), '42501');
  reset role;
  perform set_config('request.jwt.claim.sub', admin_id::text, true);
  set local role authenticated;
  perform pg_temp.expect_error(format('delete from public.word_prompts where id = %L',prompt_id),'42501');
  perform pg_temp.expect_error(format('select public.delete_word_prompt(%L,%L,%L)',prompt_id,version,' XÓA'), '22023');
  perform pg_temp.expect_error(format('select public.delete_word_prompt(%L,%L,null)',prompt_id,version), '22023');
  perform pg_temp.expect_error(format('select public.delete_word_prompt(%L,null,%L)',prompt_id,'XÓA'), '40001');
  update public.word_prompts set civilian_text = 'Other tab edit' where id = prompt_id;
  perform pg_temp.expect_error(format('select public.delete_word_prompt(%L,%L,%L)',prompt_id,version,'XÓA'), '40001');
  perform pg_temp.assert_true(exists(select 1 from public.word_prompts where id = prompt_id), 'failed deletion retains row');
  select updated_at into version from public.word_prompts where id = prompt_id;
  perform public.delete_word_prompt(prompt_id, version, 'XÓA');
  perform pg_temp.expect_error(format('select public.delete_word_prompt(%L,%L,%L)',prompt_id,version,'XÓA'), 'P0002');
  reset role;
  foreach state in array array['draft','published','archived']::public.content_status[] loop
    prompt_id := gen_random_uuid(); image := prompt_id::text || '/' || gen_random_uuid()::text || '.png';
    insert into storage.objects(bucket_id,name) values('word-prompt-images',image);
    insert into public.word_prompts(id,category_id,civilian_text,status,image_path) values(prompt_id,category_id,'Image word',state,image);
    select updated_at into version from public.word_prompts where id = prompt_id;
    set local role anon;
    perform pg_temp.assert_true((select count(*) from storage.objects where bucket_id = 'word-prompt-images' and name = image) = case when state = 'published' then 1 else 0 end, 'anon published-only image access');
    reset role;
    perform set_config('request.jwt.claim.sub', outsider_id::text, true);
    set local role authenticated;
    perform pg_temp.assert_true((select count(*) from storage.objects where bucket_id = 'word-prompt-images' and name = image) = case when state = 'published' then 1 else 0 end, 'user published-only image access');
    reset role;
    perform set_config('request.jwt.claim.sub', admin_id::text, true);
    set local role authenticated;
    perform public.delete_word_prompt(prompt_id,version,'XÓA');
    perform pg_temp.assert_true(not exists(select 1 from public.word_prompts where id = prompt_id), 'delete every status');
    reset role;
    perform pg_temp.assert_true(exists(select 1 from storage.objects where bucket_id = 'word-prompt-images' and name = image), 'image retained');
    set local role anon;
    perform pg_temp.assert_true(not exists(select 1 from storage.objects where bucket_id = 'word-prompt-images' and name = image), 'anon cannot read retained image');
    reset role;
    perform set_config('request.jwt.claim.sub', outsider_id::text, true);
    set local role authenticated;
    perform pg_temp.assert_true(not exists(select 1 from storage.objects where bucket_id = 'word-prompt-images' and name = image), 'user cannot read retained image');
    reset role;
  end loop;
  prompt_id := gen_random_uuid();
  insert into public.word_prompts(id,category_id,civilian_text) values(prompt_id,category_id,'Disabled admin');
  select updated_at into version from public.word_prompts where id = prompt_id;
  update public.admin_users set is_active = false where user_id = admin_id;
  perform set_config('request.jwt.claim.sub', admin_id::text, true);
  set local role authenticated;
  perform pg_temp.expect_error(format('select public.delete_word_prompt(%L,%L,%L)',prompt_id,version,'XÓA'), '42501');
  reset role;
  perform pg_temp.assert_true(exists(select 1 from public.game_categories where id = category_id), 'category unchanged');
  perform pg_temp.assert_true(exists(select 1 from public.game_categories where id = other_id), 'question category unchanged');
  raise notice 'word prompt management assertions passed';
end; $$;
rollback;
