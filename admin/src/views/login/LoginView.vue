<script setup>
import { ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'

const router = useRouter()
const route = useRoute()
const email = ref('')
const password = ref('')
const isSubmitting = ref(false)

async function submitLogin() {
  if (isSubmitting.value) return
  isSubmitting.value = true

  // UI-only flow for this phase: any non-empty form values can continue.
  const redirect =
    typeof route.query.redirect === 'string' &&
    route.query.redirect.startsWith('/') &&
    !route.query.redirect.startsWith('//')
      ? route.query.redirect
      : '/dashboard'

  await router.replace(redirect)
  isSubmitting.value = false
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
        <button class="primary-button login-button" type="submit" :disabled="isSubmitting">
          <span v-if="isSubmitting" class="spinner" />
          <span>{{ isSubmitting ? 'Đang đăng nhập...' : 'Đăng nhập' }}</span>
        </button>
      </form>
    </section>
    <p class="login-footer">Chỉ dành cho tài khoản quản trị được cấp quyền.</p>
  </main>
</template>
