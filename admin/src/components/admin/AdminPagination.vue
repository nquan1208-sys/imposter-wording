<script setup lang="ts">
import { useI18n } from 'vue-i18n'

const { t, n } = useI18n({ useScope: 'global' })
</script>

<template>
  <!-- Reka's default pagination labels are English even when Nuxt UI uses Vietnamese. -->
  <UPagination>
    <template #first><UButton color="neutral" variant="outline" icon="i-lucide-chevrons-left" :aria-label="t('common.pagination.first')" /></template>
    <template #prev><UButton color="neutral" variant="outline" icon="i-lucide-chevron-left" :aria-label="t('common.pagination.previous')" /></template>
    <template #item="{ item, page }"><UButton v-if="item.type === 'page'" :color="page === item.value ? 'primary' : 'neutral'" :variant="page === item.value ? 'solid' : 'outline'" :label="n(item.value)" :aria-label="t('common.pagination.page', { page: n(item.value) })" square /></template>
    <template #next><UButton color="neutral" variant="outline" icon="i-lucide-chevron-right" :aria-label="t('common.pagination.next')" /></template>
    <template #last><UButton color="neutral" variant="outline" icon="i-lucide-chevrons-right" :aria-label="t('common.pagination.last')" /></template>
  </UPagination>
</template>
