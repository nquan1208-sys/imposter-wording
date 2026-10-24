import { testWindow } from './helpers.ts'
import type { NavigationNode, StubContext, QueryStub, ClientStub } from './helpers.ts'
import test from 'node:test'
import assert from 'node:assert/strict'
import { readFile, mkdtemp, rm } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { parse, compileScript } from '@vue/compiler-sfc'
import { createServer, transformWithOxc } from 'vite'
import { defineComponent, createRenderer, h, nextTick, watchEffect } from 'vue'
import { RouterView } from 'vue-router'
import { QueryClient, VueQueryPlugin } from '@tanstack/vue-query'
import { createI18n } from 'vue-i18n'

const node = (tag = '', text = ''): NavigationNode => ({ tag, text, props: {}, children: [], parent: null })
const renderer = createRenderer<NavigationNode, NavigationNode>({
  createElement: tag => node(tag), createText: text => node('', text), createComment: () => node(),
  setText: (element, text) => { element.text = text }, setElementText: (element, text) => { element.text = text; element.children = [] },
  patchProp: (element, key, _, value) => { element.props[key] = value },
  parentNode: element => element.parent,
  nextSibling: element => element.parent?.children[element.parent.children.indexOf(element) + 1] ?? null,
  insert(element, parent, anchor) {
    if (element.parent) element.parent.children.splice(element.parent.children.indexOf(element), 1)
    const index = anchor ? parent.children.indexOf(anchor) : -1
    parent.children.splice(index < 0 ? parent.children.length : index, 0, element); element.parent = parent
  },
  remove(element) { element.parent?.children.splice(element.parent.children.indexOf(element), 1); element.parent = null },
})
function nodes(root: NavigationNode): NavigationNode[] { return [root, ...root.children.flatMap(nodes)] }
function text(root: NavigationNode): string { return [root.text, ...root.children.map(text)].join(' ') }

test('sidebar navigation renders only the current page and retains form leave guards', async () => {
  // Compile client templates: setup-only and SSR tests cannot catch stale rendered views.
  const cacheDir = await mkdtemp(join(tmpdir(), 'admin-navigation-'))
  const server = await createServer({ configFile: false, cacheDir, mode: 'localdev', optimizeDeps: { noDiscovery: true }, server: { middlewareMode: true, hmr: false, ws: false }, plugins: [{
    name: 'navigation-client-templates',
    async transform(source, id) {
      if (id.endsWith('/src/router/index.ts')) return source.replaceAll('createWebHistory', 'createMemoryHistory')
      if (id.endsWith('.vue')) return transformWithOxc(compileScript(parse(source, { filename: id }).descriptor, { id, inlineTemplate: true }).content, id + '.ts', { lang: 'ts' })
    },
  }] })
  const queryClient = new QueryClient({ defaultOptions: { queries: { enabled: false, gcTime: Infinity } } })
  const originalWindow = globalThis.window
  let app: import('vue').App<NavigationNode> | undefined
  try {
    globalThis.window = testWindow({ addEventListener() {}, removeEventListener() {}, confirm: () => false })
    const vn = JSON.parse(await readFile(new URL('../src/i18n/locales/vn.json', import.meta.url), 'utf8'))
    const supabase = (await server.ssrLoadModule('/src/lib/supabase.ts')).supabase as ClientStub
    supabase.auth.getUser = async () => ({ data: { user: { email: 'admin@example.test' } } })
    supabase.auth.getSession = async () => ({ data: { session: { user: { id: 'admin' } } } })
    supabase.from = table => {
      const query = {} as QueryStub
      for (const method of ['select', 'eq', 'order', 'range', 'maybeSingle']) query[method] = () => query
      query.then = resolve => resolve({ data: table === 'admin_users' ? { user_id: 'admin' } : [], count: 0 })
      return query
    }
    const { default: router } = await server.ssrLoadModule('/src/router/index.ts')
    await router.push('/dashboard')
    app = renderer.createApp({ render: () => h(RouterView) }).use(router).use(VueQueryPlugin, { queryClient }).use(createI18n({ legacy: false, locale: 'vi', messages: { vi: vn } }))
    const ui = { inheritAttrs: false, setup: (_: unknown, { attrs, slots }: StubContext) => () => h('div', attrs, [String(attrs.label ?? ''), slots.default?.({ errors: [] }), slots.body?.({}), slots.actions?.({}), slots.content?.({})]) }
    for (const name of ['UButton', 'UAvatar', 'UAlert', 'UBreadcrumb', 'UCard', 'USkeleton', 'UInput', 'USelectMenu', 'UFormField', 'UCheckbox', 'UForm', 'UTextarea', 'UPagination', 'UBadge', 'UIcon', 'USwitch', 'UTabs']) app.component(name, ui)
    app.component('USelect', defineComponent({ props: { items: { type: Array as import('vue').PropType<{ value: string }[]>, required: true }, modelValue: null }, setup(props, context) {
      // Reka SelectItem reserves the empty string for clearing, not an option.
      watchEffect(() => assert.ok(props.items.every((item: { value: string }) => item.value !== ''), 'select options must have nonempty values'))
      return () => h('div', { ...context.attrs, modelValue: props.modelValue })
    } }))
    app.component('UTable', { render: () => h('div') })
    const root = node('root'); app.mount(root)
    async function clickTab(name: string) {
      const link = nodes(root).find(element => element.tag === 'a' && element.props.href === `/${name}` && element.props.class?.includes('nav-item'))
      assert.ok(link)
      assert.ok(link, `sidebar link ${name}`)
      for (const click of [link.props.onClick].flat()) await click({ button: 0, preventDefault() {} })
      await nextTick()
      assert.equal(router.currentRoute.value.name, name)
      const content = nodes(root).find(element => element.props.class === 'page-content')
      assert.ok(content)
      assert.ok(content)
      return content
    }
    await router.push('/word-prompts?difficulty=hard&status=published&search=all'); await nextTick()
    for (const [field, selected] of [['difficulty', 'hard'], ['status', 'published']]) {
      const select = nodes(root).find(element => element.props.modelValue === selected)
      assert.ok(select)
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
    await router.push('/question-prompts'); await nextTick()
    assert.match(text(root), /Đang tải đề/)
    const questionFilters = { search: '', category: '', difficulty: '', family: '', locale: 'vi', status: '', sort: 'updated_at', page: 1 }
    const questionKey = ['question-prompts', 'list', questionFilters]
    queryClient.setQueryData(questionKey, { rows: [], total: 0 }); await nextTick()
    assert.match(text(root), /Không có đề phù hợp/)
    queryClient.getQueryCache().find({ queryKey: questionKey })!.setState({ status: 'error', error: new Error('offline') }); await nextTick()
    assert.match(text(root), /Thử lại/)
    queryClient.setQueryData(questionKey, { rows: [{ id: 'question-id', translations: [{ locale: 'vi', status: 'draft' }], civilian_question: 'Favourite food?', imposter_question: 'Worst food?', game_categories: { name: 'Food' }, status: 'draft', difficulty: 'medium', is_family_friendly: false, updated_at: '2026-10-21T10:00:00Z' }], total: 1 }); await nextTick()
    assert.match(text(root), /Favourite food/); assert.match(text(root), /Worst food/)
    const search = nodes(root).find(element => element.props.modelValue === '' && element.props['onUpdate:modelValue'])
    assert.ok(search)
    search.props['onUpdate:modelValue']('first'); await nextTick()
    search.props['onUpdate:modelValue']('food'); await nextTick()
    assert.equal(router.currentRoute.value.query.search, undefined)
    await new Promise(resolve => setTimeout(resolve, 330)); await nextTick()
    assert.equal(router.currentRoute.value.query.search, 'food')
    queryClient.setQueryData(['content-languages'], [{ code: 'vi', display_name: 'Tiếng Việt' }, { code: 'en', display_name: 'English' }])
    await router.push('/question-prompts/new?search=food'); await nextTick()
    assert.doesNotMatch(text(root), /Gợi ý danh mục|Hint|Ảnh/)
    for (const [label, question] of [[vn.questionPrompts.fields.civilianQuestion, 'Favourite food?'], [vn.questionPrompts.fields.imposterQuestion, 'Worst food?']]) {
      const field = nodes(root).find(element => element.props.label === label)
      assert.ok(field)
      nodes(field).find(element => element.props['onUpdate:modelValue'])!.props['onUpdate:modelValue'](question)
    }
    await nextTick()
    const previews = nodes(root).filter(element => String(element.props.class).includes('word-preview-screen'))
    assert.equal(previews.length, 2)
    assert.match(text(previews[0]), /Favourite food/); assert.doesNotMatch(text(previews[0]), /Worst food/)
    assert.match(text(previews[1]), /Worst food/); assert.doesNotMatch(text(previews[1]), /Favourite food/)
    await router.push('/categories'); await nextTick()
    assert.equal(router.currentRoute.value.name, 'question-prompt-new')
    globalThis.window.confirm = () => true
    await router.push('/question-prompts?search=food'); await nextTick()
    assert.equal(router.currentRoute.value.query.search, 'food')
    globalThis.window.confirm = () => false
    await router.push('/word-prompts/new'); await nextTick()
    assert.doesNotMatch(text(root), /Từ imposter|Hint imposter/)
    const preview = nodes(root).find(element => String(element.props.class).includes('word-preview-imposter'))
    assert.ok(preview)
    assert.match(text(preview), /Gợi ý danh mục/)
    assert.match(text(preview), /Bạn là kẻ mạo danh/)
    const hint = nodes(preview).find(element => element.props.label === vn.wordPrompts.preview.categoryHint)
    assert.ok(hint)
    hint.props['onUpdate:modelValue'](true); await nextTick()
    assert.match(text(preview), /Chọn danh mục để xem trước/)
    assert.doesNotMatch(text(preview), /Bạn là kẻ mạo danh/)
    const category = '00000000-0000-4000-8000-000000000002'
    queryClient.setQueryData(['categories', 'word-options', 'vi'], [{ id: category, name: 'Food category', locale: 'vi', is_active: true }])
    await nextTick()
    const picker = nodes(root).find(element => element.props['value-key'] === 'value')
    assert.ok(picker)
    picker.props['onUpdate:modelValue'](category); await nextTick()
    assert.match(text(preview), /Food category/)
    const otherCategory = '00000000-0000-4000-8000-000000000003'
    queryClient.setQueryData(['categories', 'word-options', 'vi'], [{ id: otherCategory, name: 'Movie category', locale: 'vi', is_active: true }])
    await nextTick()
    picker.props['onUpdate:modelValue'](otherCategory); await nextTick()
    assert.match(text(preview), /Movie category/)
    assert.doesNotMatch(text(preview), /Food category/)
    hint.props['onUpdate:modelValue'](false); await nextTick()
    assert.match(text(preview), /Bạn là kẻ mạo danh/)
    assert.doesNotMatch(text(preview), /Movie category/)
    // Inline templates do not expose setup bindings; exercise the rendered input handler.
    const civilian = nodes(root).find(element => element.props.label === vn.wordPrompts.fields.text)
    assert.ok(civilian)
    const input = nodes(civilian).find(element => element.props['onUpdate:modelValue'])
    assert.ok(input)
    input.props['onUpdate:modelValue']('Unsaved apple'); await nextTick()
    assert.doesNotMatch(text(preview), /Unsaved apple/)
    assert.equal(nodes(preview).some(element => element.tag === 'img'), false)
    await router.push('/categories'); await nextTick()
    assert.equal(router.currentRoute.value.name, 'word-prompt-new')
    globalThis.window.confirm = () => true
    await router.push('/categories'); await nextTick()
    assert.equal(router.currentRoute.value.name, 'categories')
    queryClient.setQueryData(['content-languages'], [{ code: 'vi', display_name: 'Tiếng Việt' }, { code: 'en', display_name: 'English' }])
    await router.push('/categories/new'); await nextTick()
    function categoryName() {
      const field = nodes(root).find(element => element.props.label === vn.categories.fields.name)
      assert.ok(field)
      return nodes(field).find(element => element.props['onUpdate:modelValue'])!
    }
    categoryName().props['onUpdate:modelValue']('Unsaved Vietnamese'); await nextTick()
    const tabs = nodes(root).find(element => element.props['model-value'] === 'vi' && element.props.items?.length === 2)
    assert.ok(tabs)
    tabs.props['onUpdate:modelValue']('en'); await nextTick()
    await new Promise(resolve => setTimeout(resolve, 0))
    categoryName().props['onUpdate:modelValue']('Saved English'); await nextTick()
    let categoryDetail: Record<string, unknown> | null = null
    const previousFrom = supabase.from
    supabase.from = table => {
      if (table !== 'game_categories' || !categoryDetail) return previousFrom(table)
      const query = {} as QueryStub
      for (const method of ['select', 'eq', 'single']) query[method] = () => query
      query.then = resolve => resolve({ data: categoryDetail })
      return query
    }
    supabase.rpc = async (_, input) => {
      const response = { data: {
      original: { id: input.p_id, slug: input.p_slug, game_type: input.p_game_type, sort_order: input.p_sort_order, is_active: input.p_is_active, updated_at: 'server-version' },
      translation: { category_id: input.p_id, locale: input.p_locale, name: input.p_name, description: input.p_description, status: input.p_status },
    } }
      categoryDetail = { ...response.data.original, translations: [response.data.translation] }
      return response
    }
    const statusField = nodes(root).find(element => element.props.label === vn.common.fields.status)!
    nodes(statusField).find(element => element.props['onUpdate:modelValue'])!.props['onUpdate:modelValue']('published')
    const save = nodes(root).find(element => element.props.onSubmit)
    assert.ok(save)
    assert.equal(nodes(root).filter(element => element.props.type === 'submit').length, 1)
    save.props.onSubmit(); await new Promise(resolve => setTimeout(resolve, 30)); await nextTick()
    assert.equal(router.currentRoute.value.name, 'category-edit')
    const savedTabs = nodes(root).find(element => element.props['model-value'] === 'en' && element.props.items?.length === 2)
    assert.ok(savedTabs)
    savedTabs.props['onUpdate:modelValue']('vi'); await nextTick()
    assert.equal(categoryName().props['model-value'], 'Unsaved Vietnamese', 'new-to-edit route preserves drafts in the rendered shell')
    for (const [kind, fieldLabel, secondaryLabel] of [
      ['word', vn.wordPrompts.fields.text, null],
      ['question', vn.questionPrompts.fields.civilianQuestion, vn.questionPrompts.fields.imposterQuestion],
    ] as const) {
      await router.push(`/${kind}-prompts/new`); await nextTick()
      function promptField(label: string) {
        const field = nodes(root).find(element => element.props.label === label)
        assert.ok(field)
        return nodes(field).find(element => element.props['onUpdate:modelValue'])!
      }
      promptField(fieldLabel).props['onUpdate:modelValue']('Unsaved Vietnamese'); await nextTick()
      if (secondaryLabel) promptField(secondaryLabel).props['onUpdate:modelValue']('Other Vietnamese')
      const languageTabs = nodes(root).find(element => element.props['model-value'] === 'vi' && element.props.items?.length === 2)
      assert.ok(languageTabs); languageTabs.props['onUpdate:modelValue']('en'); await nextTick()
      await new Promise(resolve => setTimeout(resolve, 0))
      promptField(fieldLabel).props['onUpdate:modelValue']('Saved English')
      if (secondaryLabel) promptField(secondaryLabel).props['onUpdate:modelValue']('Other English')
      const categoryPicker = nodes(root).find(element => element.props['value-key'] === 'value')!
      categoryPicker.props['onUpdate:modelValue'](category); await nextTick()
      let promptDetail: Record<string, unknown> | null = null
      const oldFrom = supabase.from
      supabase.from = table => {
        if (table !== `${kind}_prompts` || !promptDetail) return oldFrom(table)
        const query = {} as QueryStub
        for (const method of ['select', 'eq', 'single']) query[method] = () => query
        query.then = resolve => resolve({ data: promptDetail }); return query
      }
      supabase.rpc = async (_, input) => {
        const original = { id: input.p_id, category_id: input.p_category_id, difficulty: input.p_difficulty, is_family_friendly: input.p_is_family_friendly, image_path: null, updated_at: 'prompt-version' }
        const translation = { prompt_id: input.p_id, locale: input.p_locale, status: input.p_status, ...(kind === 'word' ? { text: input.p_text } : { civilian_question: input.p_civilian_question, imposter_question: input.p_imposter_question }) }
        promptDetail = { ...original, translations: [translation], game_categories: null }
        return { data: { original, translation } }
      }
      const statusField = nodes(root).find(element => element.props.label === vn.common.fields.status)!
      nodes(statusField).find(element => element.props['onUpdate:modelValue'])!.props['onUpdate:modelValue']('published')
      assert.equal(nodes(root).filter(element => element.props.type === 'submit').length, 1)
      const form = nodes(root).find(element => element.tag === 'form')!
      form.props.onSubmit({ preventDefault() {} }); await new Promise(resolve => setTimeout(resolve, 30)); await nextTick()
      assert.equal(router.currentRoute.value.name, `${kind}-prompt-edit`)
      const tabsAfterSave = nodes(root).find(element => element.props['model-value'] === 'en' && element.props.items?.length === 2)
      assert.ok(tabsAfterSave); tabsAfterSave.props['onUpdate:modelValue']('vi'); await nextTick()
      assert.equal(promptField(fieldLabel).props['model-value'], 'Unsaved Vietnamese', `${kind} shell preserves drafts through create/edit`)
      supabase.from = oldFrom
    }
    await router.push('/categories?locale=unknown'); await new Promise(resolve => setTimeout(resolve, 30)); await nextTick()
    assert.equal(router.currentRoute.value.query.locale, 'vi', 'invalid content locale normalizes even when languages were cached')
  } finally {
    try { app?.unmount() }
    finally { queryClient.clear(); globalThis.window = originalWindow; await server.close(); await rm(cacheDir, { recursive: true, force: true }) }
  }
})
