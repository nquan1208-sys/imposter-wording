<script setup>
import { computed, onBeforeUnmount, ref, watch } from 'vue'
import { onBeforeRouteLeave, onBeforeRouteUpdate, useRoute, useRouter } from 'vue-router'
import { useQuery, useMutation, useQueryClient } from '@tanstack/vue-query'
import { useI18n } from 'vue-i18n'
import { supabase } from '../../lib/supabase.js'
import { listWordPrompts, wordCategories, getWordPrompt, deleteWordPrompt, saveWordPrompt } from '../../api/wordPrompts.js'
import { difficulties, statuses, wordPromptFilters, wordPromptError } from '../../utils/wordPrompts.js'
import { pageSize } from '../../utils/categories.js'
import { useUnsavedChanges } from '../../utils/unsavedChanges.js'
import WordImage from '../../components/word-prompts/WordImage.vue'
import WordDeleteDialog from '../../components/word-prompts/WordDeleteDialog.vue'
function fieldLabel(field) { return 'wordPrompts.fields.' + field.replace(/_([a-z])/g, (_, letter) => letter.toUpperCase()) }
const { t, locale } = useI18n({ useScope: 'global' })
const route = useRoute(), router = useRouter(), cache = useQueryClient(), unsaved = useUnsavedChanges()
const filters = computed(() => wordPromptFilters(route.query))
const list = useQuery({ queryKey: computed(() => ['word-prompts', 'list', filters.value]), queryFn: () => listWordPrompts(supabase, filters.value), retry: false })
const categoryOptions = useQuery({ queryKey: ['categories', 'word-options'], queryFn: () => wordCategories(supabase), retry: false })
const rows = computed(() => list.data.value?.rows || [])
const total = computed(() => list.data.value?.total || 0)
const pages = computed(() => Math.max(1, Math.ceil(total.value / pageSize)))
const categoryItems = computed(() => [{ label: t('wordPrompts.all'), value: 'all' }, ...(categoryOptions.data.value || []).map(row => ({ label: `${row.name} (${row.locale})`, value: row.id }))])
function items(values, group) { return [{ label: t('wordPrompts.all'), value: 'all' }, ...values.map(value => ({ label: t(`wordPrompts.${group}.${value}`), value }))] }
function setFilter(key, value) { if (!unsaved.busy) router.replace({ name: 'word-prompts', query: { ...route.query, [key]: value || undefined, page: undefined } }) }
function changePage(page) { if (!unsaved.busy) router.replace({ name: 'word-prompts', query: { ...route.query, page: page === 1 ? undefined : String(page) } }) }
watch([total, () => filters.value.page, list.isFetching, () => unsaved.busy], () => { if (list.data.value && !list.isFetching.value && filters.value.page > pages.value) changePage(pages.value) })
const dateFormat = computed(() => new Intl.DateTimeFormat(locale.value === 'en' ? 'en-US' : 'vi-VN', { dateStyle: 'short', timeStyle: 'short' }))
const selected = ref(null), message = ref(''), actionError = ref(null)
async function invalidate() { await Promise.all([cache.invalidateQueries({ queryKey: ['word-prompts'] }), cache.invalidateQueries({ queryKey: ['categories'] })]) }
const deletion = useMutation({ mutationFn: input => deleteWordPrompt(supabase, input), retry: false,
  onSuccess: async () => { selected.value = null; message.value = 'wordPrompts.messages.deleted'; await invalidate() }, onSettled: () => { unsaved.busy = false },
})
const archiveMutation = useMutation({ mutationFn: row => saveWordPrompt(supabase, row, { id: row.id, updatedAt: row.updated_at, status: 'archived' }), retry: false,
  onSuccess: async () => { message.value = 'wordPrompts.messages.saved'; await invalidate() }, onSettled: () => { unsaved.busy = false },
})
function openDelete(row) { if (unsaved.busy) return; deletion.reset(); actionError.value = null; selected.value = { ...row }; message.value = '' }
function remove(input) { if (unsaved.busy || deletion.isPending.value || wordPromptError(deletion.error.value) === 'wordPrompts.errors.conflict') return; unsaved.busy = true; deletion.mutate(input) }
async function reloadDelete() {
  if (unsaved.busy) return
  actionError.value = null
  unsaved.busy = true
  try { const row = await getWordPrompt(supabase, selected.value.id); selected.value = null; deletion.reset(); selected.value = row }
  catch (error) { actionError.value = error }
  finally { unsaved.busy = false }
}
function archive(row) { if (unsaved.busy || !window.confirm(t('wordPrompts.confirmations.save'))) return; unsaved.busy = true; archiveMutation.mutate(row) }
function edit(row) { if (!unsaved.busy) router.push({ name: 'word-prompt-edit', params: { id: row.id }, query: route.query }) }
function beforeUnload(event) { if (unsaved.busy) { event.preventDefault(); event.returnValue = '' } }
window.addEventListener('beforeunload', beforeUnload)
onBeforeRouteLeave(() => !unsaved.busy)
onBeforeRouteUpdate(() => !unsaved.busy)
onBeforeUnmount(() => { window.removeEventListener('beforeunload', beforeUnload); unsaved.busy = false })
</script>
<template>
  <section class="categories-page">
    <div class="category-toolbar"><p>{{ t('wordPrompts.description') }}</p><UButton :to="{ name: 'word-prompt-new', query: route.query }" :label="t('wordPrompts.actions.create')" icon="i-lucide-plus" :disabled="unsaved.busy" /></div>
    <fieldset :disabled="unsaved.busy" class="category-form-fields word-filters">
      <UFormField :label="t('wordPrompts.search')"><UInput :model-value="filters.search" class="tw:w-full" @update:model-value="setFilter('search', $event)" /></UFormField>
      <UFormField :label="t('wordPrompts.fields.categoryId')"><USelect :model-value="filters.category || 'all'" :items="categoryItems" class="tw:w-full" @update:model-value="setFilter('category', $event === 'all' ? '' : $event)" /></UFormField>
      <UFormField :label="t('wordPrompts.fields.difficulty')"><USelect :model-value="filters.difficulty || 'all'" :items="items(difficulties, 'difficulties')" class="tw:w-full" @update:model-value="setFilter('difficulty', $event === 'all' ? '' : $event)" /></UFormField>
      <UFormField :label="t('wordPrompts.fields.status')"><USelect :model-value="filters.status || 'all'" :items="items(statuses, 'statuses')" class="tw:w-full" @update:model-value="setFilter('status', $event === 'all' ? '' : $event)" /></UFormField>
      <UFormField :label="t('wordPrompts.fields.isFamilyFriendly')"><USelect :model-value="filters.family || 'all'" :items="[{ label: t('wordPrompts.all'), value: 'all' }, { label: t('wordPrompts.yes'), value: 'true' }, { label: t('wordPrompts.no'), value: 'false' }]" class="tw:w-full" @update:model-value="setFilter('family', $event === 'all' ? '' : $event)" /></UFormField>
      <UFormField :label="t('wordPrompts.fields.locale')"><UInput :model-value="filters.locale" class="tw:w-full" @update:model-value="setFilter('locale', $event)" /></UFormField>
      <UFormField :label="t('wordPrompts.sort')"><USelect :model-value="filters.sort" :items="[{ label: t('wordPrompts.fields.updatedAt'), value: 'updated_at' }, { label: t('wordPrompts.fields.text'), value: 'text' }]" class="tw:w-full" @update:model-value="setFilter('sort', $event)" /></UFormField>
    </fieldset>
    <UAlert v-if="message" color="success" :description="t(message)" role="status" />
    <UAlert v-if="actionError || archiveMutation.error.value || categoryOptions.error.value" color="error" :description="t(wordPromptError(actionError || archiveMutation.error.value || categoryOptions.error.value))" role="alert" />
    <UAlert v-if="list.isError.value" color="error" :description="t(wordPromptError(list.error.value))" role="alert"><template #actions><UButton :label="t('common.actions.retry')" @click="list.refetch()" /></template></UAlert>
    <p v-else-if="list.isPending.value" role="status">{{ t('wordPrompts.loading') }}</p>
    <template v-else>
      <p v-if="!rows.length">{{ t('wordPrompts.empty') }}</p>
      <div v-else class="word-table-scroll"><table class="word-table"><thead><tr><th v-for="field in ['image_path', 'text', 'category_id', 'difficulty', 'is_family_friendly', 'status', 'updated_at']" :key="field" scope="col">{{ t(fieldLabel(field)) }}</th><th scope="col">{{ t('wordPrompts.actionsLabel') }}</th></tr></thead>
        <tbody><tr v-for="row in rows" :key="row.id">
          <td><WordImage :path="row.image_path" :alt="row.text" /></td><td><UButton color="neutral" variant="link" :label="row.text" :disabled="unsaved.busy" @click="edit(row)" /></td><td>{{ row.game_categories?.name }}</td><td>{{ t(`wordPrompts.difficulties.${row.difficulty}`) }}</td><td>{{ t(row.is_family_friendly ? 'wordPrompts.yes' : 'wordPrompts.no') }}</td><td>{{ t(`wordPrompts.statuses.${row.status}`) }}</td><td>{{ dateFormat.format(new Date(row.updated_at)) }}</td>
          <td><div class="category-actions"><UButton color="neutral" :label="t('wordPrompts.actions.edit')" variant="outline" :disabled="unsaved.busy" @click="edit(row)" /><UButton color="neutral" v-if="row.status !== 'archived'" :label="t('wordPrompts.actions.archive')" variant="outline" :disabled="unsaved.busy" @click="archive(row)" /><UButton color="error" variant="outline" :label="t('wordPrompts.actions.delete')" :disabled="unsaved.busy" @click="openDelete(row)" /></div></td>
        </tr></tbody></table></div>
      <div class="category-pagination"><span>{{ t('wordPrompts.pagination.summary', { count: total, page: filters.page, pages }) }}</span><UPagination :page="filters.page" :items-per-page="pageSize" :total="total" :disabled="unsaved.busy || list.isFetching.value" :aria-label="t('wordPrompts.pagination.label')" @update:page="changePage" /></div>
    </template>
    <WordDeleteDialog v-if="selected" :key="selected.id + selected.updated_at" :prompt="selected" :pending="unsaved.busy" :error="(actionError || deletion.error.value) ? t(wordPromptError(actionError || deletion.error.value)) : ''" :conflict="wordPromptError(deletion.error.value) === 'wordPrompts.errors.conflict'" @close="!unsaved.busy && (selected = null)" @delete="remove" @reload="reloadDelete" />
  </section>
</template>
