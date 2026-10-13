<script setup>
import { computed, onBeforeUnmount, reactive, ref, watch } from 'vue'
import { onBeforeRouteLeave, onBeforeRouteUpdate, useRoute, useRouter } from 'vue-router'
import { useQuery, useMutation, useQueryClient } from '@tanstack/vue-query'
import { useI18n } from 'vue-i18n'
import { supabase } from '../../lib/supabase.js'
import { getWordPrompt, wordCategories, saveWordPrompt, deleteWordPrompt } from '../../api/wordPrompts.js'
import { difficulties, validateImage, wordPromptPayload, wordPromptError } from '../../utils/wordPrompts.js'
import { useUnsavedChanges, confirmDiscard } from '../../utils/unsavedChanges.js'
import WordImage from '../../components/word-prompts/WordImage.vue'
import WordDeleteDialog from '../../components/word-prompts/WordDeleteDialog.vue'
function fieldLabel(field) { return 'wordPrompts.fields.' + field.replace(/_([a-z])/g, (_, letter) => letter.toUpperCase()) }
const { t } = useI18n({ useScope: 'global' })
const route = useRoute(), router = useRouter(), cache = useQueryClient(), unsaved = useUnsavedChanges()
const editing = Boolean(route.params.id), id = route.params.id || crypto.randomUUID()
const form = reactive({ civilian_text: '', category_id: '', difficulty: 'medium', is_family_friendly: false, locale: 'vi', image_path: '' })
const saved = ref(null), baseline = ref(JSON.stringify(form)), file = ref(null), localUrl = ref(''), imageInput = ref(null)
const localError = ref(null), uploadState = ref(''), deleting = ref(false), reloading = ref(false)
const detail = useQuery({ queryKey: ['word-prompts', 'detail', id], enabled: editing, queryFn: () => getWordPrompt(supabase, id), retry: false, refetchOnWindowFocus: false })
function clearFile() { if (localUrl.value) URL.revokeObjectURL(localUrl.value); localUrl.value = ''; file.value = null; if (imageInput.value) imageInput.value.value = '' }
function load(row) {
  clearFile()
  for (const key of Object.keys(form)) form[key] = row[key] ?? ''
  saved.value = row; baseline.value = JSON.stringify(form); unsaved.dirty = false
}
watch(detail.data, row => { if (row && !saved.value) load(row) }, { immediate: true })
watch([form, file], () => { unsaved.dirty = JSON.stringify(form) !== baseline.value || Boolean(file.value) }, { deep: true, flush: 'sync' })
const categoryOptions = useQuery({ queryKey: computed(() => ['categories', 'word-options', form.locale]), queryFn: () => wordCategories(supabase, form.locale), retry: false })
const categoryItems = computed(() => {
  const rows = [...(categoryOptions.data.value || [])]
  const current = saved.value?.game_categories
  if (current && current.locale === form.locale && !rows.some(row => row.id === current.id)) rows.push(current)
  return rows.map(row => ({ value: row.id, label: row.name + (row.is_active ? '' : ` (${t('wordPrompts.inactive')})`) }))
})
const previewCategoryName = computed(() => {
  const current = saved.value?.game_categories
  return (categoryOptions.data.value || []).find(row => row.id === form.category_id)?.name
    || (current?.id === form.category_id && current.locale === form.locale ? current.name : '')
    || ''
})
const difficultyItems = computed(() => difficulties.map(value => ({ value, label: t(`wordPrompts.difficulties.${value}`) })))
function update(key, value) { if (unsaved.busy) return; form[key] = value; if (key === 'locale') form.category_id = ''; localError.value = null; saving.reset() }
async function chooseImage(event) {
  const next = event.target.files?.[0]
  if (!next || unsaved.busy) return
  unsaved.busy = true
  clearFile()
  let preview
  try {
    validateImage(next)
    preview = URL.createObjectURL(next)
    await new Promise((resolve, reject) => { const image = new Image(); image.onload = resolve; image.onerror = () => reject(new Error('wordPrompts.errors.invalidImage')); image.src = preview })
    if (disposed) { URL.revokeObjectURL(preview); return }
    file.value = next; localUrl.value = preview; localError.value = null; uploadState.value = ''
  } catch (error) { if (preview) URL.revokeObjectURL(preview); localError.value = error }
  finally { unsaved.busy = false }
}
function removeImage() { if (!unsaved.busy) { clearFile(); form.image_path = ''; uploadState.value = '' } }
async function invalidate() { await Promise.all([cache.invalidateQueries({ queryKey: ['word-prompts'] }), cache.invalidateQueries({ queryKey: ['categories'] })]) }
function back() { return router.push({ name: 'word-prompts', query: route.query }) }
const saving = useMutation({ retry: false,
  mutationFn: status => saveWordPrompt(supabase, form, { id, updatedAt: saved.value?.updated_at, status, file: file.value, onUpload: state => { uploadState.value = state } }),
  onSuccess: async row => { load({ ...row, game_categories: saved.value?.game_categories }); await invalidate(); unsaved.busy = false; await back() },
  onSettled: () => { unsaved.busy = false },
})
const deletion = useMutation({ mutationFn: input => deleteWordPrompt(supabase, input), retry: false,
  onSuccess: async () => { deleting.value = false; clearFile(); baseline.value = JSON.stringify(form); unsaved.dirty = false; await invalidate(); unsaved.busy = false; await back() },
  onSettled: () => { unsaved.busy = false },
})
function submit(status) {
  if (unsaved.busy || reloading.value || saving.isPending.value || deletion.isPending.value) return
  localError.value = null
  try { wordPromptPayload(form, status) } catch (error) { localError.value = error; return }
  if (saved.value?.status === 'published' && !window.confirm(t('wordPrompts.confirmations.save'))) return
  unsaved.busy = true; saving.mutate(status)
}
function openDelete() { if (!saved.value || unsaved.busy || reloading.value || saving.isPending.value || deletion.isPending.value) return; if (!conflict.value) deletion.reset(); deleting.value = true }
function remove(input) {
  if (unsaved.busy || deletion.isPending.value || conflict.value) return
  unsaved.busy = true; deletion.mutate(input)
}
const conflict = computed(() => wordPromptError(deletion.error.value) === 'wordPrompts.errors.conflict')
const saveConflict = computed(() => wordPromptError(saving.error.value) === 'wordPrompts.errors.conflict')
async function reload() {
  if (unsaved.busy || reloading.value || (unsaved.dirty && !confirmDiscard(t('common.confirmations.discardChanges')))) return
  reloading.value = true; unsaved.busy = true
  try {
    const row = await getWordPrompt(supabase, id)
    load(row); cache.setQueryData(['word-prompts', 'detail', id], row)
    deleting.value = false; deletion.reset(); saving.reset(); localError.value = null
  } catch (error) { localError.value = error }
  finally { reloading.value = false; unsaved.busy = false }
}
function canLeave() { return !unsaved.busy && (!unsaved.dirty || confirmDiscard(t('common.confirmations.discardChanges'))) }
onBeforeRouteLeave(canLeave)
onBeforeRouteUpdate((to, from) => to.path === from.path ? !unsaved.busy : canLeave())
function beforeUnload(event) { if (unsaved.dirty || unsaved.busy) { event.preventDefault(); event.returnValue = '' } }
let disposed = false
window.addEventListener('beforeunload', beforeUnload)
onBeforeUnmount(() => { disposed = true; clearFile(); window.removeEventListener('beforeunload', beforeUnload); unsaved.dirty = false; unsaved.busy = false })
</script>
<template>
  <section class="categories-page">
    <p v-if="editing && detail.isPending.value" role="status">{{ t('wordPrompts.loading') }}</p>
    <UAlert v-else-if="editing && !saved && detail.isError.value" color="error" :description="t(wordPromptError(detail.error.value))" role="alert"><template #actions><UButton :label="t('common.actions.retry')" @click="detail.refetch()" /><UButton :label="t('common.actions.cancel')" @click="back" /></template></UAlert>
    <UCard v-else class="category-form-card">
      <form class="category-form" novalidate @submit.prevent="submit(saved?.status || 'draft')">
        <fieldset :disabled="unsaved.busy" class="category-form-fields">
          <div class="category-form-grid">
            <UFormField v-for="key in ['civilian_text', 'locale']" :key="key" :label="t(fieldLabel(key))" :required="['civilian_text', 'locale'].includes(key)"><UInput :model-value="form[key]" class="tw:w-full" @update:model-value="update(key, $event)" /></UFormField>
            <UFormField :label="t('wordPrompts.fields.categoryId')" required><USelectMenu :model-value="form.category_id" :items="categoryItems" value-key="value" :loading="categoryOptions.isFetching.value" class="tw:w-full" @update:model-value="update('category_id', $event)" /></UFormField>
            <UFormField :label="t('wordPrompts.fields.difficulty')"><USelect :model-value="form.difficulty" :items="difficultyItems" class="tw:w-full" @update:model-value="update('difficulty', $event)" /></UFormField>
            <UCheckbox :model-value="form.is_family_friendly" :label="t('wordPrompts.fields.isFamilyFriendly')" @update:model-value="update('is_family_friendly', $event)" />
            <UFormField :label="t('wordPrompts.fields.imagePath')" :help="t('wordPrompts.imageHelp')"><input ref="imageInput" type="file" :aria-label="t('wordPrompts.fields.imagePath')" accept="image/jpeg,image/png,image/webp" @change="chooseImage" /><UButton type="button" color="neutral" variant="outline" :label="t('wordPrompts.actions.removeImage')" :disabled="!file && !form.image_path" @click="removeImage" /></UFormField>
          </div>
        </fieldset>
        <p v-if="uploadState" role="status">{{ t(`wordPrompts.upload.${uploadState}`) }}</p>
        <UAlert v-if="localError || saving.error.value || categoryOptions.error.value" color="error" :description="t(wordPromptError(localError || saving.error.value || categoryOptions.error.value))" role="alert" />
        <UButton v-if="saveConflict" type="button" :label="t('wordPrompts.actions.reload')" :disabled="unsaved.busy" @click="reload" />
        <div class="word-preview">
          <UCard><h2>{{ t('wordPrompts.preview.civilian') }}</h2><p>{{ form.civilian_text }}</p><img v-if="localUrl" :src="localUrl" :alt="form.civilian_text" class="word-image" /><WordImage v-else :path="form.image_path" :alt="form.civilian_text" /></UCard>
          <UCard><h2>{{ t('wordPrompts.preview.imposter') }}</h2><p>{{ t('wordPrompts.preview.role') }}</p><h3>{{ t('wordPrompts.preview.categoryVisible') }}</h3><p>{{ previewCategoryName || t('wordPrompts.preview.selectCategory') }}</p><h3>{{ t('wordPrompts.preview.categoryHidden') }}</h3><p>{{ t('wordPrompts.preview.role') }}</p></UCard>
        </div>
        <div class="category-actions">
          <UButton type="submit" :label="t('wordPrompts.actions.save')" :loading="saving.isPending.value" :disabled="unsaved.busy" />
          <UButton v-if="saved?.status !== 'published'" type="button" :label="t('wordPrompts.actions.publish')" :disabled="unsaved.busy" @click="submit('published')" />
          <UButton v-if="saved && saved.status !== 'draft'" type="button" variant="outline" :label="t('wordPrompts.actions.draft')" :disabled="unsaved.busy" @click="submit('draft')" />
          <UButton v-if="saved && saved.status !== 'archived'" type="button" variant="outline" :label="t('wordPrompts.actions.archive')" :disabled="unsaved.busy" @click="submit('archived')" />
          <UButton v-if="saved" type="button" color="error" variant="outline" :label="t('wordPrompts.actions.delete')" :disabled="unsaved.busy" @click="openDelete" />
          <UButton type="button" color="neutral" variant="ghost" :label="t('common.actions.cancel')" :disabled="unsaved.busy" @click="back" />
        </div>
      </form>
    </UCard>
    <WordDeleteDialog v-if="deleting && saved" :prompt="saved" :pending="unsaved.busy" :error="deletion.error.value ? t(wordPromptError(deletion.error.value)) : localError ? t(wordPromptError(localError)) : ''" :conflict="conflict" @close="!unsaved.busy && (deleting = false)" @delete="remove" @reload="reload" />
  </section>
</template>
