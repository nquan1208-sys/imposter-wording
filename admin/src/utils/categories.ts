import type { LocationQuery } from 'vue-router'
import { errorFields } from '../types/admin.ts'
import { z } from 'zod'

export const gameTypeLabels = { word: 'common.gameTypes.word', question: 'common.gameTypes.question' }
export const pageSize = 20

const categoryFields = z.object({
  name: z.string({ error: 'categories.errors.nameRequired' }).trim().min(1, 'categories.errors.nameRequired'),
  slug: z.string({ error: 'categories.errors.invalidSlug' }).trim().regex(/^[a-z0-9]+(?:-[a-z0-9]+)*$/, 'categories.errors.invalidSlug'),
  description: z.string({ error: 'categories.errors.invalidData' }).nullish().transform(value => value?.trim() || null),
  sort_order: z.union([z.string(), z.number()], { error: 'categories.errors.invalidSortOrder' })
    .refine(value => String(value).trim() !== '' && Number.isSafeInteger(Number(value)) && Number(value) >= 0 && Number(value) <= 2147483647, 'categories.errors.invalidSortOrder')
    .transform(Number),
  locale: z.string().trim().min(1, 'categories.errors.invalidData'),
  status: z.enum(['draft', 'published', 'archived'], { error: 'categories.errors.invalidData' }),
  is_active: z.boolean({ error: 'categories.errors.invalidData' }).default(false),
})
const newCategorySchema = categoryFields.extend({
  game_type: z.enum(['word', 'question'], { error: 'categories.errors.invalidGameType' }),
})

export function categorySchema() { return newCategorySchema }

export function slugFromName(name: string) {
  return name.normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/[đĐ]/g, 'd')
    .toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '')
}

export function categoryPayload(form: unknown) {
  const result = categorySchema().safeParse(form)
  if (!result.success) throw new Error(result.error.issues[0].message)
  return result.data
}

// Escape PostgREST quoted values and LIKE wildcards: search is literal substring matching.
export function searchPattern(value: string) {
  const literal = value.replace(/[\\%_]/g, char => `\\${char}`)
  return `"%${literal.replace(/\\/g, '\\\\').replace(/"/g, '\\"')}%"`
}

const validationKeys = new Set(['categories.errors.nameRequired', 'categories.errors.invalidSlug', 'categories.errors.invalidSortOrder', 'categories.errors.invalidGameType', 'categories.errors.invalidData'])
const errorKeys: Record<string, string> = {
  '23505': 'categories.errors.slugExists',
  '42501': 'common.errors.forbidden',
  '23514': 'categories.errors.invalidData',
  '22023': 'categories.errors.invalidData',
  '40001': 'categories.errors.conflict',
  PT409: 'categories.errors.conflict',
  P0002: 'categories.errors.notFound',
  '23503': 'categories.errors.invalidData',
  '23502': 'categories.errors.invalidData',
  PGRST116: 'categories.errors.notFound',
}
export function categoryError(cause: unknown) {
  const error = errorFields(cause)
  if (validationKeys.has(error?.message)) return error.message
  if (error?.message === 'common.errors.sessionExpired') return 'common.errors.sessionExpired'
  return errorKeys[error?.code] || 'common.errors.operationFailed'
}

export function listFilters(query: LocationQuery): { search: string; gameType: '' | 'word' | 'question'; active: string; sort: string; page: number; locale: string } {
  const page = Number(query.page)
  return {
    locale: typeof query.locale === 'string' ? query.locale : 'vi',
    search: typeof query.search === 'string' ? query.search : '',
    gameType: query.type === 'word' || query.type === 'question' ? query.type : '',
    active: typeof query.active === 'string' && ['true', 'false'].includes(query.active) ? query.active : '',
    sort: typeof query.sort === 'string' && ['name', 'updated_at'].includes(query.sort) ? query.sort : 'sort_order',
    page: Number.isSafeInteger(page) && page > 0 ? page : 1,
  }
}
