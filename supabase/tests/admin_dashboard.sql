\ir content_test_helpers.sql
do $$
declare v_word_category uuid := gen_random_uuid(); v_question_category uuid := gen_random_uuid();
  v_word uuid := gen_random_uuid(); v_question uuid := gen_random_uuid(); before_vi jsonb; before_en jsonb; summary jsonb;
begin
  before_vi := public.admin_dashboard_summary();
  before_en := public.admin_dashboard_summary('en');
  perform pg_temp.save_category(v_word_category);
  perform pg_temp.save_category(v_word_category,'word','en','draft');
  perform pg_temp.save_category(v_question_category,'question');
  perform pg_temp.save_word(v_word,v_word_category);
  perform pg_temp.save_word(v_word,v_word_category,'en','draft');
  perform pg_temp.save_question(v_question,v_question_category,'vi','draft');
  summary := public.admin_dashboard_summary('vi');
  perform pg_temp.assert_true(summary = public.admin_dashboard_summary(),'default locale is vi');
  perform pg_temp.assert_true((summary#>>'{stats,published_word_prompts}')::int = (before_vi#>>'{stats,published_word_prompts}')::int+1,'Vietnamese published count');
  perform pg_temp.assert_true((summary#>>'{stats,drafts}')::int = (before_vi#>>'{stats,drafts}')::int+1,'Vietnamese draft count');
  perform pg_temp.assert_true((summary#>>'{stats,active_categories}')::int = (before_vi#>>'{stats,active_categories}')::int+2,'active published category translations');
  perform pg_temp.assert_true(not exists(select 1 from jsonb_array_elements(summary->'recent') i where i->>'locale' <> 'vi'),'recent items carry selected locale');
  summary := public.admin_dashboard_summary('en');
  perform pg_temp.assert_true((summary#>>'{stats,published_word_prompts}')::int = (before_en#>>'{stats,published_word_prompts}')::int,'English does not fall back to Vietnamese');
  perform pg_temp.assert_true((summary#>>'{stats,drafts}')::int = (before_en#>>'{stats,drafts}')::int+1,'English draft count');
  perform pg_temp.assert_true(not exists(select 1 from jsonb_array_elements(summary->'recent') i where i->>'id' = v_question::text),'missing English question omitted');
  perform pg_temp.expect_error('select public.admin_dashboard_summary(''missing'')','22023');
  perform pg_temp.expect_error('select public.admin_dashboard_summary(null)','22023');
  raise notice 'PASS: dashboard locale filtering, counts and links';
end;
$$;
reset role;
insert into public.content_languages(code, display_name, sort_order) values ('phase5', 'Phase 5 test', 99);
set local role authenticated;
do $$
declare word_category uuid := gen_random_uuid(); question_category uuid := gen_random_uuid();
  word_id uuid := gen_random_uuid(); question_id uuid := gen_random_uuid();
  summary jsonb; baseline jsonb; original_version timestamptz;
begin
  baseline := public.admin_dashboard_summary('vi');
  summary := public.admin_dashboard_summary('phase5');
  perform pg_temp.assert_true(summary#>>'{stats,drafts}' = '0' and summary->'recent' = '[]'::jsonb,
    'new language starts empty without fallback');
  perform pg_temp.save_category(word_category, 'word', 'phase5');
  perform pg_temp.save_category(question_category, 'question', 'phase5');
  summary := public.admin_dashboard_summary('phase5');
  perform pg_temp.assert_true(summary#>>'{warnings,empty_categories}' = '2', 'empty categories use selected language');
  perform pg_temp.save_word(word_id, word_category, 'phase5', 'draft', 'Phase 5 word');
  perform pg_temp.save_question(question_id, question_category, 'phase5', 'published');
  summary := public.admin_dashboard_summary('phase5');
  perform pg_temp.assert_true(summary#>>'{stats,drafts}' = '1' and summary#>>'{stats,published_question_prompts}' = '1',
    'third language supports both prompt types');
  perform pg_temp.assert_true(summary#>>'{warnings,empty_categories}' = '0', 'translated prompts resolve empty warnings');
  perform pg_temp.assert_true(jsonb_array_length(summary->'drafts') = 1
    and summary#>>'{drafts,0,locale}' = 'phase5' and summary#>>'{drafts,0,id}' = word_id::text,
    'draft links carry the selected locale');
  perform pg_temp.assert_true(public.admin_dashboard_summary('vi')->'stats' = baseline->'stats'
    and public.admin_dashboard_summary('vi')->'warnings' = baseline->'warnings', 'other language totals stay unchanged');
  select updated_at into original_version from public.word_prompts where id = word_id;
  perform public.save_word_prompt(word_id,word_category,'easy',null,'phase5','Phase 5 word','published',original_version);
  summary := public.admin_dashboard_summary('phase5');
  perform pg_temp.assert_true(not (summary->'warnings' ? 'non_family_easy_prompts')
    and summary#>>'{stats,published_word_prompts}' = '1', 'obsolete family warning removed');
  perform pg_temp.save_category(word_category, 'word', 'phase5', 'archived', false);
  summary := public.admin_dashboard_summary('phase5');
  perform pg_temp.assert_true(summary#>>'{stats,active_categories}' = '1'
    and summary#>>'{stats,published_word_prompts}' = '1', 'published status totals remain distinct from public visibility');
  perform pg_temp.save_category(word_category, 'word', 'en', 'draft', false);
  perform pg_temp.save_word(word_id, word_category, 'en', 'draft');
  summary := public.admin_dashboard_summary('en');
  perform pg_temp.assert_true(exists(select 1 from jsonb_array_elements(summary->'recent') i
    where i->>'id' = word_id::text and i->>'locale' = 'en'), 'second translation has its own dashboard item');
  perform pg_temp.save_word(word_id, word_category, 'vi', 'draft');
  summary := public.admin_dashboard_summary('vi');
  perform pg_temp.assert_true(exists(select 1 from jsonb_array_elements(summary->'recent') i
    where i->>'id' = word_id::text and i->'category_name' = 'null'::jsonb), 'missing category translation stays nullable');
  perform pg_temp.assert_true((select count(*) <= 5 from jsonb_array_elements(summary->'recent'))
    and (select count(*) <= 5 from jsonb_array_elements(summary->'drafts')), 'dashboard panels remain bounded');
  raise notice 'PASS: dashboard third language, warnings, independent totals and nullable categories';
end;
$$;
rollback;
