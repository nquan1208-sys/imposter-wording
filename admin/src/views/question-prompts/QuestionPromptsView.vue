<script setup lang="ts">
import type { QuestionRow, DeletePrompt } from '../../types/admin.ts'
import { computed, onBeforeUnmount, ref, watch } from 'vue'
import { onBeforeRouteLeave, onBeforeRouteUpdate, useRoute, useRouter } from 'vue-router'
import { useQuery, useMutation, useQueryClient } from '@tanstack/vue-query'
import { useI18n } from 'vue-i18n'
import { supabase } from '../../lib/supabase.ts'
import { listQuestionPrompts, questionCategories, getQuestionPrompt, deleteQuestionPrompt, saveQuestionPrompt } from '../../api/questionPrompts.ts'
import { listContentLanguages } from '../../api/categories.ts'
import { difficulties, statuses, questionPromptFilters, questionPromptError } from '../../utils/questionPrompts.ts'
import { pageSize } from '../../utils/categories.ts'
import { useUnsavedChanges } from '../../utils/unsavedChanges.ts'
import QuestionDeleteDialog from '../../components/question-prompts/QuestionDeleteDialog.vue'
function fieldLabel(field: string) { return 'questionPrompts.fields.' + field.replace(/_([a-z])/g, (_: string, letter: string) => letter.toUpperCase()) }
const { t, locale } = useI18n({ useScope: 'global' })
const route = useRoute(), router = useRouter(), cache = useQueryClient(), unsaved = useUnsavedChanges()
const search = ref(typeof route.query.search === 'string' ? route.query.search : '')
let searchTimer: ReturnType<typeof setTimeout> | undefined
watch(search, value => { clearTimeout(searchTimer); searchTimer = setTimeout(() => setFilter('search', value), 300) })
watch(() => route.query.search, value => { clearTimeout(searchTimer); search.value = typeof value === 'string' ? value : '' })
const filters = computed(() => questionPromptFilters(route.query))
const languages = useQuery({ queryKey: ['content-languages'], queryFn: () => listContentLanguages(supabase), retry: false })
watch([languages.data, () => filters.value.locale], ([rows, locale]) => { if (rows && !rows.some(row => row.code === locale)) setFilter('locale', 'vi') }, { immediate: true })
const list = useQuery({ queryKey: computed(() => ['question-prompts', 'list', filters.value]), queryFn: () => listQuestionPrompts(supabase, filters.value), retry: false })
const categoryOptions = useQuery({ queryKey: computed(() => ['categories', 'question-options', filters.value.locale]), queryFn: () => questionCategories(supabase, filters.value.locale), retry: false })
const rows = computed(() => list.data.value?.rows || [])
const total = computed(() => list.data.value?.total || 0)
const pages = computed(() => Math.max(1, Math.ceil(total.value / pageSize)))
const categoryItems = computed(() => [{ label: t('questionPrompts.all'), value: 'all' }, ...(categoryOptions.data.value || []).map(row => ({ label: (row.name || row.slug), value: row.id }))])
function items(values: readonly string[], group: string) { return [{ label: t('questionPrompts.all'), value: 'all' }, ...values.map(value => ({ label: t(`questionPrompts.${group}.${value}`), value }))] }
function setFilter(key: string, value: string | number) { if (!unsaved.busy) router.replace({ name: 'question-prompts', query: { ...route.query, [key]: value || undefined, page: undefined } }) }
function changePage(page: number) { if (!unsaved.busy) router.replace({ name: 'question-prompts', query: { ...route.query, page: page === 1 ? undefined : String(page) } }) }
watch([total, () => filters.value.page, list.isFetching, () => unsaved.busy], () => { if (list.data.value && !list.isFetching.value && filters.value.page > pages.value) changePage(pages.value) })
const dateFormat = computed(() => new Intl.DateTimeFormat(locale.value === 'en' ? 'en-US' : 'vi-VN', { dateStyle: 'short', timeStyle: 'short' }))
const selected = ref<QuestionRow | null>(null), message = ref(''), actionError = ref<unknown>(null)
async function invalidate() { await Promise.all(['word-prompts', 'question-prompts', 'categories', 'dashboard'].map(key => cache.invalidateQueries({ queryKey: [key] }))) }
const deletion = useMutation({ mutationFn: (input: DeletePrompt) => deleteQuestionPrompt(supabase, input), retry: false,
  onSuccess: async () => { selected.value = null; message.value = 'questionPrompts.messages.deleted'; await invalidate() }, onSettled: () => { unsaved.busy = false },
})
const archiveMutation = useMutation({ mutationFn: (row: QuestionRow) => saveQuestionPrompt(supabase, row, { id: row.id, updatedAt: row.updated_at, status: 'archived' }), retry: false,
  onSuccess: async () => { message.value = 'questionPrompts.messages.saved'; await invalidate() }, onSettled: () => { unsaved.busy = false },
})
function openDelete(row: QuestionRow) { if (unsaved.busy) return; deletion.reset(); actionError.value = null; selected.value = { ...row }; message.value = '' }
function remove(input: DeletePrompt) { if (unsaved.busy || deletion.isPending.value || questionPromptError(deletion.error.value) === 'questionPrompts.errors.conflict') return; unsaved.busy = true; deletion.mutate(input) }
async function reloadDelete() {
  if (unsaved.busy) return
  actionError.value = null
  unsaved.busy = true
  try { const row = await getQuestionPrompt(supabase, selected.value!.id); selected.value = null; deletion.reset(); selected.value = { ...row, civilian_question: row.translations.find(t => t.locale === filters.value.locale)?.civilian_question ?? null, imposter_question: row.translations.find(t => t.locale === filters.value.locale)?.imposter_question ?? null, locale: filters.value.locale, status: row.translations.find(t => t.locale === filters.value.locale)?.status ?? null, game_categories: row.game_categories ? { ...row.game_categories, locale: filters.value.locale, name: row.game_categories.translations.find(t => t.locale === filters.value.locale)?.name ?? null } : null } }
  catch (error) { actionError.value = error }
  finally { unsaved.busy = false }
}
async function reloadList() {
  if (unsaved.busy) return
  const result = await list.refetch()
  if (!result.error) { archiveMutation.reset(); actionError.value = null }
}
function archive(row: QuestionRow) { if (unsaved.busy || !row.status || questionPromptError(archiveMutation.error.value) === 'questionPrompts.errors.conflict' || !window.confirm(t('questionPrompts.confirmations.save'))) return; unsaved.busy = true; archiveMutation.mutate(row) }
function edit(row: QuestionRow) { if (!unsaved.busy) router.push({ name: 'question-prompt-edit', params: { id: row.id }, query: route.query }) }
function beforeUnload(event: BeforeUnloadEvent) { if (unsaved.busy) { event.preventDefault(); event.returnValue = '' } }
window.addEventListener('beforeunload', beforeUnload)
onBeforeRouteLeave(() => !unsaved.busy)
onBeforeRouteUpdate(() => !unsaved.busy)
onBeforeUnmount(() => { clearTimeout(searchTimer); window.removeEventListener('beforeunload', beforeUnload); unsaved.busy = false })
</script>
<template>
  <section class="categories-page question-prompts-page">
    <div class="category-toolbar"><p>{{ t('questionPrompts.description') }}</p><UButton :to="{ name: 'question-prompt-new', query: route.query }" :label="t('questionPrompts.actions.create')" icon="i-lucide-plus" :disabled="unsaved.busy" /></div>
    <fieldset :disabled="unsaved.busy" class="category-form-fields admin-filter-grid">
      <UFormField :label="t('questionPrompts.search')"><UInput v-model="search" class="tw:w-full" /></UFormField>
      <UFormField :label="t('questionPrompts.fields.categoryId')"><USelect :model-value="filters.category || 'all'" :items="categoryItems" class="tw:w-full" @update:model-value="setFilter('category', $event === 'all' ? '' : $event)" /></UFormField>
      <UFormField :label="t('questionPrompts.fields.difficulty')"><USelect :model-value="filters.difficulty || 'all'" :items="items(difficulties, 'difficulties')" class="tw:w-full" @update:model-value="setFilter('difficulty', $event === 'all' ? '' : $event)" /></UFormField>
      <UFormField :label="t('questionPrompts.fields.status')"><USelect :model-value="filters.status || 'all'" :items="items(statuses, 'statuses')" class="tw:w-full" @update:model-value="setFilter('status', $event === 'all' ? '' : $event)" /></UFormField>
      <UFormField :label="t('questionPrompts.fields.isFamilyFriendly')"><USelect :model-value="filters.family || 'all'" :items="[{ label: t('questionPrompts.all'), value: 'all' }, { label: t('questionPrompts.yes'), value: 'true' }, { label: t('questionPrompts.no'), value: 'false' }]" class="tw:w-full" @update:model-value="setFilter('family', $event === 'all' ? '' : $event)" /></UFormField>
      <UFormField :label="t('questionPrompts.fields.locale')"><USelect :model-value="filters.locale" :items="(languages.data.value || []).map(row => ({ value: row.code, label: row.display_name }))" class="tw:w-full" @update:model-value="setFilter('locale', $event)" /></UFormField>
      <UFormField :label="t('questionPrompts.sort')"><USelect :model-value="filters.sort" :items="[{ label: t('questionPrompts.fields.updatedAt'), value: 'updated_at' }, { label: t('questionPrompts.fields.civilianQuestion'), value: 'civilian_question' }]" class="tw:w-full" @update:model-value="setFilter('sort', $event)" /></UFormField>
    </fieldset>
    <UAlert v-if="message" color="success" :description="t(message)" role="status" />
    <UAlert v-if="actionError || archiveMutation.error.value || categoryOptions.error.value || languages.error.value" color="error" :description="t(questionPromptError(actionError || archiveMutation.error.value || categoryOptions.error.value || languages.error.value))" role="alert" />
    <UButton v-if="archiveMutation.isError.value" :label="t('questionPrompts.actions.reload')" :disabled="unsaved.busy || list.isFetching.value" @click="reloadList" />
    <UButton v-if="categoryOptions.isError.value" :label="t('common.actions.retry')" @click="categoryOptions.refetch()" />
    <UButton v-if="languages.isError.value" :label="t('common.actions.retry')" :disabled="unsaved.busy" @click="languages.refetch()" />
    <UAlert v-if="list.isError.value" color="error" :description="t(questionPromptError(list.error.value))" role="alert"><template #actions><UButton :label="t('common.actions.retry')" @click="list.refetch()" /></template></UAlert>
    <p v-else-if="list.isPending.value" role="status">{{ t('questionPrompts.loading') }}</p>
    <template v-else>
      <p v-if="!rows.length">{{ t('questionPrompts.empty') }}</p>
      <div v-else class="admin-table-scroll"><table class="admin-table word-table question-table"><thead><tr><th v-for="field in ['civilian_question', 'imposter_question', 'category_id', 'difficulty', 'is_family_friendly', 'status', 'updated_at']" :key="field" :class="`word-column-${field}`" scope="col">{{ t(fieldLabel(field)) }}</th><th scope="col">{{ t('questionPrompts.actionsLabel') }}</th></tr></thead>
        <tbody><tr v-for="row in rows" :key="row.id">
          <td class="word-text-cell"><UButton color="neutral" variant="link" :label="row.civilian_question || t('categories.translations.missing')" class="word-text-link question-truncate" :disabled="unsaved.busy" @click="edit(row)" /></td><td class="question-text-cell"><span class="question-truncate">{{ row.imposter_question || t('categories.translations.missing') }}</span></td><td class="word-category-cell">{{ row.game_categories?.name || row.game_categories?.slug }}</td><td>{{ t(`questionPrompts.difficulties.${row.difficulty}`) }}</td><td>{{ t(row.is_family_friendly ? 'questionPrompts.yes' : 'questionPrompts.no') }}</td><td><span v-for="language in (languages.data.value || [])" :key="language.code" class="tw:block">{{ language.code }}: {{ row.translations.some(t => t.locale === language.code) ? t(`questionPrompts.statuses.${row.translations.find(t => t.locale === language.code)!.status}`) : t('categories.translations.missing') }}</span></td><td>{{ dateFormat.format(new Date(row.updated_at)) }}</td>
          <td><div class="category-actions"><UButton color="neutral" :label="t('questionPrompts.actions.edit')" variant="outline" :disabled="unsaved.busy" @click="edit(row)" /><UButton color="neutral" v-if="row.status && row.status !== 'archived'" :label="t('questionPrompts.actions.archive')" variant="outline" :disabled="unsaved.busy || questionPromptError(archiveMutation.error.value) === 'questionPrompts.errors.conflict'" @click="archive(row)" /><UButton color="error" variant="outline" :label="t('questionPrompts.actions.delete')" :disabled="unsaved.busy" @click="openDelete(row)" /></div></td>
        </tr></tbody></table></div>
      <div class="category-pagination"><span>{{ t('questionPrompts.pagination.summary', { count: total, page: filters.page, pages }) }}</span><UPagination :page="filters.page" :items-per-page="pageSize" :total="total" :disabled="unsaved.busy || list.isFetching.value" :aria-label="t('questionPrompts.pagination.label')" @update:page="changePage" /></div>
    </template>
    <QuestionDeleteDialog v-if="selected" :key="selected.id + selected.updated_at" :prompt="selected" :pending="unsaved.busy" :error="(actionError || deletion.error.value) ? t(questionPromptError(actionError || deletion.error.value)) : ''" :conflict="questionPromptError(deletion.error.value) === 'questionPrompts.errors.conflict'" @close="!unsaved.busy && (selected = null)" @delete="remove" @reload="reloadDelete" />
  </section>
</template>
