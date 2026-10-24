import type { listFilters } from '../utils/categories.ts'
import type { AdminClient, Category, CategoryDetail, CategoryPreview, CategoryRow, CategoryTarget, DeleteCategory, SavedCategory } from '../types/admin.ts'
import { categoryPayload } from '../utils/categories.ts'

function resultOrThrow<T>(result: { data: T; error?: unknown }) {
  if (result.error) throw result.error
  return result.data
}

export async function listContentLanguages(client: AdminClient) {
  return resultOrThrow(await client.from('content_languages').select('*').order('sort_order').order('code')) || []
}

export async function listCategories(client: AdminClient, filters: ReturnType<typeof listFilters>) {
  return resultOrThrow(await client.rpc('admin_list_categories', {
    p_locale: filters.locale, p_search: filters.search.trim(), p_game_type: filters.gameType || null,
    p_is_active: filters.active ? filters.active === 'true' : null, p_sort: filters.sort, p_page: filters.page,
  })) as { rows: CategoryRow[]; total: number }
}

export async function getCategory(client: AdminClient, id: string): Promise<CategoryDetail> {
  const row = resultOrThrow(await client.from('game_categories').select('*, translations:game_category_translations(*)').eq('id', id).single())
  if (!row) throw new Error('categories.errors.notFound')
  return row
}

export async function saveCategory(client: AdminClient, form: unknown, id: string, updatedAt?: string) {
  const payload = categoryPayload(form)
  return resultOrThrow(await client.rpc('save_category', {
    p_id: id, p_expected_updated_at: updatedAt ?? null, p_game_type: payload.game_type,
    p_slug: payload.slug, p_sort_order: payload.sort_order, p_is_active: payload.is_active,
    p_locale: payload.locale, p_name: payload.name, p_description: payload.description, p_status: payload.status,
  })) as SavedCategory
}

export async function setCategoryActive(client: AdminClient, category: Category, active: boolean) {
  return resultOrThrow(await client.rpc('set_category_active', {
    p_id: category.id, p_is_active: active, p_expected_updated_at: category.updated_at,
  }))
}

export async function previewCategoryDelete(client: AdminClient, id: string) {
  return resultOrThrow(await client.rpc('preview_category_delete', { p_id: id })) as CategoryPreview
}

export async function transferTargets(client: AdminClient, sourceId: string, locale: string) {
  const rows: CategoryTarget[] = []
  // Fetch every candidate rather than silently truncating at the API row limit.
  for (let start = 0; ; start += 100) {
    const batch = resultOrThrow(await client.rpc('admin_category_transfer_targets', {
      p_source_id: sourceId, p_locale: locale,
    }).order('name', { nullsFirst: false }).order('id').range(start, start + 99))
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
