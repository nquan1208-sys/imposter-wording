-- Included by content suites; every suite ends in ROLLBACK.
begin;
create function pg_temp.assert_true(ok boolean, message text)
returns void language plpgsql as $$
begin
  if ok is distinct from true then raise exception 'Assertion failed: %', message; end if;
end;
$$;
create function pg_temp.expect_error(statement text, expected_code text)
returns void language plpgsql as $$
begin
  begin
    execute statement;
  exception when others then
    if sqlstate = expected_code then return; end if;
    raise exception 'Expected SQLSTATE %, got %: % (statement: %)', expected_code, sqlstate, sqlerrm, statement;
  end;
  raise exception 'Expected SQLSTATE %, statement succeeded: %', expected_code, statement;
end;
$$;
create function pg_temp.save_category(
  id uuid, game_type public.game_type default 'word', locale text default 'vi',
  status public.content_status default 'published', active boolean default true
)
returns jsonb language sql as $$
  select public.save_category(id,game_type,id::text,0,active,locale,' Category ',null,status,
    (select updated_at from public.game_categories where game_categories.id = $1));
$$;
create function pg_temp.save_word(
  id uuid, category_id uuid, locale text default 'vi', status public.content_status default 'published',
  text text default ' Word ', image_path text default null
)
returns jsonb language sql as $$
  select public.save_word_prompt(id,category_id,'medium',true,image_path,locale,text,status,
    (select updated_at from public.word_prompts where word_prompts.id = $1));
$$;
create function pg_temp.save_question(
  id uuid, category_id uuid, locale text default 'vi', status public.content_status default 'published',
  civilian text default ' Best? ', imposter text default ' Worst? '
)
returns jsonb language sql as $$
  select public.save_question_prompt(id,category_id,'medium',true,locale,civilian,imposter,status,
    (select updated_at from public.question_prompts where question_prompts.id = $1));
$$;
do $$
declare admin_id uuid := gen_random_uuid(); outsider_id uuid := gen_random_uuid();
begin
  insert into auth.users(id) values(admin_id),(outsider_id);
  insert into public.admin_users(user_id) values(admin_id);
  perform set_config('test.content_admin',admin_id::text,true);
  perform set_config('test.content_outsider',outsider_id::text,true);
  perform set_config('request.jwt.claim.sub',admin_id::text,true);
end;
$$;
set local role authenticated;
