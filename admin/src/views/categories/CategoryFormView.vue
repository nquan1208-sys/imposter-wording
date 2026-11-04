<script setup lang="ts">
import type { Category, CategoryDetail, CategoryForm as CategoryFormState, CategoryTranslation, PromptStatus } from '../../types/admin.ts'
import { useI18n } from 'vue-i18n'
import { computed, onBeforeUnmount, reactive, ref, watch } from 'vue'
import { onBeforeRouteLeave, onBeforeRouteUpdate, useRoute, useRouter } from 'vue-router'
import { useMutation, useQuery, useQueryClient } from '@tanstack/vue-query'
import { supabase } from '../../lib/supabase.ts'
import { getCategory, listContentLanguages, saveCategory } from '../../api/categories.ts'
import { categoryError, slugFromName } from '../../utils/categories.ts'
import { confirmDiscard, useUnsavedChanges } from '../../utils/unsavedChanges.ts'
import CategoryForm from '../../components/categories/CategoryForm.vue'
const { t } = useI18n({ useScope: 'global' })
const route = useRoute(), router = useRouter(), cache = useQueryClient(), unsaved = useUnsavedChanges()
const id = computed(() => typeof route.params.id === 'string' ? route.params.id : '')
const identifier = ref(crypto.randomUUID() as string)
const saved = ref<Category | null>(null)
const editing = computed(() => Boolean(id.value || saved.value))
const shared = reactive({ slug: '', game_type: 'word' as Category['game_type'], sort_order: 0 as string | number, is_active: true, is_family_friendly: false })
type Draft = { name: string; description: string; status: PromptStatus }
const drafts = reactive<Record<string, Draft>>({})
const baselines = reactive<Record<string, string>>({})
const sharedBaseline = ref(JSON.stringify(shared))
const selectedLocale = ref(typeof route.query.locale === 'string' ? route.query.locale : 'vi')
const slugEdited = ref(false), conflict = ref(false), reloading = ref(false), replacing = ref(false), message = ref('')
const persisted = ref<CategoryTranslation[]>([])
const languages = useQuery({ queryKey: ['content-languages'], queryFn: () => listContentLanguages(supabase), retry: false })
function ensureDraft(locale: string) {
  if (drafts[locale]) return
  drafts[locale] = { name: '', description: '', status: 'draft' }
  baselines[locale] = JSON.stringify(drafts[locale])
}
ensureDraft(selectedLocale.value)
const form = computed<CategoryFormState>(() => ({ ...shared, ...drafts[selectedLocale.value]!, locale: selectedLocale.value }))
const dirty = computed(() => JSON.stringify(shared) !== sharedBaseline.value || Object.entries(drafts).some(([locale, draft]) => JSON.stringify(draft) !== baselines[locale]))
watch(dirty, value => { unsaved.dirty = value }, { immediate: true, flush: 'sync' })
watch(() => route.query.locale, value => { selectedLocale.value = typeof value === 'string' ? value : 'vi'; ensureDraft(selectedLocale.value) })
watch([languages.data, selectedLocale], ([rows, locale]) => {
  if (rows && !rows.some(row => row.code === locale)) {
    selectedLocale.value = 'vi'; ensureDraft('vi')
    router.replace({ query: { ...route.query, locale: 'vi' } })
  }
}, { immediate: true })
function selectLocale(locale: string) {
  if (unsaved.busy || reloading.value) return
  ensureDraft(locale); selectedLocale.value = locale
  router.replace({ query: { ...route.query, locale } })
}
function load(data: CategoryDetail) {
  Object.assign(shared, { slug: data.slug, game_type: data.game_type, sort_order: data.sort_order, is_active: data.is_active, is_family_friendly: data.is_family_friendly })
  saved.value = data; identifier.value = data.id; persisted.value = data.translations
  for (const key of Object.keys(drafts)) { delete drafts[key]; delete baselines[key] }
  for (const translation of data.translations) {
    drafts[translation.locale] = { name: translation.name, description: translation.description ?? '', status: translation.status }
    baselines[translation.locale] = JSON.stringify(drafts[translation.locale])
  }
  ensureDraft(selectedLocale.value)
  sharedBaseline.value = JSON.stringify(shared); slugEdited.value = true; conflict.value = false
}
watch(id, next => {
  if (next && next === saved.value?.id) return
  saved.value = null; persisted.value = []; identifier.value = crypto.randomUUID()
  Object.assign(shared, { slug: '', game_type: 'word', sort_order: 0, is_active: true, is_family_friendly: false })
  for (const key of Object.keys(drafts)) { delete drafts[key]; delete baselines[key] }
  ensureDraft(selectedLocale.value); sharedBaseline.value = JSON.stringify(shared)
  slugEdited.value = false; conflict.value = false; message.value = ''; mutation.reset()
})
const detail = useQuery({ queryKey: computed(() => ['categories', 'detail', id.value]), enabled: computed(() => Boolean(id.value)), queryFn: () => getCategory(supabase, id.value), retry: false, refetchOnWindowFocus: false })
watch(detail.data, data => {
  if (data && data.id === id.value && !reloading.value && !conflict.value && (!saved.value || saved.value.id !== data.id || (!dirty.value && !unsaved.busy))) load(data)
}, { immediate: true })
function update(key: keyof CategoryFormState, value: string | number | boolean) {
  if (unsaved.busy || reloading.value) return
  if (key === 'name' || key === 'description' || key === 'status') Object.assign(drafts[selectedLocale.value]!, { [key]: value })
  else if (key !== 'locale') Object.assign(shared, { [key]: value })
  if (key === 'slug') slugEdited.value = true
  if (key === 'name' && !editing.value && !slugEdited.value) shared.slug = slugFromName(String(value))
  if (!conflict.value) mutation.reset()
  message.value = ''
}
async function invalidate() {
  await Promise.all(['categories', 'word-prompts', 'question-prompts', 'dashboard'].map(key => cache.invalidateQueries({ queryKey: [key] })))
}
const mutation = useMutation({
  mutationFn: (input: CategoryFormState) => saveCategory(supabase, input, identifier.value, saved.value?.updated_at), retry: false,
  onSuccess: async (result) => {
    saved.value = result.original
    Object.assign(shared, { slug: result.original.slug, game_type: result.original.game_type, sort_order: result.original.sort_order, is_active: result.original.is_active, is_family_friendly: result.original.is_family_friendly })
    sharedBaseline.value = JSON.stringify(shared)
    const translation = result.translation
    drafts[translation.locale] = { name: translation.name, description: translation.description ?? '', status: translation.status }
    baselines[translation.locale] = JSON.stringify(drafts[translation.locale])
    persisted.value = [...persisted.value.filter(row => row.locale !== translation.locale), translation]
    cache.setQueryData(['categories', 'detail', result.original.id], { ...result.original, translations: persisted.value })
    if (!id.value) {
      replacing.value = true
      try { await router.replace({ name: 'category-edit', params: { id: result.original.id }, query: { ...route.query, locale: selectedLocale.value } }) }
      finally { replacing.value = false }
    }
    await invalidate(); message.value = 'categories.messages.saved'
  },
  onError: cause => { if (categoryError(cause) === 'categories.errors.conflict') conflict.value = true },
  onSettled: () => { unsaved.busy = false },
})
function submit() {
  if (unsaved.busy || reloading.value || conflict.value || mutation.isPending.value || (id.value && saved.value?.id !== id.value)) return
  if (saved.value?.is_active && !shared.is_active && !window.confirm(t('categories.confirmations.deactivate'))) return
  const nextStatus = form.value.status
  if (persisted.value.some(row => row.locale === selectedLocale.value && row.status === 'published') && nextStatus === 'archived' && !window.confirm(t('categories.confirmations.archive'))) return
  unsaved.busy = true; mutation.mutate({ ...form.value, status: nextStatus })
}
async function reload() {
  if (unsaved.busy || reloading.value || (dirty.value && !confirmDiscard(t('common.confirmations.discardChanges')))) return
  reloading.value = true; unsaved.busy = true
  try {
    const result = await detail.refetch()
    if (result.data && !result.error) { load(result.data); mutation.reset() }
  } finally { reloading.value = false; unsaved.busy = false }
}
function back() { return router.push({ name: 'categories', query: route.query }) }
function canLeave() { return !unsaved.busy && (!dirty.value || confirmDiscard(t('common.confirmations.discardChanges'))) }
onBeforeRouteLeave(() => replacing.value || canLeave())
onBeforeRouteUpdate((to, from) => replacing.value || (to.path === from.path && !unsaved.busy) || canLeave())
function beforeUnload(event: BeforeUnloadEvent) {
  if (!dirty.value && !unsaved.busy) return
  event.preventDefault(); event.returnValue = ''
}
window.addEventListener('beforeunload', beforeUnload)
onBeforeUnmount(() => { window.removeEventListener('beforeunload', beforeUnload); unsaved.dirty = false; unsaved.busy = false })
</script>
<template>
  <section class="categories-page">
    <UCard v-if="languages.isPending.value || (id && detail.isPending.value && !saved)" role="status" :aria-label="t('categories.status.loading')"><USkeleton class="tw:h-64 tw:w-full" /></UCard>
    <UAlert v-else-if="languages.isError.value || (id && detail.isError.value)" color="error" :description="t(categoryError(languages.error.value || detail.error.value))" role="alert"><template #actions><UButton color="error" variant="outline" :label="t('common.actions.retry')" @click="languages.isError.value ? languages.refetch() : reload()" /><UButton color="neutral" variant="outline" :label="t('categories.actions.back')" @click="back" /></template></UAlert>
    <template v-else>
      <UAlert v-if="message" color="success" :description="t(message)" role="status" />
      <UAlert v-if="conflict" color="warning" :description="t('categories.errors.conflict')" role="alert"><template #actions><UButton type="button" :disabled="unsaved.busy" :label="t('categories.actions.reload')" @click="reload" /></template></UAlert>
      <CategoryForm :form="form" :languages="languages.data.value || []" :translations="persisted" :editing="editing" :pending="mutation.isPending.value || unsaved.busy || reloading" :conflict="conflict" :error="mutation.error.value ? t(categoryError(mutation.error.value)) : ''" @locale="selectLocale" @update="update" @submit="submit" @cancel="back" />
    </template>
  </section>
</template>
