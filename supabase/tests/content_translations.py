"""Rehearse Phase 2 in disposable copies of local Supabase. Never reset the live DB.

Requires Docker and the running supabase_db_imposter-wording container. Restores use
supabase_admin to retain Supabase-owned schemas; migrations/tests run as postgres.
"""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
import uuid

ROOT = Path(__file__).resolve().parents[2]
MIGRATION = ROOT / 'supabase/migrations/20261024045640_content_translations.sql'
DOCKER = ['docker', 'exec', '-i', 'supabase_db_imposter-wording']


class TranslationMigrationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp = tempfile.TemporaryDirectory(prefix='content-translations-')
        cls.dump = Path(cls.temp.name) / 'local.dump'
        with cls.dump.open('wb') as output:
            subprocess.run(DOCKER + ['pg_dump', '-U', 'supabase_admin', '-d', 'postgres', '-Fc'],
                           stdout=output, check=True, stderr=subprocess.PIPE)

    @classmethod
    def tearDownClass(cls):
        cls.temp.cleanup()

    def setUp(self):
        self.database = 'ct_test_' + uuid.uuid4().hex
        subprocess.run(DOCKER + ['createdb', '-U', 'supabase_admin', '-O', 'postgres', self.database],
                       check=True, capture_output=True)
        self.addCleanup(lambda: subprocess.run(
            DOCKER + ['dropdb', '-U', 'supabase_admin', '--force', self.database], check=True, capture_output=True))
        with self.dump.open('rb') as data:
            result = subprocess.run(DOCKER + ['pg_restore', '-U', 'supabase_admin', '-d', self.database,
                                             '--no-publications', '--no-subscriptions'], stdin=data, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr.decode())

    def execute(self, statement, success=True):
        result = subprocess.run(DOCKER + ['psql', '-U', 'postgres', '-d', self.database,
                                          '-X', '-qAt', '-v', 'ON_ERROR_STOP=1'],
                                input=statement, text=True, capture_output=True, timeout=30)
        if success:
            self.assertEqual(result.returncode, 0, result.stderr)
        return result

    def fresh_legacy(self):
        # Only the disposable clone is reset. Preserve auth/storage infrastructure and objects.
        self.execute('drop schema public cascade; drop schema private cascade; '
                     'create schema public authorization postgres; '
                     'grant usage on schema public to anon,authenticated,service_role;')
        for migration in sorted((ROOT / 'supabase/migrations').glob('*.sql')):
            if migration.name >= MIGRATION.name:
                break
            self.execute(migration.read_text())

    def seed_legacy(self):
        self.execute("""
          alter table public.game_categories disable trigger user;
          alter table public.word_prompts disable trigger user;
          alter table public.question_prompts disable trigger user;
          insert into public.game_categories(id,game_type,slug,name,locale,is_active,created_at,updated_at) values
            ('00000000-0000-0000-0000-000000000001','word','same','Vi','vi',true,'2020-01-01','2021-01-01'),
            ('00000000-0000-0000-0000-000000000002','word','same','English','en',false,'2020-01-02','2021-01-02'),
            ('00000000-0000-0000-0000-000000000003','question','trivia','日本語','ja',true,'2020-01-03','2021-01-03');
          insert into public.word_prompts(id,category_id,text,locale,status,created_at,updated_at) values
            ('00000000-0000-0000-0000-000000000011','00000000-0000-0000-0000-000000000001','Vi','vi','draft','2020-02-01','2021-02-01'),
            ('00000000-0000-0000-0000-000000000012','00000000-0000-0000-0000-000000000002','English','en','published','2020-02-02','2021-02-02');
          insert into public.question_prompts(id,category_id,civilian_question,imposter_question,locale,status,created_at,updated_at)
            values('00000000-0000-0000-0000-000000000013','00000000-0000-0000-0000-000000000003','Best?','Worst?','ja','archived','2020-02-03','2021-02-03');
          alter table public.game_categories enable trigger user;
          alter table public.word_prompts enable trigger user;
          alter table public.question_prompts enable trigger user;
        """)

    def inventory(self):
        return json.loads(self.execute("""select jsonb_build_object(
          'categories',(select coalesce(jsonb_agg(to_jsonb(c) order by id),'[]') from public.game_categories c),
          'words',(select coalesce(jsonb_agg(to_jsonb(w) order by id),'[]') from public.word_prompts w),
          'questions',(select coalesce(jsonb_agg(to_jsonb(q) order by id),'[]') from public.question_prompts q),
          'objects',(select coalesce(jsonb_agg(to_jsonb(o) order by id),'[]') from storage.objects o where bucket_id='word-prompt-images'));
        """).stdout)

    def migrate(self):
        return self.execute(MIGRATION.read_text())

    def suites(self):
        helper = (ROOT / 'supabase/tests/content_test_helpers.sql').read_text()
        for name in ['category_management','word_prompt_management','question_prompt_management','admin_dashboard','content_translations']:
            with self.subTest(suite=name):
                source = (ROOT / f'supabase/tests/{name}.sql').read_text().replace('\\ir content_test_helpers.sql', helper)
                self.execute(source)

    def test_empty_database_replay_and_sql_suites(self):
        self.fresh_legacy()
        result = self.migrate()
        self.assertIn('categories=0, words=0, questions=0', result.stderr)
        self.suites()

    def test_backfill_metadata_locales_statuses_and_slug_mapping(self):
        self.fresh_legacy()
        self.seed_legacy()
        before = self.inventory()
        self.migrate()
        after = self.inventory()
        self.assertEqual(before['objects'], after['objects'])
        for kind, table, key, fields in [
            ('categories','game_category_translations','category_id',['locale','name','description']),
            ('words','word_prompt_translations','prompt_id',['locale','status','text']),
            ('questions','question_prompt_translations','prompt_id',['locale','status','civilian_question','imposter_question']),
        ]:
            translations = json.loads(self.execute(f'select jsonb_agg(to_jsonb(t) order by {key},locale) from public.{table} t;').stdout)
            self.assertEqual(len(before[kind]),len(translations))
            for old, original, translation in zip(before[kind],after[kind],translations):
                self.assertEqual(old['id'],translation[key])
                reconstructed = original | {field:translation[field] for field in fields}
                if kind == 'categories':
                    reconstructed['slug'] = old['slug']
                    self.assertEqual(translation['status'],'published')
                self.assertEqual(old,reconstructed)
                for metadata in ['created_by','created_at','updated_at']:
                    self.assertEqual(old[metadata],translation[metadata])
        self.assertEqual(after['categories'][0]['slug'],'same')
        self.assertEqual(after['categories'][1]['slug'],'same-00000000-0000-0000-0000-000000000002')
        self.assertEqual(self.execute('select string_agg(code,\',\' order by code) from public.content_languages;').stdout.strip(),'en,ja,vi')
        self.suites()

    def test_blockers_rollback_every_schema_and_data_change(self):
        self.fresh_legacy()
        self.seed_legacy()
        cases = [
            ("update public.game_categories set locale=' en ' where id='00000000-0000-0000-0000-000000000002';",'locale'),
            ("update public.word_prompts set text=chr(160) where id='00000000-0000-0000-0000-000000000011';",'invalid content'),
            ("update public.question_prompts set imposter_question=' best? ' where id='00000000-0000-0000-0000-000000000013';",'invalid content'),
            ("update public.word_prompts set category_id='00000000-0000-0000-0000-000000000003' where id='00000000-0000-0000-0000-000000000011';",'category link'),
            ("update public.word_prompts set image_path=id::text||'/00000000-0000-0000-0000-000000000099.png' where id='00000000-0000-0000-0000-000000000011';",'missing image'),
            ("insert into public.game_categories(game_type,slug,name,locale) values('word','same-00000000-0000-0000-0000-000000000002','Occupied','fr');",'resulting_slug_collision'),
        ]
        for change, message in cases:
            with self.subTest(blocker=message):
                # The failed migration rolls back its inner transaction; restore fixtures per case.
                self.execute('alter table public.game_categories disable trigger user; alter table public.word_prompts disable trigger user; alter table public.question_prompts disable trigger user;' + change)
                before = self.inventory()
                result = self.execute(MIGRATION.read_text(),success=False)
                self.assertNotEqual(result.returncode,0)
                self.assertIn(message,result.stderr)
                self.assertEqual(before,self.inventory())
                self.assertEqual(self.execute("select to_regclass('public.content_languages') is null and to_regprocedure('private.content_trim(text)') is null;").stdout.strip(),'t')
                self.fresh_legacy()
                self.seed_legacy()

    def test_live_copy_and_concurrency(self):
        legacy = self.execute("select to_regclass('public.content_languages') is null;").stdout.strip() == 't'
        before = self.inventory()
        if legacy:
            self.migrate()
            self.assertEqual(before['objects'],self.inventory()['objects'])
        self.suites()
        result = subprocess.run(['python3',str(ROOT / 'supabase/tests/category_concurrency.py')],
                                env=os.environ | {'CT_TEST_DATABASE':self.database},capture_output=True,text=True,timeout=60)
        self.assertEqual(result.returncode,0,result.stdout+result.stderr)
        print(result.stdout.strip())


if __name__ == '__main__':
    unittest.main()
