<script setup>
import { useI18n } from 'vue-i18n'
import { computed, reactive } from 'vue'
import { useMutation, useQueryClient } from '@tanstack/vue-query'
import { useRoute, useRouter } from 'vue-router'
import { supabase } from '../../lib/supabase.js'
import { signInAdmin, adminAuthError } from '../../utils/adminAuth.js'
const { t } = useI18n({ useScope: 'global' })

const router = useRouter()
const route = useRoute()
const credentials = reactive({ email: '', password: '' })
const queryClient = useQueryClient()
const { mutate, isPending: isSubmitting, error } = useMutation({
  retry: false,
  gcTime: 0,
  mutationFn: async (credentials) => {
    await signInAdmin(supabase, credentials)
    queryClient.removeQueries()

    const redirect =
      typeof route.query.redirect === 'string' &&
      route.query.redirect.startsWith('/') &&
      !route.query.redirect.startsWith('//')
        ? route.query.redirect
        : '/dashboard'
    await router.replace(redirect)
  },
})
const errorMessage = computed(() =>
  error.value ? t(adminAuthError(error.value)) : '',
)

function submitLogin() {
  if (isSubmitting.value) return
  mutate({ email: credentials.email.trim(), password: credentials.password })
}
</script>

<template>
  <main class="login-page">
    <section class="login-card" aria-labelledby="login-title">
      <div class="login-card__brand">
        <span class="brand__mark">I</span>
        <span><strong>Imposter</strong><small>{{ t('navigation.account.admin') }}</small></span>
      </div>

      <div class="login-card__heading">
        <p class="eyebrow">{{ t('auth.login.eyebrow') }}</p>
        <h1 id="login-title">{{ t('auth.login.title') }}</h1>
        <p>{{ t('auth.login.description') }}</p>
      </div>

      <UForm :state="credentials" :disabled="isSubmitting" class="login-form" @submit="submitLogin">
        <UFormField :label="t('auth.login.email')" name="email" required><UInput v-model="credentials.email" type="email" autocomplete="email" placeholder="admin@example.com" required class="tw:w-full" /></UFormField>
        <UFormField :label="t('auth.login.password')" name="password" required><UInput v-model="credentials.password" type="password" autocomplete="current-password" :placeholder="t('auth.login.passwordPlaceholder')" required class="tw:w-full" /></UFormField>
        <UAlert v-if="errorMessage" color="error" :description="errorMessage" role="alert" />
        <UButton type="submit" :loading="isSubmitting" :disabled="isSubmitting" block :label="t('auth.login.submit')" />
      </UForm>
    </section>
    <p class="login-footer">{{ t('auth.login.footer') }}</p>
  </main>
</template>
