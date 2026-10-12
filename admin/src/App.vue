<script setup>
import { vi } from '@nuxt/ui/locale'
</script>
<template>
  <UApp :locale="vi">
    <RouterView />
  </UApp>
</template>
