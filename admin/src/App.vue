<script setup lang="ts">
import { watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { vi, en } from '@nuxt/ui/locale'
const { locale } = useI18n({ useScope: 'global' })
const uiLocales = { vi, en }
watch(locale, value => { document.documentElement.lang = value }, { immediate: true })
</script>
<template>
  <UApp :locale="uiLocales[locale === 'en' ? 'en' : 'vi']">
    <RouterView />
  </UApp>
</template>
