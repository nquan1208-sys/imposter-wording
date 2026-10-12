<script setup>
import { useI18n } from 'vue-i18n'
import { computed } from 'vue'
import { gameTypeLabels } from '../../utils/categories.js'
const { t } = useI18n({ useScope: 'global' })
defineProps({ form: Object, editing: Boolean, pending: Boolean, error: String })
defineEmits(['update', 'submit', 'cancel'])
const gameTypes = computed(() => Object.entries(gameTypeLabels).map(([value, label]) => ({ value, label: t(label) })))
</script>
<template>
  <UCard class="category-form-card">
  <UForm :state="form" :disabled="pending" class="category-form" @submit="$emit('submit')">
    <fieldset :disabled="pending" class="category-form-fields">
      <div class="category-form-grid">
        <UFormField :label="t('categories.fields.name')" name="name" required><UInput :model-value="form.name" required class="tw:w-full" @update:model-value="$emit('update', 'name', $event)" /></UFormField>
        <UFormField :label="t('categories.fields.slug')" name="slug" required :help="t('categories.help.slug')"><UInput :model-value="form.slug" required pattern="[a-z0-9]+(-[a-z0-9]+)*" class="tw:w-full" @update:model-value="$emit('update', 'slug', $event)" /></UFormField>
        <UFormField :label="t('common.fields.gameType')" name="game_type" :help="editing ? t('categories.help.immutableGameType') : undefined"><USelect :model-value="form.game_type" :items="gameTypes" :disabled="editing || pending" class="tw:w-full" @update:model-value="$emit('update', 'game_type', $event)" /></UFormField>
        <UFormField :label="t('common.fields.locale')" name="locale"><UInput :model-value="form.locale" disabled class="tw:w-full" /></UFormField>
        <UFormField :label="t('categories.fields.sortOrder')" name="sort_order" required><UInput type="number" :min="0" :max="2147483647" :step="1" required :model-value="form.sort_order" class="tw:w-full" @update:model-value="$emit('update', 'sort_order', $event)" /></UFormField>
        <UCheckbox :label="t('common.status.active')" :model-value="form.is_active" :disabled="pending" class="tw:self-center" @update:model-value="$emit('update', 'is_active', $event)" />
      </div>
      <UFormField :label="t('categories.fields.description')" name="description"><UTextarea :rows="5" :model-value="form.description" class="tw:w-full" @update:model-value="$emit('update', 'description', $event)" /></UFormField>
    </fieldset>
    <UAlert v-if="error" color="error" :description="error" role="alert" />
    <div class="category-actions"><UButton type="submit" :loading="pending" :disabled="pending" :label="t('categories.actions.save')" /><UButton type="button" color="neutral" variant="outline" :disabled="pending" :label="t('common.actions.cancel')" @click="$emit('cancel')" /></div>
  </UForm>
  </UCard>
</template>
