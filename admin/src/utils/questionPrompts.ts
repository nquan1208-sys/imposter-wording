import type { LocationQuery } from 'vue-router'
import { errorFields } from '../types/admin.ts'
import { z } from 'zod'
export const statuses = ['draft', 'published', 'archived'] as const
export const difficulties = ['easy', 'medium', 'hard'] as const
export const questionPromptSchema = z.object({
  civilian_question: z.string().trim().min(1, 'questionPrompts.errors.civilianRequired'),
  imposter_question: z.string().trim().min(1, 'questionPrompts.errors.imposterRequired'),
  category_id: z.uuid({ error: 'questionPrompts.errors.categoryRequired' }),
  difficulty: z.enum(difficulties),
  locale: z.string().trim().min(1, 'questionPrompts.errors.localeRequired'),
}).refine(value => value.civilian_question.toLowerCase() !== value.imposter_question.toLowerCase(), { message: 'questionPrompts.errors.sameQuestions' })
export function questionPromptPayload(form: unknown, status: unknown) {
  const result = questionPromptSchema.safeParse(form)
  if (!result.success) throw new Error(result.error.issues[0].message.startsWith('questionPrompts.') ? result.error.issues[0].message : 'questionPrompts.errors.invalidData')
  const parsedStatus = z.enum(statuses).safeParse(status)
  if (!parsedStatus.success) throw new Error('questionPrompts.errors.invalidData')
  return { ...result.data, status: parsedStatus.data }
}
export function questionPromptFilters(query: LocationQuery) {
  const page = Number(query.page)
  return {
    search: typeof query.search === 'string' ? query.search : '',
    category: z.uuid().safeParse(query.category).success ? String(query.category) : '',
    difficulty: z.enum(difficulties).safeParse(query.difficulty).success ? query.difficulty as typeof difficulties[number] : '' as const,
    locale: typeof query.locale === 'string' && query.locale ? query.locale : 'vi',
    status: z.enum(statuses).safeParse(query.status).success ? query.status as typeof statuses[number] : '' as const,
    sort: query.sort === 'civilian_question' ? 'civilian_question' : 'updated_at',
    page: Number.isSafeInteger(page) && page > 0 ? page : 1,
  }
}

export function questionPromptError(cause: unknown) {
  const error = errorFields(cause)
  if (error?.message?.startsWith('questionPrompts.errors.')) return error.message
  if (error?.message === 'common.errors.sessionExpired') return error.message
  return ({ '23514': 'questionPrompts.errors.invalidData', '23503': 'questionPrompts.errors.categoryRequired', '23505': 'questionPrompts.errors.conflict', '40001': 'questionPrompts.errors.conflict', 'PT409': 'questionPrompts.errors.conflict', '22023': 'questionPrompts.errors.invalidData', '42501': 'common.errors.forbidden', P0002: 'questionPrompts.errors.notFound', PGRST116: 'questionPrompts.errors.notFound' } as Record<string, string>)[error.code] || 'common.errors.operationFailed'
}
