"""Read-only audit checks. DB_URL overrides the running local Supabase connection.

Fixtures replace source CTEs with typed JSON recordsets; no fixture rows are written.
"""
import json
import os
from pathlib import Path
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[2]
AUDIT = (ROOT / 'supabase/scripts/audit_content_translations.sql').read_text()
DB_URL = os.environ.get('DB_URL')
if not DB_URL:
    DB_URL = json.loads(subprocess.check_output(
        ['supabase', 'status', '-o', 'json'], cwd=ROOT, stderr=subprocess.DEVNULL,
    ))['DB_URL']


def query(sql):
    result = subprocess.run(
        ['psql', DB_URL, '-X', '-qAt', '-v', 'ON_ERROR_STOP=1'],
        input=sql, text=True, capture_output=True, timeout=30,
    )
    if result.returncode:
        raise AssertionError(result.stderr)
    return [json.loads(line) for line in result.stdout.splitlines()]


def fixture(categories=(), words=(), questions=(), objects=()):
    sql = AUDIT.split('with targets as (', 1)[0] + '\nrollback;'
    for table, rows in (
        ('public.game_categories', categories), ('public.word_prompts', words),
        ('public.question_prompts', questions),
    ):
        value = json.dumps(list(rows)).replace("'", "''")
        source = f'select * from {table}'
        assert sql.count(source) == 1
        sql = sql.replace(source, f"select * from jsonb_populate_recordset(null::{table}, '{value}'::jsonb)", 1)
    value = json.dumps(list(objects)).replace("'", "''")
    sql = sql.replace("select name from storage.objects where bucket_id = 'word-prompt-images'",
                      f"select name from jsonb_to_recordset('{value}'::jsonb) as o(name text)", 1)
    return query(sql)[0]


def category(number, locale='vi', slug='same', game_type='word', active=True):
    return dict(id=f'00000000-0000-0000-0000-{number:012d}', locale=locale,
                slug=slug, game_type=game_type, name="Nhóm O'Brien", sort_order=0, is_active=active)


class AuditTests(unittest.TestCase):
    def test_empty(self):
        data = fixture()
        self.assertEqual(data['languages'], ['en', 'vi'])
        self.assertEqual(data['blockers'], [])
        self.assertEqual(data['source_manifest'], [])
        self.assertTrue(all(c == dict(source=0, expected_originals=0, expected_translations=0)
                            for c in data['counts'].values()))

    def test_mapping_preserves_rows_locales_and_statuses(self):
        categories = [category(1), category(2, locale='en', active=False), category(3, locale='ja')]
        words = [dict(id=category(10 + i)['id'], category_id=c['id'], locale=c['locale'],
                      status=status, text="O'Brien", image_path=None)
                 for i, (c, status) in enumerate(zip(categories, ['draft', 'published', 'archived']))]
        data = fixture(categories=categories, words=words)
        self.assertEqual(data['blockers'], [])
        self.assertEqual(data['languages'], ['en', 'ja', 'vi'])
        self.assertEqual(data['counts']['category']['expected_translations'], 3)
        self.assertEqual(data['counts']['word']['expected_originals'], 3)
        self.assertEqual(len(data['source_manifest']), 6)
        self.assertEqual({r['status'] for r in data['source_manifest'] if r['kind'] == 'word'},
                         {'draft', 'published', 'archived'})
        self.assertTrue(all(r['status'] == 'published' for r in data['source_manifest'] if r['kind'] == 'category'))
        self.assertEqual([m['id'] for m in data['slug_changes']], [categories[1]['id'], categories[2]['id']])
        for change in data['slug_changes']:
            self.assertEqual(change['new_slug'], 'same-' + change['id'])
        # Same slug in another game type is independent; input order cannot choose the winner.
        reordered = fixture(categories=[category(4, game_type='question'), *reversed(categories)], words=words)
        self.assertEqual(reordered['slug_changes'], data['slug_changes'])

    def test_generated_slug_collision_blocks(self):
        first, second = category(1), category(2, locale='en')
        occupied = category(3, slug='same-' + second['id'])
        data = fixture(categories=[second, occupied, first])
        self.assertEqual({i['id'] for i in data['blockers'] if i['issue'] == 'resulting_slug_collision'},
                         {second['id'], occupied['id']})

    def test_invalid_content_links_and_images_are_reported(self):
        c = category(1)
        data = fixture(categories=[c, category(2, locale=' fr '), category(3, locale='\u00a0'),
                                   category(4, slug='INVALID')],
                       words=[dict(id=category(10)['id'], category_id=c['id'], locale='en',
                                   status='draft', text='\u00a0', image_path='missing.png')],
                       questions=[dict(id=category(11)['id'], category_id=c['id'], locale='vi',
                                       status='archived', civilian_question=' Same? ', imposter_question='SAME?')])
        self.assertEqual({i['issue'] for i in data['blockers']},
                         {'invalid_locale', 'locale_needs_review', 'invalid_category', 'invalid_word',
                          'invalid_questions', 'category_link_mismatch', 'missing_image', 'invalid_image_path'})
        self.assertIn(' fr ', data['languages'])

    def test_images_and_missing_parent(self):
        c = category(1)
        image = category(10)['id'] + '/' + category(20)['id'] + '.webp'
        word = dict(id=category(10)['id'], category_id=category(99)['id'], locale='vi',
                    status='published', text='Valid', image_path=image)
        data = fixture(categories=[c], words=[word], objects=[{'name': image}, {'name': 'retained.png'}])
        self.assertEqual([i['issue'] for i in data['blockers']], ['category_link_mismatch'])
        self.assertEqual(data['images']['references'], 1)
        self.assertEqual(data['images']['unreferenced_objects'], 1)

    def test_live_audit_is_read_only_and_repeatable(self):
        before = query(AUDIT)
        after = query(AUDIT)
        self.assertEqual(before, after)
        self.assertEqual(before[0]['read_only'], 'on')
        self.assertEqual(before[0]['isolation'], 'repeatable read')
        self.assertTrue(before[0]['rls_bypassed'], 'Use postgres so RLS cannot hide rows')
        self.assertEqual(len(before[0]['source_manifest']), sum(c['source'] for c in before[0]['counts'].values()))
        self.assertIn('category_before_write', {t['name'] for t in before[1]['triggers']})
        self.assertIn('delete_category', {f['name'] for f in before[1]['functions']})


if __name__ == '__main__':
    unittest.main()
