import { testWindow, setupState, promptDetail } from './helpers.ts'
import type { HostNode, TestApp, StubContext, QueryStub, MockResult, ClientStub } from './helpers.ts'
import test from 'node:test'
import assert from 'node:assert/strict'
import { readFile } from 'node:fs/promises'
import { createServer } from 'vite'
import { computed, createRenderer, h, nextTick, ssrContextKey } from 'vue'
import { createI18n } from 'vue-i18n'
import { createMemoryHistory, createRouter, matchedRouteKey } from 'vue-router'
import { QueryClient, VueQueryPlugin } from '@tanstack/vue-query'

const vn = JSON.parse(await readFile(new URL('../src/i18n/locales/vn.json', import.meta.url), 'utf8'))

// In-memory host mounts real Vue components without a browser or UI library DOM.
const node = (text = ''): HostNode => ({ text, children: [], parent: null })
const renderer = createRenderer<HostNode, HostNode>({
  createElement: () => node(), createText: node, createComment: () => node(),
  setText: (element, text) => { element.text = text },
  setElementText: (element, text) => { element.text = text },
  patchProp() {},
  parentNode: element => element.parent,
  nextSibling: element => element.parent?.children[element.parent.children.indexOf(element) + 1] ?? null,
  insert(element, parent, anchor) {
    if (element.parent) element.parent.children.splice(element.parent.children.indexOf(element), 1)
    const index = anchor ? parent.children.indexOf(anchor) : -1
    parent.children.splice(index < 0 ? parent.children.length : index, 0, element)
    element.parent = parent
  },
  remove(element) { element.parent?.children.splice(element.parent.children.indexOf(element), 1) },
})
const stub = { setup: (_: unknown, { slots }: StubContext) => () => h('div', Object.values(slots).flatMap(slot => slot?.({}))) }

test('word editor refreshes clean cache, protects edits, and keeps save conflicts until explicit reload', async () => {
  const server = await createServer({ server: { middlewareMode: true, hmr: false, ws: false }, mode: 'localdev' })
  const originalWindow = globalThis.window
  const queryClient = new QueryClient({ defaultOptions: { queries: { enabled: false, gcTime: Infinity } } })
  const id = '00000000-0000-4000-8000-000000000001'
  const row = { id, text: 'Cached word', category_id: id, difficulty: 'medium', locale: 'vi', image_path: '', status: 'draft', updated_at: '2026-10-13T10:00:00Z' }
  const fresh = { ...row, text: 'Server word', updated_at: '2026-10-13T11:00:00Z' }
  let app: TestApp | undefined
  let supabase: ClientStub | undefined, originalFrom: ClientStub['from'] | undefined, originalGetUser: ClientStub['auth']['getUser'] | undefined
  try {
    globalThis.window = testWindow({ addEventListener() {}, removeEventListener() {}, confirm: () => false })
    const router = createRouter({ history: createMemoryHistory(), routes: [{ path: '/word-prompts/:id/edit', component: stub }] })
    await router.push(`/word-prompts/${id}/edit`)
    const { provideUnsavedChanges } = await server.ssrLoadModule('/src/utils/unsavedChanges.ts')
    supabase = (await server.ssrLoadModule('/src/lib/supabase.ts')).supabase as ClientStub
    originalFrom = supabase.from; originalGetUser = supabase.auth.getUser
    supabase.auth.getUser = async () => ({ data: { user: { id } } })
    let writes = 0, latest = fresh, readError: Error | null = null, resolveWrite!: () => void
    supabase.rpc = async () => { writes++; return new Promise<MockResult>(done => { resolveWrite = () => done({ error: { code: 'PT409' } }) }) }
    supabase.from = () => {
      const query = {} as QueryStub
      for (const name of ['select', 'eq', 'single', 'order', 'range']) query[name] = () => query
      query.then = resolve => Promise.resolve({ data: promptDetail(latest), error: readError }).then(resolve)
      return query
    }
    queryClient.setQueryData(['word-prompts', 'detail', id], promptDetail(row))
    queryClient.setQueryData(['content-languages'], [{ code: 'vi', display_name: 'Tiếng Việt' }, { code: 'en', display_name: 'English' }])
    const component = (await server.ssrLoadModule('/src/views/word-prompts/WordPromptFormView.vue')).default
    app = renderer.createApp({ setup() { provideUnsavedChanges(); return () => h({ ...component, render: () => h('div') }) } })
      .use(router).use(VueQueryPlugin, { queryClient }).use(createI18n({ legacy: false, locale: 'vi', messages: { vi: vn } }))
    app.provide(ssrContextKey, {}); app.provide(matchedRouteKey, computed(() => router.currentRoute.value.matched[0]))
    const editor = setupState(app.mount(node()).$.subTree.component)
    assert.equal(editor.form.text, row.text)
    queryClient.setQueryData(['word-prompts', 'detail', id], promptDetail(fresh))
    await nextTick()
    assert.equal(editor.form.text, fresh.text)
    assert.equal(editor.saved.updated_at, fresh.updated_at)
    assert.equal(editor.unsaved.dirty, false)
    editor.showCategoryHint = true; await nextTick()
    assert.equal(editor.unsaved.dirty, false, 'preview settings are not content edits')
    editor.update('text', 'My unsaved word')
    editor.file = { type: 'image/png', size: 1 }
    queryClient.setQueryData(['word-prompts', 'detail', id], promptDetail({ ...fresh, text: 'Another server edit' }))
    await nextTick()
    assert.equal(editor.form.text, 'My unsaved word')
    assert.ok(editor.file)
    assert.equal(editor.saved.updated_at, fresh.updated_at)
    editor.file = null
    editor.submit('draft')
    await new Promise(resolve => setTimeout(resolve, 0))
    resolveWrite()
    await new Promise(resolve => setTimeout(resolve, 0))
    assert.equal(editor.saveConflict, true)
    editor.update('text', 'Edit after conflict')
    assert.equal(editor.saveConflict, true)
    editor.submit('draft'); editor.submit('published'); editor.submit('archived')
    await nextTick()
    assert.equal(writes, 1, 'conflicted saves do not write or upload again')
    await editor.reload()
    assert.equal(editor.form.text, 'Edit after conflict', 'cancel keeps edits and conflict')
    assert.equal(editor.saveConflict, true)
    globalThis.window.confirm = () => true
    readError = new Error('offline')
    await editor.reload()
    assert.equal(editor.saveConflict, true)
    assert.equal(editor.form.text, 'Edit after conflict')
    readError = null
    latest = { ...fresh, text: 'Explicit reload', updated_at: '2026-10-13T12:00:00Z' }
    await editor.reload()
    assert.equal(editor.form.text, latest.text)
    assert.equal(editor.saved.updated_at, latest.updated_at)
    assert.equal(editor.saveConflict, false)
    assert.equal(editor.unsaved.dirty, false)
    // A background response must not replace a form while an action is busy.
    editor.unsaved.busy = true
    queryClient.setQueryData(['word-prompts', 'detail', id], promptDetail(fresh))
    await nextTick()
    assert.equal(editor.form.text, latest.text)
  } finally {
    app?.unmount(); queryClient.clear(); globalThis.window = originalWindow
    if (supabase) { supabase.from = originalFrom!; supabase.auth.getUser = originalGetUser! }
    await server.close()
  }
})

test('saved-word deletion preserves input on failure, blocks repeats/leave/logout, and reloads explicitly', async () => {
  const server = await createServer({ server: { middlewareMode: true, hmr: false, ws: false }, mode: 'localdev' })
  const apps: TestApp[] = [], originalWindow = globalThis.window
  const queryClient = new QueryClient({ defaultOptions: { queries: { enabled: false, refetchOnMount: false, gcTime: Infinity } } })
  const invalidations: (readonly unknown[] | undefined)[] = [], invalidateQueries = queryClient.invalidateQueries.bind(queryClient)
  queryClient.invalidateQueries = options => { invalidations.push((typeof options === 'function' ? options() : options)?.queryKey); return invalidateQueries(options) }
  const id = '00000000-0000-4000-8000-000000000001'
  const row = { id, text: 'Saved apple', image_path: '', category_id: id, difficulty: 'medium', locale: 'vi', status: 'published', updated_at: '2026-10-13T10:00:00Z', game_categories: { id, name: 'Saved category', locale: 'vi', is_active: false } }
  let supabase: ClientStub | undefined, originalRpc: ClientStub['rpc'] | undefined, originalFrom: ClientStub['from'] | undefined, originalGetUser: ClientStub['auth']['getUser'] | undefined, originalSignOut: ClientStub['auth']['signOut'] | undefined
  try {
    globalThis.window = testWindow({ addEventListener() {}, removeEventListener() {}, confirm: () => false })
    const i18n = createI18n({ legacy: false, locale: 'vi', messages: { vi: vn } })
    const router = createRouter({ history: createMemoryHistory(), routes: [{ path: '/word-prompts/:id/edit', name: 'word-prompt-edit', component: stub }, { path: '/word-prompts', name: 'word-prompts', component: stub }, { path: '/login', name: 'login', component: stub }] })
    await router.push({ name: 'word-prompt-edit', params: { id }, query: { status: 'published', page: '2', search: 'apple' } })
    const { provideUnsavedChanges } = await server.ssrLoadModule('/src/utils/unsavedChanges.ts')
    supabase = (await server.ssrLoadModule('/src/lib/supabase.ts')).supabase as ClientStub
    originalRpc = supabase.rpc; originalFrom = supabase.from; originalGetUser = supabase.auth.getUser; originalSignOut = supabase.auth.signOut
    supabase.auth.getUser = async () => ({ data: { user: null } })
    let signouts = 0
    supabase.auth.signOut = async () => { signouts++; return {} }
    let latest = row
    supabase.from = () => {
      const query = {} as QueryStub
      for (const method of ['select', 'eq', 'single', 'order', 'range']) query[method] = () => query
      query.then = resolve => resolve({ data: promptDetail(latest) })
      return query
    }
    queryClient.setQueryData(['word-prompts', 'detail', id], promptDetail(row))
    async function mount(path: string, props: Record<string, unknown> = {}) {
      queryClient.setQueryData(['content-languages'], [{ code: 'vi', display_name: 'Tiếng Việt' }, { code: 'en', display_name: 'English' }])
    const component = (await server.ssrLoadModule(path)).default
      const child = { ...component, render: () => h('div') }
      const root = { setup() { provideUnsavedChanges(); return () => h(child, props) } }
      const app = renderer.createApp(root).use(i18n).use(router).use(VueQueryPlugin, { queryClient })
      app.provide(ssrContextKey, {}); app.provide(matchedRouteKey, computed(() => router.currentRoute.value.matched[0]))
      apps.push(app)
      const instance = app.mount(node()).$.subTree.component
      return { state: setupState(instance), instance }
    }
    const { state: editor } = await mount('/src/views/word-prompts/WordPromptFormView.vue')
    assert.equal(editor.saved.translations[0].text, 'Saved apple')
    assert.match(editor.previewCategoryName, /Saved category/)
    assert.equal('imposter_text' in editor.form, false)
    assert.equal('imposter_hint' in editor.form, false)
    editor.update('text', '')
    editor.update('category_id', '')
    assert.equal(editor.deletePrompt.text, 'Saved apple', 'delete summary uses persisted content')
    assert.equal(editor.previewCategoryName, '')
    editor.file = { type: 'image/png', size: 1 }
    editor.openDelete()
    assert.equal(editor.deleting, true)
    assert.equal(editor.saved.translations[0].text, 'Saved apple')
    assert.equal(editor.canLeave(), false)
    // Cancel does not save anything and keeps the invalid form/file.
    editor.deleting = false
    assert.equal(editor.form.text, '')
    assert.ok(editor.file)
    editor.openDelete()
    let resolveRpc!: (result: MockResult) => void, calls = 0
    supabase.rpc = async (name, input) => {
      calls++
      assert.equal(name, 'delete_word_prompt')
      assert.equal(input.p_expected_updated_at, row.updated_at)
      return new Promise<MockResult>(resolve => { resolveRpc = resolve })
    }
    const input = { id, updatedAt: row.updated_at }
    editor.remove(input); editor.remove(input)
    assert.equal(editor.unsaved.busy, true)
    await new Promise(resolve => setTimeout(resolve, 0))
    assert.equal(calls, 1)
    const { state: shell } = await mount('/src/components/admin/AdminShell.vue')
    shell.unsaved.busy = true; shell.logout()
    assert.equal(signouts, 0)
    assert.equal(editor.canLeave(), false)
    resolveRpc({ error: new Error('offline') })
    await new Promise(resolve => setTimeout(resolve, 0))
    assert.equal(editor.unsaved.busy, false)
    assert.equal(editor.form.text, '')
    assert.ok(editor.file)
    assert.equal(editor.deleting, true)
    assert.equal(calls, 1)
    supabase.rpc = async () => { calls++; return { error: { code: 'PT409' } } }
    editor.remove(input)
    await new Promise(resolve => setTimeout(resolve, 0))
    assert.equal(editor.conflict, true)
    editor.remove(input)
    assert.equal(calls, 2)
    await editor.reload()
    assert.equal(editor.form.text, '')
    assert.equal(editor.conflict, true)
    globalThis.window.confirm = () => true
    latest = { ...row, text: 'Other tab apple', updated_at: '2026-10-13T11:00:00Z' }
    await editor.reload()
    assert.equal(editor.form.text, 'Other tab apple')
    assert.equal(editor.file, null)
    assert.equal(editor.conflict, false)
    assert.equal(editor.deleting, false)
    editor.openDelete()
    supabase.rpc = async (_, input) => { assert.equal(input.p_expected_updated_at, latest.updated_at); return { data: null } }
    editor.remove({ ...input, updatedAt: latest.updated_at })
    await new Promise(resolve => setTimeout(resolve, 10))
    assert.equal(router.currentRoute.value.name, 'word-prompts')
    assert.deepEqual(router.currentRoute.value.query, { status: 'published', page: '2', search: 'apple' })
    assert.equal(editor.unsaved.dirty, false)
    assert.equal(editor.deleting, false)

    assert.ok(invalidations.some(key => key?.[0] === 'word-prompts'))
    assert.ok(invalidations.some(key => key?.[0] === 'categories'))

    const emitted: unknown[] = []
    const { state: dialog } = await mount('/src/components/word-prompts/WordDeleteDialog.vue', { prompt: row, pending: false, onDelete: (input: { id: string; updatedAt: string }) => emitted.push(input) })
    assert.equal(dialog.canDelete, true)
    dialog.submit()
    assert.deepEqual(emitted, [input])
    const { state: pending } = await mount('/src/components/word-prompts/WordDeleteDialog.vue', { prompt: row, pending: true })
    assert.equal(pending.canDelete, false)
    pending.submit()
    const { state: conflicted } = await mount('/src/components/word-prompts/WordDeleteDialog.vue', { prompt: row, pending: false, conflict: true, onDelete: (input: { id: string; updatedAt: string }) => emitted.push(input) })
    assert.equal(conflicted.canDelete, false)
    conflicted.submit()
    assert.equal(emitted.length, 1)

    const { state: list } = await mount('/src/views/word-prompts/WordPromptsView.vue')
    queryClient.setQueryData(['word-prompts', 'list', list.filters], { rows: [], total: 20 })
    await nextTick(); await new Promise(resolve => setTimeout(resolve, 0))
    assert.equal(router.currentRoute.value.query.page, undefined)
    assert.equal(router.currentRoute.value.query.search, 'apple')
    assert.equal(router.currentRoute.value.query.status, 'published')
    queryClient.clear()
    const { state: fresh } = await mount('/src/views/word-prompts/WordPromptFormView.vue')
    assert.equal(fresh.saved, null); fresh.openDelete(); assert.equal(fresh.deleting, false)
  } finally {
    for (const app of apps.reverse()) app.unmount()
    if (supabase) { supabase.rpc = originalRpc!; supabase.from = originalFrom!; supabase.auth.getUser = originalGetUser!; supabase.auth.signOut = originalSignOut! }
    queryClient.clear(); globalThis.window = originalWindow; await server.close()
  }
})

