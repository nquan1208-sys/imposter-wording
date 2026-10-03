<script setup>
import { useRoute } from 'vue-router'
import AppIcon from '../../components/admin/AppIcon.vue'

defineProps({
  icon: {
    type: String,
    default: 'dashboard',
  },
})

const route = useRoute()
</script>

<template>
  <section class="placeholder-page">
    <div class="placeholder-card">
      <div class="placeholder-card__icon"><AppIcon :name="icon" /></div>
      <p class="eyebrow">Đang phát triển</p>
      <h2>Màn hình đang được phát triển</h2>
      <p class="placeholder-card__description">
        {{ route.meta.description || 'Tính năng quản lý chi tiết cho màn hình này sẽ được bổ sung trong phiên bản tiếp theo.' }}
      </p>
    </div>
  </section>
</template>
