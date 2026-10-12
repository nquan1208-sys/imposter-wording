<script setup>
import { gameTypeLabels } from '../../utils/categories.js'
defineProps({ form: Object, editing: Boolean, pending: Boolean, error: String })
defineEmits(['update', 'submit', 'cancel'])
const gameTypes = Object.entries(gameTypeLabels).map(([value, label]) => ({ value, label }))
</script>
<template>
  <UCard class="category-form-card">
  <UForm :state="form" :disabled="pending" class="category-form" @submit="$emit('submit')">
    <fieldset :disabled="pending" class="category-form-fields">
      <div class="category-form-grid">
        <UFormField label="Tên danh mục" name="name" required><UInput :model-value="form.name" required class="tw:w-full" @update:model-value="$emit('update', 'name', $event)" /></UFormField>
        <UFormField label="Slug" name="slug" required help="Chữ thường, số và dấu gạch ngang."><UInput :model-value="form.slug" required pattern="[a-z0-9]+(-[a-z0-9]+)*" class="tw:w-full" @update:model-value="$emit('update', 'slug', $event)" /></UFormField>
        <UFormField label="Loại trò chơi" name="game_type" :help="editing ? 'Loại trò chơi được cố định sau khi tạo.' : undefined"><USelect :model-value="form.game_type" :items="gameTypes" :disabled="editing || pending" class="tw:w-full" @update:model-value="$emit('update', 'game_type', $event)" /></UFormField>
        <UFormField label="Ngôn ngữ" name="locale"><UInput :model-value="form.locale" disabled class="tw:w-full" /></UFormField>
        <UFormField label="Thứ tự hiển thị" name="sort_order" required><UInput type="number" :min="0" :max="2147483647" :step="1" required :model-value="form.sort_order" class="tw:w-full" @update:model-value="$emit('update', 'sort_order', $event)" /></UFormField>
        <UCheckbox label="Đang hoạt động" :model-value="form.is_active" :disabled="pending" class="tw:self-center" @update:model-value="$emit('update', 'is_active', $event)" />
      </div>
      <UFormField label="Mô tả" name="description"><UTextarea :rows="5" :model-value="form.description" class="tw:w-full" @update:model-value="$emit('update', 'description', $event)" /></UFormField>
    </fieldset>
    <UAlert v-if="error" color="error" :description="error" role="alert" />
    <div class="category-actions"><UButton type="submit" :loading="pending" :disabled="pending" label="Lưu danh mục" /><UButton type="button" color="neutral" variant="outline" :disabled="pending" label="Hủy" @click="$emit('cancel')" /></div>
  </UForm>
  </UCard>
</template>
