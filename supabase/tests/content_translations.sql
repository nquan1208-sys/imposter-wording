\ir content_test_helpers.sql
do $$
declare
  v_category uuid := gen_random_uuid(); v_question_category uuid := gen_random_uuid();
  v_word uuid := gen_random_uuid(); v_question uuid := gen_random_uuid(); image text; table_name text; routine regprocedure;
begin
  foreach table_name in array array['content_languages','game_categories','word_prompts','question_prompts',
    'game_category_translations','word_prompt_translations','question_prompt_translations'] loop
    perform pg_temp.assert_true(not has_table_privilege('authenticated','public.'||table_name,'INSERT,UPDATE,DELETE,TRUNCATE'), 'admin cannot directly write '||table_name);
    perform pg_temp.assert_true(not has_table_privilege('anon','public.'||table_name,'INSERT,UPDATE,DELETE,TRUNCATE'), 'anon cannot directly write '||table_name);
    perform pg_temp.assert_true(has_table_privilege('anon','public.'||table_name,'SELECT'),'explicit read grant on '||table_name);
  end loop;
  for routine in select p.oid::regprocedure from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname in ('save_category','save_word_prompt','save_question_prompt',
      'delete_category','preview_category_delete','delete_word_prompt','delete_question_prompt','admin_dashboard_summary') loop
    perform pg_temp.assert_true(not has_function_privilege('anon',routine,'EXECUTE'),'anon cannot call '||routine::text);
    perform pg_temp.assert_true(has_function_privilege('authenticated',routine,'EXECUTE'),'authenticated guarded RPC '||routine::text);
  end loop;
  perform pg_temp.save_category(v_category);
  perform pg_temp.save_category(v_category,'word','en');
  perform pg_temp.save_category(v_question_category,'question');
  perform pg_temp.save_category(v_question_category,'question','en');
  image := v_word::text || '/' || gen_random_uuid()::text || '.png';
  reset role;
  insert into storage.objects(bucket_id,name,metadata) values('word-prompt-images',image,'{"mimetype":"image/png","size":100}');
  insert into public.content_languages values('test-language','Test language',10);
  set local role authenticated;
  perform pg_temp.save_category(v_category,'word','test-language');
  perform pg_temp.save_word(v_word,v_category,'vi','published','Vi',image);
  perform pg_temp.save_word(v_word,v_category,'en','draft','En',image);
  perform pg_temp.save_word(v_word,v_category,'test-language','draft','Test',image);
  perform pg_temp.save_question(v_question,v_question_category,'vi','published');
  perform pg_temp.save_question(v_question,v_question_category,'en','archived');
  perform pg_temp.expect_error(format('update public.word_prompts set difficulty = ''hard'' where id = %L',v_word),'42501');
  perform pg_temp.expect_error(format('delete from public.word_prompt_translations where prompt_id = %L',v_word),'42501');

  reset role;
  -- Constraints also defend trusted maintenance writes.
  perform pg_temp.expect_error(format('insert into public.word_prompt_translations(prompt_id,locale,text) values(%L,''vi'',''Duplicate'')',v_word),'23505');
  perform pg_temp.expect_error(format('insert into public.game_category_translations(category_id,locale,name) values(%L,''vi'',''Duplicate'')',v_category),'23505');
  perform pg_temp.expect_error(format('insert into public.question_prompt_translations(prompt_id,locale,civilian_question,imposter_question) values(%L,''vi'',''A'',''B'')',v_question),'23505');
  set local role anon;
  perform pg_temp.assert_true((select count(*) = 1 from public.word_prompts where id = v_word),'public original with eligible translation');
  perform pg_temp.assert_true((select count(*) = 1 from public.word_prompt_translations where prompt_id = v_word),'public sees only published locale');
  perform pg_temp.assert_true((select count(*) = 1 from public.question_prompt_translations where prompt_id = v_question),'archived question hidden');
  perform pg_temp.assert_true(exists(select 1 from storage.objects where name = image),'public image visible');
  perform pg_temp.assert_true(exists(select 1 from public.content_languages where code = 'test-language'),'data-driven languages readable');
  perform pg_temp.expect_error(format('select public.preview_category_delete(%L)',v_category),'42501');

  reset role;
  perform set_config('request.jwt.claim.sub',current_setting('test.content_outsider'),true);
  set local role authenticated;
  perform pg_temp.assert_true((select count(*) = 1 from public.word_prompt_translations where prompt_id = v_word),'non-admin sees published only');
  perform pg_temp.expect_error(format('select pg_temp.save_word(%L,%L)',v_word,v_category),'42501');
  perform pg_temp.expect_error(format('select pg_temp.save_category(%L)',v_category),'42501');
  perform pg_temp.expect_error(format('select pg_temp.save_question(%L,%L)',v_question,v_question_category),'42501');
  perform pg_temp.expect_error('select public.admin_dashboard_summary()','42501');
  perform pg_temp.expect_error(format('select public.delete_word_prompt(%L,null)',v_word),'42501');
  perform pg_temp.expect_error(format('select public.delete_question_prompt(%L,null)',v_question),'42501');
  perform pg_temp.expect_error(format('select public.delete_category(%L,''purge'')',v_category),'42501');

  reset role;
  perform set_config('request.jwt.claim.sub',current_setting('test.content_admin'),true);
  set local role authenticated;
  perform pg_temp.save_category(v_category,'word','vi','archived');
  set local role anon;
  perform pg_temp.assert_true(not exists(select 1 from public.word_prompts where id = v_word),'category translation archival hides original without another eligible translation');
  perform pg_temp.assert_true(not exists(select 1 from public.word_prompt_translations where prompt_id = v_word),'category archival hides prompt translation');
  perform pg_temp.assert_true(not exists(select 1 from storage.objects where name = image),'category archival hides image');
  set local role authenticated;
  perform pg_temp.save_word(v_word,v_category,'en','published','En',image);
  set local role anon;
  perform pg_temp.assert_true(exists(select 1 from public.word_prompts where id = v_word),'another eligible locale exposes original');
  perform pg_temp.assert_true(exists(select 1 from storage.objects where name = image),'image shared across eligible locales');
  perform pg_temp.assert_true(not exists(select 1 from public.word_prompt_translations where prompt_id = v_word and locale = 'vi'),'no fallback from hidden Vietnamese');
  set local role authenticated;
  perform pg_temp.save_category(v_category,'word','en','published',false);
  set local role anon;
  perform pg_temp.assert_true(not exists(select 1 from public.game_categories where id = v_category),'disabled category hidden');
  perform pg_temp.assert_true(not exists(select 1 from public.word_prompts where id = v_word),'disabled category hides original');
  perform pg_temp.assert_true(not exists(select 1 from storage.objects where name = image),'disabled category hides image');
  set local role authenticated;
  perform pg_temp.assert_true((select count(*) = 3 from public.word_prompt_translations where prompt_id = v_word),'admin still reads every translation');
  reset role;
  update public.admin_users set is_active = false where user_id = current_setting('test.content_admin')::uuid;
  set local role authenticated;
  perform pg_temp.expect_error(format('select pg_temp.save_word(%L,%L)',v_word,v_category),'42501');
  perform pg_temp.expect_error(format('select pg_temp.save_category(%L)',v_category),'42501');
  perform pg_temp.expect_error(format('select pg_temp.save_question(%L,%L)',v_question,v_question_category),'42501');
  perform pg_temp.assert_true(not exists(select 1 from public.word_prompts where id = v_word),'revoked admin loses hidden reads with unchanged JWT');
  perform pg_temp.expect_error('select public.admin_dashboard_summary()','42501');
  raise notice 'PASS: grants, active-admin checks, RLS, Storage eligibility and extra language';
end;
$$;
rollback;
