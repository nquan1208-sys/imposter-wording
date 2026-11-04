begin;
-- Explicit version conflicts must not trigger PostgREST's serialization retry loop.
-- Replacing only the error literal preserves each function's locks, validation and grants.
do $$
declare target regprocedure; definition text;
begin
  foreach target in array array[
    'public.save_category(uuid,public.game_type,text,integer,boolean,text,text,text,public.content_status,timestamptz)'::regprocedure,
    'public.save_word_prompt(uuid,uuid,public.difficulty_level,boolean,text,text,text,public.content_status,timestamptz)'::regprocedure,
    'public.save_question_prompt(uuid,uuid,public.difficulty_level,boolean,text,text,text,public.content_status,timestamptz)'::regprocedure,
    'public.delete_word_prompt(uuid,timestamptz)'::regprocedure,
    'public.delete_question_prompt(uuid,timestamptz)'::regprocedure,
    'public.delete_category(uuid,text,uuid,text)'::regprocedure,
    'public.set_category_active(uuid,boolean,timestamptz)'::regprocedure
  ] loop
    definition := pg_get_functiondef(target);
    execute replace(definition, '''40001''', '''PT409''');
  end loop;
end;
$$;
commit;
