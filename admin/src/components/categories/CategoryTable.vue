<script setup lang="ts">
import ContentStatusBadge from '../admin/ContentStatusBadge.vue'
import type { CategoryRow, ContentLanguage } from '../../types/admin.ts'
import { useI18n } from 'vue-i18n'
const { t, n, locale } = useI18n({ useScope: 'global' })
import { computed } from 'vue'
import { gameTypeLabels } from '../../utils/categories.ts'
defineProps<{ rows: CategoryRow[]; pending?: boolean; loading?: boolean; languages: ContentLanguage[] }>()
defineEmits<{ edit: [row: CategoryRow]; toggle: [row: CategoryRow]; delete: [row: CategoryRow] }>()
const dateFormat = computed(() => new Intl.DateTimeFormat(locale.value === 'en' ? 'en-US' : 'vi-VN', { dateStyle: 'short', timeStyle: 'short' }))
const columns = computed(() => [
  { accessorKey: 'name', header: t('categories.fields.name'), meta: { class: { td: 'category-name-cell' } } },
  { accessorKey: 'game_type', header: t('common.fields.gameType') },
  { accessorKey: 'is_family_friendly', header: t('categories.fields.isFamilyFriendly') },
  { id: 'content', header: t('categories.table.content') },
  { id: 'translations', header: t('common.fields.locale') },
  { accessorKey: 'is_active', header: t('common.fields.status') },
  { accessorKey: 'updated_at', header: t('categories.table.updated'), meta: { class: { td: 'category-updated-cell' } } },
  { id: 'actions', header: t('categories.table.actions') },
])
</script>
<template>
  <UTable :data="rows" :columns="columns" :loading="loading" :get-row-id="row => row.id" :caption="t('categories.table.caption')" :empty="t('categories.table.empty')" class="admin-table-scroll" :ui="{ base: 'admin-table category-table', tbody: 'tw:divide-y-0' }">
    <template #name-cell="{ row }">
      <UButton color="neutral" variant="link" :title="row.original.name ?? undefined" :disabled="pending" class="category-name" @click="$emit('edit', row.original)">{{ row.original.name || t('common.statuses.missing') }}</UButton>
      <small class="category-slug" :title="row.original.slug">{{ row.original.slug }}</small>
    </template>
    <template #game_type-cell="{ row }">{{ t(gameTypeLabels[row.original.game_type]) }}</template>
    <template #is_family_friendly-cell="{ row }">{{ t(row.original.is_family_friendly ? 'categories.yes' : 'categories.no') }}</template>
    <template #content-cell="{ row }">{{ n(row.original.word_count + row.original.question_count) }}</template>
    <template #translations-cell="{ row }"><div class="translation-statuses"><ContentStatusBadge v-for="language in languages" :key="language.code" :locale="language.code" :status="row.original.translations.find(item => item.locale === language.code)?.status" /></div></template>
    <template #is_active-cell="{ row }"><UBadge :color="row.original.is_active ? 'success' : 'neutral'" variant="subtle">{{ row.original.is_active ? t('common.status.active') : t('common.status.inactive') }}</UBadge></template>
    <template #updated_at-cell="{ row }">{{ dateFormat.format(new Date(row.original.updated_at)) }}</template>
    <template #actions-cell="{ row }"><div class="category-actions">
      <UButton color="neutral" variant="outline" :disabled="pending" :label="t('common.actions.edit')" @click="$emit('edit', row.original)" />
      <UButton color="neutral" variant="outline" :disabled="pending" :label="row.original.is_active ? t('common.actions.deactivate') : t('common.actions.activate')" @click="$emit('toggle', row.original)" />
      <UButton color="error" variant="outline" :disabled="pending" :label="t('common.actions.delete')" @click="$emit('delete', row.original)" />
    </div></template>
  </UTable>
</template>
