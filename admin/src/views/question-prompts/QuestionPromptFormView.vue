<script setup>
import { computed, onBeforeUnmount, reactive, ref, watch } from 'vue'
import { onBeforeRouteLeave, onBeforeRouteUpdate, useRoute, useRouter } from 'vue-router'
import { useQuery, useMutation, useQueryClient } from '@tanstack/vue-query'
import { useI18n } from 'vue-i18n'
import { supabase } from '../../lib/supabase.js'
import { getQuestionPrompt, questionCategories, saveQuestionPrompt, deleteQuestionPrompt } from '../../api/questionPrompts.js'
import { difficulties, questionPromptPayload, questionPromptError } from '../../utils/questionPrompts.js'
import { useUnsavedChanges, confirmDiscard } from '../../utils/unsavedChanges.js'
import QuestionDeleteDialog from '../../components/question-prompts/QuestionDeleteDialog.vue'
const { t } = useI18n({ useScope: 'global' })
const route = useRoute(), router = useRouter(), cache = useQueryClient(), unsaved = useUnsavedChanges()
const editing = Boolean(route.params.id), id = route.params.id || crypto.randomUUID()
const form = reactive({ civilian_question: '', imposter_question: '', category_id: '', difficulty: 'medium', is_family_friendly: false, locale: 'vi' })
const saved = ref(null), baseline = ref(JSON.stringify(form))
const localError = ref(null), deleting = ref(false), reloading = ref(false)
const saveConflict = ref(false)
const detail = useQuery({ queryKey: ['question-prompts', 'detail', id], enabled: editing, queryFn: () => getQuestionPrompt(supabase, id), retry: false, refetchOnWindowFocus: false })
function load(row) {
  for (const key of Object.keys(form)) form[key] = row[key] ?? ''
  saved.value = row; baseline.value = JSON.stringify(form); unsaved.dirty = false
}
watch(detail.data, row => {
  if (row && !unsaved.dirty && !unsaved.busy && !saveConflict.value && !deleting.value) load(row)
}, { immediate: true })
watch(form, () => { unsaved.dirty = JSON.stringify(form) !== baseline.value }, { deep: true, flush: 'sync' })
const categoryOptions = useQuery({ queryKey: computed(() => ['categories', 'question-options', form.locale]), queryFn: () => questionCategories(supabase, form.locale), retry: false })
const categoryItems = computed(() => {
  const rows = [...(categoryOptions.data.value || [])]
  const current = saved.value?.game_categories
  if (current && current.locale === form.locale && !rows.some(row => row.id === current.id)) rows.push(current)
  return rows.map(row => ({ value: row.id, label: row.name + (row.is_active ? '' : ` (${t('questionPrompts.inactive')})`) }))
})
const difficultyItems = computed(() => difficulties.map(value => ({ value, label: t(`questionPrompts.difficulties.${value}`) })))
function update(key, value) { if (unsaved.busy) return; form[key] = value; if (key === 'locale') form.category_id = ''; localError.value = null; if (!saveConflict.value) saving.reset() }
async function invalidate() { await Promise.all([cache.invalidateQueries({ queryKey: ['question-prompts'] }), cache.invalidateQueries({ queryKey: ['categories'] })]) }
function back() { return router.push({ name: 'question-prompts', query: route.query }) }
const saving = useMutation({ retry: false,
  mutationFn: status => saveQuestionPrompt(supabase, form, { id, updatedAt: saved.value?.updated_at, status }),
  onSuccess: async row => { load({ ...row, game_categories: saved.value?.game_categories }); await invalidate(); unsaved.busy = false; await back() },
  onError: error => { if (questionPromptError(error) === 'questionPrompts.errors.conflict') saveConflict.value = true },
  onSettled: () => { unsaved.busy = false },
})
const deletion = useMutation({ mutationFn: input => deleteQuestionPrompt(supabase, input), retry: false,
  onSuccess: async () => { deleting.value = false; baseline.value = JSON.stringify(form); unsaved.dirty = false; await invalidate(); unsaved.busy = false; await back() },
  onSettled: () => { unsaved.busy = false },
})
function submit(status) {
  if (unsaved.busy || reloading.value || saveConflict.value || saving.isPending.value || deletion.isPending.value) return
  localError.value = null
  try { questionPromptPayload(form, status) } catch (error) { localError.value = error; return }
  if (saved.value?.status === 'published' && !window.confirm(t('questionPrompts.confirmations.save'))) return
  unsaved.busy = true; saving.mutate(status)
}
function openDelete() { if (!saved.value || unsaved.busy || reloading.value || saving.isPending.value || deletion.isPending.value) return; if (!conflict.value) deletion.reset(); deleting.value = true }
function remove(input) {
  if (unsaved.busy || deletion.isPending.value || conflict.value) return
  unsaved.busy = true; deletion.mutate(input)
}
const conflict = computed(() => questionPromptError(deletion.error.value) === 'questionPrompts.errors.conflict')
async function reload() {
  if (unsaved.busy || reloading.value || (unsaved.dirty && !confirmDiscard(t('common.confirmations.discardChanges')))) return
  reloading.value = true; unsaved.busy = true
  try {
    const row = await getQuestionPrompt(supabase, id)
    load(row); cache.setQueryData(['question-prompts', 'detail', id], row)
    deleting.value = false; deletion.reset(); saving.reset(); saveConflict.value = false; localError.value = null
  } catch (error) { localError.value = error }
  finally { reloading.value = false; unsaved.busy = false }
}
function canLeave() { return !unsaved.busy && (!unsaved.dirty || confirmDiscard(t('common.confirmations.discardChanges'))) }
onBeforeRouteLeave(canLeave)
onBeforeRouteUpdate((to, from) => to.path === from.path ? !unsaved.busy : canLeave())
function beforeUnload(event) { if (unsaved.dirty || unsaved.busy) { event.preventDefault(); event.returnValue = '' } }
window.addEventListener('beforeunload', beforeUnload)
onBeforeUnmount(() => { window.removeEventListener('beforeunload', beforeUnload); unsaved.dirty = false; unsaved.busy = false })
</script>
<template>
  <section class="categories-page word-editor">
    <p v-if="editing && detail.isPending.value" role="status">{{ t('questionPrompts.loading') }}</p>
    <UAlert v-else-if="editing && !saved && detail.isError.value" color="error" :description="t(questionPromptError(detail.error.value))" role="alert"><template #actions><UButton :label="t('common.actions.retry')" @click="detail.refetch()" /><UButton :label="t('common.actions.cancel')" @click="back" /></template></UAlert>
    <UCard v-else>
      <form class="category-form" novalidate @submit.prevent="submit(saved?.status || 'draft')">
        <header class="word-editor-heading">
          <div><h2>{{ t(editing ? 'questionPrompts.actions.edit' : 'questionPrompts.actions.create') }}</h2><p>{{ t('questionPrompts.form.description') }}</p></div>
          <UBadge color="neutral" variant="soft" :label="t(`questionPrompts.statuses.${saved?.status || 'draft'}`)" />
        </header>
        <fieldset :disabled="unsaved.busy" class="category-form-fields word-form-section">
          <legend>{{ t('questionPrompts.form.content') }}</legend>
          <div class="category-form-grid">
            <UFormField v-for="field in ['civilian_question', 'imposter_question']" :key="field" :label="t(field === 'civilian_question' ? 'questionPrompts.fields.civilianQuestion' : 'questionPrompts.fields.imposterQuestion')" required><UTextarea :model-value="form[field]" :rows="5" class="tw:w-full" @update:model-value="update(field, $event)" /></UFormField>
          </div>
        </fieldset>
        <fieldset :disabled="unsaved.busy" class="category-form-fields word-form-section">
          <legend>{{ t('questionPrompts.form.classification') }}</legend>
          <div class="category-form-grid">
            <UFormField :label="t('questionPrompts.fields.categoryId')" required><USelectMenu :model-value="form.category_id" :items="categoryItems" value-key="value" :loading="categoryOptions.isFetching.value" :placeholder="t('questionPrompts.preview.selectCategory')" class="tw:w-full" @update:model-value="update('category_id', $event)" /></UFormField>
            <UFormField :label="t('questionPrompts.fields.locale')" required><UInput :model-value="form.locale" class="tw:w-full" @update:model-value="update('locale', $event)" /></UFormField>
            <UFormField :label="t('questionPrompts.fields.difficulty')"><USelect :model-value="form.difficulty" :items="difficultyItems" class="tw:w-full" @update:model-value="update('difficulty', $event)" /></UFormField>
            <div class="word-family-field"><UCheckbox :model-value="form.is_family_friendly" :label="t('questionPrompts.fields.isFamilyFriendly')" @update:model-value="update('is_family_friendly', $event)" /></div>
          </div>
        </fieldset>
        <UAlert v-if="saveConflict" color="warning" :description="t('questionPrompts.errors.conflict')" role="alert"><template #actions><UButton type="button" :label="t('questionPrompts.actions.reload')" :disabled="unsaved.busy" @click="reload" /></template></UAlert>
        <UAlert v-if="localError || (!saveConflict && saving.error.value) || categoryOptions.error.value" color="error" :description="t(questionPromptError(localError || saving.error.value || categoryOptions.error.value))" role="alert" />
        <UButton v-if="categoryOptions.isError.value" type="button" :label="t('common.actions.retry')" @click="categoryOptions.refetch()" />
        <section class="word-preview-section" aria-labelledby="word-preview-title">
          <div class="word-section-heading"><h2 id="word-preview-title">{{ t('questionPrompts.preview.title') }}</h2><p>{{ t('questionPrompts.preview.description') }}</p></div>
          <div class="word-preview">
            <UCard v-for="role in ['civilian', 'imposter']" :key="role" :class="['word-preview-card', `word-preview-${role}`]" :ui="{ body: 'tw:h-full' }">
              <div class="word-preview-card-body">
                <header class="word-preview-heading"><UIcon :name="role === 'civilian' ? 'i-lucide-user-round' : 'i-lucide-scan-face'" class="word-preview-icon" /><h3>{{ t(`questionPrompts.preview.${role}`) }}</h3></header>
                <div class="word-preview-screen" aria-live="polite"><p :class="form[role + '_question'].trim() ? 'word-preview-text' : 'word-preview-placeholder'">{{ form[role + '_question'].trim() || t('questionPrompts.preview.enterQuestion') }}</p></div>
              </div>
            </UCard>
          </div>
        </section>
        <footer class="word-form-footer">
          <div class="category-actions">
            <UButton type="submit" :label="t('questionPrompts.actions.save')" :loading="saving.isPending.value" :disabled="unsaved.busy || saveConflict" />
            <UButton v-if="saved?.status !== 'published'" type="button" :label="t('questionPrompts.actions.publish')" :disabled="unsaved.busy || saveConflict" @click="submit('published')" />
            <UButton v-if="saved && saved.status !== 'draft'" type="button" variant="outline" :label="t('questionPrompts.actions.draft')" :disabled="unsaved.busy || saveConflict" @click="submit('draft')" />
            <UButton v-if="saved && saved.status !== 'archived'" type="button" variant="outline" :label="t('questionPrompts.actions.archive')" :disabled="unsaved.busy || saveConflict" @click="submit('archived')" />
            <UButton type="button" color="neutral" variant="ghost" :label="t('common.actions.cancel')" :disabled="unsaved.busy" @click="back" />
          </div>
          <UButton v-if="saved" type="button" color="error" variant="outline" :label="t('questionPrompts.actions.delete')" :disabled="unsaved.busy" @click="openDelete" />
        </footer>
      </form>
    </UCard>
    <QuestionDeleteDialog v-if="deleting && saved" :prompt="saved" :pending="unsaved.busy" :error="deletion.error.value ? t(questionPromptError(deletion.error.value)) : localError ? t(questionPromptError(localError)) : ''" :conflict="conflict" @close="!unsaved.busy && (deleting = false)" @delete="remove" @reload="reload" />
  </section>
</template>
