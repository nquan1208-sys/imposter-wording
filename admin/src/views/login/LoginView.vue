<script setup>
import { computed, reactive } from 'vue'
import { useMutation, useQueryClient } from '@tanstack/vue-query'
import { useRoute, useRouter } from 'vue-router'
import { supabase } from '../../lib/supabase.js'
import { signInAdmin } from '../../utils/adminAuth.js'

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
  error.value ? error.value.message || 'Đăng nhập không thành công.' : '',
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
        <span><strong>Imposter</strong><small>Admin</small></span>
      </div>

      <div class="login-card__heading">
        <p class="eyebrow">Khu vực quản trị</p>
        <h1 id="login-title">Chào mừng trở lại</h1>
        <p>Đăng nhập để quản lý nội dung trò chơi của bạn.</p>
      </div>

      <UForm :state="credentials" :disabled="isSubmitting" class="login-form" @submit="submitLogin">
        <UFormField label="Email" name="email" required><UInput v-model="credentials.email" type="email" autocomplete="email" placeholder="admin@example.com" required class="tw:w-full" /></UFormField>
        <UFormField label="Mật khẩu" name="password" required><UInput v-model="credentials.password" type="password" autocomplete="current-password" placeholder="Nhập mật khẩu" required class="tw:w-full" /></UFormField>
        <UAlert v-if="errorMessage" color="error" :description="errorMessage" role="alert" />
        <UButton type="submit" :loading="isSubmitting" :disabled="isSubmitting" block label="Đăng nhập" />
      </UForm>
    </section>
    <p class="login-footer">Chỉ dành cho tài khoản quản trị được cấp quyền.</p>
  </main>
</template>
