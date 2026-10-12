import test from 'node:test'
import assert from 'node:assert/strict'
import { categoryPayload, slugFromName, searchPattern, listFilters, categoryError } from '../src/utils/categories.js'
import { listCategories, getCategory, saveCategory, setCategoryActive, previewCategoryDelete, transferTargets, deleteCategory } from '../src/api/categories.js'
import { QueryClient, MutationObserver } from '@tanstack/vue-query'

const form = { name: '  Đồ ăn  ', slug: 'do-an', description: '  Món ngon ', game_type: 'word', sort_order: '2', is_active: true, locale: 'en', id: 'injected', created_by: 'injected' }
function mockClient(result = { data: [], count: 0 }) {
  const calls = []
  const chain = { then(resolve, reject) { return Promise.resolve(typeof result === 'function' ? result(calls) : result).then(resolve, reject) } }
  for (const method of ['select', 'eq', 'neq', 'or', 'order', 'range', 'single', 'update', 'insert']) chain[method] = (...args) => { calls.push([method, ...args]); return chain }
  return { calls, from: table => { calls.push(['from', table]); return chain }, auth: { getUser: async () => ({ data: { user: { id: 'admin' } } }) } }
}

test('Vietnamese slug normalization', () => {
  assert.equal(slugFromName(' Đồ ăn & thức uống! '), 'do-an-thuc-uong')
  assert.equal(slugFromName('!!!'), '')
})
test('payload trims and excludes protected fields', () => {
  assert.deepEqual(categoryPayload(form), { name: 'Đồ ăn', slug: 'do-an', description: 'Món ngon', sort_order: 2, is_active: true, game_type: 'word', locale: 'vi' })
  const edited = categoryPayload(form, true)
  for (const key of ['game_type', 'locale', 'created_by', 'id']) assert.equal(key in edited, false)
})
test('reject invalid names, slugs, types, and sort orders', () => {
  for (const changes of [{ name: ' ' }, { slug: 'Đồ ăn' }, { slug: '-food' }, { game_type: 'other' }, { sort_order: '' }, { sort_order: -1 }, { sort_order: 1.5 }, { sort_order: 2147483648 }]) assert.throws(() => categoryPayload({ ...form, ...changes }))
})
test('quoted search escapes wildcards, quotes and filter delimiters', () => {
  assert.equal(searchPattern('a,b)(c'), '"%a,b)(c%"')
  assert.equal(searchPattern('a"b'), '"%a\\"b%"')
  assert.equal(searchPattern('%_'), '"%\\\\%\\\\_%"')
})
test('URL filters reject invalid page and sort values', () => {
  assert.deepEqual(listFilters({ page: '-1', type: 'bad', active: 'yes', sort: 'injected' }), { page: 1, search: '', gameType: '', active: '', sort: 'sort_order' })
  assert.equal(listFilters({ page: '2' }).page, 2)
})
test('backend search/filter/order/pagination are combined', async () => {
  const client = mockClient({ data: [{ id: '1' }], count: 24 })
  const result = await listCategories(client, { search: '  food,drink ', gameType: 'word', active: 'false', sort: 'updated_at', page: 2 })
  assert.equal(result.total, 24)
  assert.ok(client.calls.some(call => call[0] === 'or' && call[1] === 'name.ilike."%food,drink%",slug.ilike."%food,drink%"'))
  assert.ok(client.calls.some(call => call[0] === 'eq' && call[1] === 'is_active' && call[2] === false))
  assert.deepEqual(client.calls.at(-1), ['range', 20, 39])
})
test('save creation gets current user and edit cannot change identity', async () => {
  const client = mockClient({ data: { id: 'new' } })
  await saveCategory(client, form)
  assert.equal(client.calls.find(call => call[0] === 'insert')[1].created_by, 'admin')
  const updateClient = mockClient({ data: { id: 'old' } })
  await saveCategory(updateClient, form, 'old')
  assert.equal('game_type' in updateClient.calls.find(call => call[0] === 'update')[1], false)
  assert.deepEqual(updateClient.calls.at(-1), ['single'])
  client.auth.getUser = async () => ({ data: { user: null } })
  await assert.rejects(saveCategory(client, form), /hết hạn/)
})
test('API failures propagate, including zero-row update', async () => {
  const error = { code: 'PGRST116', message: 'no rows' }
  for (const action of [client => getCategory(client, 'id'), client => setCategoryActive(client, 'id', false), client => saveCategory(client, form, 'id')]) await assert.rejects(action(mockClient({ data: null, error })), value => value === error)
  assert.match(categoryError({ code: '23505' }), /Slug đã tồn tại/)
})
test('transfer target discovery reads all pages', async () => {
  const client = mockClient(calls => ({ data: calls.filter(call => call[0] === 'range').length === 1 ? Array.from({ length: 100 }, (_, id) => ({ id })) : [{ id: 'last' }] }))
  assert.equal((await transferTargets(client, { id: 'source', game_type: 'word', locale: 'vi' })).length, 101)
  assert.ok(client.calls.some(call => call[0] === 'neq' && call[1] === 'id' && call[2] === 'source'))
})
test('delete RPC includes snapshot and confirmation, propagates errors', async () => {
  const calls = []
  const client = { rpc: async (name, args) => { calls.push([name, args]); return { data: null } } }
  await previewCategoryDelete(client, 'source')
  await deleteCategory(client, { id: 'source', mode: 'purge', confirmation: 'Đồ ăn', version: 'snapshot' })
  assert.deepEqual(calls[1], ['delete_category', { p_id: 'source', p_mode: 'purge', p_target_id: null, p_confirmation: 'Đồ ăn', p_expected_version: 'snapshot' }])
  client.rpc = async () => ({ error: new Error('changed') })
  await assert.rejects(deleteCategory(client, { id: 'source', mode: 'empty' }), /changed/)
})
test('mutation exposes pending, failure, and successful retry', async () => {
  const queryClient = new QueryClient()
  let fail = true
  const observer = new MutationObserver(queryClient, { mutationFn: async () => { if (fail) throw new Error('offline'); return 'saved' }, retry: false, gcTime: 0 })
  const unsubscribe = observer.subscribe(() => {})
  try {
    const request = observer.mutate()
    assert.equal(observer.getCurrentResult().isPending, true)
    await assert.rejects(request, /offline/)
    fail = false
    assert.equal(await observer.mutate(), 'saved')
  } finally { unsubscribe(); queryClient.clear() }
})
