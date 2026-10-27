\ir content_test_helpers.sql
do $$
declare
  word_id uuid := gen_random_uuid(); question_id uuid := gen_random_uuid();
  version timestamptz; result jsonb; slug text;
begin
  perform pg_temp.save_category(word_id);
  perform pg_temp.save_category(question_id, 'question');
  perform pg_temp.assert_true((select not is_family_friendly from public.game_categories where id = word_id), 'new categories default to non-family');
  select updated_at, c.slug into version, slug from public.game_categories c where id = word_id;
  perform public.save_category(word_id,'word',slug,0,true,true,'vi','Family',null,'published',version);
  perform pg_temp.assert_true((select is_family_friendly from public.game_categories where id = word_id), 'word category can enable family');
  perform pg_temp.expect_error(format('select public.save_category(%L,''word'',%L,0,true,false,''vi'',''Stale'',null,''published'',%L)',word_id,slug,version),'PT409');
  -- Translations share the same original flag, including when adding a language.
  select updated_at into version from public.game_categories where id = word_id;
  perform public.save_category(word_id,'word',slug,0,true,true,'en','Family EN',null,'published',version);
  result := public.admin_list_categories('en','',null,null,true,'name',1);
  perform pg_temp.assert_true(exists(select 1 from jsonb_array_elements(result->'rows') c where c->>'id' = word_id::text and (c->>'is_family_friendly')::boolean), 'family filter works across languages');
  select updated_at into version from public.game_categories where id = question_id;
  perform pg_temp.expect_error(format('select public.save_category(%L,''question'',%L,0,true,true,''vi'',''Invalid'',null,''published'',%L)',question_id,question_id,version),'23514');
  perform pg_temp.assert_true((select not is_family_friendly from public.game_categories where id = question_id), 'failed save leaves question category unchanged');
  select updated_at into version from public.game_categories where id = word_id;
  perform public.save_category(word_id,'word',slug,0,true,false,'vi','Family off',null,'published',version);
  perform pg_temp.assert_true((select not is_family_friendly from public.game_categories where id = word_id), 'word category can disable family');
  perform pg_temp.assert_true(not exists(select 1 from information_schema.columns where table_schema = 'public' and table_name in ('word_prompts','question_prompts') and column_name = 'is_family_friendly'), 'prompt family columns removed');
  reset role;
  perform set_config('request.jwt.claim.sub',current_setting('test.content_outsider'),true);
  set local role authenticated;
  perform pg_temp.expect_error(format('select public.save_category(%L,''word'',%L,0,true,true,''vi'',''Forbidden'',null,''draft'',null)',word_id,slug),'42501');
  set local role anon;
  perform pg_temp.expect_error('select public.admin_list_categories(''vi'','''',null,null,true,''name'',1)','42501');
  raise notice 'PASS: category family flag, translations, filters, constraint, conflicts and permissions';
end;
$$;
rollback;
