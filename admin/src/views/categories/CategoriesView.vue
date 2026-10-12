<script setup>
import { computed, onBeforeUnmount, ref, watch } from 'vue'
import { onBeforeRouteLeave, useRoute, useRouter } from 'vue-router'
import { useMutation, useQuery, useQueryClient } from '@tanstack/vue-query'
import { supabase } from '../../lib/supabase.js'
import { listCategories, setCategoryActive, previewCategoryDelete, transferTargets, deleteCategory } from '../../api/categories.js'
import { useUnsavedChanges } from '../../utils/unsavedChanges.js'
import { categoryError, listFilters, pageSize } from '../../utils/categories.js'
import CategoryFilters from '../../components/categories/CategoryFilters.vue'
import CategoryTable from '../../components/categories/CategoryTable.vue'
import CategoryDeleteDialog from '../../components/categories/CategoryDeleteDialog.vue'

const unsaved = useUnsavedChanges()
const route = useRoute()
const router = useRouter()
const queryClient = useQueryClient()
const filters = computed(() => listFilters(route.query))
const search = ref(filters.value.search)
let timer
watch(() => filters.value.search, value => { search.value = value })
onBeforeUnmount(() => clearTimeout(timer))
function setFilter(key, value) {
  clearTimeout(timer)
  const query = { ...route.query, search: search.value || undefined, [key]: value || undefined, page: undefined }
  router.replace({ name: 'categories', query })
}
function setSearch(value) {
  search.value = value
  clearTimeout(timer)
  timer = setTimeout(() => setFilter('search', value), 300)
}
const list = useQuery({ queryKey: computed(() => ['categories', 'list', filters.value]), queryFn: () => listCategories(supabase, filters.value), retry: false })
const rows = computed(() => list.data.value?.rows || [])
const total = computed(() => list.data.value?.total || 0)
const pages = computed(() => Math.max(1, Math.ceil(total.value / pageSize)))
watch([total, () => filters.value.page, list.isFetching], () => {
  if (list.data.value && !list.isFetching.value && filters.value.page > pages.value) changePage(pages.value)
})
function changePage(page) { clearTimeout(timer); router.replace({ name: 'categories', query: { ...route.query, page: page === 1 ? undefined : String(page) } }) }
function edit(row) { router.push({ name: 'category-edit', params: { id: row.id }, query: route.query }) }
const message = ref('')
const statusMutation = useMutation({
  mutationFn: row => setCategoryActive(supabase, row.id, !row.is_active), retry: false,
  onSuccess: async () => { message.value = 'Đã cập nhật trạng thái.'; await queryClient.invalidateQueries({ queryKey: ['categories'] }) },
})
function toggle(row) {
  if (statusMutation.isPending.value || deleteMutation.isPending.value) return
  if (row.is_active && !window.confirm(`Tắt danh mục “${row.name}”? Content bên trong sẽ được giữ nguyên.`)) return
  message.value = ''; statusMutation.mutate(row)
}
const deleteId = ref('')
const preview = useQuery({ queryKey: computed(() => ['categories', 'delete-preview', deleteId.value]), enabled: computed(() => Boolean(deleteId.value)), queryFn: () => previewCategoryDelete(supabase, deleteId.value), retry: false, staleTime: 0 })
const targets = useQuery({ queryKey: computed(() => ['categories', 'transfer-targets', preview.data.value?.category]), enabled: computed(() => Boolean(deleteId.value && preview.data.value)), queryFn: () => transferTargets(supabase, preview.data.value.category), retry: false })
const deleteMutation = useMutation({
  mutationFn: input => deleteCategory(supabase, input), retry: false,
  onSuccess: async () => { deleteId.value = ''; message.value = 'Đã xóa danh mục.'; await queryClient.invalidateQueries({ queryKey: ['categories'] }) },
})
function openDelete(row) {
  deleteMutation.reset(); deleteId.value = row.id
  queryClient.invalidateQueries({ queryKey: ['categories', 'delete-preview', row.id] })
}
function refreshPreview() { deleteMutation.reset(); preview.refetch(); if (preview.data.value) targets.refetch() }
watch([deleteMutation.isPending, statusMutation.isPending], ([deleting, updating]) => { unsaved.busy = deleting || updating }, { flush: 'sync' })
onBeforeUnmount(() => { unsaved.busy = false })
onBeforeRouteLeave(() => !unsaved.busy)
</script>
<template>
  <section class="categories-page">
    <div class="category-toolbar"><p>Quản lý danh mục cho nội dung từ ngữ và câu hỏi.</p><UButton :to="{ name: 'category-new', query: route.query }" icon="i-lucide-plus" label="Thêm danh mục" :disabled="unsaved.busy" /></div>
    <CategoryFilters :filters="filters" :search="search" @search="setSearch" @filter="setFilter" />
    <UAlert v-if="message" color="success" :description="message" role="status" />
    <UAlert v-if="statusMutation.error.value" color="error" :description="categoryError(statusMutation.error.value)" role="alert" />
    <UAlert v-if="list.isError.value" color="error" :description="categoryError(list.error.value)" role="alert"><template #actions><UButton color="error" variant="outline" label="Thử lại" @click="list.refetch()" /></template></UAlert>
    <UCard v-else-if="list.isPending.value" role="status" aria-label="Đang tải danh mục"><USkeleton class="tw:h-10 tw:w-full" /><USkeleton class="tw:mt-4 tw:h-48 tw:w-full" /></UCard>
    <template v-else>
      <p v-if="list.isFetching.value" role="status">Đang cập nhật danh sách…</p>
      <CategoryTable :rows="rows" :loading="list.isFetching.value" :pending="statusMutation.isPending.value || deleteMutation.isPending.value" @edit="edit" @toggle="toggle" @delete="openDelete" />
      <div class="category-pagination"><span>{{ total }} danh mục · Trang {{ filters.page }} / {{ pages }}</span><UPagination :page="filters.page" :items-per-page="pageSize" :total="total" :sibling-count="1" :disabled="list.isFetching.value" aria-label="Phân trang danh mục" @update:page="changePage" /></div>
    </template>
    <CategoryDeleteDialog v-if="deleteId" :key="deleteId" :preview="preview.data.value" :targets="targets.data.value || []" :targets-loading="targets.isFetching.value" :targets-error="targets.error.value ? categoryError(targets.error.value) : ''" :loading="preview.isFetching.value" :pending="deleteMutation.isPending.value" :error="(deleteMutation.error.value || preview.error.value) ? categoryError(deleteMutation.error.value || preview.error.value) : ''" @close="deleteId = ''" @refresh="refreshPreview" @retry-targets="targets.refetch()" @delete="input => !deleteMutation.isPending.value && deleteMutation.mutate(input)" />
  </section>
</template>
