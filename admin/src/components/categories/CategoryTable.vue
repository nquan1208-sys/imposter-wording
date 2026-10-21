<script setup lang="ts">
import type { CategoryRow } from '../../types/admin.ts'
import { useI18n } from 'vue-i18n'
const { t, locale } = useI18n({ useScope: 'global' })
import { computed } from 'vue'
import { gameTypeLabels } from '../../utils/categories.ts'
defineProps<{ rows: CategoryRow[]; pending?: boolean; loading?: boolean }>()
defineEmits<{ edit: [row: CategoryRow]; toggle: [row: CategoryRow]; delete: [row: CategoryRow] }>()
const dateFormat = computed(() => new Intl.DateTimeFormat(locale.value === 'en' ? 'en-US' : 'vi-VN', { dateStyle: 'short', timeStyle: 'short' }))
const columns = computed(() => [
  { accessorKey: 'name', header: t('categories.fields.name'), meta: { class: { td: 'category-name-cell' } } },
  { accessorKey: 'game_type', header: t('common.fields.gameType') },
  { id: 'content', header: t('categories.table.content') },
  { accessorKey: 'locale', header: t('common.fields.locale') },
  { accessorKey: 'is_active', header: t('common.fields.status') },
  { accessorKey: 'updated_at', header: t('categories.table.updated'), meta: { class: { td: 'category-updated-cell' } } },
  { id: 'actions', header: t('categories.table.actions') },
])
</script>
<template>
  <UTable :data="rows" :columns="columns" :loading="loading" :get-row-id="row => row.id" :caption="t('categories.table.caption')" :empty="t('categories.table.empty')" class="admin-table-scroll" :ui="{ base: 'admin-table category-table', tbody: 'tw:divide-y-0' }">
    <template #name-cell="{ row }">
      <UButton color="neutral" variant="link" :title="row.original.name" :disabled="pending" class="category-name" @click="$emit('edit', row.original)">{{ row.original.name }}</UButton>
      <small class="category-slug" :title="row.original.slug">{{ row.original.slug }}</small>
    </template>
    <template #game_type-cell="{ row }">{{ t(gameTypeLabels[row.original.game_type]) }}</template>
    <template #content-cell="{ row }">{{ (row.original.word_prompts?.[0]?.count || 0) + (row.original.question_prompts?.[0]?.count || 0) }}</template>
    <template #is_active-cell="{ row }"><UBadge :color="row.original.is_active ? 'success' : 'neutral'" variant="subtle">{{ row.original.is_active ? t('common.status.active') : t('common.status.inactive') }}</UBadge></template>
    <template #updated_at-cell="{ row }">{{ dateFormat.format(new Date(row.original.updated_at)) }}</template>
    <template #actions-cell="{ row }"><div class="category-actions">
      <UButton color="neutral" variant="outline" :disabled="pending" :label="t('common.actions.edit')" @click="$emit('edit', row.original)" />
      <UButton color="neutral" variant="outline" :disabled="pending" :label="row.original.is_active ? t('common.actions.deactivate') : t('common.actions.activate')" @click="$emit('toggle', row.original)" />
      <UButton color="error" variant="outline" :disabled="pending" :label="t('common.actions.delete')" @click="$emit('delete', row.original)" />
    </div></template>
  </UTable>
</template>
