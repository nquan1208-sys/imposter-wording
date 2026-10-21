import type { listFilters } from '../utils/categories.ts'
import type { AdminClient, Category, CategoryPreview, DeleteCategory } from '../types/admin.ts'
import { categoryPayload, pageSize, searchPattern } from '../utils/categories.ts'

function resultOrThrow<T>(result: { data: T; error?: unknown }) {
  if (result.error) throw result.error
  return result.data
}

export async function listCategories(client: AdminClient, filters: ReturnType<typeof listFilters>) {
  let query = client.from('game_categories').select('*, word_prompts(count), question_prompts(count)', { count: 'exact' })
  if (filters.search.trim()) {
    const pattern = searchPattern(filters.search.trim())
    query = query.or(`name.ilike.${pattern},slug.ilike.${pattern}`)
  }
  if (filters.gameType) query = query.eq('game_type', filters.gameType)
  if (filters.active) query = query.eq('is_active', filters.active === 'true')
  query = query.order(filters.sort, { ascending: filters.sort !== 'updated_at' })
  if (filters.sort !== 'name') query = query.order('name')
  const start = (filters.page - 1) * pageSize
  const result = await query.order('id').range(start, start + pageSize - 1)
  return { rows: resultOrThrow(result), total: result.count || 0 }
}

export async function getCategory(client: AdminClient, id: string) {
  const row = resultOrThrow(await client.from('game_categories').select('*').eq('id', id).single())
  if (!row) throw new Error('categories.errors.notFound')
  return row
}

export async function saveCategory(client: AdminClient, form: unknown, id?: string) {
  if (id) return resultOrThrow(await client.from('game_categories').update(categoryPayload(form, true)).eq('id', id).select().single())
  const payload = categoryPayload(form, false)
  const { data, error } = await client.auth.getUser()
  if (error) throw error
  if (!data.user) throw new Error('common.errors.sessionExpired')
  return resultOrThrow(await client.from('game_categories').insert({ ...payload, created_by: data.user.id }).select().single())
}

export async function setCategoryActive(client: AdminClient, id: string, active: boolean) {
  return resultOrThrow(await client.from('game_categories').update({ is_active: active }).eq('id', id).select().single())
}

export async function previewCategoryDelete(client: AdminClient, id: string) {
  // This RPC returns a JSON snapshot defined by category_content_snapshot.
  return resultOrThrow(await client.rpc('preview_category_delete', { p_id: id })) as CategoryPreview
}

export async function transferTargets(client: AdminClient, category: Pick<Category, 'id' | 'game_type' | 'locale'>) {
  const rows = []
  // Fetch every candidate rather than silently truncating at the API row limit.
  for (let start = 0; ; start += 100) {
    const batch = resultOrThrow(await client.from('game_categories').select('id,name,slug')
      .eq('game_type', category.game_type).eq('locale', category.locale).eq('is_active', true)
      .neq('id', category.id).order('name').order('id').range(start, start + 99))
    rows.push(...(batch || []))
    if ((batch?.length ?? 0) < 100) return rows
  }
}

export async function deleteCategory(client: AdminClient, input: DeleteCategory) {
  return resultOrThrow(await client.rpc('delete_category', {
    p_id: input.id, p_mode: input.mode, p_target_id: input.targetId || null,
    p_expected_version: input.version || null,
  }))
}
