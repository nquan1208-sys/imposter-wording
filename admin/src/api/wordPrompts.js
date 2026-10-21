import { pageSize, searchPattern } from '../utils/categories.js'
import { imageBucket, imageTypes, validateImage, wordPromptPayload } from '../utils/wordPrompts.js'
function dataOrThrow(result) { if (result.error) throw result.error; return result.data }
export async function listWordPrompts(client, filters) {
  let query = client.from('word_prompts').select('*, game_categories(id,name,is_active)', { count: 'exact' })
  if (filters.search.trim()) {
    const pattern = searchPattern(filters.search.trim())
    query = query.or(`text.ilike.${pattern}`)
  }
  for (const [filter, field] of Object.entries({ category: 'category_id', difficulty: 'difficulty', locale: 'locale', status: 'status' })) {
    if (filters[filter]) query = query.eq(field, filters[filter])
  }
  if (filters.family) query = query.eq('is_family_friendly', filters.family === 'true')
  const start = (filters.page - 1) * pageSize
  const result = await query.order(filters.sort, { ascending: filters.sort === 'text' }).order('id').range(start, start + pageSize - 1)
  return { rows: dataOrThrow(result), total: result.count || 0 }
}
export async function getWordPrompt(client, id) {
  return dataOrThrow(await client.from('word_prompts').select('*, game_categories(id,name,is_active,locale)').eq('id', id).single())
}
export async function deleteWordPrompt(client, { id, updatedAt }) {
  return dataOrThrow(await client.rpc('delete_word_prompt', {
    p_id: id, p_expected_updated_at: updatedAt,
  }))
}
export async function wordCategories(client, locale) {
  const rows = []
  for (let start = 0; ; start += 100) {
    let query = client.from('game_categories').select('id,name,locale,is_active').eq('game_type', 'word')
    if (locale !== undefined) query = query.eq('locale', locale).eq('is_active', true)
    const batch = dataOrThrow(await query.order('name').order('id').range(start, start + 99))
    rows.push(...batch)
    if (batch.length < 100) return rows
  }
}
export async function uploadWordImage(client, id, file) {
  validateImage(file)
  const path = `${id}/${crypto.randomUUID()}.${imageTypes[file.type]}`
  dataOrThrow(await client.storage.from(imageBucket).upload(path, file, { upsert: false, contentType: file.type }))
  return path
}
export async function wordImageUrl(client, path) {
  return dataOrThrow(await client.storage.from(imageBucket).createSignedUrl(path, 300)).signedUrl
}
export async function saveWordPrompt(client, form, { id, status, updatedAt, file, onUpload }) {
  const payload = wordPromptPayload(form, status)
  const { data, error } = await client.auth.getUser()
  if (error) throw error
  if (!data.user) throw new Error('common.errors.sessionExpired')
  let uploaded
  try {
    if (file) {
      onUpload?.('uploading')
      uploaded = await uploadWordImage(client, id, file)
      payload.image_path = uploaded
      onUpload?.('uploaded')
    }
    let query = client.from('word_prompts')
    query = updatedAt ? query.update(payload).eq('id', id).eq('updated_at', updatedAt) : query.insert({ ...payload, id, created_by: data.user.id })
    const row = dataOrThrow(await query.select().maybeSingle())
    if (!row) throw new Error('wordPrompts.errors.conflict')
    return row
  } catch (error) {
    // Preserve the save error even if cleanup is offline or the file is already referenced.
    if (uploaded) { try { await client.storage.from(imageBucket).remove([uploaded]) } catch {} }
    onUpload?.('failed')
    throw error
  }
}
