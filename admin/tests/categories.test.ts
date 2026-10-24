import { asClient } from './helpers.ts'
import type { QueryStub, MockResult, Calls } from './helpers.ts'
import test from 'node:test'
import assert from 'node:assert/strict'
import { categoryPayload, slugFromName, searchPattern, listFilters, categoryError } from '../src/utils/categories.ts'
import { listCategories, getCategory, saveCategory, setCategoryActive, previewCategoryDelete, transferTargets, deleteCategory } from '../src/api/categories.ts'
import { QueryClient, MutationObserver } from '@tanstack/vue-query'

const form = { name: '  Đồ ăn  ', slug: 'do-an', description: '  Món ngon ', game_type: 'word', sort_order: '2', is_active: true, locale: 'en', status: 'draft', id: 'injected', created_by: 'injected' }
function mockClient(result: MockResult | ((calls: Calls) => MockResult) = { data: [], count: 0 }) {
  const calls: Calls = []
  const chain: QueryStub = { then(resolve: (value: MockResult) => unknown, reject?: (reason: unknown) => unknown) { return Promise.resolve(typeof result === 'function' ? result(calls) : result).then(resolve, reject) } }
  for (const method of ['select', 'eq', 'neq', 'or', 'order', 'range', 'single', 'update', 'insert']) chain[method] = (...args: unknown[]) => { calls.push([method, ...args]); return chain }
  return { calls, rpc: (name: string, args: unknown) => { calls.push(['rpc', name, args]); return chain }, from: (table: string) => { calls.push(['from', table]); return chain }, auth: { getUser: async () => ({ data: { user: { id: 'admin' } as { id: string } | null } }) } }
}

test('Vietnamese slug normalization', () => {
  assert.equal(slugFromName(' Đồ ăn & thức uống! '), 'do-an-thuc-uong')
  assert.equal(slugFromName('!!!'), '')
})
test('payload trims and excludes protected fields', () => {
  assert.deepEqual(categoryPayload(form), { name: 'Đồ ăn', slug: 'do-an', description: 'Món ngon', sort_order: 2, is_active: true, game_type: 'word', locale: 'en', status: 'draft' })
  for (const key of ['created_by', 'id']) assert.equal(key in categoryPayload(form), false)
})
test('reject invalid names, slugs, types, and sort orders', () => {
  for (const changes of [{ name: ' ' }, { locale: '' }, { status: 'unknown' }, { slug: 'Đồ ăn' }, { slug: '-food' }, { game_type: 'other' }, { sort_order: '' }, { sort_order: -1 }, { sort_order: 1.5 }, { sort_order: 2147483648 }]) assert.throws(() => categoryPayload({ ...form, ...changes }))
})
test('quoted search escapes wildcards, quotes and filter delimiters', () => {
  assert.equal(searchPattern('a,b)(c'), '"%a,b)(c%"')
  assert.equal(searchPattern('a"b'), '"%a\\"b%"')
  assert.equal(searchPattern('%_'), '"%\\\\%\\\\_%"')
})
test('URL filters reject invalid page and sort values', () => {
  assert.deepEqual(listFilters({ page: '-1', type: 'bad', active: 'yes', sort: 'injected' }), { locale: 'vi', page: 1, search: '', gameType: '', active: '', sort: 'sort_order' })
  assert.equal(listFilters({ page: '2' }).page, 2)
})
test('backend receives language, filters, sort and page together', async () => {
  const client = mockClient({ data: { rows: [{ id: '1' }], total: 24 } })
  const result = await listCategories(asClient(client), { search: '  food,drink ', gameType: 'word', active: 'false', sort: 'updated_at', page: 2, locale: 'en' })
  assert.equal(result.total, 24)
  assert.deepEqual(client.calls, [['rpc', 'admin_list_categories', { p_locale: 'en', p_search: 'food,drink', p_game_type: 'word', p_is_active: false, p_sort: 'updated_at', p_page: 2 }]])
})
test('save uses one transactional RPC, selected locale and original version', async () => {
  const client = mockClient({ data: { original: { id: 'new' }, translation: { locale: 'en' } } })
  await saveCategory(asClient(client), form, 'new')
  assert.deepEqual(client.calls[0], ['rpc', 'save_category', {
    p_id: 'new', p_expected_updated_at: null, p_game_type: 'word', p_slug: 'do-an', p_sort_order: 2,
    p_is_active: true, p_locale: 'en', p_name: 'Đồ ăn', p_description: 'Món ngon', p_status: 'draft',
  }])
  await saveCategory(asClient(client), { ...form, description: '' }, 'new', 'server-version')
  const args = client.calls[1]![2] as Record<string, unknown>
  assert.equal(args.p_expected_updated_at, 'server-version'); assert.equal(args.p_description, null)
})
test('API failures propagate, including zero-row update', async () => {
  const error = { code: 'PGRST116', message: 'no rows' }
  for (const action of [(client: object) => getCategory(asClient(client), 'id'), (client: object) => setCategoryActive(asClient(client), { id: 'id', updated_at: 'version' } as import('../src/types/admin.ts').Category, false), (client: object) => saveCategory(asClient(client), form, 'id')]) await assert.rejects(action(mockClient({ data: null, error })), value => value === error)
  assert.equal(categoryError({ code: '23505' }), 'categories.errors.slugExists')
})
test('transfer target discovery reads all pages', async () => {
  const client = mockClient(calls => ({ data: calls.filter(call => call[0] === 'range').length === 1 ? Array.from({ length: 100 }, (_, id) => ({ id })) : [{ id: 'last' }] }))
  assert.equal((await transferTargets(asClient(client), 'source', 'vi')).length, 101)
  assert.deepEqual(client.calls[0], ['rpc', 'admin_category_transfer_targets', { p_source_id: 'source', p_locale: 'vi' }])
})
test('delete RPC includes snapshot without typed confirmation, propagates errors', async () => {
  const calls: Calls = []
  const client: { rpc: (...args: unknown[]) => Promise<MockResult> } = { rpc: async (name: unknown, args: unknown) => { calls.push([name, args]); return { data: null } } }
  await previewCategoryDelete(asClient(client), 'source')
  await deleteCategory(asClient(client), { id: 'source', mode: 'purge', version: 'snapshot' })
  assert.deepEqual(calls[1], ['delete_category', { p_id: 'source', p_mode: 'purge', p_target_id: null, p_expected_version: 'snapshot' }])
  client.rpc = async () => ({ error: new Error('changed') })
  await assert.rejects(deleteCategory(asClient(client), { id: 'source', mode: 'empty' }), /changed/)
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
