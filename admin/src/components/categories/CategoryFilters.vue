<script setup>
import { gameTypeLabels } from '../../utils/categories.js'
defineProps({ filters: Object, search: String })
defineEmits(['search', 'filter'])
const gameTypes = [{ value: 'all', label: 'Tất cả' }, ...Object.entries(gameTypeLabels).map(([value, label]) => ({ value, label }))]
const statuses = [{ value: 'all', label: 'Tất cả' }, { value: 'true', label: 'Đang hoạt động' }, { value: 'false', label: 'Đã tắt' }]
const sorts = [{ value: 'sort_order', label: 'Thứ tự hiển thị' }, { value: 'name', label: 'Tên A–Z' }, { value: 'updated_at', label: 'Cập nhật mới nhất' }]
</script>
<template>
  <UCard><div class="category-filters">
    <UFormField label="Tìm kiếm"><UInput type="search" icon="i-lucide-search" :model-value="search" placeholder="Tên hoặc slug" class="tw:w-full" @update:model-value="$emit('search', $event)" /></UFormField>
    <UFormField label="Loại trò chơi"><USelect :model-value="filters.gameType || 'all'" :items="gameTypes" class="tw:w-full" @update:model-value="$emit('filter', 'type', $event === 'all' ? '' : $event)" /></UFormField>
    <UFormField label="Trạng thái"><USelect :model-value="filters.active || 'all'" :items="statuses" class="tw:w-full" @update:model-value="$emit('filter', 'active', $event === 'all' ? '' : $event)" /></UFormField>
    <UFormField label="Sắp xếp"><USelect :model-value="filters.sort" :items="sorts" class="tw:w-full" @update:model-value="$emit('filter', 'sort', $event)" /></UFormField>
  </div></UCard>
</template>
