<script setup>
import { computed, onBeforeUnmount, ref, watch } from 'vue'
import { onBeforeRouteLeave, onBeforeRouteUpdate, useRoute, useRouter } from 'vue-router'
import { useQuery, useMutation, useQueryClient } from '@tanstack/vue-query'
import { useI18n } from 'vue-i18n'
import { supabase } from '../../lib/supabase.js'
import { listQuestionPrompts, questionCategories, getQuestionPrompt, deleteQuestionPrompt, saveQuestionPrompt } from '../../api/questionPrompts.js'
import { difficulties, statuses, questionPromptFilters, questionPromptError } from '../../utils/questionPrompts.js'
import { pageSize } from '../../utils/categories.js'
import { useUnsavedChanges } from '../../utils/unsavedChanges.js'
import QuestionDeleteDialog from '../../components/question-prompts/QuestionDeleteDialog.vue'
function fieldLabel(field) { return 'questionPrompts.fields.' + field.replace(/_([a-z])/g, (_, letter) => letter.toUpperCase()) }
const { t, locale } = useI18n({ useScope: 'global' })
const route = useRoute(), router = useRouter(), cache = useQueryClient(), unsaved = useUnsavedChanges()
const search = ref(typeof route.query.search === 'string' ? route.query.search : '')
let searchTimer
watch(search, value => { clearTimeout(searchTimer); searchTimer = setTimeout(() => setFilter('search', value), 300) })
watch(() => route.query.search, value => { clearTimeout(searchTimer); search.value = typeof value === 'string' ? value : '' })
const filters = computed(() => questionPromptFilters(route.query))
const list = useQuery({ queryKey: computed(() => ['question-prompts', 'list', filters.value]), queryFn: () => listQuestionPrompts(supabase, filters.value), retry: false })
const categoryOptions = useQuery({ queryKey: ['categories', 'question-options'], queryFn: () => questionCategories(supabase), retry: false })
const rows = computed(() => list.data.value?.rows || [])
const total = computed(() => list.data.value?.total || 0)
const pages = computed(() => Math.max(1, Math.ceil(total.value / pageSize)))
const categoryItems = computed(() => [{ label: t('questionPrompts.all'), value: 'all' }, ...(categoryOptions.data.value || []).map(row => ({ label: `${row.name} (${row.locale})`, value: row.id }))])
function items(values, group) { return [{ label: t('questionPrompts.all'), value: 'all' }, ...values.map(value => ({ label: t(`questionPrompts.${group}.${value}`), value }))] }
function setFilter(key, value) { if (!unsaved.busy) router.replace({ name: 'question-prompts', query: { ...route.query, [key]: value || undefined, page: undefined } }) }
function changePage(page) { if (!unsaved.busy) router.replace({ name: 'question-prompts', query: { ...route.query, page: page === 1 ? undefined : String(page) } }) }
watch([total, () => filters.value.page, list.isFetching, () => unsaved.busy], () => { if (list.data.value && !list.isFetching.value && filters.value.page > pages.value) changePage(pages.value) })
const dateFormat = computed(() => new Intl.DateTimeFormat(locale.value === 'en' ? 'en-US' : 'vi-VN', { dateStyle: 'short', timeStyle: 'short' }))
const selected = ref(null), message = ref(''), actionError = ref(null)
async function invalidate() { await Promise.all([cache.invalidateQueries({ queryKey: ['question-prompts'] }), cache.invalidateQueries({ queryKey: ['categories'] })]) }
const deletion = useMutation({ mutationFn: input => deleteQuestionPrompt(supabase, input), retry: false,
  onSuccess: async () => { selected.value = null; message.value = 'questionPrompts.messages.deleted'; await invalidate() }, onSettled: () => { unsaved.busy = false },
})
const archiveMutation = useMutation({ mutationFn: row => saveQuestionPrompt(supabase, row, { id: row.id, updatedAt: row.updated_at, status: 'archived' }), retry: false,
  onSuccess: async () => { message.value = 'questionPrompts.messages.saved'; await invalidate() }, onSettled: () => { unsaved.busy = false },
})
function openDelete(row) { if (unsaved.busy) return; deletion.reset(); actionError.value = null; selected.value = { ...row }; message.value = '' }
function remove(input) { if (unsaved.busy || deletion.isPending.value || questionPromptError(deletion.error.value) === 'questionPrompts.errors.conflict') return; unsaved.busy = true; deletion.mutate(input) }
async function reloadDelete() {
  if (unsaved.busy) return
  actionError.value = null
  unsaved.busy = true
  try { const row = await getQuestionPrompt(supabase, selected.value.id); selected.value = null; deletion.reset(); selected.value = row }
  catch (error) { actionError.value = error }
  finally { unsaved.busy = false }
}
async function reloadList() {
  if (unsaved.busy) return
  archiveMutation.reset(); actionError.value = null
  await list.refetch()
}
function archive(row) { if (unsaved.busy || !window.confirm(t('questionPrompts.confirmations.save'))) return; unsaved.busy = true; archiveMutation.mutate(row) }
function edit(row) { if (!unsaved.busy) router.push({ name: 'question-prompt-edit', params: { id: row.id }, query: route.query }) }
function beforeUnload(event) { if (unsaved.busy) { event.preventDefault(); event.returnValue = '' } }
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
      <UFormField :label="t('questionPrompts.fields.locale')"><UInput :model-value="filters.locale" class="tw:w-full" @update:model-value="setFilter('locale', $event)" /></UFormField>
      <UFormField :label="t('questionPrompts.sort')"><USelect :model-value="filters.sort" :items="[{ label: t('questionPrompts.fields.updatedAt'), value: 'updated_at' }, { label: t('questionPrompts.fields.civilianQuestion'), value: 'civilian_question' }]" class="tw:w-full" @update:model-value="setFilter('sort', $event)" /></UFormField>
    </fieldset>
    <UAlert v-if="message" color="success" :description="t(message)" role="status" />
    <UAlert v-if="actionError || archiveMutation.error.value || categoryOptions.error.value" color="error" :description="t(questionPromptError(actionError || archiveMutation.error.value || categoryOptions.error.value))" role="alert" />
    <UButton v-if="archiveMutation.isError.value" :label="t('questionPrompts.actions.reload')" :disabled="unsaved.busy || list.isFetching.value" @click="reloadList" />
    <UButton v-if="categoryOptions.isError.value" :label="t('common.actions.retry')" @click="categoryOptions.refetch()" />
    <UAlert v-if="list.isError.value" color="error" :description="t(questionPromptError(list.error.value))" role="alert"><template #actions><UButton :label="t('common.actions.retry')" @click="list.refetch()" /></template></UAlert>
    <p v-else-if="list.isPending.value" role="status">{{ t('questionPrompts.loading') }}</p>
    <template v-else>
      <p v-if="!rows.length">{{ t('questionPrompts.empty') }}</p>
      <div v-else class="admin-table-scroll"><table class="admin-table word-table question-table"><thead><tr><th v-for="field in ['civilian_question', 'imposter_question', 'category_id', 'difficulty', 'is_family_friendly', 'status', 'updated_at']" :key="field" :class="`word-column-${field}`" scope="col">{{ t(fieldLabel(field)) }}</th><th scope="col">{{ t('questionPrompts.actionsLabel') }}</th></tr></thead>
        <tbody><tr v-for="row in rows" :key="row.id">
          <td class="word-text-cell"><UButton color="neutral" variant="link" :label="row.civilian_question" class="word-text-link question-truncate" :disabled="unsaved.busy" @click="edit(row)" /></td><td class="question-text-cell"><span class="question-truncate">{{ row.imposter_question }}</span></td><td class="word-category-cell">{{ row.game_categories?.name }}</td><td>{{ t(`questionPrompts.difficulties.${row.difficulty}`) }}</td><td>{{ t(row.is_family_friendly ? 'questionPrompts.yes' : 'questionPrompts.no') }}</td><td>{{ t(`questionPrompts.statuses.${row.status}`) }}</td><td>{{ dateFormat.format(new Date(row.updated_at)) }}</td>
          <td><div class="category-actions"><UButton color="neutral" :label="t('questionPrompts.actions.edit')" variant="outline" :disabled="unsaved.busy" @click="edit(row)" /><UButton color="neutral" v-if="row.status !== 'archived'" :label="t('questionPrompts.actions.archive')" variant="outline" :disabled="unsaved.busy" @click="archive(row)" /><UButton color="error" variant="outline" :label="t('questionPrompts.actions.delete')" :disabled="unsaved.busy" @click="openDelete(row)" /></div></td>
        </tr></tbody></table></div>
      <div class="category-pagination"><span>{{ t('questionPrompts.pagination.summary', { count: total, page: filters.page, pages }) }}</span><UPagination :page="filters.page" :items-per-page="pageSize" :total="total" :disabled="unsaved.busy || list.isFetching.value" :aria-label="t('questionPrompts.pagination.label')" @update:page="changePage" /></div>
    </template>
    <QuestionDeleteDialog v-if="selected" :key="selected.id + selected.updated_at" :prompt="selected" :pending="unsaved.busy" :error="(actionError || deletion.error.value) ? t(questionPromptError(actionError || deletion.error.value)) : ''" :conflict="questionPromptError(deletion.error.value) === 'questionPrompts.errors.conflict'" @close="!unsaved.busy && (selected = null)" @delete="remove" @reload="reloadDelete" />
  </section>
</template>
