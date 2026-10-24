<script setup lang="ts">
import type { CategoryPreview, CategoryTarget, DeleteCategory } from '../../types/admin.ts'
import { useI18n } from 'vue-i18n'
import { computed, ref, watch } from 'vue'
const { t, n } = useI18n({ useScope: 'global' })
const props = defineProps<{ preview?: CategoryPreview; targets?: CategoryTarget[]; targetsLoading?: boolean; targetsError?: string; loading?: boolean; pending?: boolean; error?: string; conflict?: boolean; locale: string }>()
const emit = defineEmits<{ close: []; refresh: []; delete: [input: DeleteCategory]; 'retry-targets': [] }>()
const mode = ref('transfer')
const targetId = ref('')
const total = computed(() => props.preview?.counts.originals.total ?? 0)
const canDelete = computed(() => props.preview && !props.loading && !props.pending && !props.conflict && (total.value === 0 || mode.value === 'purge' || (!props.targetsLoading && !props.targetsError && props.targets?.some(target => target.id === targetId.value))))
const modes = computed(() => ['transfer', 'purge'].map(value => ({ value, label: t(`categories.deleteDialog.${value}`), description: t(`categories.deleteDialog.${value}Description`) })))
const countStatuses = ['draft', 'published', 'archived'] as const
const deleteLabel = computed(() => t(total.value === 0 ? 'categories.deleteDialog.confirm' : mode.value === 'transfer' ? 'categories.deleteDialog.confirmTransfer' : 'categories.deleteDialog.confirmPurge'))
const targetItems = computed(() => (props.targets || []).map(target => ({ value: target.id, label: `${target.name || t('common.statuses.missing')} (${target.slug})` })))
watch(() => props.targets, rows => { if (!rows?.some(row => row.id === targetId.value)) targetId.value = '' })
function submit() {
  if (!canDelete.value || !props.preview) return
  emit('delete', { id: props.preview.category.id, mode: total.value === 0 ? 'empty' : mode.value, targetId: targetId.value, version: props.preview.version })
}
function refresh() { emit('refresh') }
</script>
<template>
  <UModal :open="true" :title="t('categories.deleteDialog.title')" :description="t('categories.deleteDialog.description')" :dismissible="!pending" :close="!pending" :ui="{ content: 'tw:max-w-xl' }" @update:open="open => !open && !pending && $emit('close')">
    <template #body><div class="category-delete-body">
    <p v-if="loading" role="status">{{ t('categories.deleteDialog.loading') }}</p>
    <template v-else-if="preview">
      <div class="delete-summary">
        <div class="delete-summary-icon"><UIcon name="i-lucide-folder-x" class="tw:size-6" /></div>
        <div class="delete-summary-content">
          <p class="delete-category-name">{{ t('categories.deleteDialog.category', { name: preview.category_translations.find(row => row.locale === locale)?.name || preview.category.slug }) }}</p>

        </div>
      </div>
      <p>{{ t('categories.deleteDialog.originals', { total: n(preview.counts.originals.total), word: n(preview.counts.originals.word), question: n(preview.counts.originals.question) }) }}</p>
      <h3>{{ t('categories.deleteDialog.translations') }}</h3>
      <dl class="delete-counts">
        <div v-for="status in countStatuses" :key="status">
          <dt>{{ t(`common.statuses.${status}`) }}</dt>
          <dd>{{ n(preview.counts.translations[status] || 0) }}</dd>
        </div>
      </dl>
      <p v-if="total === 0">{{ t('categories.deleteDialog.empty') }}</p>
      <fieldset v-else :disabled="pending" class="category-form-fields">
        <legend>{{ t('categories.deleteDialog.linkedContent', { count: n(total) }) }}</legend>
        <URadioGroup v-model="mode" :items="modes" :disabled="pending" variant="card" color="error" />
        <template v-if="mode === 'transfer'">
          <UFormField :label="t('categories.deleteDialog.target')"><USelectMenu v-model="targetId" :items="targetItems" value-key="value" :placeholder="t('categories.deleteDialog.targetPlaceholder')" :disabled="pending || targetsLoading" :loading="targetsLoading" class="tw:w-full" /></UFormField>
          <p v-if="targetsLoading" role="status">{{ t('categories.deleteDialog.targetsLoading') }}</p>
          <UAlert v-else-if="targetsError" color="error" :description="targetsError" role="alert"><template #actions><UButton type="button" color="error" variant="outline" :label="t('common.actions.retry')" @click="$emit('retry-targets')" /></template></UAlert>
          <p v-else-if="!targets?.length">{{ t('categories.deleteDialog.noTargets') }}</p>
        </template>
        <template v-else>
          <UAlert icon="i-lucide-triangle-alert" color="error" variant="soft" :title="t('categories.deleteDialog.irreversible')" :description="t('categories.deleteDialog.warning')" />
        </template>
      </fieldset>
    </template>
    <UAlert v-if="error" color="error" :description="error" role="alert" />
    </div></template>
    <template #footer>
      <div class="delete-footer">
        <UButton color="neutral" variant="ghost" icon="i-lucide-refresh-cw" :disabled="pending || loading" :label="t('categories.deleteDialog.refresh')" @click="refresh" />
        <div class="delete-footer-actions">
          <UButton color="neutral" variant="outline" :disabled="pending" :label="t('common.actions.cancel')" @click="$emit('close')" />
          <UButton color="error" :disabled="!canDelete" :loading="pending" :label="deleteLabel" @click="submit" />
        </div>
      </div>
    </template>
  </UModal>
</template>

<style scoped src="./CategoryDeleteDialog.css"></style>
