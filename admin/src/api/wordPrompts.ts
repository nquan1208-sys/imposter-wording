import type { wordPromptFilters } from '../utils/wordPrompts.ts'
import type { AdminClient, DeletePrompt, SaveWord, WordRow, WordDetail, SavedWord } from '../types/admin.ts'
import { imageBucket, imageTypes, validateImage, wordPromptPayload } from '../utils/wordPrompts.ts'
function dataOrThrow<T>(result: { data: T; error?: unknown }) { if (result.error) throw result.error; return result.data }
export async function listWordPrompts(client: AdminClient, filters: ReturnType<typeof wordPromptFilters>) {
  return dataOrThrow(await client.rpc('admin_list_word_prompts', {
    p_locale: filters.locale, p_search: filters.search.trim(), p_category_id: filters.category || null,
    p_difficulty: filters.difficulty || null, p_is_family_friendly: filters.family ? filters.family === 'true' : null,
    p_status: filters.status || null, p_sort: filters.sort, p_page: filters.page,
  })) as { rows: WordRow[]; total: number }
}
export async function getWordPrompt(client: AdminClient, id: string) {
  const row = dataOrThrow(await client.from('word_prompts').select('*, translations:word_prompt_translations(*), game_categories(*, translations:game_category_translations(*))').eq('id', id).single())
  if (!row) throw new Error('wordPrompts.errors.notFound')
  return row as WordDetail
}
export async function deleteWordPrompt(client: AdminClient, { id, updatedAt }: DeletePrompt) {
  return dataOrThrow(await client.rpc('delete_word_prompt', {
    p_id: id, p_expected_updated_at: updatedAt,
  }))
}
export async function wordCategories(client: AdminClient, locale = 'vi') {
  const rows = []
  for (let start = 0; ; start += 100) {
    const batch = dataOrThrow(await client.from('game_categories').select('*, translations:game_category_translations(*)')
      .eq('game_type', 'word').order('slug').order('id').range(start, start + 99))
    rows.push(...(batch || []).map(row => ({ ...row, locale, name: row.translations.find(t => t.locale === locale)?.name ?? null })))
    if ((batch?.length ?? 0) < 100) return rows
  }
}
export async function uploadWordImage(client: AdminClient, id: string, file: File) {
  validateImage(file)
  const path = `${id}/${crypto.randomUUID()}.${imageTypes[file.type]}`
  dataOrThrow(await client.storage.from(imageBucket).upload(path, file, { upsert: false, contentType: file.type }))
  return path
}
export async function wordImageUrl(client: AdminClient, path: string) {
  const data = dataOrThrow(await client.storage.from(imageBucket).createSignedUrl(path, 300))
  if (!data) throw new Error('common.errors.operationFailed')
  return data.signedUrl
}
export async function saveWordPrompt(client: AdminClient, form: unknown, { id, status, updatedAt, file, onUpload }: SaveWord) {
  const payload = wordPromptPayload(form, status)
  let uploaded
  try {
    if (file) {
      onUpload?.('uploading')
      uploaded = await uploadWordImage(client, id, file)
      payload.image_path = uploaded
      onUpload?.('uploaded')
    }
    return dataOrThrow(await client.rpc('save_word_prompt', { p_id: id, p_expected_updated_at: updatedAt ?? null, p_category_id: payload.category_id,
      p_difficulty: payload.difficulty, p_is_family_friendly: payload.is_family_friendly,
      p_locale: payload.locale, p_status: payload.status, p_text: payload.text, p_image_path: payload.image_path })) as SavedWord
  } catch (error) {
    // Preserve the save error even if cleanup is offline or the file is already referenced.
    if (uploaded) { try { await client.storage.from(imageBucket).remove([uploaded]) } catch {} }
    onUpload?.('failed')
    throw error
  }
}
