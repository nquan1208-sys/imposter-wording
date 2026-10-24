import { asClient } from './helpers.ts'
import type { QueryStub, MockResult, Calls } from './helpers.ts'
import test from 'node:test'
import assert from 'node:assert/strict'
import { deleteWordPrompt, saveWordPrompt, listWordPrompts, wordCategories } from '../src/api/wordPrompts.ts'
import { wordPromptPayload, wordPromptFilters, wordPromptError, validateImage } from '../src/utils/wordPrompts.ts'
const id = '00000000-0000-4000-8000-000000000001'
const form = { text: '  Apple  ', image_path: '', category_id: id, difficulty: 'medium', is_family_friendly: false, locale: 'vi' }
test('word payload trims optional fields and validates all states', () => {
  for (const status of ['draft', 'published', 'archived']) {
    assert.deepEqual(wordPromptPayload(form, status), { ...form, text: 'Apple', image_path: null, status })
    assert.throws(() => wordPromptPayload({ ...form, text: ' ' }, status))
  }
  assert.deepEqual(wordPromptPayload({ ...form, civilian_text: 'Legacy name', imposter_text: 'Legacy word', imposter_hint: 'Legacy hint' }, 'draft'), wordPromptPayload(form, 'draft'))
  assert.throws(() => wordPromptPayload(form, 'other'))
  assert.throws(() => validateImage({ type: 'image/gif', size: 2 }))
  assert.throws(() => validateImage({ type: 'image/png', size: 5242881 }))
  assert.throws(() => validateImage({ type: 'image/png', size: 0 }))
})
test('delete passes saved snapshot only, without auth, validation, save or upload', async () => {
  const calls: Calls = [], client: { rpc: (...args: unknown[]) => Promise<MockResult> } = { rpc: async (...args: unknown[]) => { calls.push(args); return { data: null } } }
  await deleteWordPrompt(asClient(client), Object.assign({ id, updatedAt: 'version' }, { form: { text: '' }, file: {} }))
  assert.deepEqual(calls, [['delete_word_prompt', { p_id: id, p_expected_updated_at: 'version' }]])
  for (const error of [new Error('offline'), { code: 'PT409' }, { code: 'P0002' }]) {
    client.rpc = async () => ({ error })
    await assert.rejects(deleteWordPrompt(asClient(client), { id, updatedAt: 'version' }), value => value === error)
  }
  for (const code of ['PT409', '40001']) assert.equal(wordPromptError({ code }), 'wordPrompts.errors.conflict')
  assert.equal(wordPromptError({ code: 'P0002' }), 'wordPrompts.errors.notFound')
  assert.equal(wordPromptError({ code: '22023' }), 'wordPrompts.errors.invalidData')
})

test('word list passes selected language, filters and pagination to one RPC', async () => {
 const filters = wordPromptFilters({ search: ' a,b %_ ', category: id, difficulty: 'hard', family: 'false', status: 'archived', page: '2', sort: 'text' })
 const calls: Calls = []
 const client = asClient({ rpc: async (...args: unknown[]) => { calls.push(args); return { data: { rows: [], total: 21 } } } })
 assert.deepEqual(await listWordPrompts(client, filters), { rows: [], total: 21 })
 assert.deepEqual(calls, [['admin_list_word_prompts', { p_locale: 'vi', p_search: 'a,b %_', p_category_id: id, p_difficulty: 'hard', p_is_family_friendly: false, p_status: 'archived', p_sort: 'text', p_page: 2 }]])
 assert.equal(wordPromptFilters({ page: '-1', locale: '' }).page, 1)
 assert.equal(wordPromptFilters({}).locale, 'vi')
})
test('word save sends one translation and original version through transactional RPC', async () => {
 const calls: Calls = []
 const result = { original: { id, updated_at: 'new-version' }, translation: { locale: 'vi', status: 'draft' } }
 const client = { rpc: async (...args: unknown[]): Promise<MockResult> => { calls.push(args); return { data: result } } }
 assert.deepEqual(await saveWordPrompt(asClient(client), form, { id, status: 'draft' }), result)
 assert.equal(calls[0]![0], 'save_word_prompt')
 assert.equal((calls[0]![1] as Record<string, unknown>).p_expected_updated_at, null)
 await saveWordPrompt(asClient(client), form, { id, status: 'published', updatedAt: 'snapshot' })
 const payload = calls[1]![1] as Record<string, unknown>
 assert.equal(payload.p_expected_updated_at, 'snapshot'); assert.equal(payload.p_locale, 'vi'); assert.equal(payload.p_status, 'published')
 assert.equal(payload.p_text, form.text.trim());
 for (const error of [new Error('offline'), { code: 'PT409' }, { code: '42501' }]) {
   client.rpc = async () => ({ error })
   await assert.rejects(saveWordPrompt(asClient(client), form, { id, status: 'draft' }), value => value === error)
 }
})

test('failed word RPC cleans the new upload and preserves the original error', async () => {
 const failure = { code: 'PT409' }, removed: string[][] = []
 let uploaded = ''
 const client = asClient({ rpc: async () => ({ error: failure }), storage: { from: () => ({
  upload: async (path: string) => { uploaded = path; return { data: {} } },
  remove: async (paths: string[]) => { removed.push(paths); throw new Error('offline cleanup') },
 }) } })
 await assert.rejects(saveWordPrompt(client, form, { id, status: 'draft', file: new File(['x'], 'image.png', { type: 'image/png' }) }), error => error === failure)
 assert.deepEqual(removed, [[uploaded]]); assert.ok(uploaded.startsWith(id + '/'))
})

test('word category discovery reads all pages and labels only the selected language', async () => {
 let requests = 0
 const calls: Calls = []
 const client = asClient({ from: () => {
  const query = {} as QueryStub
  for (const method of ['select', 'eq', 'order', 'range']) query[method] = (...args: unknown[]) => { calls.push([method, ...args]); return query }
  query.then = resolve => resolve({ data: requests++ === 0 ? Array.from({ length: 100 }, () => ({ id, slug: 'fallback-slug', is_active: false, translations: [{ locale: 'vi', name: 'Vietnamese' }] })) : [] })
  return query
 } })
 const rows = await wordCategories(client, 'en')
 assert.equal(requests, 2); assert.equal(rows.length, 100); assert.equal(rows[0]!.name, null)
 assert.ok(calls.some(call => call[0] === 'eq' && call[1] === 'game_type' && call[2] === 'word'))
 assert.ok(!calls.some(call => call[0] === 'eq' && call[1] === 'locale'), 'category identity is shared')
})
