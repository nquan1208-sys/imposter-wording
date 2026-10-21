import { z } from 'zod'
export const statuses = ['draft', 'published', 'archived']
export const difficulties = ['easy', 'medium', 'hard']
export const questionPromptSchema = z.object({
  civilian_question: z.string().trim().min(1, 'questionPrompts.errors.civilianRequired'),
  imposter_question: z.string().trim().min(1, 'questionPrompts.errors.imposterRequired'),
  category_id: z.uuid({ error: 'questionPrompts.errors.categoryRequired' }),
  difficulty: z.enum(difficulties), is_family_friendly: z.boolean(),
  locale: z.string().trim().min(1, 'questionPrompts.errors.localeRequired'),
}).refine(value => value.civilian_question.toLowerCase() !== value.imposter_question.toLowerCase(), { message: 'questionPrompts.errors.sameQuestions' })
export function questionPromptPayload(form, status) {
  const result = questionPromptSchema.safeParse(form)
  if (!result.success) throw new Error(result.error.issues[0].message.startsWith('questionPrompts.') ? result.error.issues[0].message : 'questionPrompts.errors.invalidData')
  if (!statuses.includes(status)) throw new Error('questionPrompts.errors.invalidData')
  return { ...result.data, status }
}
export function questionPromptFilters(query) {
  const page = Number(query.page)
  return {
    search: typeof query.search === 'string' ? query.search : '',
    category: z.uuid().safeParse(query.category).success ? query.category : '',
    difficulty: difficulties.includes(query.difficulty) ? query.difficulty : '',
    family: ['true', 'false'].includes(query.family) ? query.family : '',
    locale: typeof query.locale === 'string' ? query.locale : '',
    status: statuses.includes(query.status) ? query.status : '',
    sort: query.sort === 'civilian_question' ? 'civilian_question' : 'updated_at',
    page: Number.isSafeInteger(page) && page > 0 ? page : 1,
  }
}

export function questionPromptError(error) {
  if (error?.message?.startsWith('questionPrompts.errors.')) return error.message
  if (error?.message === 'common.errors.sessionExpired') return error.message
  return ({ '23514': 'questionPrompts.errors.invalidData', '23503': 'questionPrompts.errors.categoryRequired', '23505': 'questionPrompts.errors.conflict', '40001': 'questionPrompts.errors.conflict', '22023': 'questionPrompts.errors.invalidData', '42501': 'common.errors.forbidden', P0002: 'questionPrompts.errors.notFound', PGRST116: 'questionPrompts.errors.notFound' })[error?.code] || 'common.errors.operationFailed'
}
