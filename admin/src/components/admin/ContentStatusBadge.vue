<script setup lang="ts">
import type { PromptStatus } from '../../types/admin.ts'
import { useI18n } from 'vue-i18n'

defineProps<{ status?: PromptStatus | null; locale?: string }>()
const { t } = useI18n({ useScope: 'global' })
</script>

<template>
  <UBadge :color="status === 'published' ? 'success' : status === 'draft' ? 'warning' : 'neutral'" variant="subtle" size="md" class="content-status" :class="`content-status--${status || 'missing'}`">
    {{ locale ? `${locale}: ` : '' }}{{ t(`common.statuses.${status || 'missing'}`) }}
  </UBadge>
</template>
