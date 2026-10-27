import { testWindow, setupState } from './helpers.ts'
import type { HostNode, TestApp, StubContext, QueryStub, MockResult, ClientStub } from './helpers.ts'
import test from 'node:test'
import assert from 'node:assert/strict'
import { readFile } from 'node:fs/promises'
import { createServer } from 'vite'
import { computed, createRenderer, h, nextTick, reactive, ssrContextKey } from 'vue'
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

test('category tabs retain drafts, save only the selected translation and require explicit conflict reload', async () => {
  const server = await createServer({ server: { middlewareMode: true, hmr: false, ws: false }, mode: 'localdev' })
  const originalWindow = globalThis.window
  const cache = new QueryClient({ defaultOptions: { queries: { enabled: false, refetchOnMount: false, gcTime: Infinity } } })
  const id = '00000000-0000-4000-8000-000000000001'
  const original = { id, slug: 'food', game_type: 'word', is_family_friendly: false, sort_order: 0, is_active: true, updated_at: '2026-10-24T01:00:00Z' }
  const translation = { category_id: id, locale: 'vi', name: 'Đồ ăn', description: null, status: 'published' }
  let latest = { ...original, translations: [translation] }
  let app: TestApp | undefined
  try {
    globalThis.window = testWindow({ addEventListener() {}, removeEventListener() {}, confirm: () => false })
    const router = createRouter({ history: createMemoryHistory(), routes: [
      { path: '/categories/new', name: 'category-new', component: stub },
      { path: '/categories/:id/edit', name: 'category-edit', component: stub },
      { path: '/categories', name: 'categories', component: stub },
    ] })
    await router.push({ name: 'category-edit', params: { id }, query: { locale: 'vi', search: 'food' } })
    const { provideUnsavedChanges } = await server.ssrLoadModule('/src/utils/unsavedChanges.ts')
    const client = (await server.ssrLoadModule('/src/lib/supabase.ts')).supabase as ClientStub
    client.from = () => {
      const query = {} as QueryStub
      for (const name of ['select', 'eq', 'single', 'order', 'range']) query[name] = () => query
      query.then = resolve => Promise.resolve({ data: latest }).then(resolve)
      return query
    }
    let finish!: (result: MockResult) => void
    const calls: Record<string, unknown>[] = []
    client.rpc = async (name, input) => {
      assert.equal(name, 'save_category'); calls.push(input)
      return new Promise<MockResult>(resolve => { finish = resolve })
    }
    cache.setQueryData(['content-languages'], [{ code: 'vi', display_name: 'Tiếng Việt' }, { code: 'en', display_name: 'English' }, { code: 'fr', display_name: 'Français' }])
    cache.setQueryData(['categories', 'detail', id], latest)
    for (const prefix of ['dashboard', 'categories', 'word-prompts', 'question-prompts']) {
      for (const locale of ['vi', 'en', 'fr']) cache.setQueryData([prefix, 'list', locale], { fixture: true })
    }
    const component = (await server.ssrLoadModule('/src/views/categories/CategoryFormView.vue')).default
    const i18n = createI18n({ legacy: false, locale: 'vi', fallbackLocale: 'vi', messages: { vi: vn, en: {} }, missingWarn: false, fallbackWarn: false })
    app = renderer.createApp({ setup() { provideUnsavedChanges(); return () => h({ ...component, render: () => h('div') }) } })
      .use(router).use(VueQueryPlugin, { queryClient: cache }).use(i18n)
    app.provide(ssrContextKey, {}); app.provide(matchedRouteKey, computed(() => router.currentRoute.value.matched[0]))
    const editor = setupState(app.mount(node()).$.subTree.component)
    const tick = async () => { await nextTick(); await new Promise(resolve => setTimeout(resolve, 5)) }
    assert.equal(editor.form.name, 'Đồ ăn'); assert.equal(editor.unsaved.dirty, false)
    editor.update('name', 'Việt chưa lưu')
    editor.selectLocale('en'); await tick()
    assert.equal(editor.form.name, ''); assert.equal(editor.form.status, 'draft'); assert.equal(calls.length, 0)
    editor.update('is_family_friendly', true)
    editor.update('name', 'Food'); editor.update('slug', 'shared-food')
    i18n.global.locale.value = 'en'; await tick()
    assert.equal(editor.form.locale, 'en')
    editor.update('status', 'published'); assert.equal(calls.length, 0)
    editor.submit(); editor.submit(); await tick()
    assert.equal(calls[0]!.p_is_family_friendly, true)
    assert.equal(calls[0]!.p_status, 'published')
    assert.equal(calls.length, 1); assert.equal(calls[0]!.p_locale, 'en'); assert.equal(calls[0]!.p_name, 'Food')
    assert.equal(calls[0]!.p_expected_updated_at, original.updated_at); assert.equal(editor.canLeave(), false)
    editor.selectLocale('vi'); assert.equal(editor.form.locale, 'en', 'busy tab switch blocked')
    finish({ data: { original: { ...original, slug: 'shared-food', is_family_friendly: true, updated_at: 'version-2' }, translation: { ...translation, locale: 'en', name: 'Food' } } }); await tick()
    for (const prefix of ['dashboard', 'categories', 'word-prompts', 'question-prompts']) {
      for (const locale of ['vi', 'en', 'fr']) assert.equal(cache.getQueryState([prefix, 'list', locale])!.isInvalidated, true, `${prefix}/${locale} refreshed after save`)
    }
    assert.equal(editor.saved.updated_at, 'version-2'); assert.equal(editor.unsaved.dirty, true, 'Vietnamese edits remain dirty')
    editor.selectLocale('vi'); await tick()
    assert.equal(editor.form.name, 'Việt chưa lưu')
    editor.submit(); await tick()
    assert.equal(calls[1]!.p_expected_updated_at, 'version-2')
    finish({ error: new Error('offline') }); await tick()
    assert.equal(editor.form.name, 'Việt chưa lưu'); assert.equal(editor.unsaved.busy, false)
    editor.submit(); await tick()
    finish({ error: { code: 'PT409' } }); await tick()
    assert.equal(editor.conflict, true)
    editor.update('name', 'Still editing'); editor.submit(); await tick()
    assert.equal(calls.length, 3)
    await editor.reload(); assert.equal(editor.form.name, 'Still editing'); assert.equal(editor.conflict, true)
    globalThis.window.confirm = () => true
    latest = { ...original, updated_at: 'version-3', translations: [{ ...translation, name: 'Reloaded' }] }
    await editor.reload(); await tick()
    assert.equal(editor.form.name, 'Reloaded'); assert.equal(editor.unsaved.dirty, false); assert.equal(editor.conflict, false)
    editor.selectLocale('fr'); await tick()
    assert.equal(editor.form.name, ''); assert.equal(editor.unsaved.dirty, false, 'opening a missing tab is not an edit')
    editor.update('name', 'Nourriture'); editor.submit(); await tick()
    finish({ data: { original: { ...original, updated_at: 'version-4' }, translation: { ...translation, locale: 'fr', name: 'Nourriture', status: 'draft' } } }); await tick()
    assert.equal(editor.unsaved.dirty, false)
    assert.equal(calls[3]!.p_locale, 'fr')
    await router.push({ name: 'category-new' }); await tick()
    assert.equal(editor.form.name, ''); assert.equal(editor.saved, null)
    editor.update('name', 'New category')
    editor.selectLocale('en'); await tick(); editor.update('name', 'New English')
    editor.submit(); await tick()
    const newId = String(calls[4]!.p_id)
    assert.equal(calls[4]!.p_expected_updated_at, null)
    finish({ data: { original: { ...original, id: newId, slug: 'new-category', updated_at: 'new-version' }, translation: { ...translation, category_id: newId, locale: 'en', name: 'New English', status: 'draft' } } }); await tick()
    assert.equal(router.currentRoute.value.name, 'category-edit'); assert.equal(router.currentRoute.value.params.id, newId)
    assert.equal(editor.form.name, 'New English'); assert.equal(editor.unsaved.dirty, true)
    editor.selectLocale('vi'); await tick(); assert.equal(editor.form.name, 'New category')
  } finally { app?.unmount(); cache.clear(); globalThis.window = originalWindow; await server.close() }
})

test('category deletion counts originals and blocks stale or ineligible confirmation', async () => {
  const server = await createServer({ server: { middlewareMode: true, hmr: false, ws: false }, mode: 'localdev' })
  let app: TestApp | undefined
  try {
    const component = (await server.ssrLoadModule('/src/components/categories/CategoryDeleteDialog.vue')).default
    const deletions: unknown[] = []
    const props = reactive({ locale: 'vi', conflict: false, loading: false, pending: false, targetsLoading: false, targetsError: '',
      preview: { category: { id: 'source', slug: 'source' }, category_translations: [], counts: { originals: { total: 1, word: 1, question: 0 }, translations: { draft: 0, published: 0, archived: 0 } }, version: 'snapshot' },
      targets: [{ id: 'target', slug: 'target', name: 'Target' }], onDelete: (input: unknown) => deletions.push(input),
    })
    const child = { ...component, render: () => h('div') }
    app = renderer.createApp({ render: () => h(child, props) })
      .use(createI18n({ legacy: false, locale: 'vi', messages: { vi: vn } }))
    app.provide(ssrContextKey, {})
    const dialog = setupState(app.mount(node()).$.subTree.component)
    assert.equal(dialog.total, 1, 'prompt without translations is not an empty category')
    assert.equal(dialog.canDelete, false)
    dialog.targetId = 'target'; assert.equal(dialog.canDelete, true)
    props.conflict = true; await nextTick()
    dialog.submit(); assert.equal(deletions.length, 0)
    dialog.mode = 'purge'; assert.equal(dialog.canDelete, false)
    props.conflict = false; await nextTick()
    dialog.mode = 'transfer'; props.targetsLoading = true; await nextTick()
    assert.equal(dialog.canDelete, false)
    props.targetsLoading = false; props.targets = []; await nextTick()
    assert.equal(dialog.targetId, ''); assert.equal(dialog.canDelete, false)
    dialog.mode = 'purge'; dialog.submit()
    assert.deepEqual(deletions, [{ id: 'source', mode: 'purge', targetId: '', version: 'snapshot' }])
  } finally { app?.unmount(); await server.close() }
})
