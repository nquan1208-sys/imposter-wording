<script setup>
import { computed, ref } from "vue";
import { useMutation, useQueryClient } from "@tanstack/vue-query";
import { RouterLink, RouterView, useRoute, useRouter } from "vue-router";
import AppIcon from "./AppIcon.vue";
import { supabase } from "../../lib/supabase.js";
import { signOutAdmin } from "../../utils/adminAuth.js";

const route = useRoute();
const router = useRouter();
const isMenuOpen = ref(false);
const email = ref("");
const queryClient = useQueryClient();
const { mutate, isPending: isLoggingOut, error } = useMutation({
  retry: false,
  gcTime: 0,
  mutationFn: async () => {
    await signOutAdmin(supabase);
    queryClient.removeQueries();
    await router.replace({ name: "login" });
  },
});
const logoutError = computed(() =>
  error.value ? "Không thể đăng xuất. Vui lòng thử lại." : "",
);
const navItems = [
  { name: "dashboard", label: "Tổng quan", icon: "dashboard" },
  { name: "categories", label: "Danh mục", icon: "categories" },
  { name: "word-prompts", label: "Nội dung từ ngữ", icon: "word" },
  { name: "question-prompts", label: "Nội dung câu hỏi", icon: "question" },
];
const pageTitle = computed(() => route.meta.title || "Tổng quan");

supabase.auth.getUser().then(({ data }) => {
  email.value = data.user?.email || "";
});

function closeMenu() {
  isMenuOpen.value = false;
}

function logout() {
  if (isLoggingOut.value) return;
  mutate();
}
</script>

<template>
  <div class="admin-shell">
    <div v-if="isMenuOpen" class="sidebar-overlay" @click="closeMenu" />
    <aside class="sidebar" :class="{ 'sidebar--open': isMenuOpen }">
      <div class="sidebar__top">
        <RouterLink
          class="brand"
          :to="{ name: 'dashboard' }"
          @click="closeMenu"
        >
          <span class="brand__mark">I</span>
          <span><strong>Imposter</strong><small>Admin</small></span>
        </RouterLink>
        <button
          class="sidebar__close"
          type="button"
          aria-label="Đóng menu"
          @click="closeMenu"
        >
          ×
        </button>
      </div>
      <nav class="sidebar__nav" aria-label="Điều hướng chính">
        <p class="sidebar__label">Quản trị nội dung</p>
        <RouterLink
          v-for="item in navItems"
          :key="item.name"
          class="nav-item"
          :to="{ name: item.name }"
          :title="item.label"
          @click="closeMenu"
        >
          <AppIcon :name="item.icon" /><span>{{ item.label }}</span>
        </RouterLink>
      </nav>
      <div class="sidebar__account">
        <div class="account-card">
          <span class="account-card__avatar">{{
            email.charAt(0).toUpperCase() || "A"
          }}</span>
          <span class="account-card__details"
            ><strong>Admin</strong
            ><small :title="email">{{
              email || "Tài khoản quản trị"
            }}</small></span
          >
        </div>
        <p v-if="logoutError" class="logout-error" role="alert">{{ logoutError }}</p>
        <button
          class="logout-button"
          type="button"
          :disabled="isLoggingOut"
          @click="logout"
        >
          <span v-if="isLoggingOut" class="spinner spinner--small" /><AppIcon
            v-else
            name="logout"
          />
          <span>{{ isLoggingOut ? "Đang đăng xuất..." : "Đăng xuất" }}</span>
        </button>
      </div>
    </aside>
    <div class="admin-shell__body">
      <header class="topbar">
        <button
          class="mobile-menu-button"
          type="button"
          aria-label="Mở menu"
          @click="isMenuOpen = true"
        >
          ☰
        </button>
        <div>
          <p class="breadcrumb">
            <span>Admin</span><AppIcon name="arrow" />{{ pageTitle }}
          </p>
          <h1>{{ pageTitle }}</h1>
        </div>
      </header>
      <main class="page-content"><RouterView /></main>
    </div>
  </div>
</template>
