import test from 'node:test'
import assert from 'node:assert/strict'
import { readFile } from 'node:fs/promises'
import { createServer } from 'vite'
import { computed, createRenderer, h, nextTick, ssrContextKey } from 'vue'
import { createI18n } from 'vue-i18n'
import { createMemoryHistory, createRouter, matchedRouteKey } from 'vue-router'
import { QueryClient, VueQueryPlugin } from '@tanstack/vue-query'

const vn = JSON.parse(await readFile(new URL('../src/i18n/locales/vn.json', import.meta.url)))

// In-memory host mounts real Vue components without a browser or UI library DOM.
const node = (text = '') => ({ text, children: [], parent: null })
const renderer = createRenderer({
  createElement: () => node(), createText: node, createComment: () => node(),
  setText: (element, text) => { element.text = text },
  setElementText: (element, text) => { element.text = text },
  patchProp() {},
  parentNode: element => element.parent,
  nextSibling: element => element.parent?.children[element.parent.children.indexOf(element) + 1],
  insert(element, parent, anchor) {
    if (element.parent) element.parent.children.splice(element.parent.children.indexOf(element), 1)
    const index = anchor ? parent.children.indexOf(anchor) : -1
    parent.children.splice(index < 0 ? parent.children.length : index, 0, element)
    element.parent = parent
  },
  remove(element) { element.parent?.children.splice(element.parent.children.indexOf(element), 1) },
})
const stub = { setup: (_, { slots }) => () => h('div', Object.values(slots).flatMap(slot => slot({}))) }

test('saved-word deletion preserves input on failure, blocks repeats/leave/logout, and reloads explicitly', async () => {
  const server = await createServer({ server: { middlewareMode: true, hmr: false, ws: false }, mode: 'localdev' })
  const apps = [], originalWindow = globalThis.window
  const queryClient = new QueryClient({ defaultOptions: { queries: { enabled: false, refetchOnMount: false, gcTime: Infinity } } })
  const invalidations = [], invalidateQueries = queryClient.invalidateQueries.bind(queryClient)
  queryClient.invalidateQueries = options => { invalidations.push(options.queryKey); return invalidateQueries(options) }
  const id = '00000000-0000-4000-8000-000000000001'
  const row = { id, civilian_text: 'Saved apple', image_path: '', category_id: id, difficulty: 'medium', is_family_friendly: false, locale: 'vi', status: 'published', updated_at: '2026-10-13T10:00:00Z', game_categories: { id, name: 'Saved category', locale: 'vi', is_active: false } }
  let supabase, originalRpc, originalFrom, originalGetUser, originalSignOut
  try {
    globalThis.window = { addEventListener() {}, removeEventListener() {}, confirm: () => false }
    const i18n = createI18n({ legacy: false, locale: 'vi', messages: { vi: vn } })
    const router = createRouter({ history: createMemoryHistory(), routes: [{ path: '/word-prompts/:id/edit', name: 'word-prompt-edit', component: stub }, { path: '/word-prompts', name: 'word-prompts', component: stub }, { path: '/login', name: 'login', component: stub }] })
    await router.push({ name: 'word-prompt-edit', params: { id }, query: { status: 'published', page: '2', search: 'apple' } })
    const { provideUnsavedChanges } = await server.ssrLoadModule('/src/utils/unsavedChanges.js')
    ;({ supabase } = await server.ssrLoadModule('/src/lib/supabase.js'))
    originalRpc = supabase.rpc; originalFrom = supabase.from; originalGetUser = supabase.auth.getUser; originalSignOut = supabase.auth.signOut
    supabase.auth.getUser = async () => ({ data: { user: null } })
    let signouts = 0
    supabase.auth.signOut = async () => { signouts++; return {} }
    let latest = row
    supabase.from = () => {
      const query = {}
      for (const method of ['select', 'eq', 'single', 'order', 'range']) query[method] = () => query
      query.then = resolve => resolve({ data: latest })
      return query
    }
    queryClient.setQueryData(['word-prompts', 'detail', id], row)
    async function mount(path, props = {}) {
      const component = (await server.ssrLoadModule(path)).default
      const child = { ...component, render: () => h('div') }
      const root = { setup() { provideUnsavedChanges(); return () => h(child, props) } }
      const app = renderer.createApp(root).use(i18n).use(router).use(VueQueryPlugin, { queryClient })
      app.provide(ssrContextKey, {}); app.provide(matchedRouteKey, computed(() => router.currentRoute.value.matched[0]))
      apps.push(app)
      const instance = app.mount(node()).$.subTree.component
      return { state: instance.setupState, instance }
    }
    const { state: editor } = await mount('/src/views/word-prompts/WordPromptFormView.vue')
    assert.equal(editor.saved.civilian_text, 'Saved apple')
    assert.equal(editor.previewCategoryName, 'Saved category')
    assert.equal('imposter_text' in editor.form, false)
    assert.equal('imposter_hint' in editor.form, false)
    editor.update('civilian_text', '')
    editor.update('category_id', '')
    assert.equal(editor.previewCategoryName, '')
    editor.file = { type: 'image/png', size: 1 }
    editor.openDelete()
    assert.equal(editor.deleting, true)
    assert.equal(editor.saved.civilian_text, 'Saved apple')
    assert.equal(editor.canLeave(), false)
    // Cancel does not save anything and keeps the invalid form/file.
    editor.deleting = false
    assert.equal(editor.form.civilian_text, '')
    assert.ok(editor.file)
    editor.openDelete()
    let resolveRpc, calls = 0
    supabase.rpc = async (name, input) => {
      calls++
      assert.equal(name, 'delete_word_prompt')
      assert.equal(input.p_expected_updated_at, row.updated_at)
      return new Promise(resolve => { resolveRpc = resolve })
    }
    const input = { id, updatedAt: row.updated_at, confirmation: 'XÓA' }
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
    assert.equal(editor.form.civilian_text, '')
    assert.ok(editor.file)
    assert.equal(editor.deleting, true)
    assert.equal(calls, 1)
    supabase.rpc = async () => { calls++; return { error: { code: '40001' } } }
    editor.remove(input)
    await new Promise(resolve => setTimeout(resolve, 0))
    assert.equal(editor.conflict, true)
    editor.remove(input)
    assert.equal(calls, 2)
    await editor.reload()
    assert.equal(editor.form.civilian_text, '')
    assert.equal(editor.conflict, true)
    globalThis.window.confirm = () => true
    latest = { ...row, civilian_text: 'Other tab apple', updated_at: '2026-10-13T11:00:00Z' }
    await editor.reload()
    assert.equal(editor.form.civilian_text, 'Other tab apple')
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

    assert.ok(invalidations.some(key => key[0] === 'word-prompts'))
    assert.ok(invalidations.some(key => key[0] === 'categories'))

    const emitted = []
    const { state: dialog } = await mount('/src/components/word-prompts/WordDeleteDialog.vue', { prompt: row, pending: false, onDelete: input => emitted.push(input) })
    for (const value of ['', 'xóa', 'XÓA ', 'XOA']) { dialog.confirmation = value; dialog.submit(); assert.equal(dialog.canDelete, false) }
    assert.equal(emitted.length, 0)
    dialog.confirmation = 'XÓA'; assert.equal(dialog.canDelete, true); dialog.submit()
    assert.deepEqual(emitted, [input])
    const { state: pending } = await mount('/src/components/word-prompts/WordDeleteDialog.vue', { prompt: row, pending: true })
    pending.confirmation = 'XÓA'; assert.equal(pending.canDelete, false)

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
    if (supabase) { supabase.rpc = originalRpc; supabase.from = originalFrom; supabase.auth.getUser = originalGetUser; supabase.auth.signOut = originalSignOut }
    queryClient.clear(); globalThis.window = originalWindow; await server.close()
  }
})

