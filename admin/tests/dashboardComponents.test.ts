import { setupState } from './helpers.ts'
import type { ClientStub, MockResult } from './helpers.ts'
import test from 'node:test'
import assert from 'node:assert/strict'
import { createServer } from 'vite'
import { computed, createRenderer, createSSRApp, h, nextTick, ssrContextKey } from 'vue'
import { renderToString } from 'vue/server-renderer'
import { createI18n } from 'vue-i18n'
import { createMemoryHistory, createRouter, matchedRouteKey } from 'vue-router'
import { QueryClient, VueQueryPlugin } from '@tanstack/vue-query'
import { readFile } from 'node:fs/promises'
import { asClient } from './helpers.ts'
import { getDashboardSummary } from '../src/api/dashboard.ts'

const vn = JSON.parse(await readFile(new URL('../src/i18n/locales/vn.json', import.meta.url), 'utf8'))
type TestNode = { tag: string; props: Record<string, unknown>; text: string; children: TestNode[]; parent: TestNode | null }
const node = (tag = '#root', text = ''): TestNode => ({ tag, text, props: {}, children: [], parent: null })
const renderer = createRenderer<TestNode, TestNode>({
  createElement: tag => node(tag), createText: text => node('#text', text), createComment: () => node('#comment'),
  setText: (element, text) => { element.text = text },
  setElementText: (element, text) => { element.text = text; element.children = [] },
  patchProp: (element, key, _previous, value) => { element.props[key] = value },
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
const summary = {
  stats: { published_word_prompts: 11, published_question_prompts: 22, active_categories: 33, drafts: 44 },
  recent: [
    { locale: 'vi', id: 'word-recent', game_type: 'word', title: 'Recent word', category_name: 'Food', status: 'published', updated_at: '2026-10-20T12:00:00Z' },
    { locale: 'vi', id: 'question-recent', game_type: 'question', title: 'Recent question', category_name: 'Travel', status: 'archived', updated_at: '2026-10-20T11:00:00Z' },
  ],
  drafts: [
    { locale: 'vi', id: 'word-draft', game_type: 'word', title: 'Draft word', category_name: 'Food', status: 'draft', updated_at: '2026-10-20T10:00:00Z' },
    { locale: 'vi', id: 'question-draft', game_type: 'question', title: 'Draft question', category_name: 'Travel', status: 'draft', updated_at: '2026-10-20T09:00:00Z' },
  ],
  warnings: { empty_categories: 1, duplicate_questions: 2, non_family_easy_prompts: 3 },
}
const emptySummary = {
  stats: { published_word_prompts: 0, published_question_prompts: 0, active_categories: 0, drafts: 0 },
  recent: [], drafts: [], warnings: { empty_categories: 0, duplicate_questions: 0, non_family_easy_prompts: 0 },
}
const routeStub = { render: () => null }

async function dashboardHarness(result: (call: number, locale: unknown) => Promise<MockResult>, initialLocale?: string) {
  const server = await createServer({ server: { middlewareMode: true, hmr: false, ws: false }, mode: 'localdev' })
  const queryClient = new QueryClient({ defaultOptions: { queries: { enabled: false, gcTime: Infinity, staleTime: Infinity, retryOnMount: false } } })
  const router = createRouter({ history: createMemoryHistory(), routes: [
    { path: '/dashboard', name: 'dashboard', component: routeStub },
    { path: '/categories', name: 'categories', component: routeStub },
    { path: '/word-prompts', name: 'word-prompts', component: routeStub },
    { path: '/question-prompts', name: 'question-prompts', component: routeStub },
    { path: '/word-prompts/:id/edit', name: 'word-prompt-edit', component: routeStub },
    { path: '/question-prompts/:id/edit', name: 'question-prompt-edit', component: routeStub },
  ] })
  await router.push({ name: 'dashboard', query: initialLocale ? { locale: initialLocale } : {} })
  queryClient.setQueryData(['content-languages'], [{ code: 'vi', display_name: 'Tiếng Việt' }, { code: 'en', display_name: 'English' }, { code: 'fr', display_name: 'Français' }])
  const supabase = (await server.ssrLoadModule('/src/lib/supabase.ts')).supabase as ClientStub
  const originalRpc = supabase.rpc
  let calls = 0
  supabase.rpc = async (name, input) => {
    assert.equal(name, 'admin_dashboard_summary')
    return result(++calls, input.p_locale)
  }
  const component = (await server.ssrLoadModule('/src/views/dashboard/DashboardView.vue')).default
  const i18n = createI18n({ legacy: false, locale: 'vi', messages: { vi: vn, en: vn } })
  function ssrApp() {
    const view = createSSRApp(component)
    view.use(router).use(i18n).use(VueQueryPlugin, { queryClient })
    view.provide(matchedRouteKey, computed(() => router.currentRoute.value.matched[0]))
    return view
  }
  function interactiveApp() {
    const view = renderer.createApp({ ...component, render: () => h('div') })
    view.use(router).use(i18n).use(VueQueryPlugin, { queryClient })
    view.provide(ssrContextKey, {})
    view.provide(matchedRouteKey, computed(() => router.currentRoute.value.matched[0]))
    return view
  }
  return {
    server, queryClient, router, supabase, originalRpc, component, i18n, calls: () => calls, ssrApp, interactiveApp,
    async close(apps: { unmount(): void }[] = []) {
      for (const mounted of apps.reverse()) mounted.unmount()
      queryClient.clear(); supabase.rpc = originalRpc
      await server.close()
    },
  }
}

test('dashboard shows a loading status while the summary query is pending', async () => {
  const harness = await dashboardHarness(async () => new Promise(() => {}))
  try {
    const html = await renderToString(harness.ssrApp())
    assert.match(html, /role="status"/)
    assert.match(html, /Đang tải tổng quan/)
  } finally { await harness.close() }
})

test('dashboard renders statistics, prompt links and warning destinations', async () => {
  const harness = await dashboardHarness(async () => ({ data: summary }))
  try {
    harness.queryClient.setQueryData(['dashboard', 'summary', 'vi'], summary)
    const html = (await renderToString(harness.ssrApp())).replaceAll('&amp;', '&')
    for (const value of ['11', '22', '33', '44', 'Recent word', 'Recent question', 'Draft word', 'Draft question', 'Food', 'Travel']) assert.ok(html.includes(value), `missing ${value}`)
    for (const value of ['aria-label="Xem tất cả từ ngữ"', 'aria-label="Xem tất cả câu hỏi"', 'aria-label="Xem bản nháp từ ngữ"', 'aria-label="Xem bản nháp câu hỏi"', '>Tất cả từ ngữ</a>', '>Tất cả câu hỏi</a>', '>Nháp · Từ ngữ</a>', '>Nháp · Câu hỏi</a>']) assert.ok(html.includes(value), `missing ${value}`)
    assert.doesNotMatch(html, /Tối đa 5 (nội dung|bản nháp)/)
    for (const warning of ['Danh mục không có nội dung: 1', 'Cặp câu hỏi dân thường và kẻ mạo danh bị trùng: 2', 'Nội dung mức dễ chưa được đánh dấu phù hợp với chế độ gia đình: 3']) assert.ok(html.includes(warning), `missing ${warning}`)
    for (const href of [
      '/word-prompts/word-recent/edit?locale=vi', '/question-prompts/question-recent/edit?locale=vi',
      '/word-prompts/word-draft/edit?locale=vi', '/question-prompts/question-draft/edit?locale=vi',
      '/word-prompts?locale=vi', '/question-prompts?locale=vi', '/word-prompts?locale=vi&status=draft', '/question-prompts?locale=vi&status=draft',
      '/categories?locale=vi',
      '/word-prompts?locale=vi&difficulty=easy&family=false', '/question-prompts?locale=vi&difficulty=easy&family=false',
    ]) assert.ok(html.includes(`href="${href}"`), `missing link ${href}`)
    assert.deepEqual(harness.queryClient.getQueryCache().getAll().map(query => query.queryKey), [['content-languages'], ['dashboard', 'summary', 'vi']])
  } finally { await harness.close() }
})

test('dashboard shows clear empty states when there are no rows or warnings', async () => {
  const harness = await dashboardHarness(async () => ({ data: emptySummary }))
  try {
    harness.queryClient.setQueryData(['dashboard', 'summary', 'vi'], emptySummary)
    const html = await renderToString(harness.ssrApp())
    assert.match(html, /Chưa có nội dung cập nhật/)
    assert.match(html, /Không có bản nháp cần xử lý/)
    assert.match(html, /Không có cảnh báo dữ liệu/)
  } finally { await harness.close() }
})

test('dashboard error exposes retry and its action refetches successfully', async () => {
  const harness = await dashboardHarness(async call => call === 1 ? { data: null, error: new Error('offline') } : { data: summary })
  const apps: { unmount(): void }[] = []
  try {
    await harness.queryClient.fetchQuery({ queryKey: ['dashboard', 'summary', 'vi'], queryFn: () => getDashboardSummary(asClient(harness.supabase)), retry: false }).catch(() => {})
    const html = await renderToString(harness.ssrApp())
    assert.match(html, /role="alert"/)
    assert.match(html, /Thử lại/)
    assert.doesNotMatch(html, /class="dashboard-stats"/)
    assert.equal(harness.calls(), 1, 'failed request does not retry automatically')
    const app = harness.interactiveApp()
    apps.push(app)
    const state = setupState(app.mount(node()).$)
    await state.retry()
    await new Promise(resolve => setTimeout(resolve, 0))
    await nextTick()
    assert.equal(harness.calls(), 2)
    assert.equal(state.summary.data.value.recent[0].title, 'Recent word')
  } finally { await harness.close(apps) }
})

const tick = async () => { await new Promise(resolve => setTimeout(resolve, 0)); await nextTick() }

test('dashboard separates content language, URLs and caches and invalidates every locale', async () => {
  const requested: unknown[] = []
  let resolveEnglish!: (value: MockResult) => void
  const harness = await dashboardHarness(async (_call, locale) => {
    requested.push(locale)
    if (locale === 'en') return new Promise(resolve => { resolveEnglish = resolve })
    return { data: emptySummary }
  })
  const app = harness.interactiveApp()
  try {
    harness.queryClient.setQueryData(['dashboard', 'summary', 'vi'], summary)
    const state = setupState(app.mount(node()).$)
    harness.i18n.global.locale.value = 'en'
    await tick()
    assert.equal(state.contentLocale, 'vi')
    assert.equal(state.dateFormat.resolvedOptions().locale, 'en-US')
    assert.equal(harness.calls(), 0)
    await state.selectLocale('en'); await tick()
    assert.equal(state.summary.data.value, undefined, 'Vietnamese data never appears under English')
    assert.equal(state.summary.isPending.value, true)
    resolveEnglish({ data: emptySummary }); await tick()
    assert.equal(state.summary.data.value.stats.drafts, 0)
    await state.selectLocale('fr'); await tick()
    assert.equal(harness.router.currentRoute.value.query.locale, 'fr')
    assert.deepEqual(requested, ['en', 'fr'])
    await harness.router.replace({ query: { locale: '__proto__' } }); await tick()
    assert.equal(harness.router.currentRoute.value.query.locale, 'vi')
    assert.equal(state.summary.data.value.stats.drafts, 44)
    assert.deepEqual(requested, ['en', 'fr'], 'unknown locale never reaches RPC')
    await harness.queryClient.invalidateQueries({ queryKey: ['dashboard'], refetchType: 'none' })
    for (const locale of ['vi', 'en', 'fr']) assert.equal(harness.queryClient.getQueryState(['dashboard', 'summary', locale])!.isInvalidated, true)
  } finally { await harness.close([app]) }
})

test('dashboard uses each item locale, accepts nullable category names and keeps locale on list links', async () => {
  const harness = await dashboardHarness(async () => ({ data: summary }), 'fr')
  try {
    harness.queryClient.setQueryData(['dashboard', 'summary', 'fr'], {
      ...summary, recent: [{ ...summary.recent[0], locale: 'en', category_name: null }],
      drafts: [{ ...summary.drafts[0], locale: 'en', category_name: null }],
    })
    const html = (await renderToString(harness.ssrApp())).replaceAll('&amp;', '&')
    assert.ok(html.includes('href="/word-prompts/word-recent/edit?locale=en"'))
    assert.ok(html.includes('href="/word-prompts/word-draft/edit?locale=en"'))
    assert.ok(html.includes('href="/question-prompts?locale=fr&status=draft"'))
    assert.ok(html.includes('href="/categories?locale=fr"'))
    assert.ok(html.includes('href="/word-prompts?locale=fr&difficulty=easy&family=false"'))
    assert.doesNotMatch(html, />null</)
  } finally { await harness.close() }
})

test('dashboard waits for language discovery and recovers from its failure', async () => {
  const harness = await dashboardHarness(async () => ({ data: emptySummary }))
  const originalFrom = harness.supabase.from
  let attempts = 0
  harness.queryClient.removeQueries({ queryKey: ['content-languages'] })
  harness.supabase.from = () => {
    const builder = { select() { return builder }, order() { return builder }, then(resolve: (value: MockResult) => unknown) {
      return Promise.resolve(++attempts === 1 ? { error: new Error('offline') } : { data: [{ code: 'vi', display_name: 'Tiếng Việt' }] }).then(resolve)
    } }
    return builder as ReturnType<ClientStub['from']>
  }
  const app = harness.interactiveApp()
  try {
    const state = setupState(app.mount(node()).$)
    assert.equal(harness.calls(), 0)
    await state.languages.refetch(); await tick()
    assert.equal(state.languages.isError.value, true)
    assert.equal(harness.calls(), 0, 'summary cannot run with an unvalidated language')
    const html = await renderToString(harness.ssrApp())
    assert.match(html, /role="alert"/)
    await state.languages.refetch(); await tick()
    assert.equal(state.languages.isError.value, false)
    assert.equal(harness.calls(), 1)
  } finally { harness.supabase.from = originalFrom; await harness.close([app]) }
})
