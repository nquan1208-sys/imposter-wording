<script setup lang="ts">
import ContentStatusBadge from '../../components/admin/ContentStatusBadge.vue'
import { computed, watch } from 'vue'
import { useQuery } from '@tanstack/vue-query'
import { useI18n } from 'vue-i18n'
import { RouterLink, useRoute, useRouter } from 'vue-router'
import { getDashboardSummary } from '../../api/dashboard.ts'
import { listContentLanguages } from '../../api/categories.ts'
import { supabase } from '../../lib/supabase.ts'

const { t, n, locale } = useI18n({ useScope: 'global' })
const route = useRoute(), router = useRouter()
const languages = useQuery({ queryKey: ['content-languages'], queryFn: () => listContentLanguages(supabase), retry: false })
const contentLocale = computed(() => typeof route.query.locale === 'string' ? route.query.locale : 'vi')
const validLocale = computed(() => languages.data.value?.some(row => row.code === contentLocale.value) === true)
function selectLocale(value: string) { return router.replace({ query: { ...route.query, locale: value } }) }
watch([languages.data, contentLocale], ([rows, value]) => {
  if (rows && !rows.some(row => row.code === value)) selectLocale('vi')
}, { immediate: true })
const summary = useQuery({
  queryKey: computed(() => ['dashboard', 'summary', contentLocale.value]),
  queryFn: () => getDashboardSummary(supabase, contentLocale.value),
  enabled: validLocale,
  retry: false,
})
const dateFormat = computed(() => new Intl.DateTimeFormat(locale.value === 'en' ? 'en-US' : 'vi-VN', { dateStyle: 'short', timeStyle: 'short' }))
const hasWarnings = computed(() => {
  const warnings = summary.data.value?.warnings
  return !!warnings && Object.values(warnings).some(count => count > 0)
})
function retry() { return summary.refetch() }
</script>

<template>
  <section class="dashboard-page">
    <UFormField :label="t('common.fields.locale')">
      <USelect :model-value="contentLocale" :items="(languages.data.value || []).map(row => ({ value: row.code, label: row.display_name }))" :disabled="!languages.data.value" @update:model-value="selectLocale" />
    </UFormField>
    <div v-if="languages.isError.value" class="dashboard-error" role="alert">
      <p>{{ t('dashboard.loadError') }}</p>
      <UButton color="neutral" variant="outline" type="button" :disabled="languages.isFetching.value" @click="languages.refetch()">{{ t('dashboard.retry') }}</UButton>
    </div>
    <div v-else-if="!validLocale || summary.isPending.value" class="dashboard-loading" role="status" aria-live="polite">
      <span class="dashboard-skeleton" aria-hidden="true" />
      <span>{{ t('dashboard.loading') }}</span>
    </div>
    <div v-else-if="summary.isError.value" class="dashboard-error" role="alert">
      <p>{{ t('dashboard.loadError') }}</p>
      <UButton color="neutral" variant="outline" type="button" :disabled="summary.isFetching.value" @click="retry">{{ t('dashboard.retry') }}</UButton>
    </div>
    <template v-else-if="summary.data.value">
      <section class="dashboard-stats" aria-labelledby="dashboard-stats-heading">
        <h2 id="dashboard-stats-heading" class="dashboard-sr-only">{{ t('dashboard.stats.title') }}</h2>
        <article class="dashboard-stat">
          <p>{{ t('dashboard.stats.publishedWordPrompts') }}</p>
          <strong>{{ n(summary.data.value.stats.published_word_prompts) }}</strong>
        </article>
        <article class="dashboard-stat">
          <p>{{ t('dashboard.stats.publishedQuestionPrompts') }}</p>
          <strong>{{ n(summary.data.value.stats.published_question_prompts) }}</strong>
        </article>
        <article class="dashboard-stat">
          <p>{{ t('dashboard.stats.activeCategories') }}</p>
          <strong>{{ n(summary.data.value.stats.active_categories) }}</strong>
        </article>
        <article class="dashboard-stat">
          <p>{{ t('dashboard.stats.drafts') }}</p>
          <strong>{{ n(summary.data.value.stats.drafts) }}</strong>
        </article>
      </section>

      <div class="dashboard-panels">
        <section class="dashboard-panel" aria-labelledby="dashboard-recent-heading">
          <div class="dashboard-panel__header">
            <div>
              <h2 id="dashboard-recent-heading">{{ t('dashboard.recent.title') }}</h2>
            </div>
            <nav class="dashboard-panel__actions" :aria-label="t('dashboard.recent.title')">
              <RouterLink class="dashboard-view-all" :to="{ name: 'word-prompts', query: { locale: contentLocale } }" :aria-label="t('dashboard.recent.allWords')">{{ t('dashboard.recent.allWordsShort') }}</RouterLink>
              <RouterLink class="dashboard-view-all" :to="{ name: 'question-prompts', query: { locale: contentLocale } }" :aria-label="t('dashboard.recent.allQuestions')">{{ t('dashboard.recent.allQuestionsShort') }}</RouterLink>
            </nav>
          </div>
          <ul v-if="summary.data.value.recent.length" class="dashboard-items">
            <li v-for="item in summary.data.value.recent" :key="`${item.game_type}-${item.id}`">
              <RouterLink
                class="dashboard-item"
                :to="{ name: item.game_type === 'word' ? 'word-prompt-edit' : 'question-prompt-edit', params: { id: item.id }, query: { locale: item.locale } }"
                :aria-label="t('dashboard.editItem', { title: item.title })"
              >
                <span class="dashboard-item__title">{{ item.title }}</span>
                <span class="dashboard-item__meta">
                  {{ item.category_name }}
                  <ContentStatusBadge :status="item.status" />
                </span>
                <time class="dashboard-item__date" :datetime="item.updated_at">{{ dateFormat.format(new Date(item.updated_at)) }}</time>
              </RouterLink>
            </li>
          </ul>
          <p v-else class="dashboard-empty">{{ t('dashboard.recent.empty') }}</p>
        </section>

        <section class="dashboard-panel" aria-labelledby="dashboard-drafts-heading">
          <div class="dashboard-panel__header">
            <div>
              <h2 id="dashboard-drafts-heading">{{ t('dashboard.drafts.title') }}</h2>
            </div>
            <nav class="dashboard-panel__actions" :aria-label="t('dashboard.drafts.title')">
              <RouterLink class="dashboard-view-all" :to="{ name: 'word-prompts', query: { locale: contentLocale, status: 'draft' } }" :aria-label="t('dashboard.drafts.allWords')">{{ t('common.statuses.draft') }} · {{ t('dashboard.warnings.wordPrompts') }}</RouterLink>
              <RouterLink class="dashboard-view-all" :to="{ name: 'question-prompts', query: { locale: contentLocale, status: 'draft' } }" :aria-label="t('dashboard.drafts.allQuestions')">{{ t('common.statuses.draft') }} · {{ t('dashboard.warnings.questionPrompts') }}</RouterLink>
            </nav>
          </div>
          <ul v-if="summary.data.value.drafts.length" class="dashboard-items">
            <li v-for="item in summary.data.value.drafts" :key="`${item.game_type}-${item.id}`">
              <RouterLink
                class="dashboard-item"
                :to="{ name: item.game_type === 'word' ? 'word-prompt-edit' : 'question-prompt-edit', params: { id: item.id }, query: { locale: item.locale } }"
                :aria-label="t('dashboard.editItem', { title: item.title })"
              >
                <span class="dashboard-item__title">{{ item.title }}</span>
                <span class="dashboard-item__meta">
                  {{ item.category_name }}
                  <ContentStatusBadge :status="item.status" />
                </span>
                <time class="dashboard-item__date" :datetime="item.updated_at">{{ dateFormat.format(new Date(item.updated_at)) }}</time>
              </RouterLink>
            </li>
          </ul>
          <p v-else class="dashboard-empty">{{ t('dashboard.drafts.empty') }}</p>
        </section>
      </div>

      <section class="dashboard-panel dashboard-warnings" aria-labelledby="dashboard-warnings-heading">
        <h2 id="dashboard-warnings-heading">{{ t('dashboard.warnings.title') }}</h2>
        <ul v-if="hasWarnings" class="dashboard-warning-list">
          <li>
            <RouterLink :to="{ name: 'categories', query: { locale: contentLocale } }">{{ t('dashboard.warnings.emptyCategories', { count: n(summary.data.value.warnings.empty_categories) }) }}</RouterLink>
          </li>
          <li>
            <RouterLink :to="{ name: 'question-prompts', query: { locale: contentLocale } }">{{ t('dashboard.warnings.duplicateQuestions', { count: n(summary.data.value.warnings.duplicate_questions) }) }}</RouterLink>
          </li>
          <li>
            <span>{{ t('dashboard.warnings.nonFamilyEasyPrompts', { count: n(summary.data.value.warnings.non_family_easy_prompts) }) }}</span>
            <span class="dashboard-warning-links">
              <RouterLink :to="{ name: 'word-prompts', query: { locale: contentLocale, difficulty: 'easy', family: 'false' } }">{{ t('dashboard.warnings.wordPrompts') }}</RouterLink>
              <RouterLink :to="{ name: 'question-prompts', query: { locale: contentLocale, difficulty: 'easy', family: 'false' } }">{{ t('dashboard.warnings.questionPrompts') }}</RouterLink>
            </span>
          </li>
        </ul>
        <p v-else class="dashboard-empty">{{ t('dashboard.warnings.empty') }}</p>
      </section>
    </template>
  </section>
</template>
