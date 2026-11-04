<script setup lang="ts">
import AdminPagination from '../../components/admin/AdminPagination.vue'
import type { CategoryRow, DeleteCategory } from '../../types/admin.ts'
import { useI18n } from 'vue-i18n'
import { computed, onBeforeUnmount, ref, watch } from 'vue'
import { onBeforeRouteLeave, useRoute, useRouter } from 'vue-router'
import { useMutation, useQuery, useQueryClient } from '@tanstack/vue-query'
import { supabase } from '../../lib/supabase.ts'
import { listContentLanguages, listCategories, setCategoryActive, previewCategoryDelete, transferTargets, deleteCategory } from '../../api/categories.ts'
import { useUnsavedChanges } from '../../utils/unsavedChanges.ts'
import { categoryError, listFilters, pageSize } from '../../utils/categories.ts'
import CategoryFilters from '../../components/categories/CategoryFilters.vue'
import CategoryTable from '../../components/categories/CategoryTable.vue'
import CategoryDeleteDialog from '../../components/categories/CategoryDeleteDialog.vue'
const { t, n } = useI18n({ useScope: 'global' })

const unsaved = useUnsavedChanges()
const route = useRoute()
const router = useRouter()
const queryClient = useQueryClient()
const filters = computed(() => listFilters(route.query))
const languages = useQuery({ queryKey: ['content-languages'], queryFn: () => listContentLanguages(supabase), retry: false })
const validLocale = computed(() => Boolean(languages.data.value?.some(language => language.code === filters.value.locale)))
watch([languages.data, () => filters.value.locale], ([rows, locale]) => {
  if (rows && !rows.some(row => row.code === locale)) router.replace({ query: { ...route.query, locale: 'vi', page: undefined } })
}, { immediate: true })
async function invalidate() {
  await Promise.all(['categories', 'word-prompts', 'question-prompts', 'dashboard'].map(key => queryClient.invalidateQueries({ queryKey: [key] })))
}
const search = ref(filters.value.search)
let timer: ReturnType<typeof setTimeout> | undefined
watch(() => filters.value.search, value => { search.value = value })
onBeforeUnmount(() => clearTimeout(timer))
function setFilter(key: string, value: string) {
  clearTimeout(timer)
  const query = { ...route.query, search: search.value || undefined, [key]: value || undefined, page: undefined }
  router.replace({ name: 'categories', query })
}
function setSearch(input: string | number) {
  const value = String(input)
  search.value = value
  clearTimeout(timer)
  timer = setTimeout(() => setFilter('search', value), 300)
}
const list = useQuery({ queryKey: computed(() => ['categories', 'list', filters.value]), enabled: validLocale, queryFn: () => listCategories(supabase, filters.value), retry: false })
const rows = computed(() => list.data.value?.rows || [])
const total = computed(() => list.data.value?.total || 0)
const pages = computed(() => Math.max(1, Math.ceil(total.value / pageSize)))
watch([total, () => filters.value.page, list.isFetching], () => {
  if (list.data.value && !list.isFetching.value && filters.value.page > pages.value) changePage(pages.value)
})
function changePage(page: number) { clearTimeout(timer); router.replace({ name: 'categories', query: { ...route.query, page: page === 1 ? undefined : String(page) } }) }
function edit(row: CategoryRow) { router.push({ name: 'category-edit', params: { id: row.id }, query: route.query }) }
const message = ref('')
const statusMutation = useMutation({
  mutationFn: (row: CategoryRow) => setCategoryActive(supabase, row, !row.is_active), retry: false,
  onSuccess: async () => { message.value = 'categories.messages.statusUpdated'; await invalidate() },
})
function toggle(row: CategoryRow) {
  if (statusMutation.isPending.value || deleteMutation.isPending.value) return
  if (row.is_active && !window.confirm(t('categories.confirmations.deactivateNamed', { name: row.name || row.slug }))) return
  message.value = ''; statusMutation.mutate(row)
}
const deleteId = ref('')
const preview = useQuery({ queryKey: computed(() => ['categories', 'delete-preview', deleteId.value]), enabled: computed(() => Boolean(deleteId.value)), queryFn: () => previewCategoryDelete(supabase, deleteId.value), retry: false, staleTime: 0 })
const targets = useQuery({ queryKey: computed(() => ['categories', 'transfer-targets', deleteId.value, preview.data.value?.version, filters.value.locale]), enabled: computed(() => Boolean(deleteId.value && preview.data.value)), queryFn: () => transferTargets(supabase, deleteId.value, filters.value.locale), retry: false })
const deleteMutation = useMutation({
  mutationFn: (input: DeleteCategory) => deleteCategory(supabase, input), retry: false,
  onSuccess: async () => { deleteId.value = ''; message.value = 'categories.messages.deleted'; await invalidate() },
})
function openDelete(row: CategoryRow) {
  deleteMutation.reset(); deleteId.value = row.id
  queryClient.invalidateQueries({ queryKey: ['categories', 'delete-preview', row.id] })
}
async function refreshPreview() {
  const result = await preview.refetch()
  if (!result.error) { deleteMutation.reset(); await targets.refetch() }
}
watch([deleteMutation.isPending, statusMutation.isPending], ([deleting, updating]) => { unsaved.busy = deleting || updating }, { flush: 'sync' })
onBeforeUnmount(() => { unsaved.busy = false })
onBeforeRouteLeave(() => !unsaved.busy)
</script>
<template>
  <section class="categories-page">
    <div class="category-toolbar"><p>{{ t('categories.help.overview') }}</p><UButton :to="{ name: 'category-new', query: route.query }" icon="i-lucide-plus" :label="t('categories.actions.create')" :disabled="unsaved.busy" /></div>
    <CategoryFilters :filters="filters" :search="search" :languages="languages.data.value || []" @search="setSearch" @filter="setFilter" />
    <UAlert v-if="message" color="success" :description="t(message)" role="status" />
    <UAlert v-if="statusMutation.error.value" color="error" :description="t(categoryError(statusMutation.error.value))" role="alert"><template #actions><UButton :label="t('categories.actions.reload')" @click="async () => { const result = await list.refetch(); if (!result.error) statusMutation.reset() }" /></template></UAlert>
    <UAlert v-if="languages.isError.value" color="error" :description="t(categoryError(languages.error.value))" role="alert"><template #actions><UButton :label="t('common.actions.retry')" @click="languages.refetch()" /></template></UAlert>
    <UAlert v-else-if="list.isError.value" color="error" :description="t(categoryError(list.error.value))" role="alert"><template #actions><UButton color="error" variant="outline" :label="t('common.actions.retry')" @click="list.refetch()" /></template></UAlert>
    <UCard v-else-if="list.isPending.value" role="status" :aria-label="t('categories.status.loading')"><USkeleton class="tw:h-10 tw:w-full" /><USkeleton class="tw:mt-4 tw:h-48 tw:w-full" /></UCard>
    <template v-else>
      <p v-if="list.isFetching.value" role="status">{{ t('categories.status.refreshing') }}</p>
      <CategoryTable :rows="rows" :languages="languages.data.value || []" :loading="list.isFetching.value" :pending="statusMutation.isPending.value || deleteMutation.isPending.value || categoryError(statusMutation.error.value) === 'categories.errors.conflict'" @edit="edit" @toggle="toggle" @delete="openDelete" />
      <div class="category-pagination"><span>{{ t('categories.pagination.summary', { count: n(total), page: n(filters.page), pages: n(pages) }) }}</span><AdminPagination :page="filters.page" :items-per-page="pageSize" :total="total" :sibling-count="1" :disabled="list.isFetching.value" :aria-label="t('categories.pagination.label')" @update:page="changePage" /></div>
    </template>
    <CategoryDeleteDialog :locale="filters.locale" :conflict="categoryError(deleteMutation.error.value) === 'categories.errors.conflict'" v-if="deleteId" :key="deleteId" :preview="preview.data.value" :targets="targets.data.value || []" :targets-loading="targets.isFetching.value" :targets-error="targets.error.value ? t(categoryError(targets.error.value)) : ''" :loading="preview.isFetching.value" :pending="deleteMutation.isPending.value" :error="(deleteMutation.error.value || preview.error.value) ? t(categoryError(deleteMutation.error.value || preview.error.value)) : ''" @close="deleteId = ''" @refresh="refreshPreview" @retry-targets="targets.refetch()" @delete="input => !deleteMutation.isPending.value && deleteMutation.mutate(input)" />
  </section>
</template>
