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
    { id: 'word-recent', game_type: 'word', title: 'Recent word', category_name: 'Food', status: 'published', updated_at: '2026-10-20T12:00:00Z' },
    { id: 'question-recent', game_type: 'question', title: 'Recent question', category_name: 'Travel', status: 'archived', updated_at: '2026-10-20T11:00:00Z' },
  ],
  drafts: [
    { id: 'word-draft', game_type: 'word', title: 'Draft word', category_name: 'Food', status: 'draft', updated_at: '2026-10-20T10:00:00Z' },
    { id: 'question-draft', game_type: 'question', title: 'Draft question', category_name: 'Travel', status: 'draft', updated_at: '2026-10-20T09:00:00Z' },
  ],
  warnings: { empty_categories: 1, duplicate_questions: 2, non_family_easy_prompts: 3 },
}
const emptySummary = {
  stats: { published_word_prompts: 0, published_question_prompts: 0, active_categories: 0, drafts: 0 },
  recent: [], drafts: [], warnings: { empty_categories: 0, duplicate_questions: 0, non_family_easy_prompts: 0 },
}
const routeStub = { render: () => null }

async function dashboardHarness(result: (call: number) => Promise<MockResult>) {
  const server = await createServer({ server: { middlewareMode: true, hmr: false, ws: false }, mode: 'localdev' })
  const queryClient = new QueryClient({ defaultOptions: { queries: { enabled: false, gcTime: Infinity, staleTime: Infinity } } })
  const router = createRouter({ history: createMemoryHistory(), routes: [
    { path: '/dashboard', name: 'dashboard', component: routeStub },
    { path: '/categories', name: 'categories', component: routeStub },
    { path: '/word-prompts', name: 'word-prompts', component: routeStub },
    { path: '/question-prompts', name: 'question-prompts', component: routeStub },
    { path: '/word-prompts/:id/edit', name: 'word-prompt-edit', component: routeStub },
    { path: '/question-prompts/:id/edit', name: 'question-prompt-edit', component: routeStub },
  ] })
  await router.push('/dashboard')
  const supabase = (await server.ssrLoadModule('/src/lib/supabase.ts')).supabase as ClientStub
  const originalRpc = supabase.rpc
  let calls = 0
  supabase.rpc = async name => {
    assert.equal(name, 'admin_dashboard_summary')
    return result(++calls)
  }
  const component = (await server.ssrLoadModule('/src/views/dashboard/DashboardView.vue')).default
  const i18n = createI18n({ legacy: false, locale: 'vi', messages: { vi: vn } })
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
    server, queryClient, router, supabase, originalRpc, component, calls: () => calls, ssrApp, interactiveApp,
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
    harness.queryClient.setQueryData(['dashboard', 'summary'], summary)
    const html = (await renderToString(harness.ssrApp())).replaceAll('&amp;', '&')
    for (const value of ['11', '22', '33', '44', 'Recent word', 'Recent question', 'Draft word', 'Draft question', 'Food', 'Travel']) assert.ok(html.includes(value), `missing ${value}`)
    for (const value of ['aria-label="Xem tất cả từ ngữ"', 'aria-label="Xem tất cả câu hỏi"', 'aria-label="Xem bản nháp từ ngữ"', 'aria-label="Xem bản nháp câu hỏi"', '>Tất cả từ ngữ</a>', '>Tất cả câu hỏi</a>', '>Nháp · Từ ngữ</a>', '>Nháp · Câu hỏi</a>']) assert.ok(html.includes(value), `missing ${value}`)
    assert.doesNotMatch(html, /Tối đa 5 (nội dung|bản nháp)/)
    for (const warning of ['Danh mục không có nội dung: 1', 'Cặp câu hỏi civilian và imposter bị trùng: 2', 'Nội dung mức dễ chưa được đánh dấu phù hợp với Family Mode: 3']) assert.ok(html.includes(warning), `missing ${warning}`)
    for (const href of [
      '/word-prompts/word-recent/edit', '/question-prompts/question-recent/edit',
      '/word-prompts/word-draft/edit', '/question-prompts/question-draft/edit',
      '/word-prompts', '/question-prompts', '/word-prompts?status=draft', '/question-prompts?status=draft',
      '/categories',
      '/word-prompts?difficulty=easy&family=false', '/question-prompts?difficulty=easy&family=false',
    ]) assert.ok(html.includes(`href="${href}"`), `missing link ${href}`)
    assert.deepEqual(harness.queryClient.getQueryCache().getAll().map(query => query.queryKey), [['dashboard', 'summary']])
  } finally { await harness.close() }
})

test('dashboard shows clear empty states when there are no rows or warnings', async () => {
  const harness = await dashboardHarness(async () => ({ data: emptySummary }))
  try {
    harness.queryClient.setQueryData(['dashboard', 'summary'], emptySummary)
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
    await harness.queryClient.fetchQuery({ queryKey: ['dashboard', 'summary'], queryFn: () => getDashboardSummary(asClient(harness.supabase)), retry: false }).catch(() => {})
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
