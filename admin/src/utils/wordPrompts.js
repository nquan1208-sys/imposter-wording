import { z } from 'zod'
export const imageBucket = 'word-prompt-images'
export const imageTypes = { 'image/jpeg': 'jpg', 'image/png': 'png', 'image/webp': 'webp' }
export const statuses = ['draft', 'published', 'archived']
export const difficulties = ['easy', 'medium', 'hard']
const optionalText = z.string().nullish().transform(value => value?.trim() || null)
export const wordPromptSchema = z.object({
  text: z.string().trim().min(1, 'wordPrompts.errors.textRequired'),
  image_path: optionalText,
  category_id: z.uuid({ error: 'wordPrompts.errors.categoryRequired' }),
  difficulty: z.enum(difficulties), is_family_friendly: z.boolean(),
  locale: z.string().trim().min(1, 'wordPrompts.errors.localeRequired'),
})
export function wordPromptPayload(form, status) {
  const result = wordPromptSchema.safeParse(form)
  if (!result.success) throw new Error(result.error.issues[0].message.startsWith('wordPrompts.') ? result.error.issues[0].message : 'wordPrompts.errors.invalidData')
  if (!statuses.includes(status)) throw new Error('wordPrompts.errors.invalidData')
  return { ...result.data, status }
}
export function wordPromptFilters(query) {
  const page = Number(query.page)
  return {
    search: typeof query.search === 'string' ? query.search : '',
    category: z.uuid().safeParse(query.category).success ? query.category : '',
    difficulty: difficulties.includes(query.difficulty) ? query.difficulty : '',
    family: ['true', 'false'].includes(query.family) ? query.family : '',
    locale: typeof query.locale === 'string' ? query.locale : '',
    status: statuses.includes(query.status) ? query.status : '',
    sort: ['text', 'civilian_text'].includes(query.sort) ? 'text' : 'updated_at',
    page: Number.isSafeInteger(page) && page > 0 ? page : 1,
  }
}
export function validateImage(file) {
  if (!imageTypes[file.type] || file.size === 0 || file.size > 5242880) throw new Error('wordPrompts.errors.invalidImage')
}
export function wordPromptError(error) {
  if (error?.message?.startsWith('wordPrompts.errors.')) return error.message
  if (error?.message === 'common.errors.sessionExpired') return error.message
  return ({ '23514': 'wordPrompts.errors.invalidData', '23503': 'wordPrompts.errors.categoryRequired', '23505': 'wordPrompts.errors.conflict', '40001': 'wordPrompts.errors.conflict', '22023': 'wordPrompts.errors.invalidData', '42501': 'common.errors.forbidden', P0002: 'wordPrompts.errors.notFound', PGRST116: 'wordPrompts.errors.notFound' })[error?.code] || 'common.errors.operationFailed'
}
