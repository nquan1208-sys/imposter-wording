<script setup>
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
const props = defineProps({ prompt: Object, pending: Boolean, error: String, conflict: Boolean })
const emit = defineEmits(['close', 'delete', 'reload'])
const { t } = useI18n({ useScope: 'global' })
const canDelete = computed(() => !props.pending && !props.conflict)
function submit() {
  if (canDelete.value) emit('delete', { id: props.prompt.id, updatedAt: props.prompt.updated_at })
}
</script>
<template>
  <UModal :open="true" :title="t('questionPrompts.actions.delete')" :description="t('questionPrompts.deleteDialog.description')" :dismissible="!pending" :close="!pending" :ui="{ content: 'tw:max-w-xl' }" @update:open="open => !open && !pending && emit('close')">
    <template #body>
      <div class="word-delete-body">
        <dl class="word-delete-summary">
          <div class="word-delete-content">
            <dt>{{ t('questionPrompts.fields.civilianQuestion') }}</dt>
            <dd>{{ prompt.civilian_question }}</dd>
          </div>
          <div class="word-delete-content"><dt>{{ t('questionPrompts.fields.imposterQuestion') }}</dt><dd>{{ prompt.imposter_question }}</dd></div>
          <div>
            <dt>{{ t('questionPrompts.fields.categoryId') }}</dt>
            <dd>{{ prompt.game_categories?.name || prompt.category_id }}</dd>
          </div>
          <div>
            <dt>{{ t('questionPrompts.fields.status') }}</dt>
            <dd><UBadge color="neutral" variant="subtle">{{ t(`questionPrompts.statuses.${prompt.status}`) }}</UBadge></dd>
          </div>
        </dl>
        <UAlert icon="i-lucide-triangle-alert" color="error" variant="soft" :title="t('questionPrompts.deleteDialog.irreversible')" :description="t('questionPrompts.deleteDialog.warning')" />
        <UAlert v-if="error" color="error" :description="error" role="alert" />
      </div>
    </template>
    <template #footer>
      <div class="word-delete-actions">
        <UButton v-if="conflict" type="button" color="neutral" variant="outline" :label="t('questionPrompts.actions.reload')" :disabled="pending" @click="emit('reload')" />
        <UButton type="button" color="neutral" variant="outline" :label="t('common.actions.cancel')" :disabled="pending" @click="emit('close')" />
        <UButton type="button" color="error" :label="t('questionPrompts.deleteDialog.confirm')" :disabled="!canDelete" :loading="pending" @click="submit" />
      </div>
    </template>
  </UModal>
</template>

<style scoped src="../word-prompts/WordDeleteDialog.css"></style>
