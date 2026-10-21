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

test('mounted components react to locale changes and preserve delete/leave guards', async () => {
  const server = await createServer({ server: { middlewareMode: true, hmr: false, ws: false }, mode: 'localdev' })
  const apps = []
  const originalWindow = globalThis.window
  const queryClient = new QueryClient({ defaultOptions: { queries: { enabled: false, gcTime: Infinity } } })
  try {
    globalThis.window = { addEventListener() {}, removeEventListener() {}, confirm: () => false }
    const i18n = createI18n({ legacy: false, locale: 'vi', fallbackLocale: 'vi', messages: { vi: vn, en: {
      dashboard: { title: 'Dashboard' },
      common: { gameTypes: { word: 'Word' } },
      categories: { fields: { name: 'Category name' }, messages: { statusUpdated: 'Status updated' }, errors: { nameRequired: 'Name required' } },
      auth: { errors: { loginFailed: 'Login failed' } },
    } }, missingWarn: false, fallbackWarn: false })
    const router = createRouter({ history: createMemoryHistory(), routes: [{ path: '/', name: 'dashboard', meta: { titleKey: 'dashboard.title' }, component: stub }] })
    await router.push('/')
    const { provideUnsavedChanges } = await server.ssrLoadModule('/src/utils/unsavedChanges.js')
    const { supabase } = await server.ssrLoadModule('/src/lib/supabase.js')
    const getUser = supabase.auth.getUser
    supabase.auth.getUser = async () => ({ data: { user: null } })
    async function mount(path, props = {}) {
      const component = (await server.ssrLoadModule(path)).default
      // SSR templates are covered by categoryComponents; mount setup for reactive state.
      const child = { ...component, render: () => h('div') }
      const root = { setup() { provideUnsavedChanges(); return () => h(child, props) } }
      const app = renderer.createApp(root).use(i18n).use(router).use(VueQueryPlugin, { queryClient })
      app.provide(ssrContextKey, {})
      app.provide(matchedRouteKey, computed(() => router.currentRoute.value.matched[0]))
      apps.push(app)
      return app.mount(node()).$.subTree.component.setupState
    }
    const shell = await mount('/src/components/admin/AdminShell.vue')
    supabase.auth.getUser = getUser
    const filters = await mount('/src/components/categories/CategoryFilters.vue', { filters: { gameType: '', active: '', sort: 'sort_order' }, search: '' })
    const form = await mount('/src/components/categories/CategoryForm.vue', { form: { name: 'Food', game_type: 'word', locale: 'vi' } })
    const table = await mount('/src/components/categories/CategoryTable.vue', { rows: [] })
    const list = await mount('/src/views/categories/CategoriesView.vue')
    const login = await mount('/src/views/login/LoginView.vue')
    const editor = await mount('/src/views/categories/CategoryFormView.vue')
    list.message = 'categories.messages.statusUpdated'
    const signIn = supabase.auth.signInWithPassword
    try {
      supabase.auth.signInWithPassword = async () => ({ error: new Error('backend diagnostic') })
      login.submitLogin({ data: { email: 'admin@example.com', password: 'password' } })
      await new Promise(resolve => setTimeout(resolve, 0))
    } finally { supabase.auth.signInWithPassword = signIn }
    editor.submit()
    await new Promise(resolve => setTimeout(resolve, 0))
    assert.equal(shell.navItems[0].label, 'Tổng quan')
    assert.equal(filters.gameTypes[1].label, 'Từ ngữ')
    assert.equal(form.gameTypes[0].label, 'Từ ngữ')
    assert.equal(table.columns[0].header, 'Tên danh mục')
    assert.equal(table.dateFormat.resolvedOptions().locale, 'vi-VN')
    assert.equal(list.t(list.message), 'Đã cập nhật trạng thái.')
    assert.equal(login.errorMessage, 'Đăng nhập không thành công.')
    assert.equal(editor.mutation.error.value.message, 'categories.errors.nameRequired')
    i18n.global.locale.value = 'en'
    await nextTick()
    assert.equal(shell.navItems[0].label, 'Dashboard')
    assert.equal(shell.pageTitle, 'Dashboard')
    assert.equal(filters.gameTypes[1].label, 'Word')
    assert.equal(form.gameTypes[0].label, 'Word')
    assert.equal(table.columns[0].header, 'Category name')
    assert.equal(table.dateFormat.resolvedOptions().locale, 'en-US')
    assert.equal(list.t(list.message), 'Status updated')
    assert.equal(login.errorMessage, 'Login failed')
    assert.equal(editor.t(editor.mutation.error.value.message), 'Name required')
    assert.equal(editor.form.locale, 'vi')
    editor.update('name', 'Food')
    assert.equal(editor.canLeave(), false)
    globalThis.window.confirm = () => true
    assert.equal(editor.canLeave(), true)
    editor.unsaved.busy = true
    assert.equal(editor.canLeave(), false)
    editor.unsaved.busy = false

    const deletions = []
    const dialog = await mount('/src/components/categories/CategoryDeleteDialog.vue', { onDelete: input => deletions.push(input), preview: { category: { id: 'source', name: 'Food' }, counts: { draft: 1 }, version: 'snapshot' }, targets: [] })
    assert.equal(dialog.canDelete, false)
    dialog.targetId = 'target'
    assert.equal(dialog.canDelete, true)
    dialog.mode = 'purge'
    assert.equal(dialog.canDelete, true)
    dialog.submit()
    assert.deepEqual(deletions, [{ id: 'source', mode: 'purge', targetId: 'target', confirmation: 'Food', version: 'snapshot' }])
    dialog.refresh()
    assert.equal(dialog.canDelete, true)
  } finally {
    for (const app of apps.reverse()) app.unmount()
    queryClient.clear()
    globalThis.window = originalWindow
    await server.close()
  }
})
