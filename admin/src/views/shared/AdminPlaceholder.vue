<script setup>
import { useI18n } from 'vue-i18n'
import { useRoute } from 'vue-router'
import AppIcon from '../../components/admin/AppIcon.vue'
const { t } = useI18n({ useScope: 'global' })

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
    <UCard :ui="{ body: 'placeholder-card' }">
      <div class="placeholder-card__icon"><AppIcon :name="icon" /></div>
      <p class="eyebrow">{{ t('placeholder.eyebrow') }}</p>
      <h2>{{ t('placeholder.title') }}</h2>
      <p class="placeholder-card__description">
        {{ t(route.meta.descriptionKey || 'placeholder.description') }}
      </p>
    </UCard>
  </section>
</template>
