<script setup>
import { computed, ref } from 'vue'
const props = defineProps({ preview: Object, targets: Array, targetsLoading: Boolean, targetsError: String, loading: Boolean, pending: Boolean, error: String })
const emit = defineEmits(['close', 'refresh', 'delete', 'retry-targets'])
const mode = ref('transfer')
const targetId = ref('')
const confirmation = ref('')
const total = computed(() => Object.values(props.preview?.counts || {}).reduce((sum, count) => sum + count, 0))
const canDelete = computed(() => props.preview && !props.loading && !props.pending && (total.value === 0 || (mode.value === 'transfer' ? Boolean(targetId.value) : confirmation.value === props.preview.category.name)))
const modes = [{ value: 'transfer', label: 'Chuyển content rồi xóa' }, { value: 'purge', label: 'Xóa danh mục và toàn bộ content' }]
const targetItems = computed(() => (props.targets || []).map(target => ({ value: target.id, label: `${target.name} (${target.slug})` })))
function submit() {
  if (!canDelete.value) return
  emit('delete', { id: props.preview.category.id, mode: total.value === 0 ? 'empty' : mode.value, targetId: targetId.value, confirmation: confirmation.value, version: props.preview.version })
}
function refresh() { confirmation.value = ''; emit('refresh') }
</script>
<template>
  <UModal :open="true" title="Xóa danh mục" description="Kiểm tra nội dung liên kết trước khi xóa vĩnh viễn." :dismissible="!pending" :close="!pending" :ui="{ content: 'tw:max-w-xl' }" @update:open="open => !open && !pending && $emit('close')">
    <template #body><div class="category-delete-body">
    <p v-if="loading" role="status">Đang tải thống kê mới nhất…</p>
    <template v-else-if="preview">
      <p>Danh mục: <strong>{{ preview.category.name }}</strong></p>
      <p>Nháp: {{ preview.counts.draft }} · Published: {{ preview.counts.published }} · Archived: {{ preview.counts.archived }}</p>
      <p v-if="total === 0">Danh mục đang rỗng. Xóa vĩnh viễn danh mục này?</p>
      <fieldset v-else :disabled="pending" class="category-form-fields">
        <legend>Cách xử lý {{ total }} content đang liên kết</legend>
        <URadioGroup v-model="mode" :items="modes" :disabled="pending" />
        <template v-if="mode === 'transfer'">
          <UFormField label="Danh mục nhận"><USelectMenu v-model="targetId" :items="targetItems" value-key="value" placeholder="Chọn danh mục" :disabled="pending || targetsLoading" :loading="targetsLoading" class="tw:w-full" /></UFormField>
          <p v-if="targetsLoading" role="status">Đang tải danh mục nhận…</p>
          <UAlert v-else-if="targetsError" color="error" :description="targetsError" role="alert"><template #actions><UButton type="button" color="error" variant="outline" label="Thử lại" @click="$emit('retry-targets')" /></template></UAlert>
          <p v-else-if="!targets?.length">Không có danh mục nhận đang hoạt động, cùng loại và ngôn ngữ.</p>
        </template>
        <template v-else>
          <UAlert color="error" title="Không thể hoàn tác" description="Toàn bộ content, kể cả published, sẽ bị xóa vĩnh viễn. File ảnh Storage được giữ lại." />
          <UFormField label="Nhập đúng tên danh mục để xác nhận"><UInput v-model="confirmation" autocomplete="off" :disabled="pending" class="tw:w-full" /></UFormField>
        </template>
      </fieldset>
    </template>
    <UAlert v-if="error" color="error" :description="error" role="alert" />
    </div></template>
    <template #footer><div class="category-actions"><UButton color="error" :disabled="!canDelete" :loading="pending" label="Xác nhận xóa" @click="submit" /><UButton color="neutral" variant="outline" :disabled="pending || loading" label="Tải lại thống kê" @click="refresh" /><UButton color="neutral" variant="ghost" :disabled="pending" label="Hủy" @click="$emit('close')" /></div></template>
  </UModal>
</template>
