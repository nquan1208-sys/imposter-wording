<script setup lang="ts">
import { computed } from 'vue'
import { useQuery } from '@tanstack/vue-query'
import { useI18n } from 'vue-i18n'
import { RouterLink } from 'vue-router'
import { getDashboardSummary } from '../../api/dashboard.ts'
import { supabase } from '../../lib/supabase.ts'

const { t, locale } = useI18n({ useScope: 'global' })
const summary = useQuery({
  queryKey: ['dashboard', 'summary'],
  queryFn: () => getDashboardSummary(supabase),
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
    <div v-if="summary.isPending.value" class="dashboard-loading" role="status" aria-live="polite">
      <span class="dashboard-skeleton" aria-hidden="true" />
      <span>{{ t('dashboard.loading') }}</span>
    </div>
    <div v-else-if="summary.isError.value" class="dashboard-error" role="alert">
      <p>{{ t('dashboard.loadError') }}</p>
      <button class="dashboard-retry" type="button" :disabled="summary.isFetching.value" @click="retry">{{ t('dashboard.retry') }}</button>
    </div>
    <template v-else-if="summary.data.value">
      <section class="dashboard-stats" aria-labelledby="dashboard-stats-heading">
        <h2 id="dashboard-stats-heading" class="dashboard-sr-only">{{ t('dashboard.stats.title') }}</h2>
        <article class="dashboard-stat">
          <p>{{ t('dashboard.stats.publishedWordPrompts') }}</p>
          <strong>{{ summary.data.value.stats.published_word_prompts }}</strong>
        </article>
        <article class="dashboard-stat">
          <p>{{ t('dashboard.stats.publishedQuestionPrompts') }}</p>
          <strong>{{ summary.data.value.stats.published_question_prompts }}</strong>
        </article>
        <article class="dashboard-stat">
          <p>{{ t('dashboard.stats.activeCategories') }}</p>
          <strong>{{ summary.data.value.stats.active_categories }}</strong>
        </article>
        <article class="dashboard-stat">
          <p>{{ t('dashboard.stats.drafts') }}</p>
          <strong>{{ summary.data.value.stats.drafts }}</strong>
        </article>
      </section>

      <div class="dashboard-panels">
        <section class="dashboard-panel" aria-labelledby="dashboard-recent-heading">
          <div class="dashboard-panel__header">
            <div>
              <h2 id="dashboard-recent-heading">{{ t('dashboard.recent.title') }}</h2>
            </div>
            <nav class="dashboard-panel__actions" :aria-label="t('dashboard.recent.title')">
              <RouterLink class="dashboard-view-all" :to="{ name: 'word-prompts' }" :aria-label="t('dashboard.recent.allWords')">{{ t('dashboard.recent.allWordsShort') }}</RouterLink>
              <RouterLink class="dashboard-view-all" :to="{ name: 'question-prompts' }" :aria-label="t('dashboard.recent.allQuestions')">{{ t('dashboard.recent.allQuestionsShort') }}</RouterLink>
            </nav>
          </div>
          <ul v-if="summary.data.value.recent.length" class="dashboard-items">
            <li v-for="item in summary.data.value.recent" :key="`${item.game_type}-${item.id}`">
              <RouterLink
                class="dashboard-item"
                :to="{ name: item.game_type === 'word' ? 'word-prompt-edit' : 'question-prompt-edit', params: { id: item.id } }"
                :aria-label="t('dashboard.editItem', { title: item.title })"
              >
                <span class="dashboard-item__title">{{ item.title }}</span>
                <span class="dashboard-item__meta">
                  {{ item.category_name }}
                  <span class="dashboard-item__status" :class="`dashboard-item__status--${item.status}`">{{ t(`dashboard.statuses.${item.status}`) }}</span>
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
              <RouterLink class="dashboard-view-all" :to="{ name: 'word-prompts', query: { status: 'draft' } }" :aria-label="t('dashboard.drafts.allWords')">{{ t('dashboard.statuses.draft') }} · {{ t('dashboard.warnings.wordPrompts') }}</RouterLink>
              <RouterLink class="dashboard-view-all" :to="{ name: 'question-prompts', query: { status: 'draft' } }" :aria-label="t('dashboard.drafts.allQuestions')">{{ t('dashboard.statuses.draft') }} · {{ t('dashboard.warnings.questionPrompts') }}</RouterLink>
            </nav>
          </div>
          <ul v-if="summary.data.value.drafts.length" class="dashboard-items">
            <li v-for="item in summary.data.value.drafts" :key="`${item.game_type}-${item.id}`">
              <RouterLink
                class="dashboard-item"
                :to="{ name: item.game_type === 'word' ? 'word-prompt-edit' : 'question-prompt-edit', params: { id: item.id } }"
                :aria-label="t('dashboard.editItem', { title: item.title })"
              >
                <span class="dashboard-item__title">{{ item.title }}</span>
                <span class="dashboard-item__meta">
                  {{ item.category_name }}
                  <span class="dashboard-item__status dashboard-item__status--draft">{{ t(`dashboard.statuses.${item.status}`) }}</span>
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
            <RouterLink :to="{ name: 'categories' }">{{ t('dashboard.warnings.emptyCategories', { count: summary.data.value.warnings.empty_categories }) }}</RouterLink>
          </li>
          <li>
            <RouterLink :to="{ name: 'question-prompts' }">{{ t('dashboard.warnings.duplicateQuestions', { count: summary.data.value.warnings.duplicate_questions }) }}</RouterLink>
          </li>
          <li>
            <span>{{ t('dashboard.warnings.nonFamilyEasyPrompts', { count: summary.data.value.warnings.non_family_easy_prompts }) }}</span>
            <span class="dashboard-warning-links">
              <RouterLink :to="{ name: 'word-prompts', query: { difficulty: 'easy', family: 'false' } }">{{ t('dashboard.warnings.wordPrompts') }}</RouterLink>
              <RouterLink :to="{ name: 'question-prompts', query: { difficulty: 'easy', family: 'false' } }">{{ t('dashboard.warnings.questionPrompts') }}</RouterLink>
            </span>
          </li>
        </ul>
        <p v-else class="dashboard-empty">{{ t('dashboard.warnings.empty') }}</p>
      </section>
    </template>
  </section>
</template>
