<script setup lang="ts">
import type { CategoryForm, CategoryTranslation, ContentLanguage } from '../../types/admin.ts'
import { useI18n } from 'vue-i18n'
import { computed } from 'vue'
import { categorySchema, gameTypeLabels } from '../../utils/categories.ts'
const { t } = useI18n({ useScope: 'global' })
const props = defineProps<{ form: CategoryForm; languages: ContentLanguage[]; translations: CategoryTranslation[]; editing?: boolean; pending?: boolean; conflict?: boolean; error?: string }>()
defineEmits<{ update: [key: keyof CategoryForm, value: string | number | boolean]; locale: [value: string]; submit: []; cancel: [] }>()
const schema = categorySchema()
const gameTypes = computed(() => Object.entries(gameTypeLabels).map(([value, label]) => ({ value, label: t(label) })))
const tabs = computed(() => props.languages.map(language => ({ label: language.display_name, value: language.code, disabled: props.pending })))
const statuses = computed(() => (['draft', 'published', 'archived'] as const).map(value => ({ value, label: t(`common.statuses.${value}`) })))
</script>
<template>
  <UCard class="category-form-card" :ui="{ root: 'tw:ring-0 tw:shadow-none', body: 'category-form-body' }">
  <UForm :schema="schema" :state="form" :disabled="pending" novalidate v-slot="{ errors }" class="category-form" @submit="$emit('submit')">
    <fieldset :disabled="pending" class="category-form-fields">
      <legend>{{ t('categories.form.shared') }}</legend>
      <p>{{ t('categories.help.shared') }}</p>
      <div class="category-form-grid">
        <UFormField :label="t('categories.fields.slug')" name="slug" required :help="t('categories.help.slug')"><UInput :model-value="form.slug" required class="tw:w-full" @update:model-value="$emit('update', 'slug', $event)" /><template v-if="errors.some(issue => issue.name === 'slug')" #error="{ error }">{{ typeof error === 'string' ? t(error) : '' }}</template></UFormField>
        <UFormField :label="t('common.fields.gameType')" name="game_type" :help="editing ? t('categories.help.immutableGameType') : undefined"><USelect :model-value="form.game_type" :items="gameTypes" :disabled="editing || pending" class="tw:w-full" @update:model-value="$emit('update', 'game_type', $event)" /></UFormField>
        <UFormField :label="t('categories.fields.sortOrder')" name="sort_order" required><UInput type="number" :min="0" :max="2147483647" :step="1" required :model-value="String(form.sort_order)" class="tw:w-full" @update:model-value="$emit('update', 'sort_order', $event)" /><template v-if="errors.some(issue => issue.name === 'sort_order')" #error="{ error }">{{ typeof error === 'string' ? t(error) : '' }}</template></UFormField>
        <UCheckbox v-if="form.game_type === 'word'" :label="t('categories.fields.isFamilyFriendly')" :model-value="form.is_family_friendly" :disabled="pending" @update:model-value="$emit('update', 'is_family_friendly', $event === true)" />
        <UCheckbox :label="t('common.status.active')" :model-value="form.is_active" :disabled="pending" class="tw:self-center" @update:model-value="$emit('update', 'is_active', $event)" />
      </div>
    </fieldset>
    <UTabs :model-value="form.locale" :items="tabs" :aria-label="t('common.fields.locale')" :ui="{ list: 'tw:flex-wrap', content: 'tw:space-y-4' }" @update:model-value="$emit('locale', String($event))">
      <template #content>
        <p v-if="!translations.some(row => row.locale === form.locale)">{{ t('common.statuses.missing') }}</p>
        <fieldset :disabled="pending" class="category-form-fields">
          <UFormField :label="t('categories.fields.name')" name="name" required><UInput :model-value="form.name" required class="tw:w-full" @update:model-value="$emit('update', 'name', $event)" /><template v-if="errors.some(issue => issue.name === 'name')" #error="{ error }">{{ typeof error === 'string' ? t(error) : '' }}</template></UFormField>
          <UFormField :label="t('categories.fields.description')" name="description"><UTextarea :rows="5" :model-value="form.description" class="tw:w-full" @update:model-value="$emit('update', 'description', $event)" /></UFormField>
          <UFormField :label="t('common.fields.status')" name="status"><USelect :model-value="form.status" :items="statuses" class="tw:w-full" @update:model-value="$emit('update', 'status', $event)" /></UFormField>
        </fieldset>
      </template>
    </UTabs>
    <UAlert v-if="error" color="error" :description="error" role="alert" />
    <div class="category-actions">
      <UButton type="submit" :loading="pending" :disabled="pending || conflict" :label="t('common.actions.save')" />
      <UButton type="button" color="neutral" variant="outline" :disabled="pending" :label="t('common.actions.cancel')" @click="$emit('cancel')" />
    </div>
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
