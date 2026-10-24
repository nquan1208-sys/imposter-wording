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
rollback;
