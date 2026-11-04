import type { AdminDatabase, AdminClient } from '../src/types/admin.ts'
import { wordPromptFilters } from '../src/utils/wordPrompts.ts'

// Local integration check; creates isolated fixtures and removes them in finally.
import assert from 'node:assert/strict'
import { execFileSync } from 'node:child_process'
import { createClient } from '@supabase/supabase-js'
import { saveCategory, setCategoryActive } from '../src/api/categories.ts'
import { deleteWordPrompt, saveWordPrompt, listWordPrompts } from '../src/api/wordPrompts.ts'
const status = JSON.parse(execFileSync('supabase', ['status', '-o', 'json'], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] }))
const url = status.API_URL
assert.ok(url?.startsWith('http://127.0.0.1:'), 'Run only against Local Supabase')
const client = (key: string) => createClient<AdminDatabase>(url, key, { auth: { persistSession: false, autoRefreshToken: false } })
const service = client(status.SERVICE_ROLE_KEY), admin = client(status.ANON_KEY), user = client(status.ANON_KEY), anon = client(status.ANON_KEY)
const users: string[] = [], paths: string[] = [], category = crypto.randomUUID(), prompt = crypto.randomUUID()
const bucket = 'word-prompt-images'
const png = Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aD1sAAAAASUVORK5CYII=', 'base64')
function data<R extends { data: unknown; error?: unknown }>(result: R): R['data'] { if (result.error) throw result.error; return result.data }
function sql(statement: string) {
  return execFileSync('psql', ['postgresql://postgres:postgres@127.0.0.1:54322/postgres', '-w', '-v', 'ON_ERROR_STOP=1', '-At', '-c', statement], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] })
}
async function account(target: AdminClient) {
  const email = `word-delete-${crypto.randomUUID()}@example.test`, password = crypto.randomUUID()
  const { user } = data(await service.auth.admin.createUser({ email, password, email_confirm: true }))
  assert.ok(user)
  users.push(user.id)
  data(await target.auth.signInWithPassword({ email, password }))
  return user.id
}
try {
  console.log('Storage: creating isolated accounts')
  const adminId = await account(admin)
  await account(user)
  sql(`insert into public.admin_users(user_id) values('${adminId}');`)
  await saveCategory(admin, { game_type: 'word', name: 'Storage deletion test', slug: category, locale: 'vi', status: 'published', description: '', sort_order: 0, is_active: true }, category)
  console.log('Storage: uploading image')
  const path = `${prompt}/${crypto.randomUUID()}.png`; paths.push(path)
  data(await admin.storage.from(bucket).upload(path, png, { contentType: 'image/png', upsert: false }))
  const form = { category_id: category, text: 'Storage test', imposter_text: 'Ignored legacy word', imposter_hint: 'Ignored legacy hint', image_path: path, difficulty: 'medium', locale: 'vi' }
  console.log('Storage: saving draft')
  let result = await saveWordPrompt(admin, form, { id: prompt, status: 'draft' })
  let row = { ...result.translation, ...result.original }
  assert.equal('imposter_text' in row, false)
  assert.equal('imposter_hint' in row, false)
  for (const target of [anon, user]) {
    assert.ok((await target.storage.from(bucket).download(path)).error, 'draft download denied')
    assert.ok((await target.storage.from(bucket).createSignedUrl(path, 60)).error, 'draft signed URL denied')
  }
  console.log('Storage: publishing and searching')
  const text = 'Edited a,b %_ " word'
  result = await saveWordPrompt(admin, { ...form, text: text }, { id: prompt, updatedAt: row.updated_at, status: 'published' })
  row = { ...result.translation, ...result.original }
  const listing = await listWordPrompts(admin, wordPromptFilters({ search: text, category, sort: 'updated_at' }))
  assert.deepEqual(listing.rows!.map(row => row.id), [prompt], 'literal search works after removing imposter column')
  console.log('Storage: translation visibility and shared category state')
  let savedCategory = await saveCategory(admin, { game_type: 'word', name: 'English category', slug: category, locale: 'en', status: 'published', description: '', sort_order: 0, is_active: true }, category,
    data(await admin.from('game_categories').select('updated_at').eq('id', category).single())!.updated_at)
  result = await saveWordPrompt(admin, { ...row, locale: 'en', text: 'English storage test' }, { id: prompt, updatedAt: row.updated_at, status: 'draft' })
  row = { ...result.translation, ...result.original }
  data(await anon.storage.from(bucket).download(path))
  result = await saveWordPrompt(admin, { ...row, locale: 'vi', text }, { id: prompt, updatedAt: row.updated_at, status: 'archived' })
  row = { ...result.translation, ...result.original }
  assert.ok((await anon.storage.from(bucket).download(path)).error, 'English draft cannot expose an image after Vietnamese archive')
  result = await saveWordPrompt(admin, { ...row, locale: 'en', text: 'English storage test' }, { id: prompt, updatedAt: row.updated_at, status: 'published' })
  row = { ...result.translation, ...result.original }
  data(await anon.storage.from(bucket).download(path))
  savedCategory = await saveCategory(admin, { ...savedCategory.original, locale: 'en', name: 'English category', description: '', status: 'archived' }, category, savedCategory.original.updated_at)
  assert.ok((await anon.storage.from(bucket).download(path)).error, 'archived category translation hides its image')
  savedCategory = await saveCategory(admin, { ...savedCategory.original, locale: 'en', name: 'English category', description: '', status: 'published' }, category, savedCategory.original.updated_at)
  data(await anon.storage.from(bucket).download(path))
  await setCategoryActive(admin, savedCategory.original, false)
  assert.ok((await anon.storage.from(bucket).download(path)).error, 'inactive category hides every language')
  const inactive = data(await admin.from('game_categories').select('*').eq('id', category).single())!
  await setCategoryActive(admin, inactive, true)
  data(await anon.storage.from(bucket).download(path))
  console.log('Storage: failed saves clean new uploads and retain the shared image')
  const beforeFiles = data(await service.storage.from(bucket).list(prompt))!.map(file => file.name).sort()
  const file = new File([Uint8Array.from(png)], 'test.png', { type: 'image/png' })
  await assert.rejects(saveWordPrompt(admin, row, { id: prompt, updatedAt: '2000-01-01T00:00:00Z', status: 'published', file }),
    error => (error as { code?: string }).code === 'PT409')
  assert.deepEqual(data(await service.storage.from(bucket).list(prompt))!.map(file => file.name).sort(), beforeFiles, 'conflicted save removes only its new upload')
  await assert.rejects(saveWordPrompt(user, row, { id: prompt, updatedAt: row.updated_at, status: 'published', file }))
  assert.deepEqual(data(await service.storage.from(bucket).list(prompt))!.map(file => file.name).sort(), beforeFiles, 'rejected upload leaves no file')
  data(await anon.storage.from(bucket).download(path))
  result = await saveWordPrompt(admin, row, { id: prompt, updatedAt: row.updated_at, status: 'archived' })
  row = { ...result.translation, ...result.original }
  assert.equal(row.status, 'archived')
  result = await saveWordPrompt(admin, row, { id: prompt, updatedAt: row.updated_at, status: 'published' })
  row = { ...result.translation, ...result.original }
  for (const target of [anon, user]) {
    data(await target.storage.from(bucket).download(path))
    data(await target.storage.from(bucket).createSignedUrl(path, 60))
  }
  console.log('Storage: deleting and verifying retained bytes')
  const signed = data(await anon.storage.from(bucket).createSignedUrl(path, 60))!.signedUrl
  await deleteWordPrompt(admin, { id: prompt, updatedAt: row.updated_at })
  assert.equal(data(await admin.from('word_prompts').select('id').eq('id', prompt))!.length, 0)
  assert.equal((await data(await admin.storage.from(bucket).download(path)))!.size, png.length, 'file bytes retained')
  for (const target of [anon, user]) {
    assert.ok((await target.storage.from(bucket).download(path)).error, 'deleted image download denied')
    assert.ok((await target.storage.from(bucket).createSignedUrl(path, 60)).error, 'new signed URL denied')
  }
  assert.equal((await fetch(signed)).status, 200, 'existing signed URL remains valid')
  const userPath = `${prompt}/${crypto.randomUUID()}.png`
  assert.ok((await user.storage.from(bucket).upload(userPath, png, { contentType: 'image/png' })).error, 'ordinary user upload denied')
  sql(`update public.admin_users set is_active = false where user_id = '${adminId}';`)
  assert.ok((await admin.storage.from(bucket).createSignedUrl(path, 60)).error, 'disabled admin denied')
  console.log('PASS: Local Storage enforces multilingual visibility, cleans failed uploads, retains deleted images and preserves existing signed URLs')
} finally {
  sql(`begin; select id from public.game_categories where id = '${category}' for update; delete from public.word_prompts where category_id = '${category}'; delete from public.game_categories where id = '${category}'; commit;`)
  if (paths.length) data(await service.storage.from(bucket).remove(paths))
  for (const id of users) data(await service.auth.admin.deleteUser(id))
}
