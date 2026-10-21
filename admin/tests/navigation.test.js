import test from 'node:test'
import assert from 'node:assert/strict'
import { readFile, mkdtemp, rm } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { parse, compileScript } from '@vue/compiler-sfc'
import { createServer } from 'vite'
import { createRenderer, h, nextTick, watchEffect } from 'vue'
import { RouterView } from 'vue-router'
import { QueryClient, VueQueryPlugin } from '@tanstack/vue-query'
import { createI18n } from 'vue-i18n'

const node = (tag = '', text = '') => ({ tag, text, props: {}, children: [], parent: null })
const renderer = createRenderer({
  createElement: tag => node(tag), createText: text => node('', text), createComment: () => node(),
  setText: (element, text) => { element.text = text }, setElementText: (element, text) => { element.text = text; element.children = [] },
  patchProp: (element, key, _, value) => { element.props[key] = value },
  parentNode: element => element.parent,
  nextSibling: element => element.parent?.children[element.parent.children.indexOf(element) + 1],
  insert(element, parent, anchor) {
    if (element.parent) element.parent.children.splice(element.parent.children.indexOf(element), 1)
    const index = anchor ? parent.children.indexOf(anchor) : -1
    parent.children.splice(index < 0 ? parent.children.length : index, 0, element); element.parent = parent
  },
  remove(element) { element.parent?.children.splice(element.parent.children.indexOf(element), 1); element.parent = null },
})
function nodes(root) { return [root, ...root.children.flatMap(nodes)] }
function text(root) { return [root.text, ...root.children.map(text)].join(' ') }

test('sidebar navigation renders only the current page and retains form leave guards', async () => {
  // Compile client templates: setup-only and SSR tests cannot catch stale rendered views.
  const cacheDir = await mkdtemp(join(tmpdir(), 'admin-navigation-'))
  const server = await createServer({ configFile: false, cacheDir, mode: 'localdev', optimizeDeps: { noDiscovery: true }, server: { middlewareMode: true, hmr: false, ws: false }, plugins: [{
    name: 'navigation-client-templates',
    transform(source, id) {
      if (id.endsWith('/src/router/index.js')) return source.replaceAll('createWebHistory', 'createMemoryHistory')
      if (id.endsWith('.vue')) return compileScript(parse(source, { filename: id }).descriptor, { id, inlineTemplate: true }).content
    },
  }] })
  const queryClient = new QueryClient({ defaultOptions: { queries: { enabled: false, gcTime: Infinity } } })
  const originalWindow = globalThis.window
  let app
  try {
    globalThis.window = { addEventListener() {}, removeEventListener() {}, confirm: () => false }
    const vn = JSON.parse(await readFile(new URL('../src/i18n/locales/vn.json', import.meta.url)))
    const { supabase } = await server.ssrLoadModule('/src/lib/supabase.js')
    supabase.auth.getUser = async () => ({ data: { user: { email: 'admin@example.test' } } })
    supabase.auth.getSession = async () => ({ data: { session: { user: { id: 'admin' } } } })
    supabase.from = table => {
      const query = {}
      for (const method of ['select', 'eq', 'order', 'range', 'maybeSingle']) query[method] = () => query
      query.then = resolve => resolve({ data: table === 'admin_users' ? { user_id: 'admin' } : [], count: 0 })
      return query
    }
    const { default: router } = await server.ssrLoadModule('/src/router/index.js')
    await router.push('/dashboard')
    app = renderer.createApp({ render: () => h(RouterView) }).use(router).use(VueQueryPlugin, { queryClient }).use(createI18n({ legacy: false, locale: 'vi', messages: { vi: vn } }))
    const ui = { inheritAttrs: false, setup: (_, { attrs, slots }) => () => h('div', attrs, [attrs.label, slots.default?.({ errors: [] }), slots.body?.({}), slots.actions?.({})]) }
    for (const name of ['UButton', 'UAvatar', 'UAlert', 'UBreadcrumb', 'UCard', 'USkeleton', 'UInput', 'USelectMenu', 'UFormField', 'UCheckbox', 'UForm', 'UTextarea', 'UPagination', 'UBadge', 'UIcon', 'USwitch']) app.component(name, ui)
    app.component('USelect', { props: ['items', 'modelValue'], setup(props, context) {
      // Reka SelectItem reserves the empty string for clearing, not an option.
      watchEffect(() => assert.ok(props.items.every(item => item.value !== ''), 'select options must have nonempty values'))
      return () => h('div', { ...context.attrs, modelValue: props.modelValue })
    } })
    app.component('UTable', { render: () => h('div') })
    const root = node('root'); app.mount(root)
    async function clickTab(name) {
      const link = nodes(root).find(element => element.tag === 'a' && element.props.href === `/${name}` && element.props.class?.includes('nav-item'))
      assert.ok(link, `sidebar link ${name}`)
      for (const click of [link.props.onClick].flat()) await click({ button: 0, preventDefault() {} })
      await nextTick()
      assert.equal(router.currentRoute.value.name, name)
      const content = nodes(root).find(element => element.props.class === 'page-content')
      return content
    }
    await router.push('/word-prompts?difficulty=hard&status=published&search=all'); await nextTick()
    for (const [field, selected] of [['difficulty', 'hard'], ['status', 'published']]) {
      const select = nodes(root).find(element => element.props.modelValue === selected)
      select.props['onUpdate:modelValue']('all'); await nextTick()
      await new Promise(resolve => setTimeout(resolve, 0))
      assert.equal(router.currentRoute.value.query[field], undefined)
      assert.equal(router.currentRoute.value.query.search, 'all')
    }
    for (const name of ['categories', 'word-prompts', 'question-prompts', 'dashboard', 'word-prompts', 'categories']) {
      const content = await clickTab(name)
      const view = router.currentRoute.value.matched[1].instances.default
      const expected = { categories: 'CategoriesView', 'word-prompts': 'WordPromptsView', 'question-prompts': 'QuestionPromptsView', dashboard: 'DashboardView' }[name]
      assert.equal(view.$.type.__name, expected)
      assert.equal(content.children.filter(element => element.tag === 'section').length, 1)
      if (name === 'categories') { assert.match(text(content), /Thêm danh mục/); assert.doesNotMatch(text(content), /Tạo đề từ ngữ/) }
      if (name === 'word-prompts') { assert.match(text(content), /Tạo đề từ ngữ/); assert.doesNotMatch(text(content), /Thêm danh mục/) }
      if (name === 'dashboard' || name === 'question-prompts') assert.doesNotMatch(text(content), /Tạo đề từ ngữ|Thêm danh mục/)
    }
    await router.push('/word-prompts/new'); await nextTick()
    assert.doesNotMatch(text(root), /Từ imposter|Hint imposter/)
    const preview = nodes(root).find(element => String(element.props.class).includes('word-preview-imposter'))
    assert.match(text(preview), /Gợi ý danh mục/)
    assert.match(text(preview), /Bạn là imposter/)
    const hint = nodes(preview).find(element => element.props.label === vn.wordPrompts.preview.categoryHint)
    hint.props['onUpdate:modelValue'](true); await nextTick()
    assert.match(text(preview), /Chọn danh mục để xem trước/)
    assert.doesNotMatch(text(preview), /Bạn là imposter/)
    const category = '00000000-0000-4000-8000-000000000002'
    queryClient.setQueryData(['categories', 'word-options', 'vi'], [{ id: category, name: 'Food category', locale: 'vi', is_active: true }])
    await nextTick()
    const picker = nodes(root).find(element => element.props['value-key'] === 'value')
    picker.props['onUpdate:modelValue'](category); await nextTick()
    assert.match(text(preview), /Food category/)
    const otherCategory = '00000000-0000-4000-8000-000000000003'
    queryClient.setQueryData(['categories', 'word-options', 'vi'], [{ id: otherCategory, name: 'Movie category', locale: 'vi', is_active: true }])
    await nextTick()
    picker.props['onUpdate:modelValue'](otherCategory); await nextTick()
    assert.match(text(preview), /Movie category/)
    assert.doesNotMatch(text(preview), /Food category/)
    hint.props['onUpdate:modelValue'](false); await nextTick()
    assert.match(text(preview), /Bạn là imposter/)
    assert.doesNotMatch(text(preview), /Movie category/)
    // Inline templates do not expose setup bindings; exercise the rendered input handler.
    const civilian = nodes(root).find(element => element.props.label === vn.wordPrompts.fields.text)
    const input = nodes(civilian).find(element => element.props['onUpdate:modelValue'])
    input.props['onUpdate:modelValue']('Unsaved apple'); await nextTick()
    assert.doesNotMatch(text(preview), /Unsaved apple/)
    assert.equal(nodes(preview).some(element => element.tag === 'img'), false)
    await router.push('/categories'); await nextTick()
    assert.equal(router.currentRoute.value.name, 'word-prompt-new')
    globalThis.window.confirm = () => true
    await router.push('/categories'); await nextTick()
    assert.equal(router.currentRoute.value.name, 'categories')
  } finally {
    try { app?.unmount() }
    finally { queryClient.clear(); globalThis.window = originalWindow; await server.close(); await rm(cacheDir, { recursive: true, force: true }) }
  }
})
