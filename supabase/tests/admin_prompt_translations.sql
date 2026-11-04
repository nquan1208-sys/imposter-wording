\ir content_test_helpers.sql
do $$
declare category uuid; identifier uuid; result jsonb; i integer;
begin

  category := gen_random_uuid();
  perform pg_temp.save_category(category,'word','vi');
  perform pg_temp.save_category(category,'word','en');
  for i in 1..23 loop
    identifier := gen_random_uuid();
    perform pg_temp.save_word(identifier,category,'vi','draft','Vietnamese ' || i);
    if i <= 22 then perform pg_temp.save_word(identifier,category,'en','published','English ' || lpad(i::text,2,'0')); end if;
  end loop;
  result := public.admin_list_word_prompts('en','',category,null,null,'text',1);
  perform pg_temp.assert_true((result->>'total')::integer = 23,'word: original count');
  perform pg_temp.assert_true(jsonb_array_length(result->'rows') = 20,'word: first page');
  perform pg_temp.assert_true(result#>>'{rows,0,text}' = 'English 01','word: selected-language sort');
  perform pg_temp.assert_true(jsonb_array_length(result#>'{rows,0,translations}') = 2,'word: language statuses');
  result := public.admin_list_word_prompts('en','',category,null,null,'text',2);
  perform pg_temp.assert_true(jsonb_array_length(result->'rows') = 3,'word: second page');
  perform pg_temp.assert_true(result#>'{rows,2,text}' = 'null'::jsonb,'word: missing translation sorts last');
  perform pg_temp.assert_true(result#>'{rows,2,status}' = 'null'::jsonb,'word: missing status not draft');
  perform pg_temp.assert_true((public.admin_list_word_prompts('en','',category,null,'published','updated_at',1)->>'total')::integer = 22,'word: status excludes absent translations');
  perform pg_temp.assert_true((public.admin_list_word_prompts('en','',category,null,'draft','updated_at',1)->>'total')::integer = 0,'word: independent translation status');
  perform pg_temp.assert_true((public.admin_list_word_prompts('en','Vietnamese',category,null,null,'updated_at',1)->>'total')::integer = 0,'word: no search fallback');
  perform pg_temp.assert_true((public.admin_list_word_prompts('en','English 01',category,'medium','published','updated_at',1)->>'total')::integer = 1,'word: combined filters');
  perform pg_temp.assert_true((public.admin_list_word_prompts('en','',category,'hard',null,'updated_at',1)->>'total')::integer = 0,'word: shared filters');
  result := public.admin_list_word_prompts('en','',category,null,null,'updated_at',100);
  perform pg_temp.assert_true((result->>'total')::integer = 23 and jsonb_array_length(result->'rows') = 0,'word: empty page retains total');
  perform pg_temp.expect_error('select public.admin_list_word_prompts(''unknown'','''',null,null,null,''text'',1)','22023');
  perform pg_temp.expect_error('select public.admin_list_word_prompts(''vi'','''',null,null,null,''invalid'',1)','22023');
  perform pg_temp.expect_error('select public.admin_list_word_prompts(''vi'','''',null,null,null,''text'',0)','22023');
  perform pg_temp.assert_true((public.admin_list_word_prompts('en','%_',category,null,null,'text',1)->>'total')::integer = 0,'word: literal wildcards');

  category := gen_random_uuid();
  perform pg_temp.save_category(category,'question','vi');
  perform pg_temp.save_category(category,'question','en');
  for i in 1..23 loop
    identifier := gen_random_uuid();
    perform pg_temp.save_question(identifier,category,'vi','draft','Vietnamese ' || i ,'Different Vietnamese ' || i);
    if i <= 22 then perform pg_temp.save_question(identifier,category,'en','published','English ' || lpad(i::text,2,'0'),'Other English a,b %_ ' || i); end if;
  end loop;
  result := public.admin_list_question_prompts('en','',category,null,null,'civilian_question',1);
  perform pg_temp.assert_true((result->>'total')::integer = 23,'question: original count');
  perform pg_temp.assert_true(jsonb_array_length(result->'rows') = 20,'question: first page');
  perform pg_temp.assert_true(result#>>'{rows,0,civilian_question}' = 'English 01','question: selected-language sort');
  perform pg_temp.assert_true(jsonb_array_length(result#>'{rows,0,translations}') = 2,'question: language statuses');
  result := public.admin_list_question_prompts('en','',category,null,null,'civilian_question',2);
  perform pg_temp.assert_true(jsonb_array_length(result->'rows') = 3,'question: second page');
  perform pg_temp.assert_true(result#>'{rows,2,civilian_question}' = 'null'::jsonb,'question: missing translation sorts last');
  perform pg_temp.assert_true(result#>'{rows,2,status}' = 'null'::jsonb,'question: missing status not draft');
  perform pg_temp.assert_true((public.admin_list_question_prompts('en','',category,null,'published','updated_at',1)->>'total')::integer = 22,'question: status excludes absent translations');
  perform pg_temp.assert_true((public.admin_list_question_prompts('en','',category,null,'draft','updated_at',1)->>'total')::integer = 0,'question: independent translation status');
  perform pg_temp.assert_true((public.admin_list_question_prompts('en','Vietnamese',category,null,null,'updated_at',1)->>'total')::integer = 0,'question: no search fallback');
  perform pg_temp.assert_true((public.admin_list_question_prompts('en','English 01',category,'medium','published','updated_at',1)->>'total')::integer = 1,'question: combined filters');
  perform pg_temp.assert_true((public.admin_list_question_prompts('en','',category,'hard',null,'updated_at',1)->>'total')::integer = 0,'question: shared filters');
  result := public.admin_list_question_prompts('en','',category,null,null,'updated_at',100);
  perform pg_temp.assert_true((result->>'total')::integer = 23 and jsonb_array_length(result->'rows') = 0,'question: empty page retains total');
  perform pg_temp.expect_error('select public.admin_list_question_prompts(''unknown'','''',null,null,null,''civilian_question'',1)','22023');
  perform pg_temp.expect_error('select public.admin_list_question_prompts(''vi'','''',null,null,null,''invalid'',1)','22023');
  perform pg_temp.expect_error('select public.admin_list_question_prompts(''vi'','''',null,null,null,''civilian_question'',0)','22023');
  perform pg_temp.assert_true((public.admin_list_question_prompts('en','a,b %_',category,null,null,'civilian_question',1)->>'total')::integer = 22,'question: literal search of second question');

  reset role;
  perform set_config('request.jwt.claim.sub',current_setting('test.content_outsider'),true);
  set local role authenticated;
  perform pg_temp.expect_error('select public.admin_list_word_prompts(''vi'','''',null,null,null,''text'',1)','42501');
  perform pg_temp.expect_error('select public.admin_list_question_prompts(''vi'','''',null,null,null,''civilian_question'',1)','42501');
  reset role;
  perform set_config('request.jwt.claim.sub',current_setting('test.content_admin'),true);
  update public.admin_users set is_active = false where user_id = current_setting('test.content_admin')::uuid;
  set local role authenticated;
  perform pg_temp.expect_error('select public.admin_list_word_prompts(''vi'','''',null,null,null,''text'',1)','42501');
  perform pg_temp.expect_error('select public.admin_list_question_prompts(''vi'','''',null,null,null,''civilian_question'',1)','42501');
  set local role anon;
  perform pg_temp.expect_error('select public.admin_list_word_prompts(''vi'','''',null,null,null,''text'',1)','42501');
  perform pg_temp.expect_error('select public.admin_list_question_prompts(''vi'','''',null,null,null,''civilian_question'',1)','42501');
  raise notice 'PASS: Phase 4 prompt lists, language semantics, pagination and authorization';
end;
$$;
rollback;
