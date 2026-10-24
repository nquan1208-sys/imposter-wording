import { testWindow, setupState } from './helpers.ts'
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


for (const [kind, cap, field, other] of [['word', 'Word', 'text', null], ['question', 'Question', 'civilian_question', 'imposter_question']] as const) {
 test(`${kind} translation drafts survive first save and remain independent across language tabs`, async () => {
  const server = await createServer({ server: { middlewareMode: true, hmr: false, ws: false }, mode: 'localdev' })
  const originalWindow = globalThis.window
  const cache = new QueryClient({ defaultOptions: { queries: { enabled: false, refetchOnMount: false, gcTime: Infinity } } })
  const category = '00000000-0000-4000-8000-000000000001'
  let app: TestApp | undefined
  try {
   globalThis.window = testWindow({ addEventListener() {}, removeEventListener() {}, confirm: () => false })
   const router = createRouter({ history: createMemoryHistory(), routes: [
    { path: `/${kind}-prompts/new`, name: `${kind}-prompt-new`, component: stub },
    { path: `/${kind}-prompts/:id/edit`, name: `${kind}-prompt-edit`, component: stub },
    { path: `/${kind}-prompts`, name: `${kind}-prompts`, component: stub },
   ] })
   await router.push({ name: `${kind}-prompt-new`, query: { locale: 'vi' } })
   const { provideUnsavedChanges } = await server.ssrLoadModule('/src/utils/unsavedChanges.ts')
   const client = (await server.ssrLoadModule('/src/lib/supabase.ts')).supabase as ClientStub
   let latest: Record<string, unknown> | null = null
   client.from = () => {
    const query = {} as QueryStub
    for (const name of ['select', 'eq', 'single', 'order', 'range']) query[name] = () => query
    query.then = resolve => Promise.resolve({ data: latest }).then(resolve)
    return query
   }
   let finish!: (result: MockResult) => void
   const calls: Record<string, unknown>[] = []
   client.rpc = async (name, input) => { assert.equal(name, `save_${kind}_prompt`); calls.push(input); return new Promise<MockResult>(resolve => { finish = resolve }) }
   cache.setQueryData(['content-languages'], [{ code: 'vi', display_name: 'Tiếng Việt' }, { code: 'en', display_name: 'English' }, { code: 'fr', display_name: 'Français' }])
   for (const prefix of ['dashboard', 'categories', 'word-prompts', 'question-prompts']) {
     for (const locale of ['vi', 'en', 'fr']) cache.setQueryData([prefix, 'list', locale], { fixture: true })
   }
   const component = (await server.ssrLoadModule(`/src/views/${kind}-prompts/${cap}PromptFormView.vue`)).default
   const i18n = createI18n({ legacy: false, locale: 'vi', messages: { vi: vn, en: {} }, missingWarn: false, fallbackWarn: false })
   app = renderer.createApp({ setup() { provideUnsavedChanges(); return () => h({ ...component, render: () => h('div') }) } })
    .use(router).use(VueQueryPlugin, { queryClient: cache }).use(i18n)
   app.provide(ssrContextKey, {}); app.provide(matchedRouteKey, computed(() => router.currentRoute.value.matched[0]))
   const editor = setupState(app.mount(node()).$.subTree.component)
   const tick = async () => { await nextTick(); await new Promise(resolve => setTimeout(resolve, 10)) }
   assert.equal(editor.unsaved.dirty, false)
   editor.update(field, 'Vietnamese draft'); if (other) editor.update(other, 'Other Vietnamese')
   editor.update('category_id', category)
   editor.selectLocale('en'); await tick()
   assert.equal(editor.form[field], ''); assert.equal(editor.form.category_id, category, 'shared category survives tab switch')
   editor.update(field, 'English'); if (other) editor.update(other, 'Other English')
   i18n.global.locale.value = 'en'; await tick(); assert.equal(editor.form.locale, 'en')
   editor.submit('published'); editor.submit('archived'); await tick()
   assert.equal(calls.length, 1); assert.equal(calls[0]!.p_locale, 'en'); assert.equal(calls[0]!.p_expected_updated_at, null)
   editor.selectLocale('vi'); assert.equal(editor.form.locale, 'en', 'busy switch blocked')
   const original = { id: calls[0]!.p_id, category_id: category, difficulty: 'medium', is_family_friendly: false, image_path: null, updated_at: 'version-1' }
   const translation = { prompt_id: original.id, locale: 'en', [field]: 'English', ...(other ? { [other]: 'Other English' } : {}), status: 'published' }
   latest = { ...original, translations: [translation], game_categories: null }
   finish({ data: { original, translation } }); await tick()
   for (const prefix of ['dashboard', 'categories', 'word-prompts', 'question-prompts']) {
     for (const locale of ['vi', 'en', 'fr']) assert.equal(cache.getQueryState([prefix, 'list', locale])!.isInvalidated, true, `${prefix}/${locale} refreshed after save`)
   }
   assert.equal(router.currentRoute.value.name, `${kind}-prompt-edit`)
   assert.equal(editor.unsaved.busy, false); assert.equal(editor.unsaved.dirty, true)
   editor.selectLocale('vi'); await tick(); assert.equal(editor.form[field], 'Vietnamese draft')
   editor.submit('draft'); await tick(); assert.equal(calls[1]!.p_expected_updated_at, 'version-1')
   const vietnamese = { ...translation, locale: 'vi', [field]: 'Vietnamese draft', ...(other ? { [other]: 'Other Vietnamese' } : {}), status: 'draft' }
   latest = { ...original, updated_at: 'version-2', translations: [translation, vietnamese], game_categories: null }
   finish({ data: { original: { ...original, updated_at: 'version-2' }, translation: vietnamese } }); await tick()
   assert.equal(editor.unsaved.dirty, false)
   editor.selectLocale('en'); await tick(); assert.equal(editor.form[field], 'English'); assert.equal(editor.activeTranslation.status, 'published')
   editor.selectLocale('fr'); await tick(); assert.equal(editor.form[field], ''); assert.equal(editor.unsaved.dirty, false)
   editor.update(field, 'French'); if (other) editor.update(other, 'Other French')
   editor.submit('draft'); await tick(); assert.equal(calls[2]!.p_expected_updated_at, 'version-2')
   finish({ error: new Error('offline') }); await tick(); assert.equal(editor.form[field], 'French'); assert.equal(editor.unsaved.dirty, true)
   editor.submit('draft'); await tick(); finish({ error: { code: 'PT409' } }); await tick()
   assert.equal(editor.saveConflict, true); editor.submit('draft'); assert.equal(calls.length, 4)
   await editor.reload(); assert.equal(editor.form[field], 'French', 'cancelled reload preserves draft')
   globalThis.window.confirm = () => true; await editor.reload(); await tick()
   assert.equal(editor.form[field], ''); assert.equal(editor.unsaved.dirty, false); assert.equal(editor.saveConflict, false)
   await router.replace({ query: { locale: '__proto__' } }); await tick()
   assert.equal(editor.form.locale, 'vi'); assert.equal(editor.unsaved.dirty, false, 'unknown locale normalizes with cached languages')
   editor.update(field, ''); editor.submit('draft'); assert.ok(editor.localError)
   await router.push({ name: `${kind}-prompt-new`, query: { locale: 'en' } }); await tick()
   assert.equal(editor.saved, null); assert.equal(editor.form[field], ''); assert.equal(editor.localError, null)
   assert.equal(editor.unsaved.dirty, false); assert.equal(editor.currentStatus, 'draft')
  } finally { app?.unmount(); cache.clear(); globalThis.window = originalWindow; await server.close() }
 })
}
