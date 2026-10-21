<script setup lang="ts">
import type { WordRow, WordForm, DeletePrompt, PromptStatus } from '../../types/admin.ts'
import { computed, onBeforeUnmount, reactive, ref, watch } from 'vue'
import { onBeforeRouteLeave, onBeforeRouteUpdate, useRoute, useRouter } from 'vue-router'
import { useQuery, useMutation, useQueryClient } from '@tanstack/vue-query'
import { useI18n } from 'vue-i18n'
import { supabase } from '../../lib/supabase.ts'
import { getWordPrompt, wordCategories, saveWordPrompt, deleteWordPrompt } from '../../api/wordPrompts.ts'
import { difficulties, validateImage, wordPromptPayload, wordPromptError } from '../../utils/wordPrompts.ts'
import { useUnsavedChanges, confirmDiscard } from '../../utils/unsavedChanges.ts'
import WordImage from '../../components/word-prompts/WordImage.vue'
import WordDeleteDialog from '../../components/word-prompts/WordDeleteDialog.vue'
const { t } = useI18n({ useScope: 'global' })
const route = useRoute(), router = useRouter(), cache = useQueryClient(), unsaved = useUnsavedChanges()
const editing = Boolean(route.params.id), id = typeof route.params.id === 'string' ? route.params.id : crypto.randomUUID()
const form = reactive<WordForm>({ text: '', category_id: '', difficulty: 'medium', is_family_friendly: false, locale: 'vi', image_path: '' })
const saved = ref<WordRow | null>(null), baseline = ref(JSON.stringify(form)), file = ref<File | null>(null), localUrl = ref(''), imageInput = ref<HTMLInputElement | null>(null)
const localError = ref<unknown>(null), uploadState = ref(''), deleting = ref(false), reloading = ref(false)
const saveConflict = ref(false), showCategoryHint = ref(false)
const detail = useQuery({ queryKey: ['word-prompts', 'detail', id], enabled: editing, queryFn: () => getWordPrompt(supabase, id), retry: false, refetchOnWindowFocus: false })
function clearFile() { if (localUrl.value) URL.revokeObjectURL(localUrl.value); localUrl.value = ''; file.value = null; if (imageInput.value) imageInput.value.value = '' }
function load(row: WordRow) {
  clearFile()
  form.text = row.text
  form.category_id = row.category_id
  form.difficulty = row.difficulty
  form.is_family_friendly = row.is_family_friendly
  form.locale = row.locale
  form.image_path = row.image_path ?? ''
  saved.value = row; baseline.value = JSON.stringify(form); unsaved.dirty = false
}
watch(detail.data, row => {
  if (row && !unsaved.dirty && !unsaved.busy && !saveConflict.value && !deleting.value) load(row)
}, { immediate: true })
watch([form, file], () => { unsaved.dirty = JSON.stringify(form) !== baseline.value || Boolean(file.value) }, { deep: true, flush: 'sync' })
const categoryOptions = useQuery({ queryKey: computed(() => ['categories', 'word-options', form.locale]), queryFn: () => wordCategories(supabase, form.locale), retry: false })
const categoryItems = computed(() => {
  const rows = [...(categoryOptions.data.value || [])]
  const current = saved.value?.game_categories
  if (current && current.locale === form.locale && !rows.some(row => row.id === current.id)) rows.push({ ...current, locale: form.locale })
  return rows.map(row => ({ value: row.id, label: row.name + (row.is_active ? '' : ` (${t('wordPrompts.inactive')})`) }))
})
const previewCategoryName = computed(() => {
  const current = saved.value?.game_categories
  return (categoryOptions.data.value || []).find(row => row.id === form.category_id)?.name
    || (current?.id === form.category_id && current.locale === form.locale ? current.name : '')
    || ''
})
const difficultyItems = computed(() => difficulties.map(value => ({ value, label: t(`wordPrompts.difficulties.${value}`) })))
function update<K extends keyof WordForm>(key: K, value: WordForm[K]) { if (unsaved.busy) return; form[key] = value; if (key === 'locale') form.category_id = ''; localError.value = null; if (!saveConflict.value) saving.reset() }
async function chooseImage(event: Event) {
  const next = (event.target as HTMLInputElement).files?.[0]
  if (!next || unsaved.busy) return
  unsaved.busy = true
  clearFile()
  let preview
  try {
    validateImage(next)
    preview = URL.createObjectURL(next)
    await new Promise((resolve, reject) => { const image = new Image(); image.onload = resolve; image.onerror = () => reject(new Error('wordPrompts.errors.invalidImage')); image.src = preview! })
    if (disposed) { URL.revokeObjectURL(preview); return }
    file.value = next; localUrl.value = preview; localError.value = null; uploadState.value = ''
  } catch (error) { if (preview) URL.revokeObjectURL(preview); localError.value = error }
  finally { unsaved.busy = false }
}
function removeImage() { if (!unsaved.busy) { clearFile(); form.image_path = ''; uploadState.value = '' } }
async function invalidate() { await Promise.all([cache.invalidateQueries({ queryKey: ['word-prompts'] }), cache.invalidateQueries({ queryKey: ['categories'] })]) }
function back() { return router.push({ name: 'word-prompts', query: route.query }) }
const saving = useMutation({ retry: false,
  mutationFn: (status: PromptStatus) => saveWordPrompt(supabase, form, { id, updatedAt: saved.value?.updated_at, status, file: file.value, onUpload: state => { uploadState.value = state } }),
  onSuccess: async row => { load({ ...row, game_categories: saved.value?.game_categories }); await invalidate(); unsaved.busy = false; await back() },
  onError: error => { if (wordPromptError(error) === 'wordPrompts.errors.conflict') saveConflict.value = true },
  onSettled: () => { unsaved.busy = false },
})
const deletion = useMutation({ mutationFn: (input: DeletePrompt) => deleteWordPrompt(supabase, input), retry: false,
  onSuccess: async () => { deleting.value = false; clearFile(); baseline.value = JSON.stringify(form); unsaved.dirty = false; await invalidate(); unsaved.busy = false; await back() },
  onSettled: () => { unsaved.busy = false },
})
function submit(status: PromptStatus) {
  if (unsaved.busy || reloading.value || saveConflict.value || saving.isPending.value || deletion.isPending.value) return
  localError.value = null
  try { wordPromptPayload(form, status) } catch (error) { localError.value = error; return }
  if (saved.value?.status === 'published' && !window.confirm(t('wordPrompts.confirmations.save'))) return
  unsaved.busy = true; saving.mutate(status)
}
function openDelete() { if (!saved.value || unsaved.busy || reloading.value || saving.isPending.value || deletion.isPending.value) return; if (!conflict.value) deletion.reset(); deleting.value = true }
function remove(input: DeletePrompt) {
  if (unsaved.busy || deletion.isPending.value || conflict.value) return
  unsaved.busy = true; deletion.mutate(input)
}
const conflict = computed(() => wordPromptError(deletion.error.value) === 'wordPrompts.errors.conflict')
async function reload() {
  if (unsaved.busy || reloading.value || (unsaved.dirty && !confirmDiscard(t('common.confirmations.discardChanges')))) return
  reloading.value = true; unsaved.busy = true
  try {
    const row = await getWordPrompt(supabase, id)
    load(row); cache.setQueryData(['word-prompts', 'detail', id], row)
    deleting.value = false; deletion.reset(); saving.reset(); saveConflict.value = false; localError.value = null
  } catch (error) { localError.value = error }
  finally { reloading.value = false; unsaved.busy = false }
}
function canLeave() { return !unsaved.busy && (!unsaved.dirty || confirmDiscard(t('common.confirmations.discardChanges'))) }
onBeforeRouteLeave(canLeave)
onBeforeRouteUpdate((to, from) => to.path === from.path ? !unsaved.busy : canLeave())
function beforeUnload(event: BeforeUnloadEvent) { if (unsaved.dirty || unsaved.busy) { event.preventDefault(); event.returnValue = '' } }
let disposed = false
window.addEventListener('beforeunload', beforeUnload)
onBeforeUnmount(() => { disposed = true; clearFile(); window.removeEventListener('beforeunload', beforeUnload); unsaved.dirty = false; unsaved.busy = false })
</script>
<template>
  <section class="categories-page word-editor">
    <p v-if="editing && detail.isPending.value" role="status">{{ t('wordPrompts.loading') }}</p>
    <UAlert v-else-if="editing && !saved && detail.isError.value" color="error" :description="t(wordPromptError(detail.error.value))" role="alert"><template #actions><UButton :label="t('common.actions.retry')" @click="detail.refetch()" /><UButton :label="t('common.actions.cancel')" @click="back" /></template></UAlert>
    <UCard v-else>
      <form class="category-form" novalidate @submit.prevent="submit(saved?.status || 'draft')">
        <header class="word-editor-heading">
          <div><h2>{{ t(editing ? 'wordPrompts.actions.edit' : 'wordPrompts.actions.create') }}</h2><p>{{ t('wordPrompts.form.description') }}</p></div>
          <UBadge color="neutral" variant="soft" :label="t(`wordPrompts.statuses.${saved?.status || 'draft'}`)" />
        </header>
        <fieldset :disabled="unsaved.busy" class="category-form-fields word-form-section">
          <legend>{{ t('wordPrompts.form.content') }}</legend>
          <UFormField :label="t('wordPrompts.fields.text')" required><UInput :model-value="form.text" class="tw:w-full" :placeholder="t('wordPrompts.form.textPlaceholder')" @update:model-value="update('text', $event)" /></UFormField>
        </fieldset>
        <fieldset :disabled="unsaved.busy" class="category-form-fields word-form-section">
          <legend>{{ t('wordPrompts.form.classification') }}</legend>
          <div class="category-form-grid">
            <UFormField :label="t('wordPrompts.fields.categoryId')" required><USelectMenu :model-value="form.category_id" :items="categoryItems" value-key="value" :loading="categoryOptions.isFetching.value" :placeholder="t('wordPrompts.preview.selectCategory')" class="tw:w-full" @update:model-value="update('category_id', $event)" /></UFormField>
            <UFormField :label="t('wordPrompts.fields.locale')" required><UInput :model-value="form.locale" class="tw:w-full" @update:model-value="update('locale', $event)" /></UFormField>
            <UFormField :label="t('wordPrompts.fields.difficulty')"><USelect :model-value="form.difficulty" :items="difficultyItems" class="tw:w-full" @update:model-value="update('difficulty', $event)" /></UFormField>
            <div class="word-family-field"><UCheckbox :model-value="form.is_family_friendly" :label="t('wordPrompts.fields.isFamilyFriendly')" @update:model-value="update('is_family_friendly', $event === true)" /></div>
          </div>
        </fieldset>
        <fieldset :disabled="unsaved.busy" class="category-form-fields word-form-section">
          <legend>{{ t('wordPrompts.fields.imagePath') }}</legend>
          <UFormField :label="t('wordPrompts.form.chooseImage')" :help="t('wordPrompts.imageHelp')">
            <div class="word-image-controls">
              <input ref="imageInput" type="file" hidden :aria-label="t('wordPrompts.form.chooseImage')" accept="image/jpeg,image/png,image/webp" @change="chooseImage" />
              <UButton type="button" size="lg" icon="i-lucide-image-plus" :label="t('wordPrompts.form.chooseImage')" :disabled="unsaved.busy" @click="imageInput?.click()" />
              <span v-if="file" class="word-image-filename" role="status">{{ file.name }}</span>
              <UButton type="button" color="neutral" variant="outline" icon="i-lucide-trash-2" :label="t('wordPrompts.actions.removeImage')" :disabled="unsaved.busy || (!file && !form.image_path)" @click="removeImage" />
            </div>
          </UFormField>
        </fieldset>
        <p v-if="uploadState" role="status">{{ t(`wordPrompts.upload.${uploadState}`) }}</p>
        <UAlert v-if="saveConflict" color="warning" :description="t('wordPrompts.errors.conflict')" role="alert"><template #actions><UButton type="button" :label="t('wordPrompts.actions.reload')" :disabled="unsaved.busy" @click="reload" /></template></UAlert>
        <UAlert v-if="localError || (!saveConflict && saving.error.value) || categoryOptions.error.value" color="error" :description="t(wordPromptError(localError || saving.error.value || categoryOptions.error.value))" role="alert" />
        <section class="word-preview-section" aria-labelledby="word-preview-title">
          <div class="word-section-heading"><h2 id="word-preview-title">{{ t('wordPrompts.preview.title') }}</h2><p>{{ t('wordPrompts.preview.description') }}</p></div>
          <div class="word-preview">
            <UCard class="word-preview-card word-preview-civilian" :ui="{ body: 'tw:h-full' }">
              <div class="word-preview-card-body">
                <header class="word-preview-heading"><UIcon name="i-lucide-user-round" class="word-preview-icon" /><h3>{{ t('wordPrompts.preview.civilian') }}</h3></header>
                <div class="word-preview-screen">
                  <p :class="form.text.trim() ? 'word-preview-text' : 'word-preview-placeholder'">{{ form.text.trim() || t('wordPrompts.preview.enterText') }}</p>
                  <img v-if="localUrl" :src="localUrl" :alt="form.text" class="word-image" />
                  <WordImage v-else-if="form.image_path" :path="form.image_path" :alt="form.text" />
                </div>
              </div>
            </UCard>
            <UCard class="word-preview-card word-preview-imposter" :ui="{ body: 'tw:h-full' }">
              <div class="word-preview-card-body">
                <header class="word-preview-heading"><UIcon name="i-lucide-scan-face" class="word-preview-icon" /><h3>{{ t('wordPrompts.preview.imposter') }}</h3></header>
                <USwitch v-model="showCategoryHint" :label="t('wordPrompts.preview.categoryHint')" :disabled="unsaved.busy" />
                <div class="word-preview-screen" aria-live="polite">
                  <p :class="showCategoryHint && !previewCategoryName ? 'word-preview-placeholder' : 'word-preview-text'">{{ showCategoryHint ? (previewCategoryName || t('wordPrompts.preview.selectCategory')) : t('wordPrompts.preview.role') }}</p>
                </div>
                <p class="word-preview-note">{{ t('wordPrompts.preview.simulationOnly') }}</p>
              </div>
            </UCard>
          </div>
        </section>
        <footer class="word-form-footer">
          <div class="category-actions">
            <UButton type="submit" :label="t('wordPrompts.actions.save')" :loading="saving.isPending.value" :disabled="unsaved.busy || saveConflict" />
            <UButton v-if="saved?.status !== 'published'" type="button" :label="t('wordPrompts.actions.publish')" :disabled="unsaved.busy || saveConflict" @click="submit('published')" />
            <UButton v-if="saved && saved.status !== 'draft'" type="button" variant="outline" :label="t('wordPrompts.actions.draft')" :disabled="unsaved.busy || saveConflict" @click="submit('draft')" />
            <UButton v-if="saved && saved.status !== 'archived'" type="button" variant="outline" :label="t('wordPrompts.actions.archive')" :disabled="unsaved.busy || saveConflict" @click="submit('archived')" />
            <UButton type="button" color="neutral" variant="ghost" :label="t('common.actions.cancel')" :disabled="unsaved.busy" @click="back" />
          </div>
          <UButton v-if="saved" type="button" color="error" variant="outline" :label="t('wordPrompts.actions.delete')" :disabled="unsaved.busy" @click="openDelete" />
        </footer>
      </form>
    </UCard>
    <WordDeleteDialog v-if="deleting && saved" :prompt="saved" :pending="unsaved.busy" :error="deletion.error.value ? t(wordPromptError(deletion.error.value)) : localError ? t(wordPromptError(localError)) : ''" :conflict="conflict" @close="!unsaved.busy && (deleting = false)" @delete="remove" @reload="reload" />
  </section>
</template>
