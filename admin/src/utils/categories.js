export const gameTypeLabels = { word: 'Từ ngữ', question: 'Câu hỏi' }
export const pageSize = 20

export function slugFromName(name) {
  return name.normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/[đĐ]/g, 'd')
    .toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '')
}

export function categoryPayload(form, editing = false) {
  const name = form.name.trim()
  const slug = form.slug.trim()
  if (!name) throw new Error('Vui lòng nhập tên danh mục.')
  if (!/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(slug)) throw new Error('Slug chỉ gồm chữ thường, số và dấu gạch ngang giữa các từ.')
  if (String(form.sort_order).trim() === '' || !Number.isSafeInteger(Number(form.sort_order)) || Number(form.sort_order) < 0 || Number(form.sort_order) > 2147483647) {
    throw new Error('Thứ tự phải là số nguyên không âm trong giới hạn 2147483647.')
  }
  const payload = { name, slug, description: form.description?.trim() || null, sort_order: Number(form.sort_order), is_active: Boolean(form.is_active) }
  if (!editing) {
    if (!Object.hasOwn(gameTypeLabels, form.game_type)) throw new Error('Loại trò chơi không hợp lệ.')
    Object.assign(payload, { game_type: form.game_type, locale: 'vi' })
  }
  return payload
}

// Escape PostgREST quoted values and LIKE wildcards: search is literal substring matching.
export function searchPattern(value) {
  const literal = value.replace(/[\\%_]/g, char => `\\${char}`)
  return `"%${literal.replace(/\\/g, '\\\\').replace(/"/g, '\\"')}%"`
}

export function categoryError(error) {
  if (error?.code === '23505') return 'Slug đã tồn tại trong loại trò chơi và ngôn ngữ này.'
  if (error?.code === '42501') return 'Bạn không có quyền thực hiện thao tác này. Vui lòng đăng nhập lại.'
  return error?.message || 'Không thể thực hiện thao tác. Vui lòng thử lại.'
}

export function listFilters(query) {
  const page = Number(query.page)
  return {
    search: typeof query.search === 'string' ? query.search : '',
    gameType: ['word', 'question'].includes(query.type) ? query.type : '',
    active: ['true', 'false'].includes(query.active) ? query.active : '',
    sort: ['name', 'updated_at'].includes(query.sort) ? query.sort : 'sort_order',
    page: Number.isSafeInteger(page) && page > 0 ? page : 1,
  }
}
