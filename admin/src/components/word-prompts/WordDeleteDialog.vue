<script setup lang="ts">
import ContentStatusBadge from '../admin/ContentStatusBadge.vue'
import type { WordRow, DeletePrompt } from '../../types/admin.ts'
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
const props = defineProps<{ prompt: WordRow; pending?: boolean; error?: string; conflict?: boolean }>()
const emit = defineEmits<{ close: []; delete: [input: DeletePrompt]; reload: [] }>()
const { t } = useI18n({ useScope: 'global' })
const canDelete = computed(() => !props.pending && !props.conflict)
function submit() {
  if (canDelete.value) emit('delete', { id: props.prompt.id, updatedAt: props.prompt.updated_at })
}
</script>
<template>
  <UModal :open="true" :title="t('common.actions.delete')" :description="t('wordPrompts.deleteDialog.description')" :dismissible="!pending" :close="!pending" :ui="{ content: 'tw:max-w-xl' }" @update:open="open => !open && !pending && emit('close')">
    <template #body>
      <div class="word-delete-body">
        <dl class="word-delete-summary">
          <div class="word-delete-content">
            <dt>{{ t('wordPrompts.fields.text') }}</dt>
            <dd>{{ prompt.text || t('common.statuses.missing') }}</dd>
          </div>
          <div>
            <dt>{{ t('wordPrompts.fields.categoryId') }}</dt>
            <dd>{{ prompt.game_categories?.name || prompt.category_id }}</dd>
          </div>
          <div>
            <dt>{{ t('wordPrompts.fields.status') }}</dt>
            <dd><ContentStatusBadge :status="prompt.status" /></dd>
          </div>
        </dl>
        <UAlert icon="i-lucide-triangle-alert" color="error" variant="soft" :title="t('wordPrompts.deleteDialog.irreversible')" :description="t('wordPrompts.deleteDialog.warning')" />
        <UAlert v-if="error" color="error" :description="error" role="alert" />
      </div>
    </template>
    <template #footer>
      <div class="word-delete-actions">
        <UButton v-if="conflict" type="button" color="neutral" variant="outline" :label="t('wordPrompts.actions.reload')" :disabled="pending" @click="emit('reload')" />
        <UButton type="button" color="neutral" variant="outline" :label="t('common.actions.cancel')" :disabled="pending" @click="emit('close')" />
        <UButton type="button" color="error" :label="t('wordPrompts.deleteDialog.confirm')" :disabled="!canDelete" :loading="pending" @click="submit" />
      </div>
    </template>
  </UModal>
</template>

<style scoped src="./WordDeleteDialog.css"></style>
