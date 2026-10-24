\ir content_test_helpers.sql
do $$
declare
  source_id uuid := gen_random_uuid(); target_id uuid := gen_random_uuid(); question_id uuid := gen_random_uuid();
  word_id uuid := gen_random_uuid(); empty_id uuid := gen_random_uuid(); preview jsonb; before_row jsonb; version timestamptz;
begin
  perform pg_temp.save_category(source_id);
  perform pg_temp.save_category(target_id);
  perform pg_temp.save_category(question_id,'question');
  select to_jsonb(c) into before_row from public.game_categories c where id = source_id;
  version := (before_row->>'updated_at')::timestamptz;
  perform pg_temp.save_category(source_id,'word','en','draft');
  perform pg_temp.assert_true((select count(*) = 2 from public.game_category_translations where category_id = source_id),'two translations, one category');
  perform pg_temp.assert_true((select name = 'Category' from public.game_category_translations where category_id = source_id and locale = 'vi'),'trimmed category name');
  perform pg_temp.assert_true((select updated_at > version from public.game_categories where id = source_id),'translation touches original');
  perform pg_temp.expect_error(format('select public.save_category(%L,%L,%L,0,true,%L,%L,null,%L,%L)',source_id,'word',source_id,'vi','stale','published',version),'40001');
  perform pg_temp.expect_error(format('select public.save_category(%L,%L,%L,0,true,%L,%L,null,%L,null)',source_id,'word',source_id,'vi','exists','published'),'40001');
  perform pg_temp.expect_error(format('select public.save_category(%L,%L,%L,0,true,%L,%L,null,%L,%L)',empty_id,'word',empty_id,'vi','missing','draft',version),'P0002');
  perform pg_temp.expect_error(format('select pg_temp.save_category(%L,%L)',source_id,'question'),'23514');
  perform pg_temp.expect_error(format('select public.save_category(%L,%L,%L,-1,true,%L,%L,null,%L,null)',empty_id,'word',empty_id,'vi','Name','draft'),'23514');
  perform pg_temp.expect_error(format('select public.save_category(%L,%L,%L,0,true,%L,%L,null,%L,null)',empty_id,'word','bad slug','vi','Name','draft'),'23514');
  perform pg_temp.expect_error(format('select public.save_category(%L,%L,%L,0,true,%L,%L,null,%L,null)',empty_id,'word',empty_id,'vi',chr(160)||chr(65279),'draft'),'23514');
  perform pg_temp.assert_true(not exists(select 1 from public.game_categories where id = empty_id),'failed category translation rolls back original');
  perform pg_temp.expect_error(format('select pg_temp.save_category(%L,%L,%L)',empty_id,'word','missing'),'23503');
  perform pg_temp.assert_true(not exists(select 1 from public.game_categories where id = empty_id),'unknown locale is atomic');

  perform pg_temp.save_word(word_id,source_id);
  perform pg_temp.save_word(word_id,source_id,'en','draft');
  preview := public.preview_category_delete(source_id);
  perform pg_temp.assert_true(preview#>>'{counts,originals,total}' = '1' and preview#>>'{counts,translations,published}' = '1'
    and preview#>>'{counts,translations,draft}' = '1','preview distinguishes originals and translations');
  perform pg_temp.expect_error(format('select public.delete_category(%L,%L)',source_id,'empty'),'23503');
  perform pg_temp.save_word(word_id,source_id,'en','archived');
  perform pg_temp.expect_error(format('select public.delete_category(%L,%L,null,%L)',source_id,'purge',preview->>'version'),'40001');
  preview := public.preview_category_delete(source_id);
  perform pg_temp.save_category(source_id,'word','en','published');
  perform pg_temp.expect_error(format('select public.delete_category(%L,%L,%L,%L)',source_id,'transfer',target_id,preview->>'version'),'40001');
  perform pg_temp.save_word(word_id,source_id,'en','published');
  preview := public.preview_category_delete(source_id);
  perform pg_temp.expect_error(format('select public.delete_category(%L,%L,%L,%L)',source_id,'transfer',target_id,preview->>'version'),'23514');
  perform pg_temp.expect_error(format('select public.delete_category(%L,%L,%L,%L)',source_id,'transfer',question_id,preview->>'version'),'23514');
  perform pg_temp.save_category(target_id,'word','en','published',false);
  perform pg_temp.expect_error(format('select public.delete_category(%L,%L,%L,%L)',source_id,'transfer',target_id,preview->>'version'),'23514');
  perform pg_temp.save_category(target_id,'word','en');
  perform public.delete_category(source_id,'transfer',target_id,preview->>'version');
  perform pg_temp.assert_true((select category_id = target_id from public.word_prompts where id = word_id),'transfer moves original');
  perform pg_temp.assert_true((select count(*) = 2 from public.word_prompt_translations where prompt_id = word_id),'transfer preserves translations');
  perform pg_temp.assert_true(not exists(select 1 from public.game_category_translations where category_id = source_id),'source translations cascade');
  preview := public.preview_category_delete(target_id);
  perform public.delete_category(target_id,'purge',null,preview->>'version');
  perform pg_temp.assert_true(not exists(select 1 from public.word_prompts where id = word_id)
    and not exists(select 1 from public.word_prompt_translations where prompt_id = word_id),'purge cascades prompt translations');
  perform pg_temp.save_category(empty_id);
  perform public.delete_category(empty_id,'empty');
  perform pg_temp.expect_error(format('select public.preview_category_delete(%L)',empty_id),'P0002');
  perform pg_temp.expect_error(format('select public.delete_category(%L,%L)',question_id,'invalid'),'22023');
  -- The same transfer and purge contract applies to question originals.
  source_id := gen_random_uuid(); word_id := gen_random_uuid();
  perform pg_temp.save_category(source_id,'question');
  perform pg_temp.save_question(word_id,source_id);
  preview := public.preview_category_delete(source_id);
  perform public.delete_category(source_id,'transfer',question_id,preview->>'version');
  perform pg_temp.assert_true((select category_id = question_id from public.question_prompts where id = word_id),'question transfer');
  preview := public.preview_category_delete(question_id);
  perform public.delete_category(question_id,'purge',null,preview->>'version');
  perform pg_temp.assert_true(not exists(select 1 from public.question_prompt_translations where prompt_id = word_id),'question purge cascades translations');
  raise notice 'PASS: category translations, atomicity, preview, transfer and purge';
end;
$$;
rollback;
