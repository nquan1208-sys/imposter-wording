\ir content_test_helpers.sql
do $$
declare
  category_id uuid := gen_random_uuid(); target_id uuid := gen_random_uuid(); wrong_id uuid := gen_random_uuid();
  v_prompt uuid := gen_random_uuid(); failed_id uuid := gen_random_uuid(); version timestamptz;
  before_original jsonb; before_translation jsonb; image text; state public.content_status;
begin
  perform pg_temp.save_category(category_id);
  perform pg_temp.save_category(category_id,'word','en');
  perform pg_temp.save_category(target_id);
  perform pg_temp.save_category(wrong_id,'question');
  image := v_prompt::text || '/' || gen_random_uuid()::text || '.webp';
  reset role;
  insert into storage.objects(bucket_id,name,metadata) values('word-prompt-images',image,'{"mimetype":"image/webp","size":100}');
  set local role authenticated;
  perform pg_temp.save_word(v_prompt,category_id,'vi','published',' Word ',image);
  select updated_at,to_jsonb(w) into version,before_original from public.word_prompts w where id = v_prompt;
  select to_jsonb(t) into before_translation from public.word_prompt_translations t where t.prompt_id = v_prompt and locale = 'vi';
  perform pg_temp.assert_true(before_translation->>'text' = 'Word','word trimmed');
  perform pg_temp.save_word(v_prompt,category_id,'en','draft','English',image);
  perform pg_temp.expect_error(format('select public.delete_word_prompt(%L,%L)',v_prompt,version),'40001');
  perform pg_temp.assert_true((select count(*) = 2 from public.word_prompt_translations where prompt_id = v_prompt),'translation does not duplicate original');
  perform pg_temp.assert_true((select to_jsonb(t) = before_translation from public.word_prompt_translations t where prompt_id = v_prompt and locale = 'vi'),'saving English preserves Vietnamese metadata and content');
  perform pg_temp.expect_error(format('select public.save_word_prompt(%L,%L,%L,%L,%L,%L,%L,%L)',v_prompt,category_id,'easy',image,'vi','stale','published',version),'40001');
  select to_jsonb(w),updated_at into before_original,version from public.word_prompts w where id = v_prompt;
  perform pg_temp.expect_error(format('select public.save_word_prompt(%L,%L,%L,%L,%L,%L,%L,%L)',v_prompt,category_id,'hard',image,'en',chr(160)||chr(65279),'draft',version),'23514');
  perform pg_temp.assert_true((select to_jsonb(w) = before_original from public.word_prompts w where id = v_prompt),'failed translation rolls back shared fields and version');
  perform pg_temp.expect_error(format('select pg_temp.save_word(%L,%L,%L,%L)',failed_id,category_id,'unknown','draft'),'23503');
  perform pg_temp.assert_true(not exists(select 1 from public.word_prompts where id = failed_id),'unknown-language creation is atomic');
  perform pg_temp.expect_error(format('select pg_temp.save_word(%L,%L)',failed_id,wrong_id),'23514');
  perform pg_temp.expect_error(format('select pg_temp.save_word(%L,%L,%L,%L,%L,%L)',failed_id,category_id,'vi','draft','Word',image),'23514');
  perform pg_temp.expect_error(format('select pg_temp.save_word(%L,%L,%L,%L,%L,%L)',failed_id,category_id,'vi','draft','Word',failed_id::text||'/'||gen_random_uuid()::text||'.png'),'23514');
  perform pg_temp.save_word(v_prompt,category_id,'en','published','English',image);
  perform pg_temp.expect_error(format('select pg_temp.save_word(%L,%L,%L,%L,%L,%L)',v_prompt,target_id,'vi','published','Word',image),'23514');
  perform pg_temp.save_category(category_id,'word','en','archived');
  perform pg_temp.expect_error(format('select pg_temp.save_word(%L,%L,%L,%L,%L,%L)',v_prompt,category_id,'en','published','English',image),'23514');
  perform pg_temp.save_word(v_prompt,category_id,'en','draft','English',image);
  perform pg_temp.save_category(category_id,'word','vi','published',false);
  perform pg_temp.expect_error(format('select pg_temp.save_word(%L,%L,%L,%L,%L,%L)',v_prompt,category_id,'vi','published','Word',image),'23514');
  perform pg_temp.save_word(v_prompt,category_id,'vi','archived','Word',image);
  select updated_at into version from public.word_prompts where id = v_prompt;
  perform pg_temp.expect_error(format('select public.delete_word_prompt(%L,null)',v_prompt),'40001');
  perform public.delete_word_prompt(v_prompt,version);
  perform pg_temp.assert_true(not exists(select 1 from public.word_prompt_translations where prompt_id = v_prompt),'delete cascades every translation');
  perform pg_temp.assert_true(exists(select 1 from storage.objects where name = image),'delete retains image');
  set local role anon;
  perform pg_temp.assert_true(not exists(select 1 from storage.objects where name = image),'retained image is private after deletion');
  set local role authenticated;
  perform pg_temp.expect_error(format('select public.delete_word_prompt(%L,%L)',v_prompt,version),'P0002');
  -- Delete remains available for every translation state.
  perform pg_temp.save_category(category_id);
  foreach state in array enum_range(null::public.content_status) loop
    perform pg_temp.save_word(v_prompt,category_id,'vi',state);
    perform public.delete_word_prompt(v_prompt,(select updated_at from public.word_prompts where id = v_prompt));
  end loop;
  raise notice 'PASS: word translations, validation, atomicity, versions, images and delete';
end;
$$;
rollback;
