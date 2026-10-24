import type { questionPromptFilters } from '../utils/questionPrompts.ts'
import type { AdminClient, DeletePrompt, SavePrompt, QuestionRow, QuestionDetail, SavedQuestion } from '../types/admin.ts'
import { questionPromptPayload } from '../utils/questionPrompts.ts'
function dataOrThrow<T>(result: { data: T; error?: unknown }) { if (result.error) throw result.error; return result.data }
export async function listQuestionPrompts(client: AdminClient, filters: ReturnType<typeof questionPromptFilters>) {
  return dataOrThrow(await client.rpc('admin_list_question_prompts', {
    p_locale: filters.locale, p_search: filters.search.trim(), p_category_id: filters.category || null,
    p_difficulty: filters.difficulty || null, p_is_family_friendly: filters.family ? filters.family === 'true' : null,
    p_status: filters.status || null, p_sort: filters.sort, p_page: filters.page,
  })) as { rows: QuestionRow[]; total: number }
}
export async function getQuestionPrompt(client: AdminClient, id: string) {
  const row = dataOrThrow(await client.from('question_prompts').select('*, translations:question_prompt_translations(*), game_categories(*, translations:game_category_translations(*))').eq('id', id).single())
  if (!row) throw new Error('questionPrompts.errors.notFound')
  return row as QuestionDetail
}
export async function deleteQuestionPrompt(client: AdminClient, { id, updatedAt }: DeletePrompt) {
  return dataOrThrow(await client.rpc('delete_question_prompt', {
    p_id: id, p_expected_updated_at: updatedAt,
  }))
}
export async function questionCategories(client: AdminClient, locale = 'vi') {
  const rows = []
  for (let start = 0; ; start += 100) {
    const batch = dataOrThrow(await client.from('game_categories').select('*, translations:game_category_translations(*)')
      .eq('game_type', 'question').order('slug').order('id').range(start, start + 99))
    rows.push(...(batch || []).map(row => ({ ...row, locale, name: row.translations.find(t => t.locale === locale)?.name ?? null })))
    if ((batch?.length ?? 0) < 100) return rows
  }
}
export async function saveQuestionPrompt(client: AdminClient, form: unknown, { id, status, updatedAt }: SavePrompt) {
  const payload = questionPromptPayload(form, status)
  return dataOrThrow(await client.rpc('save_question_prompt', { p_id: id, p_expected_updated_at: updatedAt ?? null, p_category_id: payload.category_id,
      p_difficulty: payload.difficulty, p_is_family_friendly: payload.is_family_friendly,
      p_locale: payload.locale, p_status: payload.status, p_civilian_question: payload.civilian_question, p_imposter_question: payload.imposter_question })) as SavedQuestion
}
