import test from 'node:test'
import assert from 'node:assert/strict'
import { deleteWordPrompt, saveWordPrompt, listWordPrompts } from '../src/api/wordPrompts.js'
import { wordPromptPayload, wordPromptFilters, wordPromptError, validateImage } from '../src/utils/wordPrompts.js'
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
  const calls = [], client = { rpc: async (...args) => { calls.push(args); return { data: null } } }
  await deleteWordPrompt(client, { id, updatedAt: 'version', confirmation: 'XÓA', form: { text: '' }, file: {} })
  assert.deepEqual(calls, [['delete_word_prompt', { p_id: id, p_expected_updated_at: 'version', p_confirmation: 'XÓA' }]])
  for (const error of [new Error('offline'), { code: '40001' }, { code: 'P0002' }]) {
    client.rpc = async () => ({ error })
    await assert.rejects(deleteWordPrompt(client, { id }), value => value === error)
  }
  assert.equal(wordPromptError({ code: '40001' }), 'wordPrompts.errors.conflict')
  assert.equal(wordPromptError({ code: 'P0002' }), 'wordPrompts.errors.notFound')
  assert.equal(wordPromptError({ code: '22023' }), 'wordPrompts.errors.confirmation')
})
test('list combines URL filters and stable pagination', async () => {
  const calls = [], query = {}
  for (const method of ['select', 'eq', 'or', 'order', 'range']) query[method] = (...args) => { calls.push([method, ...args]); return query }
  query.then = resolve => resolve({ data: [], count: 21 })
  const filters = wordPromptFilters({ search: 'a,b', category: id, status: 'archived', family: 'false', difficulty: 'hard', page: '2' })
  const result = await listWordPrompts({ from: () => query }, filters)
  assert.equal(result.total, 21)
  assert.deepEqual(calls.at(-1), ['range', 20, 39])
  assert.ok(calls.some(call => call[0] === 'eq' && call[1] === 'is_family_friendly' && call[2] === false))
  assert.deepEqual(calls.find(call => call[0] === 'or'), ['or', 'text.ilike."%a,b%"'])
  assert.equal(wordPromptFilters({ page: '-1', status: 'bad' }).page, 1)
  for (const sort of ['text', 'civilian_text']) assert.equal(wordPromptFilters({ sort }).sort, 'text')
  assert.equal(wordPromptFilters({ sort: 'unexpected' }).sort, 'updated_at')
})
test('save conflicts keep the original error even if image cleanup fails', async () => {
  const calls = [], query = {}
  for (const method of ['update', 'eq', 'select', 'maybeSingle']) query[method] = (...args) => { calls.push([method, ...args]); return query }
  query.then = resolve => resolve({ data: null })
  const client = { auth: { getUser: async () => ({ data: { user: { id } } }) }, from: () => query,
    storage: { from: () => ({ upload: async () => ({ data: {} }), remove: async () => { throw new Error('cleanup offline') } }) } }
  await assert.rejects(saveWordPrompt(client, form, { id, status: 'draft', updatedAt: 'snapshot', file: { type: 'image/png', size: 1 } }), /wordPrompts.errors.conflict/)
  assert.ok(calls.some(call => call[0] === 'eq' && call[1] === 'updated_at' && call[2] === 'snapshot'))
})
