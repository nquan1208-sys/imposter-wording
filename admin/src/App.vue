<script setup lang="ts">
import { watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { vi, en } from '@nuxt/ui/locale'
import { useRoute } from 'vue-router'
import { persistUiLocale } from './i18n/index.ts'
const { t, locale } = useI18n({ useScope: 'global' })
const route = useRoute()
const uiLocales = { vi, en }
watch(locale, value => { document.documentElement.lang = value; persistUiLocale(value) }, { immediate: true })
watch(() => t(route.meta.titleKey || 'dashboard.title'), title => { document.title = `${title} · Imposter` }, { immediate: true })
</script>
<template>
  <UApp :locale="uiLocales[locale === 'en' ? 'en' : 'vi']">
    <RouterView />
  </UApp>
</template>
