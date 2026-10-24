import type { LocationQuery } from 'vue-router'
import { errorFields } from '../types/admin.ts'
import { z } from 'zod'
export const imageBucket = 'word-prompt-images'
export const imageTypes: Record<string, string> = { 'image/jpeg': 'jpg', 'image/png': 'png', 'image/webp': 'webp' }
export const statuses = ['draft', 'published', 'archived'] as const
export const difficulties = ['easy', 'medium', 'hard'] as const
const optionalText = z.string().nullish().transform(value => value?.trim() || null)
export const wordPromptSchema = z.object({
  text: z.string().trim().min(1, 'wordPrompts.errors.textRequired'),
  image_path: optionalText,
  category_id: z.uuid({ error: 'wordPrompts.errors.categoryRequired' }),
  difficulty: z.enum(difficulties), is_family_friendly: z.boolean(),
  locale: z.string().trim().min(1, 'wordPrompts.errors.localeRequired'),
})
export function wordPromptPayload(form: unknown, status: unknown) {
  const result = wordPromptSchema.safeParse(form)
  if (!result.success) throw new Error(result.error.issues[0].message.startsWith('wordPrompts.') ? result.error.issues[0].message : 'wordPrompts.errors.invalidData')
  const parsedStatus = z.enum(statuses).safeParse(status)
  if (!parsedStatus.success) throw new Error('wordPrompts.errors.invalidData')
  return { ...result.data, status: parsedStatus.data }
}
export function wordPromptFilters(query: LocationQuery) {
  const page = Number(query.page)
  return {
    search: typeof query.search === 'string' ? query.search : '',
    category: z.uuid().safeParse(query.category).success ? String(query.category) : '',
    difficulty: z.enum(difficulties).safeParse(query.difficulty).success ? query.difficulty as typeof difficulties[number] : '' as const,
    family: typeof query.family === 'string' && ['true', 'false'].includes(query.family) ? query.family : '',
    locale: typeof query.locale === 'string' && query.locale ? query.locale : 'vi',
    status: z.enum(statuses).safeParse(query.status).success ? query.status as typeof statuses[number] : '' as const,
    sort: typeof query.sort === 'string' && ['text', 'civilian_text'].includes(query.sort) ? 'text' : 'updated_at',
    page: Number.isSafeInteger(page) && page > 0 ? page : 1,
  }
}
export function validateImage(file: Pick<File, 'type' | 'size'>) {
  if (!imageTypes[file.type] || file.size === 0 || file.size > 5242880) throw new Error('wordPrompts.errors.invalidImage')
}
export function wordPromptError(cause: unknown) {
  const error = errorFields(cause)
  if (error?.message?.startsWith('wordPrompts.errors.')) return error.message
  if (error?.message === 'common.errors.sessionExpired') return error.message
  return ({ '23514': 'wordPrompts.errors.invalidData', '23503': 'wordPrompts.errors.categoryRequired', '23505': 'wordPrompts.errors.conflict', '40001': 'wordPrompts.errors.conflict', '22023': 'wordPrompts.errors.invalidData', '42501': 'common.errors.forbidden', P0002: 'wordPrompts.errors.notFound', PGRST116: 'wordPrompts.errors.notFound' } as Record<string, string>)[error.code] || 'common.errors.operationFailed'
}
