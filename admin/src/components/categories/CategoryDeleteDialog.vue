<script setup>
import { useI18n } from 'vue-i18n'
import { computed, ref } from 'vue'
const { t } = useI18n({ useScope: 'global' })
const props = defineProps({ preview: Object, targets: Array, targetsLoading: Boolean, targetsError: String, loading: Boolean, pending: Boolean, error: String })
const emit = defineEmits(['close', 'refresh', 'delete', 'retry-targets'])
const mode = ref('transfer')
const targetId = ref('')
const total = computed(() => Object.values(props.preview?.counts || {}).reduce((sum, count) => sum + count, 0))
const canDelete = computed(() => props.preview && !props.loading && !props.pending && (total.value === 0 || mode.value === 'purge' || Boolean(targetId.value)))
const modes = computed(() => ['transfer', 'purge'].map(value => ({ value, label: t(`categories.deleteDialog.${value}`), description: t(`categories.deleteDialog.${value}Description`) })))
const countStatuses = ['draft', 'published', 'archived']
const deleteLabel = computed(() => t(total.value === 0 ? 'categories.deleteDialog.confirm' : mode.value === 'transfer' ? 'categories.deleteDialog.confirmTransfer' : 'categories.deleteDialog.confirmPurge'))
const targetItems = computed(() => (props.targets || []).map(target => ({ value: target.id, label: `${target.name} (${target.slug})` })))
function submit() {
  if (!canDelete.value) return
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
          <p class="delete-category-name">{{ t('categories.deleteDialog.category', { name: preview.category.name }) }}</p>

        </div>
      </div>
      <dl class="delete-counts">
        <div v-for="status in countStatuses" :key="status">
          <dt>{{ t(`categories.deleteDialog.${status}`) }}</dt>
          <dd>{{ preview.counts[status] || 0 }}</dd>
        </div>
      </dl>
      <p v-if="total === 0">{{ t('categories.deleteDialog.empty') }}</p>
      <fieldset v-else :disabled="pending" class="category-form-fields">
        <legend>{{ t('categories.deleteDialog.linkedContent', { count: total }) }}</legend>
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
