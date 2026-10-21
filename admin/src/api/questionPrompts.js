import { pageSize, searchPattern } from '../utils/categories.js'
import { questionPromptPayload } from '../utils/questionPrompts.js'
function dataOrThrow(result) { if (result.error) throw result.error; return result.data }
export async function listQuestionPrompts(client, filters) {
  let query = client.from('question_prompts').select('*, game_categories(id,name,is_active)', { count: 'exact' })
  if (filters.search.trim()) {
    const pattern = searchPattern(filters.search.trim())
    query = query.or(`civilian_question.ilike.${pattern},imposter_question.ilike.${pattern}`)
  }
  for (const [filter, field] of Object.entries({ category: 'category_id', difficulty: 'difficulty', locale: 'locale', status: 'status' })) {
    if (filters[filter]) query = query.eq(field, filters[filter])
  }
  if (filters.family) query = query.eq('is_family_friendly', filters.family === 'true')
  const start = (filters.page - 1) * pageSize
  const result = await query.order(filters.sort, { ascending: filters.sort === 'civilian_question' }).order('id').range(start, start + pageSize - 1)
  return { rows: dataOrThrow(result), total: result.count || 0 }
}
export async function getQuestionPrompt(client, id) {
  return dataOrThrow(await client.from('question_prompts').select('*, game_categories(id,name,is_active,locale)').eq('id', id).single())
}
export async function deleteQuestionPrompt(client, { id, updatedAt }) {
  return dataOrThrow(await client.rpc('delete_question_prompt', {
    p_id: id, p_expected_updated_at: updatedAt,
  }))
}
export async function questionCategories(client, locale) {
  const rows = []
  for (let start = 0; ; start += 100) {
    let query = client.from('game_categories').select('id,name,locale,is_active').eq('game_type', 'question')
    if (locale !== undefined) query = query.eq('locale', locale).eq('is_active', true)
    const batch = dataOrThrow(await query.order('name').order('id').range(start, start + 99))
    rows.push(...batch)
    if (batch.length < 100) return rows
  }
}
export async function saveQuestionPrompt(client, form, { id, status, updatedAt }) {
  const payload = questionPromptPayload(form, status)
  const { data, error } = await client.auth.getUser()
  if (error) throw error
  if (!data.user) throw new Error('common.errors.sessionExpired')
  let query = client.from('question_prompts')
  query = updatedAt ? query.update(payload).eq('id', id).eq('updated_at', updatedAt) : query.insert({ ...payload, id, created_by: data.user.id })
  const row = dataOrThrow(await query.select().maybeSingle())
  if (!row) throw new Error('questionPrompts.errors.conflict')
  return row
}
