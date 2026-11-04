"""Local DB concurrency checks; CT_TEST_DATABASE selects an isolated rehearsal DB."""
from concurrent.futures import ThreadPoolExecutor
import os
import subprocess
import time
import uuid

CONTAINER = 'supabase_db_imposter-wording'
DATABASE = os.environ.get('CT_TEST_DATABASE', 'postgres')


def sql(statement):
    return subprocess.run(
        ['docker', 'exec', '-i', CONTAINER, 'psql', '-U', 'postgres', '-d', DATABASE,
         '-X', '-qAt', '-v', 'ON_ERROR_STOP=1', '-v', 'VERBOSITY=verbose'],
        input=statement, text=True, capture_output=True, timeout=20,
    )


def checked(statement):
    result = sql(statement)
    assert result.returncode == 0, result.stderr
    return result.stdout.strip()


def races():
    admin, category, target, word, question_category, question = [str(uuid.uuid4()) for _ in range(6)]
    auth = f"set local request.jwt.claim.sub = '{admin}'; set local role authenticated;"

    def save_category(identifier, locale='vi', status='published'):
        kind = 'question' if identifier == question_category else 'word'
        return (f"select public.save_category('{identifier}','{kind}','{identifier}',0,true,false,'{locale}',"
                f"'Category',null,'{status}',(select updated_at from public.game_categories where id='{identifier}'));")

    def save_prompt(identifier, parent, locale='vi', version='null'):
        content = "null,'vi','Word'" if identifier == word else "'vi','Best?','Worst?'"
        content = content.replace("'vi'", f"'{locale}'")
        kind = 'word' if identifier == word else 'question'
        return f"select public.save_{kind}_prompt('{identifier}','{parent}','medium',{content},'published',{version});"

    def race(first, second, expected_error):
        # The first transaction has completed its mutation before the competitor starts.
        label = 'ct-' + str(uuid.uuid4())
        with ThreadPoolExecutor() as executor:
            holding = executor.submit(sql, f"begin; set local application_name='{label}'; {auth} {first} select pg_sleep(1); commit;")
            deadline = time.monotonic() + 10
            while time.monotonic() < deadline:
                if holding.done():
                    result = holding.result()
                    raise AssertionError(f'Holder ended before observation: {result.stderr}')
                if checked(f"select count(*) from pg_stat_activity where datname=current_database() and application_name='{label}' and wait_event='PgSleep';") == '1':
                    break
                time.sleep(0.02)
            else:
                raise AssertionError('Holder never reached pg_sleep')
            competing = executor.submit(sql, f'begin; {auth} {second} commit;')
            first_result, second_result = holding.result(), competing.result()
        assert first_result.returncode == 0, first_result.stderr
        assert second_result.returncode != 0 and (expected_error in second_result.stderr
            or (expected_error == '40001' and 'PT409' in second_result.stderr)), second_result.stderr
        assert '40P01' not in second_result.stderr, 'Unexpected deadlock'

    try:
        checked(f"insert into auth.users(id) values('{admin}'); insert into public.admin_users(user_id) values('{admin}');")
        checked(f'begin; {auth} {save_category(category)} {save_category(target)} {save_category(question_category)} commit;')
        # A translation saved while activation waits invalidates the original version.
        version = checked(f"select updated_at from public.game_categories where id='{target}';")
        race(save_category(target, 'en'),
             f"select public.set_category_active('{target}',false,'{version}');", '40001')
        # Parent deletion must reject a waiting RPC insert, rather than leave an orphan.
        race(f"select public.delete_category('{category}','empty');", save_prompt(word, category), '23514')
        assert checked(f"select count(*) from public.word_prompts where id='{word}';") == '0'
        checked(f'begin; {auth} {save_category(category)} {save_category(category,"en")} {save_category(question_category,"en")} '
                f'{save_prompt(word,category)} {save_prompt(question,question_category)} commit;')
        # Updating different translations still conflicts on the shared original version.
        for identifier, parent in [(word, category), (question, question_category)]:
            version = checked(f"select updated_at from public.{'word' if identifier == word else 'question'}_prompts where id='{identifier}';")
            race(save_prompt(identifier, parent, 'vi', f"'{version}'"),
                 save_prompt(identifier, parent, 'en', f"'{version}'"), '40001')
        # A completed translation edit invalidates a preview while purge waits on the category.
        version = checked(f"begin; {auth} select public.preview_category_delete('{category}')->>'version'; commit;")
        current = f"(select updated_at from public.word_prompts where id='{word}')"
        race(save_prompt(word, category, 'vi', current),
             f"select public.delete_category('{category}','purge',null,'{version}');", '40001')
        # Eligibility is checked after acquiring the category lock, not against an old snapshot.
        race(save_category(category, 'vi', 'archived'), save_prompt(word, category, 'vi', current), '23514')
        checked(f'begin; {auth} {save_category(category)} commit;')
        version = checked(f"begin; {auth} select public.preview_category_delete('{category}')->>'version'; commit;")
        race(save_category(target, 'vi', 'archived'),
             f"select public.delete_category('{category}','transfer','{target}','{version}');", '23514')
        assert checked(f"select category_id from public.word_prompts where id='{word}';") == category
        # Revocation committed while a save waits must be observed with the same JWT.
        race(f"reset role; update public.admin_users set is_active=false where user_id='{admin}';",
             save_prompt(word, category, 'vi', current), '42501')
        print('PASS: 8 lock races (translation/activation, delete/insert, two stale saves, preview/purge, publish/archive, transfer/archive, revoked admin)')
    finally:
        checked(f"delete from public.word_prompts where id='{word}'; delete from public.question_prompts where id='{question}';"
                f"delete from public.game_categories where id in ('{category}','{target}','{question_category}');"
                f"delete from auth.users where id='{admin}';")


if __name__ == '__main__':
    races()
