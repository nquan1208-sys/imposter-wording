<script setup lang="ts">
import { useI18n } from 'vue-i18n'
import { computed, ref } from "vue"
import { useMutation, useQueryClient } from "@tanstack/vue-query"
import { RouterLink, RouterView, useRoute, useRouter } from "vue-router"
import AppIcon from "./AppIcon.vue";
import LanguageSelect from './LanguageSelect.vue'
import { supabase } from "../../lib/supabase.ts"
import { signOutAdmin } from "../../utils/adminAuth.ts"

import { provideUnsavedChanges, confirmDiscard } from "../../utils/unsavedChanges.ts"
const { t } = useI18n({ useScope: 'global' })

const unsaved = provideUnsavedChanges();
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
    unsaved.dirty = false;
    unsaved.busy = false;
    queryClient.removeQueries();
    await router.replace({ name: "login" });
  },
  onSettled: () => { unsaved.busy = false; },
});
const logoutError = computed(() =>
  error.value ? t('auth.errors.logoutFailed') : "",
);
const navItems = computed(() => [
  { name: "dashboard", label: t('dashboard.title'), icon: "dashboard" },
  { name: "categories", label: t('categories.title'), icon: "categories" },
  { name: "word-prompts", label: t('wordPrompts.title'), icon: "word" },
  { name: "question-prompts", label: t('questionPrompts.title'), icon: "question" },
]);
const pageTitle = computed(() => t(route.meta.titleKey || 'dashboard.title'));

supabase.auth.getUser().then(({ data }) => {
  email.value = data.user?.email || "";
});

function closeMenu() {
  isMenuOpen.value = false;
}

function logout() {
  if (isLoggingOut.value || unsaved.busy) return;
  if (unsaved.dirty && !confirmDiscard(t('common.confirmations.discardChanges'))) return;
  unsaved.busy = true;
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
          <span><strong>Imposter</strong><small>{{ t('navigation.account.admin') }}</small></span>
        </RouterLink>
        <UButton
          class="sidebar__close"
          color="neutral"
          variant="ghost"
          icon="i-lucide-x"
          type="button"
          :aria-label="t('navigation.accessibility.closeMenu')"
          @click="closeMenu"
        />
      </div>
      <nav class="sidebar__nav" :aria-label="t('navigation.accessibility.main')">
        <p class="sidebar__label">{{ t('navigation.contentManagement') }}</p>
        <RouterLink
          v-for="item in navItems"
          :key="item.name"
          class="nav-item"
          :to="{ name: item.name }"
          :title="item.label"
          :class="{ 'router-link-active': item.name === 'categories' && route.path.startsWith('/categories') }"
          @click="closeMenu"
        >
          <AppIcon :name="item.icon" /><span>{{ item.label }}</span>
        </RouterLink>
      </nav>
      <div class="sidebar__account">
        <LanguageSelect />
        <div class="account-card">
          <UAvatar :alt="email || t('navigation.account.admin')" size="md" />
          <span class="account-card__details"
            ><strong>{{ t('navigation.account.admin') }}</strong
            ><small :title="email">{{
              email || t('navigation.account.fallback')
            }}</small></span
          >
        </div>
        <UAlert v-if="logoutError" color="error" :description="logoutError" role="alert" />
        <UButton
          class="logout-button"
          color="neutral"
          variant="ghost"
          icon="i-lucide-log-out"
          :loading="isLoggingOut"
          :label="isLoggingOut ? t('auth.logout.pending') : t('auth.logout.submit')"
          type="button"
          :disabled="isLoggingOut || unsaved.busy"
          @click="logout"
        />
      </div>
    </aside>
    <div class="admin-shell__body">
      <header class="topbar">
        <UButton
          class="mobile-menu-button"
          color="neutral"
          variant="ghost"
          icon="i-lucide-menu"
          type="button"
          :aria-label="t('navigation.accessibility.openMenu')"
          @click="isMenuOpen = true"
        />
        <div>
          <UBreadcrumb :items="[{ label: t('navigation.account.admin'), to: { name: 'dashboard' } }, { label: pageTitle }]" class="breadcrumb" />
          <h1>{{ pageTitle }}</h1>
        </div>
      </header>
      <main class="page-content"><RouterView v-slot="{ Component }"><component :is="Component" :key="route.name === 'category-new' || route.name === 'category-edit' ? 'category-editor' : route.name === 'word-prompt-new' || route.name === 'word-prompt-edit' ? 'word-editor' : route.name === 'question-prompt-new' || route.name === 'question-prompt-edit' ? 'question-editor' : route.path" /></RouterView></main>
    </div>
  </div>
</template>
