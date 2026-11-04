"""Upload bundled sample images to local Supabase, then verify anonymous reads.

Run from any directory after applying migrations. Applies supabase/seed.sql too.
"""

import json
from pathlib import Path
import subprocess
from urllib.request import Request, urlopen
from uuid import UUID


ROOT = Path(__file__).resolve().parents[2]
BUCKET = 'word-prompt-images'


def main():
    status = json.loads(subprocess.check_output(
        ['supabase', 'status', '-o', 'json'], cwd=ROOT, stderr=subprocess.DEVNULL))
    api = status['API_URL']
    if api != 'http://127.0.0.1:54321':
        raise RuntimeError('This script only seeds the default local Supabase stack')

    def sql(query):
        subprocess.run(['docker', 'exec', '-i', 'supabase_db_imposter-wording',
                        'psql', '-U', 'postgres', '-d', 'postgres', '-v', 'ON_ERROR_STOP=1'],
                       input=query, text=True, check=True, stdout=subprocess.DEVNULL)

    sql((ROOT / 'supabase/seed.sql').read_text())

    def request(path, key, data=None, headers=None):
        req = Request(api + path, data=data, headers={
            'apikey': key, 'Authorization': f'Bearer {key}', **(headers or {})})
        with urlopen(req, timeout=30) as response:
            return response.read()

    images = sorted((ROOT / 'supabase/seed-images').glob('*.png'))
    assert len(images) == 25, 'Expected 25 bundled images'
    updates = []
    for image in images:
        prompt_id = str(UUID(image.stem))
        path = f'{prompt_id}/{prompt_id}.png'
        data = image.read_bytes()
        assert data.startswith(b'\x89PNG\r\n\x1a\n'), f'Invalid PNG: {image}'
        request(f'/storage/v1/object/{BUCKET}/{path}', status['SERVICE_ROLE_KEY'],
                data, {'Content-Type': 'image/png', 'x-upsert': 'true'})
        updates.append(f"update public.word_prompts set image_path = '{path}' "
                       f"where id = '{prompt_id}' and image_path is null;")

    # Preserve images already changed by an admin when re-running the seed.
    sql('begin;\n' + '\n'.join(updates) + '\ncommit;')

    anon = status['ANON_KEY']
    categories = json.loads(request(
        '/rest/v1/game_categories?slug=like.sample-*&select=id,game_type', anon))
    assert len(categories) == 10, 'Expected 10 visible sample categories'
    for category in categories:
        for locale in ('vi', 'en'):
            translations = json.loads(request(
                f"/rest/v1/game_category_translations?category_id=eq.{category['id']}&locale=eq.{locale}", anon))
            assert len(translations) == 1 and translations[0]['status'] == 'published'
        table = 'word_prompts' if category['game_type'] == 'word' else 'question_prompts'
        prompts = json.loads(request(
            f"/rest/v1/{table}?category_id=eq.{category['id']}&select=*", anon))
        assert len(prompts) == 5, f'Expected 5 visible prompts: {category}'
        for prompt in prompts:
            translation_table = 'word_prompt_translations' if table == 'word_prompts' else 'question_prompt_translations'
            for locale in ('vi', 'en'):
                translations = json.loads(request(
                    f"/rest/v1/{translation_table}?prompt_id=eq.{prompt['id']}&locale=eq.{locale}", anon))
                assert len(translations) == 1 and translations[0]['status'] == 'published'
            if table == 'word_prompts':
                assert prompt['image_path'], 'Missing word image'
                signed = json.loads(request(
                    f"/storage/v1/object/sign/{BUCKET}/{prompt['image_path']}", anon,
                    json.dumps({'expiresIn': 60}).encode(), {'Content-Type': 'application/json'}))
                content = request('/storage/v1' + signed['signedURL'], anon)
                assert content.startswith(b'\x89PNG\r\n\x1a\n'), 'Image download failed'
    print('Verified: 10 categories and 50 prompts published in both Vietnamese and English, 25 downloadable images.')


if __name__ == '__main__':
    main()
