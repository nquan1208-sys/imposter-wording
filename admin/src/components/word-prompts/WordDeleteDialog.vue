<script setup>
import { computed, ref } from 'vue'
import { useI18n } from 'vue-i18n'
const props = defineProps({ prompt: Object, pending: Boolean, error: String, conflict: Boolean })
const emit = defineEmits(['close', 'delete', 'reload'])
const { t } = useI18n({ useScope: 'global' })
const confirmation = ref('')
const canDelete = computed(() => confirmation.value === 'XÓA' && !props.pending && !props.conflict)
function submit() {
  if (canDelete.value) emit('delete', { id: props.prompt.id, updatedAt: props.prompt.updated_at, confirmation: confirmation.value })
}
</script>
<template>
  <UModal :open="true" :title="t('wordPrompts.actions.delete')" :description="t('wordPrompts.deleteDialog.warning')" :dismissible="!pending" :close="!pending" @update:open="open => !open && !pending && emit('close')">
    <template #body><div class="category-delete-body">
      <dl><dt>{{ t('wordPrompts.fields.text') }}</dt><dd>{{ prompt.text }}</dd><dt>{{ t('wordPrompts.fields.categoryId') }}</dt><dd>{{ prompt.game_categories?.name || prompt.category_id }}</dd><dt>{{ t('wordPrompts.fields.status') }}</dt><dd>{{ t(`wordPrompts.statuses.${prompt.status}`) }}</dd></dl>
      <UFormField :label="t('wordPrompts.deleteDialog.confirmation')"><UInput v-model="confirmation" autocomplete="off" :disabled="pending || conflict" class="tw:w-full" @keydown.enter.prevent="submit" /></UFormField>
      <UAlert v-if="error" color="error" :description="error" role="alert" />
    </div></template>
    <template #footer><div class="category-actions">
      <UButton type="button" color="error" :label="t('wordPrompts.actions.delete')" :disabled="!canDelete" :loading="pending" @click="submit" />
      <UButton v-if="conflict" type="button" color="neutral" variant="outline" :label="t('wordPrompts.actions.reload')" :disabled="pending" @click="emit('reload')" />
      <UButton type="button" color="neutral" variant="ghost" :label="t('common.actions.cancel')" :disabled="pending" @click="emit('close')" />
    </div></template>
  </UModal>
</template>
