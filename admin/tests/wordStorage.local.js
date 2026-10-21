// Local integration check; creates isolated fixtures and removes them in finally.
import assert from 'node:assert/strict'
import { execFileSync } from 'node:child_process'
import { createClient } from '@supabase/supabase-js'
import { deleteWordPrompt, saveWordPrompt, listWordPrompts } from '../src/api/wordPrompts.js'
const status = JSON.parse(execFileSync('supabase', ['status', '-o', 'json'], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] }))
const url = status.API_URL
assert.ok(url?.startsWith('http://127.0.0.1:'), 'Run only against Local Supabase')
const client = key => createClient(url, key, { auth: { persistSession: false, autoRefreshToken: false } })
const service = client(status.SERVICE_ROLE_KEY), admin = client(status.ANON_KEY), user = client(status.ANON_KEY), anon = client(status.ANON_KEY)
const users = [], paths = [], category = crypto.randomUUID(), prompt = crypto.randomUUID()
const bucket = 'word-prompt-images'
const png = Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aD1sAAAAASUVORK5CYII=', 'base64')
function data(result) { if (result.error) throw result.error; return result.data }
function sql(statement) {
  return execFileSync('psql', ['postgresql://postgres:postgres@127.0.0.1:54322/postgres', '-w', '-v', 'ON_ERROR_STOP=1', '-At', '-c', statement], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] })
}
async function account(target) {
  const email = `word-delete-${crypto.randomUUID()}@example.test`, password = crypto.randomUUID()
  const { user } = data(await service.auth.admin.createUser({ email, password, email_confirm: true }))
  users.push(user.id)
  data(await target.auth.signInWithPassword({ email, password }))
  return user.id
}
try {
  const adminId = await account(admin)
  await account(user)
  sql(`insert into public.admin_users(user_id) values('${adminId}');`)
  data(await admin.from('game_categories').insert({ id: category, game_type: 'word', name: 'Storage deletion test', slug: category }))
  const path = `${prompt}/${crypto.randomUUID()}.png`; paths.push(path)
  data(await admin.storage.from(bucket).upload(path, png, { contentType: 'image/png', upsert: false }))
  const form = { category_id: category, text: 'Storage test', imposter_text: 'Ignored legacy word', imposter_hint: 'Ignored legacy hint', image_path: path, difficulty: 'medium', is_family_friendly: false, locale: 'vi' }
  let row = await saveWordPrompt(admin, form, { id: prompt, status: 'draft' })
  assert.equal('imposter_text' in row, false)
  assert.equal('imposter_hint' in row, false)
  for (const target of [anon, user]) {
    assert.ok((await target.storage.from(bucket).download(path)).error, 'draft download denied')
    assert.ok((await target.storage.from(bucket).createSignedUrl(path, 60)).error, 'draft signed URL denied')
  }
  const text = 'Edited a,b %_ " word'
  row = await saveWordPrompt(admin, { ...form, text: text }, { id: prompt, updatedAt: row.updated_at, status: 'published' })
  const result = await listWordPrompts(admin, { search: text, category, sort: 'updated_at', page: 1 })
  assert.deepEqual(result.rows.map(row => row.id), [prompt], 'literal search works after removing imposter column')
  row = await saveWordPrompt(admin, row, { id: prompt, updatedAt: row.updated_at, status: 'archived' })
  assert.equal(row.status, 'archived')
  row = await saveWordPrompt(admin, row, { id: prompt, updatedAt: row.updated_at, status: 'published' })
  for (const target of [anon, user]) {
    data(await target.storage.from(bucket).download(path))
    data(await target.storage.from(bucket).createSignedUrl(path, 60))
  }
  const signed = data(await anon.storage.from(bucket).createSignedUrl(path, 60)).signedUrl
  await deleteWordPrompt(admin, { id: prompt, updatedAt: row.updated_at })
  assert.equal(data(await admin.from('word_prompts').select('id').eq('id', prompt)).length, 0)
  assert.equal((await data(await admin.storage.from(bucket).download(path))).size, png.length, 'file bytes retained')
  for (const target of [anon, user]) {
    assert.ok((await target.storage.from(bucket).download(path)).error, 'deleted image download denied')
    assert.ok((await target.storage.from(bucket).createSignedUrl(path, 60)).error, 'new signed URL denied')
  }
  assert.equal((await fetch(signed)).status, 200, 'existing signed URL remains valid')
  const userPath = `${prompt}/${crypto.randomUUID()}.png`
  assert.ok((await user.storage.from(bucket).upload(userPath, png, { contentType: 'image/png' })).error, 'ordinary user upload denied')
  sql(`update public.admin_users set is_active = false where user_id = '${adminId}';`)
  assert.ok((await admin.storage.from(bucket).createSignedUrl(path, 60)).error, 'disabled admin denied')
  console.log('PASS: Local Storage retains deleted image, denies new player access, and preserves existing signed URL')
} finally {
  sql(`delete from public.word_prompts where category_id = '${category}'; delete from public.game_categories where id = '${category}';`)
  if (paths.length) data(await service.storage.from(bucket).remove(paths))
  for (const id of users) data(await service.auth.admin.deleteUser(id))
}
