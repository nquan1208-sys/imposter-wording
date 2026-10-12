export const gameTypeLabels = { word: 'common.gameTypes.word', question: 'common.gameTypes.question' }
export const pageSize = 20

export function slugFromName(name) {
  return name.normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/[đĐ]/g, 'd')
    .toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '')
}

export function categoryPayload(form, editing = false) {
  const name = form.name.trim()
  const slug = form.slug.trim()
  if (!name) throw new Error('categories.errors.nameRequired')
  if (!/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(slug)) throw new Error('categories.errors.invalidSlug')
  if (String(form.sort_order).trim() === '' || !Number.isSafeInteger(Number(form.sort_order)) || Number(form.sort_order) < 0 || Number(form.sort_order) > 2147483647) {
    throw new Error('categories.errors.invalidSortOrder')
  }
  const payload = { name, slug, description: form.description?.trim() || null, sort_order: Number(form.sort_order), is_active: Boolean(form.is_active) }
  if (!editing) {
    if (!Object.hasOwn(gameTypeLabels, form.game_type)) throw new Error('categories.errors.invalidGameType')
    Object.assign(payload, { game_type: form.game_type, locale: 'vi' })
  }
  return payload
}

// Escape PostgREST quoted values and LIKE wildcards: search is literal substring matching.
export function searchPattern(value) {
  const literal = value.replace(/[\\%_]/g, char => `\\${char}`)
  return `"%${literal.replace(/\\/g, '\\\\').replace(/"/g, '\\"')}%"`
}

const validationKeys = new Set(['categories.errors.nameRequired', 'categories.errors.invalidSlug', 'categories.errors.invalidSortOrder', 'categories.errors.invalidGameType'])
const errorKeys = {
  '23505': 'categories.errors.slugExists',
  '42501': 'common.errors.forbidden',
  '23514': 'categories.errors.invalidData',
  '22023': 'categories.errors.invalidData',
  PGRST116: 'categories.errors.notFound',
}
export function categoryError(error) {
  if (validationKeys.has(error?.message)) return error.message
  if (error?.message === 'common.errors.sessionExpired') return 'common.errors.sessionExpired'
  return errorKeys[error?.code] || 'common.errors.operationFailed'
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
