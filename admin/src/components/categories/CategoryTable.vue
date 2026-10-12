<script setup>
import { gameTypeLabels } from '../../utils/categories.js'
defineProps({ rows: Array, pending: Boolean, loading: Boolean })
defineEmits(['edit', 'toggle', 'delete'])
const dateFormat = new Intl.DateTimeFormat('vi-VN', { dateStyle: 'short', timeStyle: 'short' })
const columns = [
  { accessorKey: 'name', header: 'Tên danh mục' },
  { accessorKey: 'game_type', header: 'Loại trò chơi' },
  { id: 'content', header: 'Content' },
  { accessorKey: 'locale', header: 'Ngôn ngữ' },
  { accessorKey: 'is_active', header: 'Trạng thái' },
  { accessorKey: 'updated_at', header: 'Cập nhật' },
  { id: 'actions', header: 'Thao tác' },
]
</script>
<template>
  <UTable :data="rows" :columns="columns" :loading="loading" :get-row-id="row => row.id" caption="Danh sách danh mục" empty="Không có danh mục phù hợp." class="tw:rounded-lg tw:border tw:border-default tw:bg-default">
    <template #name-cell="{ row }">
      <UButton color="neutral" variant="link" :title="row.original.name" :disabled="pending" class="category-name" @click="$emit('edit', row.original)">{{ row.original.name }}</UButton>
      <small class="category-slug" :title="row.original.slug">{{ row.original.slug }}</small>
    </template>
    <template #game_type-cell="{ row }">{{ gameTypeLabels[row.original.game_type] }}</template>
    <template #content-cell="{ row }">{{ (row.original.word_prompts?.[0]?.count || 0) + (row.original.question_prompts?.[0]?.count || 0) }}</template>
    <template #is_active-cell="{ row }"><UBadge :color="row.original.is_active ? 'success' : 'neutral'" variant="subtle">{{ row.original.is_active ? 'Đang hoạt động' : 'Đã tắt' }}</UBadge></template>
    <template #updated_at-cell="{ row }">{{ dateFormat.format(new Date(row.original.updated_at)) }}</template>
    <template #actions-cell="{ row }"><div class="category-actions">
      <UButton color="neutral" variant="outline" :disabled="pending" label="Sửa" @click="$emit('edit', row.original)" />
      <UButton color="neutral" variant="outline" :disabled="pending" :label="row.original.is_active ? 'Tắt' : 'Bật'" @click="$emit('toggle', row.original)" />
      <UButton color="error" variant="soft" :disabled="pending" label="Xóa" @click="$emit('delete', row.original)" />
    </div></template>
  </UTable>
</template>
