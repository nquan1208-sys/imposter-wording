<script setup lang="ts">
import ContentStatusBadge from '../../components/admin/ContentStatusBadge.vue'
import type { QuestionRow, QuestionDetail, QuestionForm, DeletePrompt, PromptStatus } from '../../types/admin.ts'
import { computed, onBeforeUnmount, reactive, ref, watch } from 'vue'
import { onBeforeRouteLeave, onBeforeRouteUpdate, useRoute, useRouter } from 'vue-router'
import { useQuery, useMutation, useQueryClient } from '@tanstack/vue-query'
import { useI18n } from 'vue-i18n'
import { supabase } from '../../lib/supabase.ts'
import { getQuestionPrompt, questionCategories, saveQuestionPrompt, deleteQuestionPrompt } from '../../api/questionPrompts.ts'
import { listContentLanguages } from '../../api/categories.ts'
import { statuses, difficulties, questionPromptPayload, questionPromptError } from '../../utils/questionPrompts.ts'
import { useUnsavedChanges, confirmDiscard } from '../../utils/unsavedChanges.ts'
import QuestionDeleteDialog from '../../components/question-prompts/QuestionDeleteDialog.vue'
const { t } = useI18n({ useScope: 'global' })
const route = useRoute(), router = useRouter(), cache = useQueryClient(), unsaved = useUnsavedChanges()
const routeId = computed(() => typeof route.params.id === 'string' ? route.params.id : '')
const identifier = ref(routeId.value || crypto.randomUUID())
const id = computed(() => identifier.value)
const editing = computed(() => Boolean(routeId.value || saved.value))
const selectedLocale = ref(typeof route.query.locale === 'string' ? route.query.locale : 'vi')
const form = reactive<QuestionForm>({ civilian_question: '', imposter_question: '', category_id: '', difficulty: 'medium', locale: selectedLocale.value })
const saved = ref<QuestionDetail | null>(null)
type Draft = { civilian_question: string; imposter_question: string; status: PromptStatus }
const drafts = reactive<Record<string, Draft>>(Object.create(null)), baselines = reactive<Record<string, string>>(Object.create(null))
const currentStatus = ref<PromptStatus>('draft'), replacing = ref(false), message = ref('')
function translationDraft(): Draft { return { civilian_question: form.civilian_question, imposter_question: form.imposter_question, status: currentStatus.value } }
function sharedDraft() { return { category_id: form.category_id, difficulty: form.difficulty } }
const sharedBaseline = ref(JSON.stringify(sharedDraft()))
function ensureDraft(locale: string) {
  if (!drafts[locale]) { drafts[locale] = { civilian_question: '', imposter_question: '', status: 'draft' }; baselines[locale] = JSON.stringify(drafts[locale]) }
}
ensureDraft(selectedLocale.value)
function stash() { drafts[selectedLocale.value] = translationDraft() }
const activeTranslation = computed(() => saved.value?.translations.find(row => row.locale === selectedLocale.value))
const deletePrompt = computed<QuestionRow | null>(() => saved.value ? ({ ...saved.value, civilian_question: activeTranslation.value?.civilian_question ?? null, imposter_question: activeTranslation.value?.imposter_question ?? null, status: activeTranslation.value?.status ?? null, locale: selectedLocale.value,
  game_categories: saved.value.game_categories ? { ...saved.value.game_categories, locale: selectedLocale.value, name: saved.value.game_categories.translations.find(t => t.locale === selectedLocale.value)?.name ?? null } : null }) : null)
const languages = useQuery({ queryKey: ['content-languages'], queryFn: () => listContentLanguages(supabase), retry: false })
const localError = ref<unknown>(null), deleting = ref(false), reloading = ref(false)
const saveConflict = ref(false)
const detail = useQuery({ queryKey: computed(() => ['question-prompts', 'detail', routeId.value]), enabled: computed(() => Boolean(routeId.value)), queryFn: () => getQuestionPrompt(supabase, routeId.value), retry: false, refetchOnWindowFocus: false })
function load(row: QuestionDetail) {

  Object.assign(form, { category_id: row.category_id, difficulty: row.difficulty })
  saved.value = row; identifier.value = row.id
  for (const key of Object.keys(drafts)) { delete drafts[key]; delete baselines[key] }
  for (const rowTranslation of row.translations) {
    drafts[rowTranslation.locale] = { civilian_question: rowTranslation.civilian_question, imposter_question: rowTranslation.imposter_question, status: rowTranslation.status }
    baselines[rowTranslation.locale] = JSON.stringify(drafts[rowTranslation.locale])
  }
  ensureDraft(selectedLocale.value); Object.assign(form, drafts[selectedLocale.value], { locale: selectedLocale.value }); currentStatus.value = drafts[selectedLocale.value]!.status
  sharedBaseline.value = JSON.stringify(sharedDraft())
}
watch(detail.data, row => {
  if (row && row.id === routeId.value && !unsaved.dirty && !unsaved.busy && !saveConflict.value && !deleting.value) load(row)
}, { immediate: true })
const dirty = computed(() => JSON.stringify(sharedDraft()) !== sharedBaseline.value
  || JSON.stringify(translationDraft()) !== baselines[selectedLocale.value]
  || Object.entries(drafts).some(([locale, draft]) => locale !== selectedLocale.value && JSON.stringify(draft) !== baselines[locale]))
watch(dirty, value => { unsaved.dirty = value }, { immediate: true, flush: 'sync' })
function selectLocale(locale: string) {
  if (unsaved.busy || reloading.value) return
  message.value = ''; localError.value = null
  stash(); ensureDraft(locale); selectedLocale.value = locale
  Object.assign(form, drafts[locale], { locale }); currentStatus.value = drafts[locale]!.status
  router.replace({ query: { ...route.query, locale } })
}
watch(() => route.query.locale, value => { const locale = typeof value === 'string' && value ? value : 'vi'; if (locale !== selectedLocale.value) selectLocale(locale) })
watch([languages.data, selectedLocale], ([rows, locale]) => { if (rows && !rows.some(row => row.code === locale)) selectLocale('vi') }, { immediate: true })
watch(routeId, next => {
  if (next === saved.value?.id) return

  saved.value = null; identifier.value = next || crypto.randomUUID()
  Object.assign(form, { civilian_question: '', imposter_question: '', category_id: '', difficulty: 'medium' })
  for (const key of Object.keys(drafts)) { delete drafts[key]; delete baselines[key] }
  ensureDraft(selectedLocale.value); currentStatus.value = 'draft'; sharedBaseline.value = JSON.stringify(sharedDraft())
  saveConflict.value = false; message.value = ''; localError.value = null; saving.reset(); deletion.reset(); deleting.value = false
})
const categoryOptions = useQuery({ queryKey: computed(() => ['categories', 'question-options', form.locale]), queryFn: () => questionCategories(supabase, form.locale), retry: false })
const categoryItems = computed(() => {
  const rows = (categoryOptions.data.value || []).filter(row => row.is_active || row.id === form.category_id)
  const current = saved.value?.game_categories
  if (current && !rows.some(row => row.id === current.id)) rows.push({ ...current, locale: form.locale, name: current.translations.find(t => t.locale === form.locale)?.name ?? null })
  return rows.map(row => ({ value: row.id, label: (row.name || row.slug) + (row.is_active ? '' : ` (${t('questionPrompts.inactive')})`) }))
})
const statusItems = computed(() => statuses.map(value => ({ value, label: t(`common.statuses.${value}`) })))
const difficultyItems = computed(() => difficulties.map(value => ({ value, label: t(`questionPrompts.difficulties.${value}`) })))
function update<K extends keyof QuestionForm>(key: K, value: QuestionForm[K]) { if (unsaved.busy) return; if (key === 'locale') { selectLocale(String(value)); return } form[key] = value; localError.value = null; message.value = ''; if (!saveConflict.value) saving.reset() }
async function invalidate() { await Promise.all(['word-prompts', 'question-prompts', 'categories', 'dashboard'].map(key => cache.invalidateQueries({ queryKey: [key] }))) }
function back() { return router.push({ name: 'question-prompts', query: route.query }) }
const saving = useMutation({ retry: false,
  mutationFn: (status: PromptStatus) => saveQuestionPrompt(supabase, form, { id: id.value, updatedAt: saved.value?.updated_at, status }),
  onSuccess: async result => {
    const translation = result.translation
    saved.value = { ...result.original, game_categories: categoryOptions.data.value?.find(row => row.id === result.original.category_id)
      ?? (saved.value?.game_categories?.id === result.original.category_id ? saved.value.game_categories : null),
      translations: [...(saved.value?.translations || []).filter(row => row.locale !== translation.locale), translation] }
    identifier.value = result.original.id
    Object.assign(form, { category_id: result.original.category_id, difficulty: result.original.difficulty })

    sharedBaseline.value = JSON.stringify(sharedDraft())
    Object.assign(form, translation); currentStatus.value = translation.status; stash(); baselines[translation.locale] = JSON.stringify(drafts[translation.locale])
    cache.setQueryData(['question-prompts', 'detail', result.original.id], saved.value)
    if (!routeId.value) { replacing.value = true; try { await router.replace({ name: 'question-prompt-edit', params: { id: result.original.id }, query: { ...route.query, locale: selectedLocale.value } }) } finally { replacing.value = false } }
    await invalidate(); message.value = 'questionPrompts.messages.saved'
  },
  onError: error => { if (questionPromptError(error) === 'questionPrompts.errors.conflict') saveConflict.value = true },
  onSettled: () => { unsaved.busy = false },
})
const deletion = useMutation({ mutationFn: (input: DeletePrompt) => deleteQuestionPrompt(supabase, input), retry: false,
  onSuccess: async () => { deleting.value = false; sharedBaseline.value = JSON.stringify(sharedDraft()); stash(); for (const key of Object.keys(drafts)) baselines[key] = JSON.stringify(drafts[key]); unsaved.dirty = false; await invalidate(); unsaved.busy = false; await back() },
  onSettled: () => { unsaved.busy = false },
})
function submit(status: PromptStatus = currentStatus.value) {
  if (unsaved.busy || reloading.value || saveConflict.value || saving.isPending.value || deletion.isPending.value) return
  localError.value = null
  try { questionPromptPayload(form, status) } catch (error) { localError.value = error; return }
  if (activeTranslation.value?.status === 'published' && !window.confirm(t('questionPrompts.confirmations.save'))) return
  unsaved.busy = true; saving.mutate(status)
}
function openDelete() { if (!saved.value || unsaved.busy || reloading.value || saving.isPending.value || deletion.isPending.value) return; if (!conflict.value) deletion.reset(); deleting.value = true }
function remove(input: DeletePrompt) {
  if (unsaved.busy || deletion.isPending.value || conflict.value) return
  unsaved.busy = true; deletion.mutate(input)
}
const conflict = computed(() => questionPromptError(deletion.error.value) === 'questionPrompts.errors.conflict')
function updateStatus(status: PromptStatus) {
  if (unsaved.busy || reloading.value) return
  currentStatus.value = status; localError.value = null; message.value = ''; if (!saveConflict.value) saving.reset()
}
async function reload() {
  if (unsaved.busy || reloading.value || (unsaved.dirty && !confirmDiscard(t('common.confirmations.discardChanges')))) return
  reloading.value = true; unsaved.busy = true
  try {
    const row = await getQuestionPrompt(supabase, id.value)
    load(row); cache.setQueryData(['question-prompts', 'detail', id.value], row)
    deleting.value = false; deletion.reset(); saving.reset(); saveConflict.value = false; localError.value = null
  } catch (error) { localError.value = error }
  finally { reloading.value = false; unsaved.busy = false }
}
function canLeave() { return !unsaved.busy && (!unsaved.dirty || confirmDiscard(t('common.confirmations.discardChanges'))) }
onBeforeRouteLeave(() => replacing.value || canLeave())
onBeforeRouteUpdate((to, from) => replacing.value || (to.path === from.path ? !unsaved.busy : canLeave()))
function beforeUnload(event: BeforeUnloadEvent) { if (unsaved.dirty || unsaved.busy) { event.preventDefault(); event.returnValue = '' } }
window.addEventListener('beforeunload', beforeUnload)
onBeforeUnmount(() => { window.removeEventListener('beforeunload', beforeUnload); unsaved.dirty = false; unsaved.busy = false })
</script>
<template>
  <section class="categories-page word-editor">
    <p v-if="languages.isPending.value || (routeId && detail.isPending.value && !saved)" role="status">{{ t('questionPrompts.loading') }}</p>
    <UAlert v-else-if="languages.isError.value || (editing && !saved && detail.isError.value)" color="error" :description="t(questionPromptError(languages.error.value || detail.error.value))" role="alert"><template #actions><UButton :label="t('common.actions.retry')" @click="languages.isError.value ? languages.refetch() : detail.refetch()" /><UButton :label="t('common.actions.cancel')" @click="back" /></template></UAlert>
    <UCard v-else>
      <UAlert v-if="message" color="success" :description="t(message)" role="status" />
      <form class="category-form" novalidate @submit.prevent="submit(currentStatus)">
        <header class="word-editor-heading">
          <div><h2>{{ t(editing ? 'questionPrompts.form.editTitle' : 'questionPrompts.actions.create') }}</h2><p>{{ t('questionPrompts.form.description') }}</p></div>
          <ContentStatusBadge :status="currentStatus" />
        </header>
        <fieldset :disabled="unsaved.busy" class="category-form-fields word-form-section">
          <legend>{{ t('questionPrompts.form.classification') }}</legend><p>{{ t('questionPrompts.sharedWarning') }}</p>
          <div class="category-form-grid">
            <UFormField :label="t('questionPrompts.fields.categoryId')" required><USelectMenu :model-value="form.category_id" :items="categoryItems" value-key="value" :loading="categoryOptions.isFetching.value" :placeholder="t('questionPrompts.preview.selectCategory')" class="tw:w-full" @update:model-value="update('category_id', $event)" /></UFormField>

            <UFormField :label="t('questionPrompts.fields.difficulty')"><USelect :model-value="form.difficulty" :items="difficultyItems" class="tw:w-full" @update:model-value="update('difficulty', $event)" /></UFormField>
          </div>
        </fieldset>
        <fieldset :disabled="unsaved.busy" class="category-form-fields word-form-section">
          <legend>{{ t('questionPrompts.form.content') }}</legend>
          <UTabs :model-value="selectedLocale" :items="(languages.data.value || []).map(row => ({ label: row.display_name, value: row.code, disabled: unsaved.busy }))" :content="false" :aria-label="t('common.fields.locale')" :ui="{ list: 'tw:flex-wrap' }" @update:model-value="selectLocale(String($event))" />
          <UFormField :label="t('common.fields.status')"><USelect :model-value="currentStatus" :items="statusItems" class="tw:w-full" @update:model-value="updateStatus($event)" /></UFormField>
          <p v-if="!activeTranslation" role="status">{{ t('common.statuses.missing') }}</p>
          <div class="category-form-grid">
            <UFormField v-for="field in (['civilian_question', 'imposter_question'] as const)" :key="field" :label="t(field === 'civilian_question' ? 'questionPrompts.fields.civilianQuestion' : 'questionPrompts.fields.imposterQuestion')" required><UTextarea :model-value="form[field]" :rows="5" class="tw:w-full" @update:model-value="update(field, $event)" /></UFormField>
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
                <div class="word-preview-screen" aria-live="polite"><p :class="(role === 'civilian' ? form.civilian_question : form.imposter_question).trim() ? 'word-preview-text' : 'word-preview-placeholder'">{{ (role === 'civilian' ? form.civilian_question : form.imposter_question).trim() || t('questionPrompts.preview.enterQuestion') }}</p></div>
              </div>
            </UCard>
          </div>
        </section>
        <footer class="word-form-footer">
          <div class="category-actions">
            <UButton type="submit" :label="t('common.actions.save')" :loading="saving.isPending.value" :disabled="unsaved.busy || saveConflict" />
            <UButton type="button" color="neutral" variant="outline" :label="t('common.actions.cancel')" :disabled="unsaved.busy" @click="back" />
          </div>
          <UButton v-if="saved" type="button" color="error" variant="outline" :label="t('common.actions.delete')" :disabled="unsaved.busy" @click="openDelete" />
        </footer>
      </form>
    </UCard>
    <QuestionDeleteDialog v-if="deleting && deletePrompt" :prompt="deletePrompt" :pending="unsaved.busy" :error="deletion.error.value ? t(questionPromptError(deletion.error.value)) : localError ? t(questionPromptError(localError)) : ''" :conflict="conflict" @close="!unsaved.busy && (deleting = false)" @delete="remove" @reload="reload" />
  </section>
</template>
