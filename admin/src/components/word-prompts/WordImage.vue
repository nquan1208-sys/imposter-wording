<script setup>
import { computed } from 'vue'
import { useQuery } from '@tanstack/vue-query'
import { useI18n } from 'vue-i18n'
import { supabase } from '../../lib/supabase.js'
import { wordImageUrl } from '../../api/wordPrompts.js'
const props = defineProps({ path: String, alt: String })
const { t } = useI18n({ useScope: 'global' })
const url = useQuery({ queryKey: computed(() => ['word-images', props.path]), enabled: computed(() => Boolean(props.path)), queryFn: () => wordImageUrl(supabase, props.path), staleTime: 240000, refetchInterval: 240000, retry: false })
</script>
<template>
  <img v-if="url.data.value" :src="url.data.value" :alt="alt || ''" class="word-image" />
  <UButton v-else-if="url.isError.value" variant="link" :label="t('wordPrompts.actions.retryImage')" @click="url.refetch()" />
  <span v-else-if="path" role="status">{{ t('wordPrompts.loadingImage') }}</span>
</template>
