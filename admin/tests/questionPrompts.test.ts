import { asClient } from './helpers.ts'
import type { QueryStub, MockResult, Calls } from './helpers.ts'
import test from 'node:test'
import assert from 'node:assert/strict'
import { deleteQuestionPrompt, saveQuestionPrompt, listQuestionPrompts, questionCategories } from '../src/api/questionPrompts.ts'
import { questionPromptPayload, questionPromptFilters, questionPromptError } from '../src/utils/questionPrompts.ts'
const id = '00000000-0000-4000-8000-000000000001'
const form = { civilian_question: '  Favourite food?  ', imposter_question: ' Worst food? ', category_id: id, difficulty: 'medium', is_family_friendly: false, locale: 'vi' }
function mockQuery(result: MockResult) {
  const calls: Calls = [], query = {} as QueryStub
  for (const method of ['select', 'eq', 'or', 'order', 'range', 'update', 'insert', 'maybeSingle']) query[method] = (...args: unknown[]) => { calls.push([method, ...args]); return query }
  query.then = resolve => resolve(result)
  return { query, calls }
}
test('question payload trims, requires distinct questions in every state and excludes hint', () => {
  for (const status of ['draft', 'published', 'archived']) {
    assert.deepEqual(questionPromptPayload({ ...form, imposter_hint: 'ignored' }, status), { ...form, civilian_question: 'Favourite food?', imposter_question: 'Worst food?', status })
    for (const field of ['civilian_question', 'imposter_question']) for (const value of ['', ' \n\t', null]) assert.throws(() => questionPromptPayload({ ...form, [field]: value }, status))
    assert.throws(() => questionPromptPayload({ ...form, imposter_question: ' FAVOURITE FOOD? ' }, status), /sameQuestions/)
    assert.throws(() => questionPromptPayload({ ...form, civilian_question: '\u00a0\ufeff' }, status))
  }
  assert.throws(() => questionPromptPayload(form, 'other'))
})
test('question listing searches both fields, filters and paginates with stable sorts', async () => {
  for (const sort of ['updated_at', 'civilian_question']) {
    const { query, calls } = mockQuery({ data: [], count: 21 })
    const filters = questionPromptFilters({ search: 'a,b', category: id, locale: 'vi', status: 'archived', family: 'false', difficulty: 'hard', page: '2', sort })
    assert.deepEqual(await listQuestionPrompts(asClient({ from: (table: string) => { assert.equal(table, 'question_prompts'); return query } }), filters), { rows: [], total: 21 })
    assert.deepEqual(calls.at(-1), ['range', 20, 39])
    assert.deepEqual(calls.filter(call => call[0] === 'order'), [['order', sort, { ascending: sort === 'civilian_question' }], ['order', 'id']])
    assert.deepEqual(calls.find(call => call[0] === 'or'), ['or', 'civilian_question.ilike."%a,b%",imposter_question.ilike."%a,b%"'])
    for (const [field, value] of Object.entries({ category_id: id, locale: 'vi', status: 'archived', difficulty: 'hard', is_family_friendly: false })) assert.ok(calls.some(call => call[0] === 'eq' && call[1] === field && call[2] === value))
  }
  assert.equal(questionPromptFilters({ page: '-1', sort: 'text', status: 'bad' }).page, 1)
  assert.equal(questionPromptFilters({ sort: 'text' }).sort, 'updated_at')
})
test('question saves use a version predicate and authenticated creator, propagating errors', async () => {
  const { query, calls } = mockQuery({ data: { id } })
  const client = { auth: { getUser: async () => ({ data: { user: { id } as { id: string } | null } }) }, from: () => query }
  await saveQuestionPrompt(asClient(client), form, { id, status: 'draft' })
  assert.deepEqual(calls.find(call => call[0] === 'insert')![1], { ...questionPromptPayload(form, 'draft'), id, created_by: id })
  calls.length = 0
  await saveQuestionPrompt(asClient(client), form, { id, status: 'published', updatedAt: 'snapshot' })
  assert.ok(calls.some(call => call[0] === 'eq' && call[1] === 'updated_at' && call[2] === 'snapshot'))
  client.from = () => mockQuery({ data: null }).query
  await assert.rejects(saveQuestionPrompt(asClient(client), form, { id, status: 'draft', updatedAt: 'old' }), /conflict/)
  client.from = () => mockQuery({ error: { code: '42501' } }).query
  await assert.rejects(saveQuestionPrompt(asClient(client), form, { id, status: 'draft' }), error => questionPromptError(error) === 'common.errors.forbidden')
  client.auth.getUser = async () => ({ data: { user: null } })
  await assert.rejects(saveQuestionPrompt(asClient(client), form, { id, status: 'draft' }), /sessionExpired/)
})
test('question deletion sends only the snapshot and maps permission, missing and conflict errors', async () => {
  const calls: Calls = [], client: { rpc: (...args: unknown[]) => Promise<MockResult> } = { rpc: async (...args: unknown[]) => { calls.push(args); return { data: null } } }
  await deleteQuestionPrompt(asClient(client), Object.assign({ id, updatedAt: 'version' }, { imposter_hint: 'ignored' }))
  assert.deepEqual(calls, [['delete_question_prompt', { p_id: id, p_expected_updated_at: 'version' }]])
  for (const [code, key] of [['40001', 'questionPrompts.errors.conflict'], ['P0002', 'questionPrompts.errors.notFound'], ['42501', 'common.errors.forbidden']]) {
    client.rpc = async () => ({ error: { code } })
    await assert.rejects(deleteQuestionPrompt(asClient(client), { id, updatedAt: 'version' }), error => questionPromptError(error) === key)
  }
})
test('question category discovery paginates and limits form options to active matching locale', async () => {
  const calls: Calls[] = []
  let page = 0
  const client = { from: () => { const mock = mockQuery({ data: page++ === 0 ? Array.from({ length: 100 }, () => ({ id })) : [] }); calls.push(mock.calls); return mock.query } }
  assert.equal((await questionCategories(asClient(client), 'vi')).length, 100)
  assert.equal(calls.length, 2)
  for (const pageCalls of calls) for (const filter of [['eq', 'game_type', 'question'], ['eq', 'locale', 'vi'], ['eq', 'is_active', true]]) assert.ok(pageCalls.some(call => JSON.stringify(call) === JSON.stringify(filter)))
})
