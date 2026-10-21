<script setup>
import { useI18n } from 'vue-i18n'
import { computed } from 'vue'
import { categorySchema, gameTypeLabels } from '../../utils/categories.js'
const { t } = useI18n({ useScope: 'global' })
const props = defineProps({ form: Object, editing: Boolean, pending: Boolean, error: String })
defineEmits(['update', 'submit', 'cancel'])
const schema = computed(() => categorySchema(props.editing))
const gameTypes = computed(() => Object.entries(gameTypeLabels).map(([value, label]) => ({ value, label: t(label) })))
</script>
<template>
  <UCard class="category-form-card" :ui="{ root: 'tw:ring-0 tw:shadow-none', body: 'category-form-body' }">
  <UForm :schema="schema" :state="form" :disabled="pending" novalidate v-slot="{ errors }" class="category-form" @submit="$emit('submit')">
    <fieldset :disabled="pending" class="category-form-fields">
      <div class="category-form-grid">
        <UFormField :label="t('categories.fields.name')" name="name" required><UInput :model-value="form.name" required class="tw:w-full" @update:model-value="$emit('update', 'name', $event)" /><template v-if="errors.some(issue => issue.name === 'name')" #error="{ error }">{{ t(error) }}</template></UFormField>
        <UFormField :label="t('categories.fields.slug')" name="slug" required :help="t('categories.help.slug')"><UInput :model-value="form.slug" required class="tw:w-full" @update:model-value="$emit('update', 'slug', $event)" /><template v-if="errors.some(issue => issue.name === 'slug')" #error="{ error }">{{ t(error) }}</template></UFormField>
        <UFormField :label="t('common.fields.gameType')" name="game_type" :help="editing ? t('categories.help.immutableGameType') : undefined"><USelect :model-value="form.game_type" :items="gameTypes" :disabled="editing || pending" class="tw:w-full" @update:model-value="$emit('update', 'game_type', $event)" /><template v-if="errors.some(issue => issue.name === 'game_type')" #error="{ error }">{{ t(error) }}</template></UFormField>
        <UFormField :label="t('common.fields.locale')" name="locale"><UInput :model-value="form.locale" disabled class="tw:w-full" /></UFormField>
        <UFormField :label="t('categories.fields.sortOrder')" name="sort_order" required><UInput type="number" :min="0" :max="2147483647" :step="1" required :model-value="form.sort_order" class="tw:w-full" @update:model-value="$emit('update', 'sort_order', $event)" /><template v-if="errors.some(issue => issue.name === 'sort_order')" #error="{ error }">{{ t(error) }}</template></UFormField>
        <UCheckbox :label="t('common.status.active')" :model-value="form.is_active" :disabled="pending" class="tw:self-center" @update:model-value="$emit('update', 'is_active', $event)" />
      </div>
      <UFormField :label="t('categories.fields.description')" name="description"><UTextarea :rows="5" :model-value="form.description" class="tw:w-full" @update:model-value="$emit('update', 'description', $event)" /><template v-if="errors.some(issue => issue.name === 'description')" #error="{ error }">{{ t(error) }}</template></UFormField>
    </fieldset>
    <UAlert v-if="error" color="error" :description="error" role="alert" />
    <div class="category-actions"><UButton type="submit" :loading="pending" :disabled="pending" :label="t('categories.actions.save')" /><UButton type="button" color="neutral" variant="outline" :disabled="pending" :label="t('common.actions.cancel')" @click="$emit('cancel')" /></div>
  </UForm>
  </UCard>
</template>

<style scoped>
.category-form-card {
  width: 100%;
  min-width: 0;
  max-width: 850px;
  border: 1px solid var(--color-teal-border);
  border-radius: var(--radius-md);
  background: var(--color-white);
  color: var(--color-charcoal);
}

.category-form-card :deep(.category-form-body) {
  padding: var(--space-4);
}

.category-form,
.category-form-fields {
  display: grid;
  min-width: 0;
  gap: var(--space-4);
}

.category-form-fields {
  margin: 0;
  padding: 0;
  border: 0;
}

.category-form-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: var(--space-3);
}

.category-form-grid > *,
.category-form-fields > * {
  min-width: 0;
}

.category-form :deep([data-slot="label"]) {
  color: var(--color-charcoal);
  overflow-wrap: anywhere;
}

.category-form :deep([data-slot="help"]) {
  color: var(--color-charcoal-soft);
  overflow-wrap: anywhere;
}

.category-actions {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-1);
}

@media (max-width: 600px) {
  .category-form-grid {
    grid-template-columns: minmax(0, 1fr);
  }
}
</style>
