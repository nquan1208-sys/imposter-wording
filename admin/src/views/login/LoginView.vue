<script setup>
import { computed, ref } from 'vue'
import { useMutation, useQueryClient } from '@tanstack/vue-query'
import { useRoute, useRouter } from 'vue-router'
import { supabase } from '../../lib/supabase.js'
import { signInAdmin } from '../../utils/adminAuth.js'

const router = useRouter()
const route = useRoute()
const email = ref('')
const password = ref('')
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
  mutate({ email: email.value.trim(), password: password.value })
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

      <form class="login-form" @submit.prevent="submitLogin">
        <div class="form-field">
          <label for="email">Email</label>
          <input id="email" v-model="email" type="text" autocomplete="email" placeholder="admin@example.com" required :disabled="isSubmitting" />
        </div>
        <div class="form-field">
          <label for="password">Mật khẩu</label>
          <input id="password" v-model="password" type="password" autocomplete="current-password" placeholder="Nhập mật khẩu" required :disabled="isSubmitting" />
        </div>
        <p v-if="errorMessage" class="form-error" role="alert">{{ errorMessage }}</p>
        <button class="primary-button login-button" type="submit" :disabled="isSubmitting">
          <span v-if="isSubmitting" class="spinner" />
          <span>{{ isSubmitting ? 'Đang đăng nhập...' : 'Đăng nhập' }}</span>
        </button>
      </form>
    </section>
    <p class="login-footer">Chỉ dành cho tài khoản quản trị được cấp quyền.</p>
  </main>
</template>
