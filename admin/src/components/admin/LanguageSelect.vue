<script setup lang="ts">
import { useI18n } from 'vue-i18n'

const { t, locale } = useI18n({ useScope: 'global' })
const languages = [{ label: 'Tiếng Việt', value: 'vi' }, { label: 'English', value: 'en' }]
</script>

<template>
  <UFormField :label="t('common.fields.uiLanguage')" class="language-select">
    <USelect v-model="locale" :items="languages" :aria-label="t('common.fields.uiLanguage')" class="tw:w-full" />
  </UFormField>
</template>
