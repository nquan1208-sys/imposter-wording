\ir content_test_helpers.sql
do $$
declare category_id uuid := gen_random_uuid(); question_category uuid := gen_random_uuid();
  word_id uuid := gen_random_uuid(); question_id uuid := gen_random_uuid();
  stale timestamptz := '2000-01-01'; snapshot text; before_row jsonb;
begin
  perform pg_temp.save_category(category_id);
  perform pg_temp.save_category(question_category, 'question');
  perform pg_temp.save_word(word_id, category_id);
  perform pg_temp.save_question(question_id, question_category);
  select to_jsonb(w) into before_row from public.word_prompts w where id = word_id;
  perform pg_temp.expect_error(format('select public.save_category(%L,''word'',%L,0,true,''en'',''Stale'',null,''draft'',%L)', category_id,category_id,stale),'PT409');
  perform pg_temp.expect_error(format('select public.set_category_active(%L,false,%L)',category_id,stale),'PT409');
  perform pg_temp.expect_error(format('select public.save_word_prompt(%L,%L,''easy'',false,null,''en'',''Stale'',''draft'',%L)',word_id,category_id,stale),'PT409');
  perform pg_temp.expect_error(format('select public.save_question_prompt(%L,%L,''easy'',false,''en'',''Stale?'',''Other?'',''draft'',%L)',question_id,question_category,stale),'PT409');
  perform pg_temp.expect_error(format('select public.delete_word_prompt(%L,%L)',word_id,stale),'PT409');
  perform pg_temp.expect_error(format('select public.delete_question_prompt(%L,%L)',question_id,stale),'PT409');
  snapshot := public.preview_category_delete(category_id)->>'version';
  perform pg_temp.save_word(word_id,category_id,'en','draft');
  perform pg_temp.expect_error(format('select public.delete_category(%L,''purge'',null,%L)',category_id,snapshot),'PT409');
  perform pg_temp.assert_true((select to_jsonb(w) - 'updated_at' = before_row - 'updated_at' from public.word_prompts w where id = word_id), 'conflicts cannot partially change shared fields');
  perform pg_temp.assert_true((select text = 'Word' and status = 'published' from public.word_prompt_translations where prompt_id = word_id and locale = 'vi'), 'conflicts cannot overwrite the saved translation');
  raise notice 'PASS: all seven content mutation RPCs return PT409 for explicit conflicts';
end;
$$;
rollback;
