\ir content_test_helpers.sql
do $$
declare
  source uuid := gen_random_uuid(); target uuid := gen_random_uuid(); wrong_type uuid := gen_random_uuid();
  prompt uuid := gen_random_uuid(); identifier uuid; result jsonb; version timestamptz; snapshot text; before_translation jsonb;
  marker text := 'phase3-' || gen_random_uuid()::text; i integer;
begin
  perform pg_temp.save_category(source);
  perform pg_temp.save_category(source,'word','en');
  perform pg_temp.save_category(target);
  perform pg_temp.save_category(wrong_type,'question');
  perform pg_temp.save_word(prompt,source,'vi');
  perform pg_temp.save_word(prompt,source,'en');
  perform pg_temp.assert_true(not exists(select 1 from public.admin_category_transfer_targets(source,'vi') where id = target),'target missing English excluded');
  perform pg_temp.save_category(target,'word','en','draft');
  perform pg_temp.assert_true(not exists(select 1 from public.admin_category_transfer_targets(source,'vi') where id = target),'draft English excluded');
  perform pg_temp.save_category(target,'word','en','published');
  perform pg_temp.assert_true(exists(select 1 from public.admin_category_transfer_targets(source,'vi') where id = target),'eligible target included');
  perform pg_temp.assert_true(not exists(select 1 from public.admin_category_transfer_targets(source,'vi') where id in (source,wrong_type)),'source and different game excluded');
  select updated_at into version from public.game_categories where id = target;
  select to_jsonb(t) into before_translation from public.game_category_translations t where category_id = target and locale = 'en';
  perform public.set_category_active(target,false,version);
  perform pg_temp.assert_true(not exists(select 1 from public.admin_category_transfer_targets(source,'vi') where id = target),'inactive target excluded');
  perform pg_temp.assert_true((select to_jsonb(t) = before_translation from public.game_category_translations t where category_id = target and locale = 'en'),'activation preserves translation metadata');
  perform pg_temp.expect_error(format('select public.set_category_active(%L,true,%L)',target,version),'40001');
  perform pg_temp.expect_error(format('select public.set_category_active(%L,true,null)',target),'40001');
  perform pg_temp.expect_error(format('select public.set_category_active(%L,true,now())',gen_random_uuid()),'P0002');
  select updated_at into version from public.game_categories where id = target;
  perform public.set_category_active(target,true,version);
  snapshot := public.preview_category_delete(source)->>'version';
  perform pg_temp.save_category(source,'word','en','archived');
  perform pg_temp.expect_error(format('select public.delete_category(%L,''purge'',null,%L)',source,snapshot),'40001');
  -- Multiple matching translations still yield one row per original.
  for i in 1..23 loop
    identifier := gen_random_uuid();
    perform public.save_category(identifier,'word',marker || '-' || i,0,true,'vi',marker || ' ' || lpad(i::text,2,'0'),null,'draft',null);
    if i <= 22 then
      select updated_at into version from public.game_categories where id = identifier;
      perform public.save_category(identifier,'word',marker || '-' || i,0,true,'en',marker || ' English ' || lpad(i::text,2,'0'),null,'published',version);
    end if;
  end loop;
  result := public.admin_list_categories('en',marker,'word',true,'name',1);
  perform pg_temp.assert_true((result->>'total')::integer = 23,'exact original count without duplication');
  perform pg_temp.assert_true(jsonb_array_length(result->'rows') = 20,'first page size');
  perform pg_temp.assert_true(result#>>'{rows,0,name}' = marker || ' English 01','selected-language name sort');
  result := public.admin_list_categories('en',marker,'word',true,'name',2);
  perform pg_temp.assert_true(jsonb_array_length(result->'rows') = 3,'second page size');
  perform pg_temp.assert_true(result#>'{rows,2,name}' = 'null'::jsonb,'missing name last without fallback');
  result := public.admin_list_categories('en',marker || ' 01','word',true,'name',1);
  perform pg_temp.assert_true((result->>'total')::integer = 1,'search finds another locale');
  perform pg_temp.assert_true((public.admin_list_categories('vi',marker || '%_','word',true,'name',1)->>'total')::integer = 0,'literal wildcard search');
  perform pg_temp.assert_true((public.admin_list_categories('vi',marker,'word',true,'name',10)->>'total')::integer = 23,'empty page retains total');
  perform pg_temp.expect_error('select public.admin_list_categories(''unknown'','''',null,null,''name'',1)','22023');
  perform pg_temp.expect_error('select public.admin_list_categories(''vi'','''',null,null,''injected'',1)','22023');
  perform pg_temp.expect_error('select public.admin_list_categories(''vi'','''',null,null,''name'',0)','22023');
  reset role;
  perform set_config('request.jwt.claim.sub',current_setting('test.content_outsider'),true);
  set local role authenticated;
  perform pg_temp.expect_error('select public.admin_list_categories(''vi'','''',null,null,''name'',1)','42501');
  perform pg_temp.expect_error(format('select public.admin_category_transfer_targets(%L,''vi'')',source),'42501');
  perform pg_temp.expect_error(format('select public.set_category_active(%L,false,now())',source),'42501');
  reset role;
  perform set_config('request.jwt.claim.sub',current_setting('test.content_admin'),true);
  update public.admin_users set is_active = false where user_id = current_setting('test.content_admin')::uuid;
  set local role authenticated;
  perform pg_temp.expect_error('select public.admin_list_categories(''vi'','''',null,null,''name'',1)','42501');
  perform pg_temp.expect_error(format('select public.set_category_active(%L,false,now())',source),'42501');
  perform pg_temp.expect_error(format('select public.admin_category_transfer_targets(%L,''vi'')',source),'42501');
  set local role anon;
  perform pg_temp.expect_error('select public.admin_list_categories(''vi'','''',null,null,''name'',1)','42501');
  raise notice 'PASS: Phase 3 listing, activation, transfer targets and authorization';
end;
$$;
rollback;
