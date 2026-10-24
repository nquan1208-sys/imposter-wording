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
    const { i18n } = await server.ssrLoadModule('/src/i18n/index.ts')
    const router = createRouter({ history: createMemoryHistory(), routes: [{ path: '/', component: { template: '<div />' } }] })
    await router.push('/')
    const render = async (component: import('vue').Component, props: Record<string, unknown>) => (await renderToString(createSSRApp(component, props).use(router).use(ui).use(i18n))).replace(/<!--[\s\S]*?-->/g, '')
    const table = (await server.ssrLoadModule('/src/components/categories/CategoryTable.vue')).default
    const languages = [{ code: 'vi', display_name: 'Tiếng Việt', sort_order: 0 }, { code: 'en', display_name: 'English', sort_order: 1 }]
    const row = { id: 'id', name: 'Đồ ăn', slug: 'do-an', game_type: 'word', locale: 'vi', is_active: true, updated_at: '2026-10-12T10:00:00Z', word_count: 3, question_count: 0, translations: [{ locale: 'vi', name: 'Đồ ăn', status: 'published' }] }
    const html = await render(table, { languages, rows: [row], pending: false })
    assert.match(html, /Đồ ăn/)
    assert.match(html, /Chưa có bản dịch/)
    assert.match(html, /en:/)
    assert.match(html, /Từ ngữ/)
    assert.match(html, /<td[^>]*>3<\/td>/)
    const pageHtml = await render(table, { rows: Array.from({ length: 20 }, (_, index) => ({ ...row, id: String(index), name: `Danh mục ${index}` })), languages, pending: false })
    assert.equal((pageHtml.match(/class="category-slug"/g) || []).length, 20)
    const filters = (await server.ssrLoadModule('/src/components/categories/CategoryFilters.vue')).default
    const filterHtml = await render(filters, { languages, filters: { locale: 'vi', gameType: '', active: '', sort: 'sort_order' }, search: '' })
    assert.equal((filterHtml.match(/>Tất cả</g) || []).length, 2)
    const form = (await server.ssrLoadModule('/src/components/categories/CategoryForm.vue')).default
    const formHtml = await render(form, { languages, translations: row.translations, form: { ...row, status: 'draft', description: '', sort_order: 0 }, editing: true, pending: true, error: 'Lỗi lưu' })
    assert.match(formHtml, /<fieldset[^>]* disabled/)
    assert.match(formHtml, /<button[^>]*role="combobox"[^>]* disabled/)
    assert.match(formHtml, /role="alert"/)
    assert.equal((formHtml.match(/type="submit"/g) || []).length, 1)
    assert.doesNotMatch(formHtml, />Xuất bản<|>Lưu trữ</)
    const badge = (await server.ssrLoadModule('/src/components/admin/ContentStatusBadge.vue')).default
    const pagination = (await server.ssrLoadModule('/src/components/admin/AdminPagination.vue')).default
    for (const locale of ['vi', 'en'] as const) {
      i18n.global.locale.value = locale
      for (const status of ['draft', 'published', 'archived', null]) {
        const badgeHtml = await render(badge, { status, locale: 'en' })
        assert.ok(badgeHtml.includes(i18n.global.t(`common.statuses.${status || 'missing'}`)))
        assert.match(badgeHtml, /en:/)
        assert.ok(badgeHtml.includes(`content-status--${status || 'missing'}`))
      }
      const pages = await render(pagination, { page: 2, itemsPerPage: 20, total: 60 })
      assert.ok(pages.includes(`aria-label="${i18n.global.t('common.pagination.first')}"`))
      assert.ok(pages.includes(`aria-label="${i18n.global.t('common.pagination.page', { page: '2' })}"`))
      const localizedForm = await render(form, { languages, translations: [], form: { ...row, status: 'draft', description: '', sort_order: 0 } })
      assert.ok(localizedForm.includes(i18n.global.t('common.actions.save')))
      assert.equal((localizedForm.match(/type="submit"/g) || []).length, 1)
      const localizedTable = await render(table, { languages, rows: [row] })
      assert.ok(localizedTable.includes(i18n.global.t('common.statuses.published')))
      assert.ok(localizedTable.includes(i18n.global.t('common.statuses.missing')))
    }
    i18n.global.locale.value = 'vi'
    const dialog = (await server.ssrLoadModule('/src/components/categories/CategoryDeleteDialog.vue')).default
    const dialogProps = { portal: false, unmountOnHide: false, locale: 'vi', preview: { category: row, category_translations: row.translations, counts: { originals: { total: 2, word: 2, question: 0 }, translations: { draft: 1, published: 1, archived: 1 } }, version: 'snapshot' }, targets: [], loading: false, pending: false }
    const dialogHtml = await render(dialog, dialogProps)
    assert.match(dialogHtml, /Đã xuất bản<\/dt><dd[^>]*>1/)
    assert.match(dialogHtml, /Xóa danh mục cùng toàn bộ nội dung/)
    assert.match(dialogHtml, /Không có danh mục đang bật/)
    assert.match(dialogHtml, /<button[^>]* disabled[^>]*><span[^>]*>Chuyển nội dung và xóa<\/span>/)
    assert.match(dialogHtml, /Giữ lại toàn bộ nội dung/)
    assert.doesNotMatch(dialogHtml, /<input[^>]*type="text"|Nhập đúng tên/)
    const wordDialog = (await server.ssrLoadModule('/src/components/word-prompts/WordDeleteDialog.vue')).default
    const wordHtml = await render(wordDialog, { portal: false, unmountOnHide: false, prompt: { text: 'Quả táo', category_id: 'food', game_categories: { name: 'Đồ ăn' }, status: 'published' } })
    assert.match(wordHtml, /Quả táo/)
    assert.match(wordHtml, /Đồ ăn/)
    assert.match(wordHtml, /Không thể hoàn tác/)
    assert.match(wordHtml, /Xóa vĩnh viễn/)
    assert.doesNotMatch(wordHtml, /<input|Nhập chính xác XÓA/)
    const pendingHtml = await render(dialog, { ...dialogProps, pending: true })
    assert.match(pendingHtml, /<button[^>]* disabled[^>]*><span[^>]*>Hủy<\/span>/)
    assert.doesNotMatch(pendingHtml, /data-slot="close"/)
  } finally { await server.close() }
})
