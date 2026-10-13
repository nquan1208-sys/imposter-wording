<script setup>
import { useI18n } from 'vue-i18n'
import { computed, onBeforeUnmount, reactive, ref, watch } from 'vue'
import { onBeforeRouteLeave, onBeforeRouteUpdate, useRoute, useRouter } from 'vue-router'
import { useMutation, useQuery, useQueryClient } from '@tanstack/vue-query'
import { supabase } from '../../lib/supabase.js'
import { getCategory, saveCategory } from '../../api/categories.js'
import { categoryError, slugFromName } from '../../utils/categories.js'
import { confirmDiscard, useUnsavedChanges } from '../../utils/unsavedChanges.js'
import CategoryForm from '../../components/categories/CategoryForm.vue'
const { t } = useI18n({ useScope: 'global' })
const route = useRoute()
const router = useRouter()
const queryClient = useQueryClient()
const unsaved = useUnsavedChanges()
const id = computed(() => typeof route.params.id === 'string' ? route.params.id : '')
const editing = computed(() => Boolean(id.value))
const form = reactive({ name: '', slug: '', game_type: 'word', description: '', locale: 'vi', sort_order: 0, is_active: true })
const baseline = ref(JSON.stringify(form))
const slugEdited = ref(false)
const loadedId = ref('')
const detail = useQuery({ queryKey: computed(() => ['categories', 'detail', id.value]), enabled: editing, queryFn: () => getCategory(supabase, id.value), retry: false, refetchOnWindowFocus: false })
watch(detail.data, data => {
  if (!data || loadedId.value === id.value) return
  for (const key of Object.keys(form)) form[key] = data[key] ?? ''
  baseline.value = JSON.stringify(form); loadedId.value = id.value; unsaved.dirty = false
}, { immediate: true })
watch(form, () => { unsaved.dirty = JSON.stringify(form) !== baseline.value }, { deep: true, flush: 'sync' })
function update(key, value) {
  form[key] = value
  if (key === 'slug') slugEdited.value = true
  if (key === 'name' && !editing.value && !slugEdited.value) form.slug = slugFromName(value)
  mutation.reset()
}
function back() { return router.push({ name: 'categories', query: route.query }) }
const mutation = useMutation({
  mutationFn: () => saveCategory(supabase, form, id.value || undefined), retry: false,
  onSuccess: async () => {
    baseline.value = JSON.stringify(form); unsaved.dirty = false
    await queryClient.invalidateQueries({ queryKey: ['categories'] })
    unsaved.busy = false
    await back()
  },
  onSettled: () => { unsaved.busy = false },
})
function submit() {
  if (mutation.isPending.value) return
  if (loadedId.value && detail.data.value?.is_active && !form.is_active && !window.confirm(t('categories.confirmations.deactivate'))) return
  unsaved.busy = true; mutation.mutate()
}
function canLeave() {
  if (unsaved.busy) return false
  return !unsaved.dirty || confirmDiscard(t('common.confirmations.discardChanges'))
}
onBeforeRouteLeave(canLeave)
onBeforeRouteUpdate((to, from) => to.path === from.path || canLeave())
function beforeUnload(event) {
  if (!unsaved.dirty && !unsaved.busy) return
  event.preventDefault(); event.returnValue = ''
}
window.addEventListener('beforeunload', beforeUnload)
onBeforeUnmount(() => { window.removeEventListener('beforeunload', beforeUnload); unsaved.dirty = false; unsaved.busy = false })
</script>
<template>
  <section class="categories-page">
    <UCard v-if="editing && detail.isPending.value" role="status" :aria-label="t('categories.status.loading')"><USkeleton class="tw:h-64 tw:w-full" /></UCard>
    <UAlert v-else-if="editing && detail.isError.value" color="error" :description="t(categoryError(detail.error.value))" role="alert"><template #actions><UButton color="error" variant="outline" :label="t('common.actions.retry')" @click="detail.refetch()" /><UButton color="neutral" variant="outline" :label="t('categories.actions.back')" @click="back" /></template></UAlert>
    <CategoryForm v-else :form="form" :editing="editing" :pending="mutation.isPending.value || unsaved.busy" :error="mutation.error.value ? t(categoryError(mutation.error.value)) : ''" @update="update" @submit="submit" @cancel="back" />
  </section>
</template>
