<script setup>
import { useI18n } from 'vue-i18n'
import { computed } from 'vue'
import { gameTypeLabels } from '../../utils/categories.js'
const { t } = useI18n({ useScope: 'global' })
defineProps({ filters: Object, search: String })
defineEmits(['search', 'filter'])
const gameTypes = computed(() => [{ value: 'all', label: t('categories.filters.all') }, ...Object.entries(gameTypeLabels).map(([value, label]) => ({ value, label: t(label) }))])
const statuses = computed(() => [{ value: 'all', label: t('categories.filters.all') }, { value: 'true', label: t('common.status.active') }, { value: 'false', label: t('common.status.inactive') }])
const sorts = computed(() => [{ value: 'sort_order', label: t('categories.fields.sortOrder') }, { value: 'name', label: t('categories.filters.nameAscending') }, { value: 'updated_at', label: t('categories.filters.latestUpdated') }])
</script>
<template>
  <UCard><div class="category-filters">
    <UFormField :label="t('categories.filters.search')"><UInput type="search" icon="i-lucide-search" :model-value="search" :placeholder="t('categories.filters.searchPlaceholder')" class="tw:w-full" @update:model-value="$emit('search', $event)" /></UFormField>
    <UFormField :label="t('common.fields.gameType')"><USelect :model-value="filters.gameType || 'all'" :items="gameTypes" class="tw:w-full" @update:model-value="$emit('filter', 'type', $event === 'all' ? '' : $event)" /></UFormField>
    <UFormField :label="t('common.fields.status')"><USelect :model-value="filters.active || 'all'" :items="statuses" class="tw:w-full" @update:model-value="$emit('filter', 'active', $event === 'all' ? '' : $event)" /></UFormField>
    <UFormField :label="t('categories.filters.sort')"><USelect :model-value="filters.sort" :items="sorts" class="tw:w-full" @update:model-value="$emit('filter', 'sort', $event)" /></UFormField>
  </div></UCard>
</template>
