import test from 'node:test'
import assert from 'node:assert/strict'
import { createServer } from 'vite'
import { createSSRApp } from 'vue'
import { renderToString } from 'vue/server-renderer'
import { createMemoryHistory, createRouter } from 'vue-router'

test('category components render backend rows, immutable fields and destructive confirmation', async () => {
  const server = await createServer({ server: { middlewareMode: true, hmr: false, ws: false }, mode: 'localdev' })
  try {
    const ui = (await server.ssrLoadModule('@nuxt/ui/vue-plugin')).default
    const { i18n } = await server.ssrLoadModule('/src/i18n/index.js')
    const router = createRouter({ history: createMemoryHistory(), routes: [{ path: '/', component: { template: '<div />' } }] })
    await router.push('/')
    const render = async (component, props) => (await renderToString(createSSRApp(component, props).use(router).use(ui).use(i18n))).replace(/<!--[\s\S]*?-->/g, '')
    const table = (await server.ssrLoadModule('/src/components/categories/CategoryTable.vue')).default
    const row = { id: 'id', name: 'Đồ ăn', slug: 'do-an', game_type: 'word', locale: 'vi', is_active: true, updated_at: '2026-10-12T10:00:00Z', word_prompts: [{ count: 3 }], question_prompts: [{ count: 0 }] }
    const html = await render(table, { rows: [row], pending: false })
    assert.match(html, /Đồ ăn/)
    assert.match(html, /Từ ngữ/)
    assert.match(html, /<td[^>]*>3<\/td>/)
    const pageHtml = await render(table, { rows: Array.from({ length: 20 }, (_, index) => ({ ...row, id: String(index), name: `Danh mục ${index}` })), pending: false })
    assert.equal((pageHtml.match(/class="category-slug"/g) || []).length, 20)
    const filters = (await server.ssrLoadModule('/src/components/categories/CategoryFilters.vue')).default
    const filterHtml = await render(filters, { filters: { gameType: '', active: '', sort: 'sort_order' }, search: '' })
    assert.equal((filterHtml.match(/>Tất cả</g) || []).length, 2)
    const form = (await server.ssrLoadModule('/src/components/categories/CategoryForm.vue')).default
    const formHtml = await render(form, { form: { ...row, description: '', sort_order: 0 }, editing: true, pending: true, error: 'Lỗi lưu' })
    assert.match(formHtml, /<fieldset[^>]* disabled/)
    assert.match(formHtml, /<button[^>]*role="combobox"[^>]* disabled/)
    assert.match(formHtml, /role="alert"/)
    const dialog = (await server.ssrLoadModule('/src/components/categories/CategoryDeleteDialog.vue')).default
    const dialogProps = { portal: false, unmountOnHide: false, preview: { category: row, counts: { draft: 1, published: 1, archived: 1 }, version: 'snapshot' }, targets: [], loading: false, pending: false }
    const dialogHtml = await render(dialog, dialogProps)
    assert.match(dialogHtml, /Published: 1/)
    assert.match(dialogHtml, /Xóa danh mục và toàn bộ content/)
    assert.match(dialogHtml, /Không có danh mục nhận/)
    assert.match(dialogHtml, /<button[^>]* disabled[^>]*><span[^>]*>Xác nhận xóa<\/span>/)
    const pendingHtml = await render(dialog, { ...dialogProps, pending: true })
    assert.match(pendingHtml, /<button[^>]* disabled[^>]*><span[^>]*>Hủy<\/span>/)
    assert.doesNotMatch(pendingHtml, /data-slot="close"/)
  } finally { await server.close() }
})
