<script setup lang="ts">
import AdminPagination from '../../components/admin/AdminPagination.vue'
import ContentStatusBadge from '../../components/admin/ContentStatusBadge.vue'
import type { WordRow, DeletePrompt } from '../../types/admin.ts'
import { computed, onBeforeUnmount, ref, watch } from 'vue'
import { onBeforeRouteLeave, onBeforeRouteUpdate, useRoute, useRouter } from 'vue-router'
import { useQuery, useMutation, useQueryClient } from '@tanstack/vue-query'
import { useI18n } from 'vue-i18n'
import { supabase } from '../../lib/supabase.ts'
import { listWordPrompts, wordCategories, getWordPrompt, deleteWordPrompt, saveWordPrompt } from '../../api/wordPrompts.ts'
import { listContentLanguages } from '../../api/categories.ts'
import { difficulties, statuses, wordPromptFilters, wordPromptError } from '../../utils/wordPrompts.ts'
import { pageSize } from '../../utils/categories.ts'
import { useUnsavedChanges } from '../../utils/unsavedChanges.ts'
import WordImage from '../../components/word-prompts/WordImage.vue'
import WordDeleteDialog from '../../components/word-prompts/WordDeleteDialog.vue'
function fieldLabel(field: string) { return 'wordPrompts.fields.' + field.replace(/_([a-z])/g, (_: string, letter: string) => letter.toUpperCase()) }
const { t, n, locale } = useI18n({ useScope: 'global' })
const route = useRoute(), router = useRouter(), cache = useQueryClient(), unsaved = useUnsavedChanges()
const filters = computed(() => wordPromptFilters(route.query))
const languages = useQuery({ queryKey: ['content-languages'], queryFn: () => listContentLanguages(supabase), retry: false })
watch([languages.data, () => filters.value.locale], ([rows, locale]) => { if (rows && !rows.some(row => row.code === locale)) setFilter('locale', 'vi') }, { immediate: true })
const list = useQuery({ queryKey: computed(() => ['word-prompts', 'list', filters.value]), queryFn: () => listWordPrompts(supabase, filters.value), retry: false })
const categoryOptions = useQuery({ queryKey: computed(() => ['categories', 'word-options', filters.value.locale]), queryFn: () => wordCategories(supabase, filters.value.locale), retry: false })
const rows = computed(() => list.data.value?.rows || [])
const total = computed(() => list.data.value?.total || 0)
const pages = computed(() => Math.max(1, Math.ceil(total.value / pageSize)))
const categoryItems = computed(() => [{ label: t('wordPrompts.all'), value: 'all' }, ...(categoryOptions.data.value || []).map(row => ({ label: (row.name || row.slug), value: row.id }))])
function items(values: readonly string[], group: string) { return [{ label: t('wordPrompts.all'), value: 'all' }, ...values.map(value => ({ label: t(`${group === 'statuses' ? 'common' : 'wordPrompts'}.${group}.${value}`), value }))] }
function setFilter(key: string, value: string | number) { if (!unsaved.busy) router.replace({ name: 'word-prompts', query: { ...route.query, [key]: value || undefined, page: undefined } }) }
function changePage(page: number) { if (!unsaved.busy) router.replace({ name: 'word-prompts', query: { ...route.query, page: page === 1 ? undefined : String(page) } }) }
watch([total, () => filters.value.page, list.isFetching, () => unsaved.busy], () => { if (list.data.value && !list.isFetching.value && filters.value.page > pages.value) changePage(pages.value) })
const dateFormat = computed(() => new Intl.DateTimeFormat(locale.value === 'en' ? 'en-US' : 'vi-VN', { dateStyle: 'short', timeStyle: 'short' }))
const selected = ref<WordRow | null>(null), message = ref(''), actionError = ref<unknown>(null)
async function invalidate() { await Promise.all(['word-prompts', 'question-prompts', 'categories', 'dashboard'].map(key => cache.invalidateQueries({ queryKey: [key] }))) }
const deletion = useMutation({ mutationFn: (input: DeletePrompt) => deleteWordPrompt(supabase, input), retry: false,
  onSuccess: async () => { selected.value = null; message.value = 'wordPrompts.messages.deleted'; await invalidate() }, onSettled: () => { unsaved.busy = false },
})
const archiveMutation = useMutation({ mutationFn: (row: WordRow) => saveWordPrompt(supabase, row, { id: row.id, updatedAt: row.updated_at, status: 'archived' }), retry: false,
  onSuccess: async () => { message.value = 'wordPrompts.messages.saved'; await invalidate() }, onSettled: () => { unsaved.busy = false },
})
function openDelete(row: WordRow) { if (unsaved.busy) return; deletion.reset(); actionError.value = null; selected.value = { ...row }; message.value = '' }
function remove(input: DeletePrompt) { if (unsaved.busy || deletion.isPending.value || wordPromptError(deletion.error.value) === 'wordPrompts.errors.conflict') return; unsaved.busy = true; deletion.mutate(input) }
async function reloadDelete() {
  if (unsaved.busy) return
  actionError.value = null
  unsaved.busy = true
  try { const row = await getWordPrompt(supabase, selected.value!.id); selected.value = null; deletion.reset(); selected.value = { ...row, text: row.translations.find(t => t.locale === filters.value.locale)?.text ?? null, locale: filters.value.locale, status: row.translations.find(t => t.locale === filters.value.locale)?.status ?? null, game_categories: row.game_categories ? { ...row.game_categories, locale: filters.value.locale, name: row.game_categories.translations.find(t => t.locale === filters.value.locale)?.name ?? null } : null } }
  catch (error) { actionError.value = error }
  finally { unsaved.busy = false }
}
async function reloadList() {
  if (unsaved.busy) return
  const result = await list.refetch()
  if (!result.error) { archiveMutation.reset(); actionError.value = null }
}
function archive(row: WordRow) { if (unsaved.busy || !row.status || wordPromptError(archiveMutation.error.value) === 'wordPrompts.errors.conflict' || !window.confirm(t('wordPrompts.confirmations.archive'))) return; unsaved.busy = true; archiveMutation.mutate(row) }
function edit(row: WordRow) { if (!unsaved.busy) router.push({ name: 'word-prompt-edit', params: { id: row.id }, query: route.query }) }
function beforeUnload(event: BeforeUnloadEvent) { if (unsaved.busy) { event.preventDefault(); event.returnValue = '' } }
window.addEventListener('beforeunload', beforeUnload)
onBeforeRouteLeave(() => !unsaved.busy)
onBeforeRouteUpdate(() => !unsaved.busy)
onBeforeUnmount(() => { window.removeEventListener('beforeunload', beforeUnload); unsaved.busy = false })
</script>
<template>
  <section class="categories-page word-prompts-page">
    <div class="category-toolbar"><p>{{ t('wordPrompts.description') }}</p><UButton :to="{ name: 'word-prompt-new', query: route.query }" :label="t('wordPrompts.actions.create')" icon="i-lucide-plus" :disabled="unsaved.busy" /></div>
    <fieldset :disabled="unsaved.busy" class="category-form-fields admin-filter-grid">
      <UFormField :label="t('wordPrompts.search')"><UInput :model-value="filters.search" class="tw:w-full" @update:model-value="setFilter('search', $event)" /></UFormField>
      <UFormField :label="t('wordPrompts.fields.categoryId')"><USelect :model-value="filters.category || 'all'" :items="categoryItems" class="tw:w-full" @update:model-value="setFilter('category', $event === 'all' ? '' : $event)" /></UFormField>
      <UFormField :label="t('wordPrompts.fields.difficulty')"><USelect :model-value="filters.difficulty || 'all'" :items="items(difficulties, 'difficulties')" class="tw:w-full" @update:model-value="setFilter('difficulty', $event === 'all' ? '' : $event)" /></UFormField>
      <UFormField :label="t('wordPrompts.fields.status')"><USelect :model-value="filters.status || 'all'" :items="items(statuses, 'statuses')" class="tw:w-full" @update:model-value="setFilter('status', $event === 'all' ? '' : $event)" /></UFormField>
      <UFormField :label="t('wordPrompts.fields.locale')"><USelect :model-value="filters.locale" :items="(languages.data.value || []).map(row => ({ value: row.code, label: row.display_name }))" class="tw:w-full" @update:model-value="setFilter('locale', $event)" /></UFormField>
      <UFormField :label="t('wordPrompts.sort')"><USelect :model-value="filters.sort" :items="[{ label: t('wordPrompts.fields.updatedAt'), value: 'updated_at' }, { label: t('wordPrompts.fields.text'), value: 'text' }]" class="tw:w-full" @update:model-value="setFilter('sort', $event)" /></UFormField>
    </fieldset>
    <UAlert v-if="message" color="success" :description="t(message)" role="status" />
    <UAlert v-if="actionError || archiveMutation.error.value || categoryOptions.error.value || languages.error.value" color="error" :description="t(wordPromptError(actionError || archiveMutation.error.value || categoryOptions.error.value || languages.error.value))" role="alert" />
    <UButton v-if="archiveMutation.isError.value" :label="t('wordPrompts.actions.reload')" :disabled="unsaved.busy || list.isFetching.value" @click="reloadList" />
    <UButton v-if="languages.isError.value" :label="t('common.actions.retry')" :disabled="unsaved.busy" @click="languages.refetch()" />
    <UAlert v-if="list.isError.value" color="error" :description="t(wordPromptError(list.error.value))" role="alert"><template #actions><UButton :label="t('common.actions.retry')" @click="list.refetch()" /></template></UAlert>
    <p v-else-if="list.isPending.value" role="status">{{ t('wordPrompts.loading') }}</p>
    <template v-else>
      <p v-if="!rows.length">{{ t('wordPrompts.empty') }}</p>
      <div v-else class="admin-table-scroll"><table class="admin-table word-table"><thead><tr><th v-for="field in ['image_path', 'text', 'category_id', 'difficulty', 'status', 'updated_at']" :key="field" :class="`word-column-${field}`" scope="col">{{ t(fieldLabel(field)) }}</th><th scope="col">{{ t('wordPrompts.actionsLabel') }}</th></tr></thead>
        <tbody><tr v-for="row in rows" :key="row.id">
          <td><WordImage :path="row.image_path" :alt="row.text || ''" /></td><td class="word-text-cell"><UButton color="neutral" variant="link" :label="row.text || t('common.statuses.missing')" class="word-text-link" :disabled="unsaved.busy" @click="edit(row)" /></td><td class="word-category-cell">{{ row.game_categories?.name || row.game_categories?.slug }}</td><td>{{ t(`wordPrompts.difficulties.${row.difficulty}`) }}</td><td><div class="translation-statuses"><ContentStatusBadge v-for="language in (languages.data.value || [])" :key="language.code" :locale="language.code" :status="row.translations.find(item => item.locale === language.code)?.status" /></div></td><td>{{ dateFormat.format(new Date(row.updated_at)) }}</td>
          <td><div class="category-actions"><UButton color="neutral" :label="t('common.actions.edit')" variant="outline" :disabled="unsaved.busy" @click="edit(row)" /><UButton color="neutral" v-if="row.status && row.status !== 'archived'" :label="t('common.actions.archive')" variant="outline" :disabled="unsaved.busy || wordPromptError(archiveMutation.error.value) === 'wordPrompts.errors.conflict'" @click="archive(row)" /><UButton color="error" variant="outline" :label="t('common.actions.delete')" :disabled="unsaved.busy" @click="openDelete(row)" /></div></td>
        </tr></tbody></table></div>
      <div class="category-pagination"><span>{{ t('wordPrompts.pagination.summary', { count: n(total), page: n(filters.page), pages: n(pages) }) }}</span><AdminPagination :page="filters.page" :items-per-page="pageSize" :total="total" :disabled="unsaved.busy || list.isFetching.value" :aria-label="t('wordPrompts.pagination.label')" @update:page="changePage" /></div>
    </template>
    <WordDeleteDialog v-if="selected" :key="selected.id + selected.updated_at" :prompt="selected" :pending="unsaved.busy" :error="(actionError || deletion.error.value) ? t(wordPromptError(actionError || deletion.error.value)) : ''" :conflict="wordPromptError(deletion.error.value) === 'wordPrompts.errors.conflict'" @close="!unsaved.busy && (selected = null)" @delete="remove" @reload="reloadDelete" />
  </section>
</template>
