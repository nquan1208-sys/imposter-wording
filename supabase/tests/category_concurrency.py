"""Local-only FK race test. Run with Docker access; fixtures are removed in finally."""
import concurrent.futures
import subprocess
import time
import uuid

CONTAINER = "supabase_db_imposter-wording"

def sql(statement):
    return subprocess.run(
        ["docker", "exec", "-i", CONTAINER, "psql", "-U", "postgres", "-d", "postgres", "-v", "ON_ERROR_STOP=1", "-At"],
        input=statement, text=True, capture_output=True, timeout=20,
    )

def checked(statement):
    result = sql(statement)
    assert result.returncode == 0, result.stderr
    return result.stdout

admin_id, category_id = str(uuid.uuid4()), str(uuid.uuid4())
try:
    checked(f"insert into auth.users(id) values('{admin_id}'); insert into public.admin_users(user_id) values('{admin_id}'); insert into public.game_categories(id,game_type,name,slug) values('{category_id}','word','Concurrency test','{category_id}');")
    with concurrent.futures.ThreadPoolExecutor() as executor:
        deleting = executor.submit(sql, f"begin; set local application_name = 'category-test-{category_id}'; set local request.jwt.claim.sub = '{admin_id}'; set local role authenticated; select id from public.game_categories where id = '{category_id}' for update; select pg_sleep(2); select public.delete_category('{category_id}','empty'); commit;")
        # Observe the actual lock before starting the competing insert.
        deadline = time.monotonic() + 10
        while time.monotonic() < deadline:
            if deleting.done():
                result = deleting.result()
                raise AssertionError(f'Delete session ended early: {result.stdout} {result.stderr}')
            locks = checked(f"select count(*) from pg_locks l join pg_stat_activity a on a.pid = l.pid where a.application_name = 'category-test-{category_id}' and l.relation = 'public.game_categories'::regclass and l.mode = 'RowShareLock' and l.granted;")
            if locks.strip() == '1':
                break
            time.sleep(0.05)
        else:
            raise AssertionError("Delete transaction did not acquire its lock")
        inserting = executor.submit(sql, f"insert into public.word_prompts(category_id,civilian_text) values('{category_id}','Concurrent insert');")
        delete_result, insert_result = deleting.result(), inserting.result()
        assert delete_result.returncode == 0, delete_result.stderr
        assert insert_result.returncode != 0 and 'foreign key constraint' in insert_result.stderr, insert_result.stderr
    assert checked(f"select count(*) from public.word_prompts where category_id = '{category_id}';").strip() == '0'
    print('PASS: category delete blocks concurrent insertion; no orphan content')
finally:
    checked(f"delete from public.word_prompts where category_id = '{category_id}'; delete from public.game_categories where id = '{category_id}'; delete from auth.users where id = '{admin_id}';")
