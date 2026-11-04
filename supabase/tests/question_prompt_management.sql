\ir content_test_helpers.sql
do $$
declare
  v_category uuid := gen_random_uuid(); wrong_id uuid := gen_random_uuid(); v_prompt uuid := gen_random_uuid();
  version timestamptz; original jsonb; translation jsonb; state public.content_status;
begin
  perform pg_temp.save_category(v_category,'question');
  perform pg_temp.save_category(v_category,'question','en');
  perform pg_temp.save_category(wrong_id);
  perform pg_temp.save_question(v_prompt,v_category);
  select updated_at into version from public.question_prompts where id = v_prompt;
  select to_jsonb(t) into translation from public.question_prompt_translations t where prompt_id = v_prompt and locale = 'vi';
  perform pg_temp.assert_true(translation->>'civilian_question' = 'Best?' and translation->>'imposter_question' = 'Worst?','questions trimmed');
  perform pg_temp.save_question(v_prompt,v_category,'en','draft');
  perform pg_temp.expect_error(format('select public.delete_question_prompt(%L,%L)',v_prompt,version),'40001');
  perform pg_temp.assert_true((select to_jsonb(t) = translation from public.question_prompt_translations t where prompt_id = v_prompt and locale = 'vi'),'other translation untouched');
  perform pg_temp.expect_error(format('select public.save_question_prompt(%L,%L,%L,%L,%L,%L,%L,%L)',v_prompt,v_category,'easy','vi','stale','other','draft',version),'40001');
  select to_jsonb(q) into original from public.question_prompts q where id = v_prompt;
  perform pg_temp.expect_error(format('select pg_temp.save_question(%L,%L,%L,%L,%L,%L)',v_prompt,v_category,'en','draft',' SAME? ',chr(160)||'same?'||chr(65279)),'23514');
  perform pg_temp.expect_error(format('select pg_temp.save_question(%L,%L,%L,%L,%L,%L)',v_prompt,v_category,'en','draft',chr(160),'Other'),'23514');
  perform pg_temp.expect_error(format('select pg_temp.save_question(%L,%L,%L,%L,%L,null)',v_prompt,v_category,'en','draft','Other'),'23502');
  perform pg_temp.assert_true((select to_jsonb(q) = original from public.question_prompts q where id = v_prompt),'invalid question rolls back version');
  perform pg_temp.expect_error(format('select pg_temp.save_question(%L,%L)',gen_random_uuid(),wrong_id),'23514');
  perform pg_temp.expect_error(format('select pg_temp.save_question(%L,%L,%L,%L)',gen_random_uuid(),v_category,'missing','draft'),'23503');
  perform pg_temp.save_category(v_category,'question','vi','published',false);
  perform pg_temp.expect_error(format('select pg_temp.save_question(%L,%L)',v_prompt,v_category),'23514');
  perform pg_temp.save_question(v_prompt,v_category,'vi','archived');
  perform pg_temp.save_question(v_prompt,v_category,'en','draft');
  perform pg_temp.save_category(v_category,'question');
  foreach state in array enum_range(null::public.content_status) loop
    perform pg_temp.save_question(v_prompt,v_category,'vi',state);
    select updated_at into version from public.question_prompts where id = v_prompt;
    perform pg_temp.expect_error(format('select public.delete_question_prompt(%L,null)',v_prompt),'40001');
    perform public.delete_question_prompt(v_prompt,version);
    perform pg_temp.assert_true(not exists(select 1 from public.question_prompt_translations where prompt_id = v_prompt),'all question translations deleted');
  end loop;
  perform pg_temp.expect_error(format('select public.delete_question_prompt(%L,%L)',v_prompt,version),'P0002');
  raise notice 'PASS: question translations, validation, atomicity and delete';
end;
$$;
rollback;
